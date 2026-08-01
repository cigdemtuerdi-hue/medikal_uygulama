const express = require('express');
const { requireAdmin } = require('../controllers/adminAuthController');
const {
  listUsers,
  listListings,
  overview,
} = require('../controllers/adminDataController');

const router = express.Router();

/**
 * Operator console data — mounted at /api/admin
 *
 * GET /overview  → user and listing counts
 * GET /users     → registered accounts, newest first
 * GET /listings  → every published listing, including hidden ones
 */
router.use(requireAdmin);

router.get('/overview', overview);
router.get('/users', listUsers);
router.get('/listings', listListings);

module.exports = router;
