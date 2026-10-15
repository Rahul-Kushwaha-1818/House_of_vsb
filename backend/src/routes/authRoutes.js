const express = require('express');
const router = express.Router();
const {
  login,
  signup,
  forgotPassword,
  resetPassword,
  registerPushToken,
  getMe,
  getDemoAccounts,
} = require('../controllers/authController');
const { authenticate } = require('../middleware/auth');

router.post('/login', login);
router.post('/signup', signup);
router.post('/forgot-password', forgotPassword);
router.post('/reset-password', resetPassword);
router.post('/push-token', authenticate, registerPushToken);
router.get('/me', authenticate, getMe);
router.get('/demo-accounts', getDemoAccounts);

module.exports = router;
