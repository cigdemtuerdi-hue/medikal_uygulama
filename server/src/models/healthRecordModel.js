const mongoose = require('mongoose');
const { encryptPhi, decryptPhi } = require('../utils/phiCrypto');

/**
 * Encrypted health / PHI records (AES-256-GCM at rest).
 * Plaintext PHI never lives in Mongo fields — only ciphertext blobs.
 */
const healthRecordSchema = new mongoose.Schema(
  {
    ownerUserId: { type: String, required: true, index: true },
    ownerEmailHash: { type: String, required: true, index: true },
    recordType: {
      type: String,
      required: true,
      enum: [
        'doctor_report',
        'condition_video',
        'id_document',
        'medical_notes',
        'other',
      ],
      index: true,
    },
    /** AES-256-GCM ciphertext for display title */
    titleEnc: { type: String, default: null },
    /** AES-256-GCM ciphertext for free-text notes / diagnosis summary */
    notesEnc: { type: String, default: null },
    /** AES-256-GCM ciphertext for local file ref / storage key (not raw bytes) */
    fileRefEnc: { type: String, default: null },
    status: {
      type: String,
      default: 'active',
      enum: ['active', 'archived', 'deleted'],
      index: true,
    },
  },
  { timestamps: true },
);

const HealthRecord =
  mongoose.models.HealthRecord ||
  mongoose.model('HealthRecord', healthRecordSchema);

function encryptPayload({ title, notes, fileRef }) {
  return {
    titleEnc: title ? encryptPhi(title) : null,
    notesEnc: notes ? encryptPhi(notes) : null,
    fileRefEnc: fileRef ? encryptPhi(fileRef) : null,
  };
}

function decryptRecord(doc) {
  if (!doc) return null;
  const plain = typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
  return {
    id: String(plain._id || plain.id),
    ownerUserId: plain.ownerUserId,
    recordType: plain.recordType,
    title: decryptPhi(plain.titleEnc),
    notes: decryptPhi(plain.notesEnc),
    fileRef: decryptPhi(plain.fileRefEnc),
    status: plain.status,
    createdAt: plain.createdAt,
    updatedAt: plain.updatedAt,
  };
}

/** In-memory fallback when Mongo is unavailable. */
const memoryRecords = [];
const crypto = require('crypto');

const MemoryHealthStore = {
  async create(doc) {
    const row = {
      _id: crypto.randomBytes(12).toString('hex'),
      ...doc,
      createdAt: new Date(),
      updatedAt: new Date(),
    };
    memoryRecords.push(row);
    return row;
  },
  async findByOwner(ownerUserId) {
    return memoryRecords.filter(
      (r) => r.ownerUserId === ownerUserId && r.status !== 'deleted',
    );
  },
  async findById(id) {
    return memoryRecords.find((r) => r._id === id) || null;
  },
  async softDelete(id) {
    const row = memoryRecords.find((r) => r._id === id);
    if (!row) return null;
    row.status = 'deleted';
    row.updatedAt = new Date();
    return row;
  },
};

module.exports = {
  HealthRecord,
  encryptPayload,
  decryptRecord,
  MemoryHealthStore,
};
