const express = require('express');
const router = express.Router();
const {
  getAuctions,
  getAuctionById,
  createAuction,
  placeBid,
} = require('../controllers/auctionController');
const { authenticate, optionalAuth, requireAdmin } = require('../middleware/auth');
const upload = require('../middleware/upload');

// Public / Personalized listing
router.get('/', optionalAuth, getAuctions);
router.get('/:id', optionalAuth, getAuctionById);

// Admin-only creation
router.post('/', authenticate, requireAdmin, upload.single('image'), createAuction);

// Authenticated bidding
router.post('/:id/bid', authenticate, placeBid);

module.exports = router;
