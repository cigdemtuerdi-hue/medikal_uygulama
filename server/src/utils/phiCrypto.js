const crypto = require('crypto');

/**
 * AES-256-GCM helpers for PHI/PII at rest.
 * Key: PHI_ENCRYPTION_KEY (64 hex chars = 32 bytes) or derived from ADMIN_PASSWORD+salt.
 */

const ALGO = 'aes-256-gcm';
const IV_LEN = 12;
const TAG_LEN = 16;

function resolveKey() {
  const raw = (process.env.PHI_ENCRYPTION_KEY || '').trim();
  if (/^[0-9a-fA-F]{64}$/.test(raw)) {
    return Buffer.from(raw, 'hex');
  }
  // Deterministic fallback so memory/dev deploys still encrypt (rotate via env in prod).
  const seed =
    (process.env.PHI_ENCRYPTION_SECRET ||
      process.env.ADMIN_PASSWORD ||
      'medgift-dev-phi-key').toString();
  return crypto.createHash('sha256').update(`medgift-phi-v1:${seed}`).digest();
}

function encryptPhi(plaintext) {
  if (plaintext == null || plaintext === '') return null;
  const key = resolveKey();
  const iv = crypto.randomBytes(IV_LEN);
  const cipher = crypto.createCipheriv(ALGO, key, iv);
  const enc = Buffer.concat([
    cipher.update(String(plaintext), 'utf8'),
    cipher.final(),
  ]);
  const tag = cipher.getAuthTag();
  return `v1:${iv.toString('base64')}:${tag.toString('base64')}:${enc.toString('base64')}`;
}

function decryptPhi(payload) {
  if (payload == null || payload === '') return null;
  const text = String(payload);
  if (!text.startsWith('v1:')) return text; // legacy plaintext
  const parts = text.split(':');
  if (parts.length !== 4) return null;
  const [, ivB64, tagB64, dataB64] = parts;
  const key = resolveKey();
  const decipher = crypto.createDecipheriv(
    ALGO,
    key,
    Buffer.from(ivB64, 'base64'),
  );
  decipher.setAuthTag(Buffer.from(tagB64, 'base64'));
  const dec = Buffer.concat([
    decipher.update(Buffer.from(dataB64, 'base64')),
    decipher.final(),
  ]);
  return dec.toString('utf8');
}

function isEncryptedPhi(value) {
  return typeof value === 'string' && value.startsWith('v1:');
}

module.exports = {
  encryptPhi,
  decryptPhi,
  isEncryptedPhi,
};
