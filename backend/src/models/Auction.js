const mongoose = require('mongoose');

const bidSchema = new mongoose.Schema({
  bidder: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  amount: {
    type: Number,
    required: true,
    min: 0,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

const auctionSchema = new mongoose.Schema({
  title: {
    type: String,
    required: [true, 'Title is required'],
    trim: true,
  },
  description: {
    type: String,
    required: [true, 'Description is required'],
    trim: true,
  },
  imageUrl: {
    type: String,
    default: '',
  },
  startingPrice: {
    type: Number,
    required: [true, 'Starting price is required'],
    min: [0, 'Starting price cannot be negative'],
  },
  minIncrement: {
    type: Number,
    required: [true, 'Minimum increment is required'],
    min: [1, 'Minimum increment must be at least 1'],
  },
  currentHighestBid: {
    type: Number,
    default: 0,
  },
  currentHighestBidder: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  bids: [bidSchema],
  startTime: {
    type: Date,
    required: [true, 'Start time is required'],
  },
  endTime: {
    type: Date,
    required: [true, 'End time is required'],
  },
  status: {
    type: String,
    enum: ['upcoming', 'live', 'ended'],
    default: 'upcoming',
  },
  winner: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    default: null,
  },
  createdBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },
  createdAt: {
    type: Date,
    default: Date.now,
  },
});

// Indexes for query performance and cron scanning
auctionSchema.index({ status: 1, endTime: 1 });
auctionSchema.index({ status: 1, startTime: 1 });
auctionSchema.index({ 'bids.bidder': 1 });

module.exports = mongoose.model('Auction', auctionSchema);
