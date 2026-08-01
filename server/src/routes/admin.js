const express = require('express');
const { requireAdmin } = require('../controllers/adminAuthController');
const {
  listUsers,
  listListings,
  overview,
} = require('../controllers/adminDataController');
const {
  getAdminSettings,
  putAdminSettings,
} = require('../controllers/settingsController');

const router = express.Router();

/**
 * Operator console data — mounted at /api/admin
 *
 * GET  /overview   → user and listing counts
 * GET  /users      → registered accounts, newest first
 * GET  /listings   → every published listing, including hidden ones
 * GET  /settings   → full CMS document (alias of /api/settings/admin)
 * PUT  /settings   → save CMS document (alias of /api/settings/admin)
 */
router.use(requireAdmin);

router.get('/overview', overview);
router.get('/users', listUsers);
router.get('/listings', listListings);
router.get('/settings', getAdminSettings);
router.put('/settings', putAdminSettings);

module.exports = router;
