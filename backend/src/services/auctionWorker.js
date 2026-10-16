const Auction = require('../models/Auction');
const { broadcastAuctionEnded, broadcastAuctionStarted } = require('./socketService');

let workerInterval = null;

const processAuctionTransitions = async () => {
  const now = new Date();

  try {
    // 1. Transition Upcoming -> Live
    const upcomingToLive = await Auction.find({
      status: 'upcoming',
      startTime: { $lte: now },
      endTime: { $gt: now },
    });

    for (const auction of upcomingToLive) {
      auction.status = 'live';
      await auction.save();
      console.log(`[Auction Worker] Auction "${auction.title}" (${auction._id}) is now LIVE.`);
      broadcastAuctionStarted(auction._id, {
        auctionId: auction._id,
        title: auction.title,
        status: 'live',
      });
    }

    // 2. Transition Live -> Ended (and any missed upcoming that already passed endTime)
    const expiredAuctions = await Auction.find({
      status: { $in: ['live', 'upcoming'] },
      endTime: { $lte: now },
    }).populate('currentHighestBidder', 'name email');

    for (const auction of expiredAuctions) {
      auction.status = 'ended';
      // If bids were placed, winner is the currentHighestBidder, otherwise null
      if (auction.bids && auction.bids.length > 0 && auction.currentHighestBidder) {
        auction.winner = auction.currentHighestBidder._id;
      } else {
        auction.winner = null;
      }
      await auction.save();

      const winnerInfo = auction.currentHighestBidder
        ? { id: auction.currentHighestBidder._id, name: auction.currentHighestBidder.name, email: auction.currentHighestBidder.email }
        : null;

      console.log(
        `[Auction Worker] Auction "${auction.title}" (${auction._id}) ENDED. Winner: ${
          winnerInfo ? `${winnerInfo.name} ($${auction.currentHighestBid})` : 'No Bids (Unsold)'
        }`
      );

      broadcastAuctionEnded(auction._id, {
        auctionId: auction._id,
        title: auction.title,
        status: 'ended',
        winner: winnerInfo,
        highestBid: auction.currentHighestBid,
      });
    }
  } catch (error) {
    console.error('[Auction Worker] Error running auction lifecycle processor:', error);
  }
};

const startAuctionWorker = (intervalMs = 4000) => {
  // Run immediately on boot to handle any auctions that expired while offline
  processAuctionTransitions();

  if (workerInterval) {
    clearInterval(workerInterval);
  }

  workerInterval = setInterval(processAuctionTransitions, intervalMs);
  console.log(`[Auction Worker] Background worker started (polling interval: ${intervalMs}ms)`);
};

const stopAuctionWorker = () => {
  if (workerInterval) {
    clearInterval(workerInterval);
    workerInterval = null;
    console.log('[Auction Worker] Background worker stopped');
  }
};

module.exports = {
  startAuctionWorker,
  stopAuctionWorker,
  processAuctionTransitions,
};
