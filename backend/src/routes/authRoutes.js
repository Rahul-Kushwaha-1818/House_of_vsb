const express = require('express');
const router = express.Router();
const {
  login,
  getMe,
  getDemoAccounts,
} = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

router.post('/login', login);
router.get('/me', authenticate, getMe);
router.get('/demo-accounts', getDemoAccounts);

module.exports = router;
