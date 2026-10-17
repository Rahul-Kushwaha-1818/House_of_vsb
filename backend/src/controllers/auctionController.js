const Auction = require('../models/Auction');
const { broadcastNewBid, broadcastAuctionCreated } = require('../services/socketService');

// Get all auctions with optional filters: status, myBids
const getAuctions = async (req, res, next) => {
  try {
    const { status, myBids } = req.query;
    const filter = {};

    if (status && ['live', 'upcoming', 'ended'].includes(status)) {
      filter.status = status;
    }

    if (myBids === 'true' && req.user) {
      filter['bids.bidder'] = req.user._id;
    }

    const auctions = await Auction.find(filter)
      .sort({ createdAt: -1 })
      .populate('currentHighestBidder', 'name email')
      .populate('winner', 'name email')
      .populate('createdBy', 'name email');

    // Attach computed userOutcome for convenience
    const currentUserId = req.user ? req.user._id.toString() : null;
    const mapped = auctions.map((auction) => {
      const obj = auction.toObject();
      if (obj.bids && Array.isArray(obj.bids)) {
        obj.bids.sort((a, b) => b.amount - a.amount);
      }
      if (currentUserId && obj.bids && obj.bids.some(b => b.bidder.toString() === currentUserId)) {
        if (obj.status === 'ended') {
          obj.userOutcome = (obj.winner && obj.winner._id.toString() === currentUserId) ? 'won' : 'lost';
        } else if (obj.status === 'live') {
          obj.userOutcome = (obj.currentHighestBidder && obj.currentHighestBidder._id.toString() === currentUserId) ? 'winning' : 'outbid';
        } else {
          obj.userOutcome = 'participated';
        }
      }
      return obj;
    });

    return res.status(200).json({
      success: true,
      count: mapped.length,
      auctions: mapped,
    });
  } catch (error) {
    next(error);
  }
};

// Get single auction with complete bid history
const getAuctionById = async (req, res, next) => {
  try {
    const { id } = req.params;

    const auction = await Auction.findById(id)
      .populate('currentHighestBidder', 'name email')
      .populate('winner', 'name email')
      .populate('createdBy', 'name email')
      .populate('bids.bidder', 'name email');

    if (!auction) {
      return res.status(404).json({
        success: false,
        message: 'Auction not found',
      });
    }

    const obj = auction.toObject();
    if (obj.bids && Array.isArray(obj.bids)) {
      obj.bids.sort((a, b) => b.amount - a.amount);
    }
    const currentUserId = req.user ? req.user._id.toString() : null;
    if (currentUserId && obj.bids && obj.bids.some(b => b.bidder._id.toString() === currentUserId)) {
      if (obj.status === 'ended') {
        obj.userOutcome = (obj.winner && obj.winner._id.toString() === currentUserId) ? 'won' : 'lost';
      } else if (obj.status === 'live') {
        obj.userOutcome = (obj.currentHighestBidder && obj.currentHighestBidder._id.toString() === currentUserId) ? 'winning' : 'outbid';
      } else {
        obj.userOutcome = 'participated';
      }
    }

    return res.status(200).json({
      success: true,
      auction: obj,
    });
  } catch (error) {
    next(error);
  }
};

// Create an auction (Admin only)
const createAuction = async (req, res, next) => {
  try {
    const { title, description, startingPrice, minIncrement, startTime, endTime } = req.body;

    if (!title || !description || startingPrice === undefined || minIncrement === undefined || !startTime || !endTime) {
      return res.status(400).json({
        success: false,
        message: 'Please provide all required fields (title, description, startingPrice, minIncrement, startTime, endTime)',
      });
    }

    const numStartingPrice = Number(startingPrice);
    const numMinIncrement = Number(minIncrement);
    const startDate = new Date(startTime);
    const endDate = new Date(endTime);
    const now = new Date();

    if (isNaN(numStartingPrice) || numStartingPrice < 0) {
      return res.status(400).json({
        success: false,
        message: 'Starting price must be a non-negative number',
      });
    }

    if (isNaN(numMinIncrement) || numMinIncrement < 1) {
      return res.status(400).json({
        success: false,
        message: 'Minimum bid increment must be at least 1',
      });
    }

    if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid date format for startTime or endTime',
      });
    }

    if (endDate <= startDate) {
      return res.status(400).json({
        success: false,
        message: 'End time must be after start time',
      });
    }

    if (endDate <= now) {
      return res.status(400).json({
        success: false,
        message: 'End time must be in the future',
      });
    }

    // Determine initial status based on start time
    // Allow a 60-second grace window to account for network transmission time and slight clock drift
    const graceWindow = new Date(now.getTime() + 60 * 1000);
    let initialStatus = 'upcoming';
    let actualStartDate = startDate;
    if (startDate <= graceWindow && endDate > now) {
      initialStatus = 'live';
      if (startDate > now) {
        actualStartDate = now;
      }
    }

    // Handle image file or URL fallback
    let imageUrl = req.body.imageUrl || '';
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    }

    const auction = await Auction.create({
      title,
      description,
      startingPrice: numStartingPrice,
      minIncrement: numMinIncrement,
      currentHighestBid: 0,
      currentHighestBidder: null,
      startTime: actualStartDate,
      endTime: endDate,
      status: initialStatus,
      imageUrl,
      createdBy: req.user._id,
      bids: [],
    });

    const populated = await Auction.findById(auction._id)
      .populate('createdBy', 'name email');

    broadcastAuctionCreated(populated); // here we update the without refreashing the page

    return res.status(201).json({
      success: true,
      message: 'Auction created successfully',
      auction: populated,
    });
  } catch (error) {
    next(error);
  }
};

// Place a bid (Concurrency safe via MongoDB atomic condition)
const placeBid = async (req, res, next) => {
  try {
    const { id } = req.params;
    const amount = Number(req.body.amount);

    if (isNaN(amount) || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Please provide a valid bid amount greater than zero',
      });
    }

    // Role check: Admin is not supposed to bid
    if (req.user.role === 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Admins cannot place bids on auctions',
      });
    }

    const now = new Date();

    // Fetch existing state for descriptive preliminary validation
    const auction = await Auction.findById(id);
    if (!auction) {
      return res.status(404).json({
        success: false,
        message: 'Auction not found',
      });
    }

    // Rule: Accepts bids only between start time and end time
    if (auction.status === 'upcoming' || (auction.status !== 'live' && now < new Date(auction.startTime))) {
      return res.status(400).json({
        success: false,
        message: `Auction has not started yet. Begins at ${new Date(auction.startTime).toLocaleString()}`,
      });
    }

    if (now >= new Date(auction.endTime) || auction.status === 'ended') {
      return res.status(400).json({
        success: false,
        message: 'Auction has already ended',
      });
    }

    // Prevent bidder from outbidding themselves if already holding the top bid
    if (auction.currentHighestBidder && auction.currentHighestBidder.toString() === req.user._id.toString()) {
      return res.status(400).json({
        success: false,
        message: 'You already hold the highest bid on this auction',
      });
    }

    // Rule: First bid >= starting price; Each later bid >= currentHighestBid + minIncrement
    const hasExistingBids = auction.bids && auction.bids.length > 0;
    const minRequiredBid = hasExistingBids
      ? auction.currentHighestBid + auction.minIncrement
      : auction.startingPrice;

    if (amount < minRequiredBid) {
      return res.status(400).json({
        success: false,
        message: hasExistingBids
          ? `Bid too low. Minimum required bid is ₹${minRequiredBid} (Current highest: ₹${auction.currentHighestBid} + ₹${auction.minIncrement} increment)`
          : `Bid too low. The first bid must be at least the starting price of ₹${auction.startingPrice}`,
        minRequiredBid,
        currentHighestBid: auction.currentHighestBid,
      });
    }

    const previousHighestBidderId = auction.currentHighestBidder ? auction.currentHighestBidder.toString() : null;

    // ATOMIC CONCURRENCY GUARD:
    // Execute atomic findOneAndUpdate with condition filter.
    // If two requests bid simultaneously, only the one satisfying the condition succeeds.
    const filter = {
      _id: id,
      status: 'live',
      startTime: { $lte: now },
      endTime: { $gt: now },
    };

    if (!hasExistingBids) {
      // First bid condition: no bids in array yet AND startingPrice <= amount
      filter.bids = { $size: 0 };
      filter.startingPrice = { $lte: amount };
    } else {
      // Subsequent bid condition: current highest bid must not have surpassed (amount - minIncrement)
      filter.currentHighestBid = { $lte: amount - auction.minIncrement };
    }

    const update = {
      $set: {
        currentHighestBid: amount,
        currentHighestBidder: req.user._id,
      },
      $push: {
        bids: {
          bidder: req.user._id,
          amount,
          createdAt: now,
        },
      },
    };

    const updatedAuction = await Auction.findOneAndUpdate(filter, update, {
      new: true,
    })
      .populate('currentHighestBidder', 'name email')
      .populate('bids.bidder', 'name email');

    if (!updatedAuction) {
      // The atomic condition failed! Re-inspect auction to report exact conflict reason
      const fresh = await Auction.findById(id).populate('currentHighestBidder', 'name');
      if (!fresh || fresh.status === 'ended' || now >= new Date(fresh.endTime)) {
        return res.status(409).json({
          success: false,
          message: 'Bid rejected: The auction ended before your bid could be processed.',
        });
      }

      const freshMin = fresh.bids.length === 0
        ? fresh.startingPrice
        : fresh.currentHighestBid + fresh.minIncrement;

      return res.status(409).json({
        success: false,
        message: `Conflict! Another bidder placed a bid of ₹${fresh.currentHighestBid} just ahead of you. Minimum required bid is now ₹${freshMin}.`,
        currentHighestBid: fresh.currentHighestBid,
        minRequiredBid: freshMin,
      });
    }

    // Success: Extract newly added bid and broadcast in real-time
    const latestBid = updatedAuction.bids[updatedAuction.bids.length - 1];

    broadcastNewBid(id, {
      auctionId: id,
      bid: {
        _id: latestBid._id,
        amount: latestBid.amount,
        bidder: {
          _id: req.user._id,
          name: req.user.name,
          email: req.user.email,
        },
        createdAt: latestBid.createdAt,
      },
      currentHighestBid: updatedAuction.currentHighestBid,
      currentHighestBidder: {
        _id: req.user._id,
        name: req.user.name,
        email: req.user.email,
      },
      totalBids: updatedAuction.bids.length,
    });

    const returnAuction = updatedAuction.toObject();
    if (returnAuction.bids && Array.isArray(returnAuction.bids)) {
      returnAuction.bids.sort((a, b) => b.amount - a.amount);
    }

    return res.status(200).json({
      success: true,
      message: 'Bid placed successfully!',
      auction: returnAuction,
      placedBid: latestBid,
    });
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getAuctions,
  getAuctionById,
  createAuction,
  placeBid,
};
