const express = require('express');
const { requireUser } = require('../middleware/userAuth');
const {
  create,
  listMine,
  browse,
  matches,
  reserve,
  update,
} = require('../controllers/listingController');

const router = express.Router();

/**
 * Listing routes — mounted at /api/listings
 *
 * Every route requires a signed session token: browse returns other people's
 * listings, so an unauthenticated or spoofable caller must never reach it.
 *
 * POST   /                → publish an offer (donor) or request (recipient)
 * GET    /mine            → the caller's own listings, full detail
 * GET    /browse          → counterpart listings with contact details stripped
 * GET    /:id/matches     → ranked counterparts for one of the caller's listings
 * POST   /:id/reserve     → 48-hour hold on a counterpart listing
 * PATCH  /:id             → owner-only edit / status change
 */
router.use(requireUser);

router.post('/', create);
router.get('/mine', listMine);
router.get('/browse', browse);
router.get('/:id/matches', matches);
router.post('/:id/reserve', reserve);
router.patch('/:id', update);

module.exports = router;
