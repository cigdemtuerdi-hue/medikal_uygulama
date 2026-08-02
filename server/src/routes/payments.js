const express = require('express');
const { requireUser } = require('../middleware/userAuth');
const {
  getOrder,
  getOrderBySession,
} = require('../controllers/paymentController');

const router = express.Router();

/**
 * Order read routes — mounted at /api/orders
 * (Webhook lives on /api/payments/webhook with a raw body parser.)
 */
router.use(requireUser);
router.get('/by-session/:sessionId', getOrderBySession);
router.get('/:id', getOrder);

module.exports = router;
