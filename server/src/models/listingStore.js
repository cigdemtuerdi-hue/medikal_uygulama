const crypto = require('crypto');

/**
 * Data access for listings, backed by Mongo when available and an in-memory
 * array otherwise (same fallback the user store uses on Render free tier).
 *
 * Both backends are hidden behind plain functions rather than a fake Mongoose
 * model so callers never depend on query-builder chaining.
 */

const state = {
  mongoModel: null,
  memory: [],
};

function useMongo() {
  return Boolean(state.mongoModel);
}

function setListingModel(model) {
  state.mongoModel = model || null;
}

function normalize(doc) {
  if (!doc) return null;
  const plain = typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
  return {
    ...plain,
    id: String(plain._id ?? plain.id),
  };
}

function matches(row, filter = {}) {
  if (filter.kind && row.kind !== filter.kind) return false;
  if (filter.status && row.status !== filter.status) return false;
  if (filter.category && row.category !== filter.category) return false;
  if (filter.ownerUserId && row.ownerUserId !== filter.ownerUserId) return false;
  if (filter.excludeOwnerUserId && row.ownerUserId === filter.excludeOwnerUserId) {
    return false;
  }
  if (!filter.includeHidden && row.hidden) return false;
  if (filter.state && String(row.state || '').toUpperCase() !== filter.state) {
    return false;
  }
  if (filter.search) {
    const needle = filter.search.toLowerCase();
    const haystack = [row.title, row.description, row.category, row.sizeNote]
      .filter(Boolean)
      .join(' ')
      .toLowerCase();
    if (!haystack.includes(needle)) return false;
  }
  return true;
}

function toMongoQuery(filter = {}) {
  const query = {};
  if (filter.kind) query.kind = filter.kind;
  if (filter.status) query.status = filter.status;
  if (filter.category) query.category = filter.category;
  if (filter.ownerUserId) query.ownerUserId = filter.ownerUserId;
  if (filter.excludeOwnerUserId) {
    query.ownerUserId = { $ne: filter.excludeOwnerUserId };
  }
  if (!filter.includeHidden) query.hidden = { $ne: true };
  if (filter.state) query.state = filter.state;
  if (filter.search) {
    const rx = new RegExp(
      filter.search.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'),
      'i',
    );
    query.$or = [
      { title: rx },
      { description: rx },
      { category: rx },
      { sizeNote: rx },
    ];
  }
  return query;
}

async function createListing(doc) {
  if (useMongo()) {
    const created = await state.mongoModel.create(doc);
    return normalize(created);
  }
  const now = new Date();
  const row = {
    ...doc,
    _id: crypto.randomBytes(12).toString('hex'),
    status: doc.status || 'active',
    quantity: doc.quantity || 1,
    hidden: Boolean(doc.hidden),
    createdAt: now,
    updatedAt: now,
  };
  state.memory.push(row);
  return normalize(row);
}

async function findListingById(id) {
  if (!id) return null;
  if (useMongo()) {
    try {
      return normalize(await state.mongoModel.findById(id));
    } catch (_) {
      return null;
    }
  }
  return normalize(state.memory.find((row) => String(row._id) === String(id)));
}

async function queryListings(filter = {}, { limit = 60, skip = 0 } = {}) {
  if (useMongo()) {
    const rows = await state.mongoModel
      .find(toMongoQuery(filter))
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);
    return rows.map(normalize);
  }
  return state.memory
    .filter((row) => matches(row, filter))
    .sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt))
    .slice(skip, skip + limit)
    .map(normalize);
}

async function countListings(filter = {}) {
  if (useMongo()) {
    return state.mongoModel.countDocuments(toMongoQuery(filter));
  }
  return state.memory.filter((row) => matches(row, filter)).length;
}

/**
 * @param {string} id
 * @param {Record<string, unknown>} patch
 */
async function updateListing(id, patch) {
  if (useMongo()) {
    const updated = await state.mongoModel.findByIdAndUpdate(
      id,
      { $set: patch },
      { new: true },
    );
    return normalize(updated);
  }
  const row = state.memory.find((r) => String(r._id) === String(id));
  if (!row) return null;
  Object.assign(row, patch, { updatedAt: new Date() });
  return normalize(row);
}

function _resetMemory() {
  state.memory = [];
}

module.exports = {
  setListingModel,
  createListing,
  findListingById,
  queryListings,
  countListings,
  updateListing,
  _resetMemory,
};
