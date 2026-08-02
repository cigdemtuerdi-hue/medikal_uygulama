const mongoose = require('mongoose');

/**
 * Listing — one durable medical equipment offer (donor), need (recipient),
 * or paid sale listing.
 *
 * Both donation sides share a schema so browse and matching can run one query
 * instead of joining two collections. `kind` separates them; `sale` carries a
 * price and is browsed on the shop surface rather than the donate matcher.
 *
 * Location is stored as city/state/postalCode. The public projection in
 * listingController never exposes street address or the owner's contact
 * details; see toPublicJson there.
 */
const listingSchema = new mongoose.Schema(
  {
    /** 'offer' | 'request' | 'sale' */
    kind: {
      type: String,
      required: true,
      enum: ['offer', 'request', 'sale'],
      index: true,
    },
    ownerUserId: {
      type: String,
      required: true,
      index: true,
    },
    ownerEmail: {
      type: String,
      required: true,
      lowercase: true,
      trim: true,
    },
    ownerRole: {
      type: String,
      default: null,
    },
    title: {
      type: String,
      required: true,
      trim: true,
      maxlength: 120,
    },
    description: {
      type: String,
      default: '',
      trim: true,
      maxlength: 2000,
    },
    /** Equipment family, e.g. wheelchair, hospitalBed, walker, oxygen. */
    category: {
      type: String,
      required: true,
      trim: true,
      index: true,
    },
    /** new | likeNew | good | fair — only meaningful for offers. */
    condition: {
      type: String,
      default: null,
    },
    /** Free-form size/spec note, e.g. "18 inch seat", "bariatric". */
    sizeNote: {
      type: String,
      default: null,
      trim: true,
      maxlength: 160,
    },
    quantity: {
      type: Number,
      default: 1,
      min: 1,
      max: 999,
    },
    /** low | normal | high — recipients can flag urgency. */
    urgency: {
      type: String,
      default: 'normal',
    },
    city: {
      type: String,
      default: null,
      trim: true,
    },
    state: {
      type: String,
      default: null,
      trim: true,
      uppercase: true,
    },
    postalCode: {
      type: String,
      default: null,
      trim: true,
      index: true,
    },
    /**
     * Up to five photo URLs, in display order. Paths returned by
     * /api/uploads, validated in listingController before they land here.
     */
    photos: {
      type: [String],
      default: [],
      validate: {
        validator: (value) => !value || value.length <= 5,
        message: 'En fazla 5 görsel eklenebilir.',
      },
    },
    /**
     * Kept as the cover image for listings created before `photos` existed.
     * Writers mirror photos[0] into it; readers should prefer `photos`.
     */
    photoUrl: {
      type: String,
      default: null,
      trim: true,
      maxlength: 600,
    },
    /**
     * Asking price in USD cents. Required for `sale`; ignored for donate
     * kinds. Stored as an integer so $17.00 never becomes 16.999999.
     */
    priceCents: {
      type: Number,
      default: null,
      min: 100,
      max: 100000000,
    },
    currency: {
      type: String,
      default: 'USD',
      uppercase: true,
      trim: true,
      maxlength: 3,
    },
    /** Platform take rate applied at create time (currently 0.17). */
    commissionRate: {
      type: Number,
      default: 0.17,
      min: 0,
      max: 1,
    },
    /** active | reserved | fulfilled | withdrawn */
    status: {
      type: String,
      default: 'active',
      index: true,
    },
    /** Set when a counterpart reserves it; drives the 48-hour rule. */
    reservedByUserId: {
      type: String,
      default: null,
    },
    reservedUntil: {
      type: Date,
      default: null,
    },
    /** Admin moderation flag — hidden from browse when true. */
    hidden: {
      type: Boolean,
      default: false,
      index: true,
    },
  },
  {
    timestamps: true,
  },
);

listingSchema.index({ kind: 1, status: 1, category: 1 });

module.exports = mongoose.model('Listing', listingSchema);
