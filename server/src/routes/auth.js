const express = require('express');
const {
  forgotPassword,
  resetPassword,
  resetPasswordSms,
} = require('../controllers/authController');
const {
  forgotPasswordLimiter,
  resetPasswordLimiter,
} = require('../middleware/rateLimit');

const router = express.Router();

/**
 * Auth routes — mounted at /api/auth
 *
 * POST /forgot-password          → email link OR SMS 4-digit OTP (method)
 * POST /reset-password/:token    → redeem email token
 * POST /reset-password-sms       → redeem SMS OTP + set password
 */
router.post('/forgot-password', forgotPasswordLimiter, forgotPassword);
router.post('/reset-password/:token', resetPasswordLimiter, resetPassword);
router.post('/reset-password-sms', resetPasswordLimiter, resetPasswordSms);

module.exports = router;
