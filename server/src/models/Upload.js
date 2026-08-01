const mongoose = require('mongoose');

/**
 * Upload — a listing photo, stored as bytes in Mongo rather than on disk.
 *
 * Render's filesystem is ephemeral, so anything written to disk disappears on
 * the next deploy. Keeping the bytes in the database that already backs the
 * listings avoids introducing a second service (S3/Cloudinary) and its
 * credentials for what is at most five small JPEGs per listing.
 *
 * The client downscales and re-encodes before uploading, so documents stay far
 * below Mongo's 16 MB cap; `uploadController` also enforces a hard byte limit.
 */
const uploadSchema = new mongoose.Schema(
  {
    ownerUserId: {
      type: String,
      required: true,
      index: true,
    },
    contentType: {
      type: String,
      required: true,
      enum: ['image/jpeg', 'image/png', 'image/webp'],
    },
    byteSize: {
      type: Number,
      required: true,
    },
    data: {
      type: Buffer,
      required: true,
    },
  },
  {
    timestamps: true,
  },
);

module.exports = mongoose.model('Upload', uploadSchema);
