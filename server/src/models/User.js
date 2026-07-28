const mongoose = require('mongoose');

/**
 * User — auth identity for MedGift US.
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
    /** E.164-ish phone used for SMS OTP reset (optional). */
    phone: {
      type: String,
      default: null,
      trim: true,
      index: true,
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
    /** SHA-256 of the 4-digit SMS OTP. */
    resetSmsCodeHash: {
      type: String,
      default: null,
      index: true,
    },
    /** Absolute expiry for the SMS OTP (typically now + 10 minutes). */
    resetSmsExpires: {
      type: Date,
      default: null,
    },
  },
  {
    timestamps: true,
  },
);

module.exports = mongoose.model('User', userSchema);
