const rateLimit = require('express-rate-limit');

/**
 * Shared JSON body for rate-limit responses (generic — no endpoint hints).
 */
function rateLimitHandler(_req, res) {
  res.status(429).json({
    success: false,
    message: 'Çok fazla istek gönderildi. Lütfen daha sonra tekrar deneyin.',
    code: 'RATE_LIMITED',
  });
}

/**
 * Forgot-password is email-enumeration sensitive — keep the window tight.
 * 5 requests / 15 minutes per IP.
 */
const forgotPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

/**
 * Reset-password protects against token / password brute-force.
 * 10 requests / 15 minutes per IP.
 */
const resetPasswordLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  standardHeaders: true,
  legacyHeaders: false,
  handler: rateLimitHandler,
});

module.exports = {
  forgotPasswordLimiter,
  resetPasswordLimiter,
};
