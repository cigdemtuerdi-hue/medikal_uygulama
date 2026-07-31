const mongoose = require('mongoose');
const {
  ConsentLog,
  AuditLog,
  hashIdentifier,
  MemoryComplianceStore,
} = require('../models/complianceModels');

const HIPAA_NOTICE_VERSION = 'hipaa-npp-2026.07';

function usingMongo() {
  return mongoose.connection.readyState === 1;
}

function clientIp(req) {
  const xf = req.headers['x-forwarded-for'];
  if (typeof xf === 'string' && xf.trim()) {
    return xf.split(',')[0].trim();
  }
  return req.ip || req.socket?.remoteAddress || null;
}

/**
 * POST /api/compliance/consent
 * Body: { email?, userId?, consentType, version?, accepted }
 */
async function recordConsent(req, res, next) {
  try {
    const email = String(req.body?.email || '')
      .trim()
      .toLowerCase();
    const userId = req.body?.userId ? String(req.body.userId) : null;
    const consentType = String(req.body?.consentType || '').trim();
    const version = String(req.body?.version || HIPAA_NOTICE_VERSION).trim();
    const accepted = req.body?.accepted !== false;

    if (!consentType) {
      return res.status(400).json({
        success: false,
        message: 'consentType required',
        code: 'CONSENT_TYPE_REQUIRED',
      });
    }
    if (!accepted) {
      return res.status(400).json({
        success: false,
        message: 'Consent must be accepted to continue.',
        code: 'CONSENT_NOT_ACCEPTED',
      });
    }

    const doc = {
      userId,
      emailHash: hashIdentifier(email),
      consentType,
      version,
      accepted: true,
      ipAddress: clientIp(req),
      userAgent: String(req.headers['user-agent'] || '').slice(0, 300) || null,
      metadata: {
        noticeVersion: HIPAA_NOTICE_VERSION,
      },
    };

    if (usingMongo()) {
      await ConsentLog.create(doc);
    } else {
      await MemoryComplianceStore.addConsent(doc);
    }

    return res.status(201).json({
      success: true,
      message: 'Consent recorded.',
      version,
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/compliance/audit
 * Body: { actorEmail?, actorUserId?, actorRole?, action, resourceType, resourceId?, details? }
 */
async function recordAudit(req, res, next) {
  try {
    const action = String(req.body?.action || '').trim().toLowerCase();
    const resourceType = String(req.body?.resourceType || '').trim();
    if (!['read', 'write', 'delete'].includes(action) || !resourceType) {
      return res.status(400).json({
        success: false,
        message: 'action (read|write|delete) and resourceType required',
        code: 'AUDIT_INVALID',
      });
    }

    const doc = {
      actorUserId: req.body?.actorUserId
        ? String(req.body.actorUserId)
        : null,
      actorEmailHash: hashIdentifier(req.body?.actorEmail),
      actorRole: req.body?.actorRole ? String(req.body.actorRole) : null,
      action,
      resourceType,
      resourceId: req.body?.resourceId
        ? String(req.body.resourceId).slice(0, 120)
        : null,
      ipAddress: clientIp(req),
      userAgent: String(req.headers['user-agent'] || '').slice(0, 300) || null,
      details: req.body?.details
        ? String(req.body.details).slice(0, 500)
        : null,
    };

    if (usingMongo()) {
      await AuditLog.create(doc);
    } else {
      await MemoryComplianceStore.addAudit(doc);
    }

    return res.status(201).json({
      success: true,
      persistence: usingMongo() ? 'mongo' : 'memory',
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/compliance/notice-version
 */
function noticeVersion(_req, res) {
  return res.json({
    success: true,
    version: HIPAA_NOTICE_VERSION,
    path: '/hipaa-privacy-notice',
  });
}

module.exports = {
  recordConsent,
  recordAudit,
  noticeVersion,
  HIPAA_NOTICE_VERSION,
  clientIp,
};
