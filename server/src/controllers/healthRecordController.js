const mongoose = require('mongoose');
const {
  HealthRecord,
  encryptPayload,
  decryptRecord,
  MemoryHealthStore,
} = require('../models/healthRecordModel');
const {
  AuditLog,
  hashIdentifier,
  MemoryComplianceStore,
} = require('../models/complianceModels');
const { canAccessRecord } = require('../middleware/rbac');
const { clientIp } = require('./complianceController');

function usingMongo() {
  return mongoose.connection.readyState === 1;
}

async function writeAudit({
  req,
  action,
  resourceId,
  actor,
  details,
}) {
  const doc = {
    actorUserId: actor?.userId ? String(actor.userId) : null,
    actorEmailHash:
      actor?.emailHash || hashIdentifier(actor?.email) || null,
    actorRole: actor?.role || null,
    action,
    resourceType: 'health_record',
    resourceId: resourceId ? String(resourceId) : null,
    ipAddress: clientIp(req),
    userAgent: String(req.headers['user-agent'] || '').slice(0, 300) || null,
    details: details ? String(details).slice(0, 500) : null,
  };
  if (usingMongo()) {
    await AuditLog.create(doc);
  } else {
    await MemoryComplianceStore.addAudit(doc);
  }
}

/**
 * POST /api/health-records
 * Body: { recordType, title?, notes?, fileRef? }
 * Headers: X-User-Role, X-User-Id, X-User-Email
 */
async function createHealthRecord(req, res, next) {
  try {
    const actor = req.phiActor;
    const recordType = String(req.body?.recordType || '').trim();
    const allowed = [
      'doctor_report',
      'condition_video',
      'id_document',
      'medical_notes',
      'other',
    ];
    if (!allowed.includes(recordType)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid recordType',
        code: 'RECORD_TYPE_INVALID',
      });
    }

    const ownerUserId = String(actor.userId || actor.email || 'anonymous');
    const ownerEmailHash = hashIdentifier(actor.email);
    const enc = encryptPayload({
      title: req.body?.title,
      notes: req.body?.notes,
      fileRef: req.body?.fileRef,
    });

    const base = {
      ownerUserId,
      ownerEmailHash,
      recordType,
      ...enc,
      status: 'active',
    };

    let created;
    if (usingMongo()) {
      created = await HealthRecord.create(base);
    } else {
      created = await MemoryHealthStore.create(base);
    }

    await writeAudit({
      req,
      action: 'write',
      resourceId: created._id,
      actor,
      details: `create:${recordType}`,
    });

    return res.status(201).json({
      success: true,
      record: decryptRecord(created),
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/health-records
 * Lists records owned by the calling user (admin may pass ?ownerUserId=).
 */
async function listHealthRecords(req, res, next) {
  try {
    const actor = req.phiActor;
    let ownerUserId = String(actor.userId || actor.email || '');
    if (actor.role === 'admin' && req.query?.ownerUserId) {
      ownerUserId = String(req.query.ownerUserId);
    }

    let rows = [];
    if (usingMongo()) {
      rows = await HealthRecord.find({
        ownerUserId,
        status: { $ne: 'deleted' },
      })
        .sort({ createdAt: -1 })
        .limit(100);
    } else {
      rows = await MemoryHealthStore.findByOwner(ownerUserId);
    }

    const visible = rows.filter((row) =>
      canAccessRecord({
        actorRole: actor.role,
        actorUserId: actor.userId,
        actorEmailHash: actor.emailHash || hashIdentifier(actor.email),
        record: row,
      }),
    );

    await writeAudit({
      req,
      action: 'read',
      resourceId: null,
      actor,
      details: `list:count=${visible.length}`,
    });

    return res.json({
      success: true,
      records: visible.map(decryptRecord),
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/health-records/:id
 */
async function getHealthRecord(req, res, next) {
  try {
    const actor = req.phiActor;
    const id = String(req.params.id || '');
    let row = null;
    if (usingMongo()) {
      row = await HealthRecord.findById(id);
    } else {
      row = await MemoryHealthStore.findById(id);
    }

    if (!row || row.status === 'deleted') {
      return res.status(404).json({
        success: false,
        message: 'Record not found',
        code: 'NOT_FOUND',
      });
    }

    const allowed = canAccessRecord({
      actorRole: actor.role,
      actorUserId: actor.userId,
      actorEmailHash: actor.emailHash || hashIdentifier(actor.email),
      record: row,
    });
    if (!allowed) {
      return res.status(403).json({
        success: false,
        message: 'RBAC denied for this health record.',
        code: 'RBAC_DENIED',
      });
    }

    await writeAudit({
      req,
      action: 'read',
      resourceId: id,
      actor,
      details: `get:${row.recordType}`,
    });

    return res.json({
      success: true,
      record: decryptRecord(row),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * DELETE /api/health-records/:id  (soft delete)
 */
async function deleteHealthRecord(req, res, next) {
  try {
    const actor = req.phiActor;
    const id = String(req.params.id || '');
    let row = null;
    if (usingMongo()) {
      row = await HealthRecord.findById(id);
    } else {
      row = await MemoryHealthStore.findById(id);
    }

    if (!row || row.status === 'deleted') {
      return res.status(404).json({
        success: false,
        message: 'Record not found',
        code: 'NOT_FOUND',
      });
    }

    const allowed = canAccessRecord({
      actorRole: actor.role,
      actorUserId: actor.userId,
      actorEmailHash: actor.emailHash || hashIdentifier(actor.email),
      record: row,
    });
    if (!allowed) {
      return res.status(403).json({
        success: false,
        message: 'RBAC denied for this health record.',
        code: 'RBAC_DENIED',
      });
    }

    if (usingMongo()) {
      row.status = 'deleted';
      // Wipe ciphertext on delete (minimum necessary retention).
      row.titleEnc = null;
      row.notesEnc = null;
      row.fileRefEnc = null;
      await row.save();
    } else {
      await MemoryHealthStore.softDelete(id);
      row.titleEnc = null;
      row.notesEnc = null;
      row.fileRefEnc = null;
    }

    await writeAudit({
      req,
      action: 'delete',
      resourceId: id,
      actor,
      details: `delete:${row.recordType}`,
    });

    return res.json({ success: true, message: 'Health record deleted.' });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  createHealthRecord,
  listHealthRecords,
  getHealthRecord,
  deleteHealthRecord,
};
