const express = require('express');
const {
  forgotPassword,
  resetPassword,
  register,
  login,
} = require('../controllers/authController');
const {
  forgotPasswordLimiter,
  resetPasswordLimiter,
  authCredentialLimiter,
} = require('../middleware/rateLimit');

const router = express.Router();

/**
 * Auth routes — mounted at /api/auth
 *
 * POST /register                 → create account with password
 * POST /login                    → email + password sign-in
 * POST /forgot-password          → email set/reset link
 * POST /reset-password/:token    → redeem email token
 */
router.post('/register', authCredentialLimiter, register);
router.post('/login', authCredentialLimiter, login);
router.post('/forgot-password', forgotPasswordLimiter, forgotPassword);
router.post('/reset-password/:token', resetPasswordLimiter, resetPassword);

module.exports = router;
