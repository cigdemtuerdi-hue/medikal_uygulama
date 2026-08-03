const {
  createListing,
  findListingById,
  queryListings,
  countListings,
  updateListing,
} = require('../models/listingStore');
const { uploadExists } = require('../models/uploadStore');

/** Donors publish offers, recipients/NGO publish requests; anyone may sell. */
const KINDS = new Set(['offer', 'request', 'sale']);
const DONATE_KINDS = new Set(['offer', 'request']);
const STATUSES = new Set(['active', 'reserved', 'fulfilled', 'withdrawn']);
const CONDITIONS = new Set(['new', 'likeNew', 'good', 'fair']);
const URGENCIES = new Set(['low', 'normal', 'high']);

/** Platform take on every sale. Sellers see this before they publish. */
const COMMISSION_RATE = 0.17;

/** Floor: $1.00. Ceiling guards against fat-fingered billion-dollar listings. */
const MIN_PRICE_CENTS = 100;
const MAX_PRICE_CENTS = 100_000_000;

/** Reservations expire so stalled handoffs release the item back to browse. */
const RESERVATION_WINDOW_MS = 48 * 60 * 60 * 1000;

const MAX_PHOTOS = 5;

/** Both Mongo ObjectIds and the memory store's ids are 24 hex characters. */
const UPLOAD_PATH_RE = /^\/api\/uploads\/([a-f0-9]{24})$/i;

function clampText(value, max) {
  return String(value ?? '')
    .trim()
    .slice(0, max);
}

/**
 * Accepts only paths this API itself issued, and only ones that still resolve
 * to stored bytes.
 *
 * Taking an arbitrary URL would let a listing point at any third-party address
 * — a tracking pixel aimed at whoever browses, or a `javascript:`/`data:` value
 * rendered straight into an <img>. Restricting to our own upload ids also means
 * a photo can never outlive the object it references.
 */
async function sanitizePhotos(value) {
  if (value == null) return [];
  const list = Array.isArray(value) ? value : [value];

  const seen = new Set();
  const accepted = [];
  for (const entry of list) {
    if (accepted.length >= MAX_PHOTOS) break;
    const match = UPLOAD_PATH_RE.exec(String(entry ?? '').trim());
    if (!match) continue;

    const id = match[1].toLowerCase();
    if (seen.has(id)) continue;
    seen.add(id);

    if (await uploadExists(id)) accepted.push(`/api/uploads/${id}`);
  }
  return accepted;
}

/** Older records predate `photos` and only carry a single `photoUrl`. */
function readPhotos(row) {
  if (Array.isArray(row.photos) && row.photos.length > 0) {
    return row.photos.slice(0, MAX_PHOTOS);
  }
  return row.photoUrl ? [row.photoUrl] : [];
}

function pricingFields(row) {
  if (row.kind !== 'sale' || row.priceCents == null) {
    return {
      priceCents: null,
      currency: null,
      commissionRate: null,
      commissionCents: null,
      sellerNetCents: null,
    };
  }
  const priceCents = Math.round(Number(row.priceCents));
  const rate =
    typeof row.commissionRate === 'number' ? row.commissionRate : COMMISSION_RATE;
  const commissionCents = Math.round(priceCents * rate);
  return {
    priceCents,
    currency: row.currency || 'USD',
    commissionRate: rate,
    commissionCents,
    sellerNetCents: priceCents - commissionCents,
  };
}

/**
 * Everything a signed-in counterpart may see. Deliberately omits ownerEmail,
 * ownerUserId, street address and any free-text the owner did not intend to
 * publish. City/state stay because handoff logistics are useless without them.
 */
function toPublicJson(row) {
  if (!row) return null;
  return {
    id: row.id,
    kind: row.kind,
    title: row.title,
    description: row.description || '',
    category: row.category,
    condition: row.condition || null,
    sizeNote: row.sizeNote || null,
    quantity: row.quantity || 1,
    urgency: row.urgency || 'normal',
    city: row.city || null,
    state: row.state || null,
    postalPrefix: row.postalCode ? String(row.postalCode).slice(0, 3) : null,
    photos: readPhotos(row),
    photoUrl: row.photoUrl || null,
    ...pricingFields(row),
    status: row.status || 'active',
    reservedUntil: row.reservedUntil || null,
    createdAt: row.createdAt,
  };
}

/** The owner's own view — adds the fields only they should read back. */
function toOwnerJson(row) {
  if (!row) return null;
  return {
    ...toPublicJson(row),
    postalCode: row.postalCode || null,
    reservedByUserId: row.reservedByUserId || null,
    hidden: Boolean(row.hidden),
    updatedAt: row.updatedAt,
  };
}

/** Full record for the platform operator. */
function toAdminJson(row) {
  if (!row) return null;
  return {
    ...toOwnerJson(row),
    ownerUserId: row.ownerUserId,
    ownerEmail: row.ownerEmail,
    ownerRole: row.ownerRole || null,
  };
}

/**
 * Which listing kind a role is allowed to publish.
 * Donors give equipment away; recipients and NGO partners ask for it.
 */
function allowedKindForRole(role) {
  if (role === 'donor') return 'offer';
  if (role === 'recipient' || role === 'ngoPartner') return 'request';
  return null;
}

/** The kind a role should see when browsing — the opposite side of the market. */
function counterpartKind(role) {
  const own = allowedKindForRole(role);
  if (own === 'offer') return 'request';
  if (own === 'request') return 'offer';
  return null;
}

/**
 * POST /api/listings
 *
 * `kind: 'sale'` is open to any signed-in account. Donate kinds still follow
 * the role map (donor → offer, recipient/NGO → request).
 */
async function create(req, res, next) {
  try {
    const role = req.user.role;
    const requestedKind = String(req.body?.kind || '').trim();
    const isSale = requestedKind === 'sale';

    let kind;
    if (isSale) {
      kind = 'sale';
    } else {
      const expectedKind = allowedKindForRole(role);
      if (!expectedKind) {
        return res.status(403).json({
          success: false,
          message:
            'Bu hesap için ilan türü belirlenemedi. Profilinizden rolünüzü seçin.',
          code: 'ROLE_REQUIRED',
        });
      }
      kind = requestedKind || expectedKind;
      if (!DONATE_KINDS.has(kind) || kind !== expectedKind) {
        return res.status(403).json({
          success: false,
          message: 'Rolünüz bu ilan türünü yayınlayamaz.',
          code: 'KIND_NOT_ALLOWED',
        });
      }
    }

    const title = clampText(req.body?.title, 120);
    const category = clampText(req.body?.category, 60);
    if (!title || !category) {
      return res.status(400).json({
        success: false,
        message: 'Başlık ve kategori zorunlu.',
        code: 'FIELDS_REQUIRED',
      });
    }

    let priceCents = null;
    if (isSale) {
      // Prefer integer cents; fall back to dollars when the client sends `price`.
      let asCents;
      if (req.body?.priceCents != null) {
        asCents = Math.round(Number(req.body.priceCents));
      } else if (req.body?.price != null) {
        asCents = Math.round(Number(req.body.price) * 100);
      }
      if (
        !Number.isFinite(asCents) ||
        asCents < MIN_PRICE_CENTS ||
        asCents > MAX_PRICE_CENTS
      ) {
        return res.status(400).json({
          success: false,
          message: 'Satış fiyatı en az $1.00 olmalıdır.',
          code: 'PRICE_REQUIRED',
        });
      }
      priceCents = asCents;
    }

    const condition = clampText(req.body?.condition, 20);
    const urgency = clampText(req.body?.urgency, 10);
    const quantityRaw = Number(req.body?.quantity);
    const photos = await sanitizePhotos(req.body?.photos ?? req.body?.photoUrl);
    if (photos.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'En az bir fotoğraf zorunludur.',
        code: 'PHOTO_REQUIRED',
      });
    }

    const created = await createListing({
      kind,
      ownerUserId: req.user.userId,
      ownerEmail: req.user.email,
      ownerRole: role,
      title,
      description: clampText(req.body?.description, 2000),
      category,
      condition: CONDITIONS.has(condition) ? condition : null,
      sizeNote: clampText(req.body?.sizeNote, 160) || null,
      quantity:
        Number.isFinite(quantityRaw) && quantityRaw >= 1
          ? Math.min(Math.floor(quantityRaw), 999)
          : 1,
      urgency: isSale ? 'normal' : URGENCIES.has(urgency) ? urgency : 'normal',
      city: clampText(req.body?.city, 80) || null,
      state: clampText(req.body?.state, 2).toUpperCase() || null,
      postalCode: clampText(req.body?.postalCode, 10) || null,
      photos,
      // Mirrored so clients still reading the old single-photo field keep working.
      photoUrl: photos[0] || null,
      priceCents,
      currency: isSale ? 'USD' : null,
      commissionRate: isSale ? COMMISSION_RATE : null,
      status: 'active',
    });

    return res.status(201).json({ success: true, listing: toOwnerJson(created) });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/listings/mine
 */
async function listMine(req, res, next) {
  try {
    const rows = await queryListings(
      { ownerUserId: req.user.userId, includeHidden: true },
      { limit: 200 },
    );
    return res.status(200).json({
      success: true,
      listings: rows.map(toOwnerJson),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/listings/shop
 * Active paid listings for the marketplace. Open to any signed-in user.
 */
async function shop(req, res, next) {
  try {
    const limit = Math.min(Number(req.query?.limit) || 60, 100);
    const skip = Math.max(Number(req.query?.skip) || 0, 0);
    const filter = {
      kind: 'sale',
      status: 'active',
      excludeOwnerUserId: req.user.userId,
      category: clampText(req.query?.category, 60) || undefined,
      state: clampText(req.query?.state, 2).toUpperCase() || undefined,
      search: clampText(req.query?.q, 80) || undefined,
    };

    const [rows, total] = await Promise.all([
      queryListings(filter, { limit, skip }),
      countListings(filter),
    ]);

    return res.status(200).json({
      success: true,
      kind: 'sale',
      commissionRate: COMMISSION_RATE,
      total,
      listings: rows.map(toPublicJson),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/listings/:id/purchase
 * Buyer requests a sale item — holds it for 48 hours (Stripe comes later).
 */
async function purchase(req, res, next) {
  try {
    const row = await findListingById(req.params.id);
    if (!row || row.hidden || row.kind !== 'sale') {
      return res.status(404).json({
        success: false,
        message: 'Satış ilanı bulunamadı.',
        code: 'LISTING_NOT_FOUND',
      });
    }
    if (row.ownerUserId === req.user.userId) {
      return res.status(400).json({
        success: false,
        message: 'Kendi satış ilanınızı satın alamazsınız.',
        code: 'SELF_PURCHASE',
      });
    }
    if (row.status !== 'active') {
      return res.status(409).json({
        success: false,
        message: 'Bu ürün şu anda satışa açık değil.',
        code: 'NOT_AVAILABLE',
      });
    }

    const updated = await updateListing(row.id, {
      status: 'reserved',
      reservedByUserId: req.user.userId,
      reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
    });

    return res.status(200).json({
      success: true,
      message:
        'Satın alma talebiniz alındı. Satıcı 48 saat içinde sizinle iletişime geçecek.',
      listing: toPublicJson(updated),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/listings/browse
 * Returns the opposite side of the market with contact details stripped.
 */
async function browse(req, res, next) {
  try {
    const role = req.user.role;
    const requested = String(req.query?.kind || '');
    // Shop has its own endpoint; keep donate browse free of sale rows.
    const kind = DONATE_KINDS.has(requested)
      ? requested
      : counterpartKind(role);

    if (!kind) {
      return res.status(403).json({
        success: false,
        message:
          'Gözatma için hesabınızda bir rol tanımlı olmalı (bağışçı veya alıcı).',
        code: 'ROLE_REQUIRED',
      });
    }

    const limit = Math.min(Number(req.query?.limit) || 60, 100);
    const skip = Math.max(Number(req.query?.skip) || 0, 0);
    const filter = {
      kind,
      status: 'active',
      excludeOwnerUserId: req.user.userId,
      category: clampText(req.query?.category, 60) || undefined,
      state: clampText(req.query?.state, 2).toUpperCase() || undefined,
      search: clampText(req.query?.q, 80) || undefined,
    };

    const [rows, total] = await Promise.all([
      queryListings(filter, { limit, skip }),
      countListings(filter),
    ]);

    return res.status(200).json({
      success: true,
      kind,
      total,
      listings: rows.map(toPublicJson),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * Scores how well a counterpart listing fits `mine`.
 * Category is the dominant signal; location and urgency break ties.
 */
function scoreMatch(mine, other) {
  let score = 0;
  const reasons = [];

  if (mine.category && other.category && mine.category === other.category) {
    score += 55;
    reasons.push('category');
  }

  const mySize = String(mine.sizeNote || '').toLowerCase();
  const otherSize = String(other.sizeNote || '').toLowerCase();
  if (mySize && otherSize && (mySize.includes(otherSize) || otherSize.includes(mySize))) {
    score += 15;
    reasons.push('size');
  }

  const myZip = String(mine.postalCode || '');
  const otherZip = String(other.postalCode || '');
  if (myZip && otherZip) {
    if (myZip === otherZip) {
      score += 20;
      reasons.push('sameZip');
    } else if (myZip.slice(0, 3) === otherZip.slice(0, 3)) {
      score += 14;
      reasons.push('nearby');
    }
  }
  if (
    mine.state &&
    other.state &&
    String(mine.state).toUpperCase() === String(other.state).toUpperCase()
  ) {
    score += 8;
    reasons.push('sameState');
  }

  if (other.urgency === 'high') {
    score += 10;
    reasons.push('urgent');
  }

  const title = String(other.title || '').toLowerCase();
  const myTitle = String(mine.title || '').toLowerCase();
  if (title && myTitle) {
    const words = myTitle.split(/\s+/).filter((w) => w.length > 3);
    if (words.some((w) => title.includes(w))) {
      score += 7;
      reasons.push('title');
    }
  }

  return { score: Math.min(score, 100), reasons };
}

/**
 * GET /api/listings/:id/matches
 * Ranks the opposite side of the market against one of the caller's listings.
 */
async function matches(req, res, next) {
  try {
    const mine = await findListingById(req.params.id);
    if (!mine) {
      return res.status(404).json({
        success: false,
        message: 'İlan bulunamadı.',
        code: 'LISTING_NOT_FOUND',
      });
    }
    if (mine.ownerUserId !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Bu ilan size ait değil.',
        code: 'NOT_OWNER',
      });
    }

    if (mine.kind === 'sale') {
      return res.status(400).json({
        success: false,
        message: 'Satış ilanları bağış eşleştirmesine dahil edilmez.',
        code: 'SALE_NO_MATCH',
      });
    }

    const wanted = mine.kind === 'offer' ? 'request' : 'offer';
    const candidates = await queryListings(
      {
        kind: wanted,
        status: 'active',
        excludeOwnerUserId: req.user.userId,
      },
      { limit: 200 },
    );

    const ranked = candidates
      .map((row) => {
        const { score, reasons } = scoreMatch(mine, row);
        return { ...toPublicJson(row), matchScore: score, matchReasons: reasons };
      })
      .filter((row) => row.matchScore > 0)
      .sort((a, b) => b.matchScore - a.matchScore)
      .slice(0, 25);

    return res.status(200).json({
      success: true,
      listingId: mine.id,
      matches: ranked,
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * POST /api/listings/:id/reserve
 * Holds a counterpart listing for 48 hours.
 */
async function reserve(req, res, next) {
  try {
    const row = await findListingById(req.params.id);
    if (!row || row.hidden) {
      return res.status(404).json({
        success: false,
        message: 'İlan bulunamadı.',
        code: 'LISTING_NOT_FOUND',
      });
    }
    if (row.kind === 'sale') {
      return res.status(400).json({
        success: false,
        message: 'Satış ilanları için /purchase kullanın.',
        code: 'USE_PURCHASE',
      });
    }
    if (row.ownerUserId === req.user.userId) {
      return res.status(400).json({
        success: false,
        message: 'Kendi ilanınızı rezerve edemezsiniz.',
        code: 'SELF_RESERVE',
      });
    }

    const stillHeld =
      row.status === 'reserved' &&
      row.reservedUntil &&
      new Date(row.reservedUntil).getTime() > Date.now();
    if (stillHeld && row.reservedByUserId !== req.user.userId) {
      return res.status(409).json({
        success: false,
        message: 'Bu ilan şu anda başka bir kullanıcı için rezerve.',
        code: 'ALREADY_RESERVED',
      });
    }

    const updated = await updateListing(row.id, {
      status: 'reserved',
      reservedByUserId: req.user.userId,
      reservedUntil: new Date(Date.now() + RESERVATION_WINDOW_MS),
    });

    return res.status(200).json({
      success: true,
      listing: toPublicJson(updated),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * PATCH /api/listings/:id — owner-only status and field edits.
 */
async function update(req, res, next) {
  try {
    const row = await findListingById(req.params.id);
    if (!row) {
      return res.status(404).json({
        success: false,
        message: 'İlan bulunamadı.',
        code: 'LISTING_NOT_FOUND',
      });
    }
    if (row.ownerUserId !== req.user.userId) {
      return res.status(403).json({
        success: false,
        message: 'Bu ilan size ait değil.',
        code: 'NOT_OWNER',
      });
    }

    const patch = {};
    if (req.body?.title != null) patch.title = clampText(req.body.title, 120);
    if (req.body?.description != null) {
      patch.description = clampText(req.body.description, 2000);
    }
    if (req.body?.sizeNote != null) {
      patch.sizeNote = clampText(req.body.sizeNote, 160) || null;
    }
    if (req.body?.photos != null) {
      const photos = await sanitizePhotos(req.body.photos);
      patch.photos = photos;
      patch.photoUrl = photos[0] || null;
    }
    if (req.body?.status != null) {
      const status = clampText(req.body.status, 20);
      if (!STATUSES.has(status)) {
        return res.status(400).json({
          success: false,
          message: 'Geçersiz durum.',
          code: 'INVALID_STATUS',
        });
      }
      patch.status = status;
      if (status !== 'reserved') {
        patch.reservedByUserId = null;
        patch.reservedUntil = null;
      }
    }

    const updated = await updateListing(row.id, patch);
    return res.status(200).json({ success: true, listing: toOwnerJson(updated) });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  create,
  listMine,
  browse,
  shop,
  matches,
  reserve,
  purchase,
  update,
  toPublicJson,
  toOwnerJson,
  toAdminJson,
  scoreMatch,
  COMMISSION_RATE,
};
