const mongoose = require('mongoose');
const crypto = require('crypto');

const consentLogSchema = new mongoose.Schema(
  {
    userId: { type: String, default: null, index: true },
    emailHash: { type: String, default: null, index: true },
    consentType: { type: String, required: true, index: true },
    version: { type: String, required: true },
    accepted: { type: Boolean, required: true, default: true },
    ipAddress: { type: String, default: null },
    userAgent: { type: String, default: null },
    metadata: { type: mongoose.Schema.Types.Mixed, default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

const ConsentLog =
  mongoose.models.ConsentLog || mongoose.model('ConsentLog', consentLogSchema);

const auditLogSchema = new mongoose.Schema(
  {
    actorUserId: { type: String, default: null, index: true },
    actorEmailHash: { type: String, default: null, index: true },
    actorRole: { type: String, default: null },
    action: { type: String, required: true, index: true }, // read|write|delete
    resourceType: { type: String, required: true, index: true },
    resourceId: { type: String, default: null, index: true },
    ipAddress: { type: String, default: null },
    userAgent: { type: String, default: null },
    details: { type: String, default: null },
  },
  { timestamps: { createdAt: true, updatedAt: false } },
);

const AuditLog =
  mongoose.models.AuditLog || mongoose.model('AuditLog', auditLogSchema);

function hashIdentifier(value) {
  if (!value) return null;
  return crypto
    .createHash('sha256')
    .update(String(value).trim().toLowerCase())
    .digest('hex');
}

/** In-memory fallbacks when Mongo is down. */
const memoryConsent = [];
const memoryAudit = [];

const MemoryComplianceStore = {
  async addConsent(doc) {
    const row = {
      _id: crypto.randomBytes(12).toString('hex'),
      ...doc,
      createdAt: new Date(),
    };
    memoryConsent.push(row);
    return row;
  },
  async addAudit(doc) {
    const row = {
      _id: crypto.randomBytes(12).toString('hex'),
      ...doc,
      createdAt: new Date(),
    };
    memoryAudit.push(row);
    return row;
  },
  async listAudit({ limit = 100 } = {}) {
    return [...memoryAudit].reverse().slice(0, limit);
  },
  async listConsent({ limit = 100 } = {}) {
    return [...memoryConsent].reverse().slice(0, limit);
  },
};

module.exports = {
  ConsentLog,
  AuditLog,
  hashIdentifier,
  MemoryComplianceStore,
};
