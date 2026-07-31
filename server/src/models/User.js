const mongoose = require('mongoose');
const { encryptPhi, decryptPhi, isEncryptedPhi } = require('../utils/phiCrypto');

/**
 * User — auth identity for MedGift US.
 * Phone (PII) is stored AES-256-GCM encrypted at rest when set.
 */
const userSchema = new mongoose.Schema(
  {
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      index: true,
    },
    /**
     * Optional contact phone — AES-256-GCM ciphertext (`v1:...`) preferred.
     * Legacy plaintext values are accepted and re-encrypted on next save.
     */
    phone: {
      type: String,
      default: null,
      trim: true,
    },
    /** Digits-only hash for lookup without storing plaintext phone. */
    phoneLookupHash: {
      type: String,
      default: null,
      index: true,
    },
    /** App role: donor | recipient | ngoPartner */
    role: {
      type: String,
      default: null,
      index: true,
    },
    hipaaConsentVersion: {
      type: String,
      default: null,
    },
    hipaaConsentAt: {
      type: Date,
      default: null,
    },
    passwordHash: {
      type: String,
      default: null,
      select: false,
    },
    /** SHA-256 of the emailed one-time reset token. */
    resetPasswordToken: {
      type: String,
      default: null,
      index: true,
    },
    resetPasswordExpires: {
      type: Date,
      default: null,
    },
    /** Legacy SMS OTP fields (unused — SMS reset removed). */
    resetSmsCodeHash: {
      type: String,
      default: null,
      index: true,
    },
    resetSmsExpires: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

userSchema.methods.getDecryptedPhone = function getDecryptedPhone() {
  if (!this.phone) return null;
  try {
    return decryptPhi(this.phone);
  } catch (_) {
    return null;
  }
};

userSchema.pre('save', function encryptPhonePreSave(next) {
  if (!this.isModified('phone') || !this.phone) return next();
  if (isEncryptedPhi(this.phone)) return next();
  const crypto = require('crypto');
  const digits = String(this.phone).replace(/\D/g, '');
  if (digits) {
    this.phoneLookupHash = crypto
      .createHash('sha256')
      .update(digits)
      .digest('hex');
  }
  this.phone = encryptPhi(this.phone);
  return next();
});

module.exports = mongoose.model('User', userSchema);
