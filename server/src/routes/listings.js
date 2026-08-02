const express = require('express');
const { requireUser } = require('../middleware/userAuth');
const {
  create,
  listMine,
  browse,
  shop,
  matches,
  reserve,
  purchase,
  update,
} = require('../controllers/listingController');
const { createCheckout } = require('../controllers/paymentController');

const router = express.Router();

/**
 * Listing routes — mounted at /api/listings
 *
 * Every route requires a signed session token: browse returns other people's
 * listings, so an unauthenticated or spoofable caller must never reach it.
 *
 * POST   /                → publish offer / request / sale
 * GET    /mine            → the caller's own listings, full detail
 * GET    /browse          → donate-side counterpart listings (PII stripped)
 * GET    /shop            → active paid sale listings (PII stripped)
 * GET    /:id/matches     → ranked counterparts for one of the caller's listings
 * POST   /:id/reserve     → 48-hour hold on a donate counterpart listing
 * POST   /:id/checkout    → Stripe Checkout Session for a sale listing
 * POST   /:id/purchase    → hold-only fallback when Stripe is not configured
 * PATCH  /:id             → owner-only edit / status change
 */
router.use(requireUser);

router.post('/', create);
router.get('/mine', listMine);
router.get('/browse', browse);
router.get('/shop', shop);
router.get('/:id/matches', matches);
router.post('/:id/reserve', reserve);
router.post('/:id/checkout', createCheckout);
router.post('/:id/purchase', purchase);
router.patch('/:id', update);

module.exports = router;
