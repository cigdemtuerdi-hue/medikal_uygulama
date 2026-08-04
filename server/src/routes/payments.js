const express = require('express');
const { requireUser } = require('../middleware/userAuth');
const {
  getOrder,
  getOrderBySession,
  capturePayPalOrder,
} = require('../controllers/paymentController');

const router = express.Router();

/**
 * Order read + PayPal capture — mounted at /api/orders
 * (Stripe webhook: /api/payments/webhook; PayPal webhook: /api/payments/paypal/webhook)
 */
router.post('/paypal/capture', requireUser, capturePayPalOrder);
router.use(requireUser);
router.get('/by-session/:sessionId', getOrderBySession);
router.get('/:id', getOrder);

module.exports = router;
