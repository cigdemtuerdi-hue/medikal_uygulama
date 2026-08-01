const express = require('express');
const { requireUser } = require('../middleware/userAuth');
const {
  uploadImage,
  serveImage,
  MAX_BYTES,
} = require('../controllers/uploadController');

const router = express.Router();

/**
 * Upload routes — mounted at /api/uploads
 *
 * POST /      → store one listing photo (session token required)
 * GET  /:id   → serve the bytes (public; see serveImage for why)
 *
 * The raw parser accepts any type so the controller can reject with a clear
 * 415 after sniffing the bytes; letting express reject on `type` would surface
 * as an opaque 500 from the error handler instead.
 */
router.post(
  '/',
  requireUser,
  express.raw({ type: () => true, limit: MAX_BYTES }),
  uploadImage,
);

router.get('/:id', serveImage);

module.exports = router;
