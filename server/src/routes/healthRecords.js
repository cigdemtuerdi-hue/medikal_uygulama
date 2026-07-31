const express = require('express');
const {
  createHealthRecord,
  listHealthRecords,
  getHealthRecord,
  deleteHealthRecord,
} = require('../controllers/healthRecordController');
const { requirePhiRole } = require('../middleware/rbac');
const { authCredentialLimiter } = require('../middleware/rateLimit');

const router = express.Router();

router.use(requirePhiRole);

router.post('/', authCredentialLimiter, createHealthRecord);
router.get('/', listHealthRecords);
router.get('/:id', getHealthRecord);
router.delete('/:id', authCredentialLimiter, deleteHealthRecord);

module.exports = router;
