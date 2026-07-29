const express = require('express');
const {
  getPublicSettings,
  getAdminSettings,
  putAdminSettings,
} = require('../controllers/settingsController');
const { requireAdmin } = require('../controllers/adminAuthController');

const router = express.Router();

router.get('/public', getPublicSettings);
router.get('/admin', requireAdmin, getAdminSettings);
router.put('/admin', requireAdmin, putAdminSettings);

module.exports = router;
