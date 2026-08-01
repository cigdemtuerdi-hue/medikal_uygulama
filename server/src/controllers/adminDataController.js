const { getUserModel } = require('../models/userModel');
const { queryListings, countListings } = require('../models/listingStore');
const { toAdminJson } = require('./listingController');

/**
 * Read-only operator views: who signed up and what they published.
 *
 * These sit behind requireAdmin. Unlike the counterpart-facing listing
 * projections, they intentionally include owner email so the operator can
 * support and moderate accounts.
 */

const ROLES = ['donor', 'recipient', 'ngoPartner'];

function supportsListUsers(User) {
  return typeof User.listUsers === 'function';
}

async function fetchUsers({ role, limit, skip }) {
  const User = getUserModel();
  if (supportsListUsers(User)) {
    const rows = await User.listUsers({ role, limit, skip });
    const total = await User.countUsers({ role });
    return { rows, total };
  }
  const filter = role ? { role } : {};
  const rows = await User.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(limit);
  const total = await User.countDocuments(filter);
  return { rows, total };
}

/** Phone stays masked — the operator rarely needs it and it is PII at rest. */
function maskPhone(user) {
  try {
    const plain = user.getDecryptedPhone?.();
    if (!plain) return null;
    const digits = String(plain).replace(/\D/g, '');
    return digits ? `•••• ${digits.slice(-4)}` : null;
  } catch (_) {
    return null;
  }
}

function toAdminUserJson(user) {
  return {
    id: String(user._id),
    email: user.email,
    role: user.role || null,
    phoneMasked: maskPhone(user),
    hasPassword: Boolean(user.passwordHash),
    hipaaConsentVersion: user.hipaaConsentVersion || null,
    hipaaConsentAt: user.hipaaConsentAt || null,
    createdAt: user.createdAt || null,
    updatedAt: user.updatedAt || null,
  };
}

/**
 * GET /api/admin/users?role=&limit=&skip=
 */
async function listUsers(req, res, next) {
  try {
    const role = ROLES.includes(String(req.query?.role)) ? req.query.role : null;
    const limit = Math.min(Number(req.query?.limit) || 100, 200);
    const skip = Math.max(Number(req.query?.skip) || 0, 0);

    const { rows, total } = await fetchUsers({ role, limit, skip });
    return res.status(200).json({
      success: true,
      total,
      users: rows.map(toAdminUserJson),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/admin/listings?kind=&status=&limit=&skip=
 */
async function listListings(req, res, next) {
  try {
    const limit = Math.min(Number(req.query?.limit) || 100, 200);
    const skip = Math.max(Number(req.query?.skip) || 0, 0);
    const filter = {
      includeHidden: true,
      kind: ['offer', 'request'].includes(String(req.query?.kind))
        ? req.query.kind
        : undefined,
      status: req.query?.status ? String(req.query.status) : undefined,
      search: req.query?.q ? String(req.query.q).slice(0, 80) : undefined,
    };

    const [rows, total] = await Promise.all([
      queryListings(filter, { limit, skip }),
      countListings(filter),
    ]);

    return res.status(200).json({
      success: true,
      total,
      listings: rows.map(toAdminJson),
    });
  } catch (err) {
    return next(err);
  }
}

/**
 * GET /api/admin/overview — headline counts for the console dashboard.
 */
async function overview(_req, res, next) {
  try {
    const User = getUserModel();
    const roleCounts = {};
    for (const role of ROLES) {
      roleCounts[role] = supportsListUsers(User)
        ? await User.countUsers({ role })
        : await User.countDocuments({ role });
    }
    const totalUsers = supportsListUsers(User)
      ? await User.countUsers({})
      : await User.countDocuments({});

    const [offers, requests, reserved, fulfilled] = await Promise.all([
      countListings({ kind: 'offer', includeHidden: true }),
      countListings({ kind: 'request', includeHidden: true }),
      countListings({ status: 'reserved', includeHidden: true }),
      countListings({ status: 'fulfilled', includeHidden: true }),
    ]);

    return res.status(200).json({
      success: true,
      users: { total: totalUsers, byRole: roleCounts },
      listings: { offers, requests, reserved, fulfilled },
    });
  } catch (err) {
    return next(err);
  }
}

module.exports = {
  listUsers,
  listListings,
  overview,
};
