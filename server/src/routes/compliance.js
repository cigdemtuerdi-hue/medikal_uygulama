const express = require('express');
const {
  recordConsent,
  recordAudit,
  noticeVersion,
} = require('../controllers/complianceController');
const { authCredentialLimiter } = require('../middleware/rateLimit');

const router = express.Router();

router.get('/notice-version', noticeVersion);
router.post('/consent', authCredentialLimiter, recordConsent);
router.post('/audit', authCredentialLimiter, recordAudit);

module.exports = router;
