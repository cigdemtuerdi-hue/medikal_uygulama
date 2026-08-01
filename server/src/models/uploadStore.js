const crypto = require('crypto');

/**
 * Data access for uploaded images, mirroring listingStore: Mongo when the
 * connection is up, an in-memory map otherwise so local dev and the memory
 * fallback deploy keep working.
 *
 * The memory backend is bounded because image buffers are large enough to
 * exhaust a small dyno if a client uploads in a loop.
 */

const MEMORY_LIMIT = 200;

const state = {
  mongoModel: null,
  memory: new Map(),
};

function useMongo() {
  return Boolean(state.mongoModel);
}

function setUploadModel(model) {
  state.mongoModel = model || null;
}

async function createUpload({ ownerUserId, contentType, data }) {
  if (useMongo()) {
    const created = await state.mongoModel.create({
      ownerUserId,
      contentType,
      byteSize: data.length,
      data,
    });
    return { id: String(created._id) };
  }

  if (state.memory.size >= MEMORY_LIMIT) {
    // Oldest first: Map preserves insertion order.
    state.memory.delete(state.memory.keys().next().value);
  }
  const id = crypto.randomBytes(12).toString('hex');
  state.memory.set(id, {
    id,
    ownerUserId,
    contentType,
    byteSize: data.length,
    data,
    createdAt: new Date(),
  });
  return { id };
}

async function findUploadById(id) {
  if (!id) return null;
  if (useMongo()) {
    try {
      const doc = await state.mongoModel.findById(id);
      if (!doc) return null;
      return {
        id: String(doc._id),
        ownerUserId: doc.ownerUserId,
        contentType: doc.contentType,
        byteSize: doc.byteSize,
        data: doc.data,
      };
    } catch (_) {
      // Malformed ObjectId — treat as not found rather than a 500.
      return null;
    }
  }
  return state.memory.get(String(id)) || null;
}

/** True when the id points at a real upload, without loading the bytes. */
async function uploadExists(id) {
  if (!id) return false;
  if (useMongo()) {
    try {
      return Boolean(await state.mongoModel.exists({ _id: id }));
    } catch (_) {
      return false;
    }
  }
  return state.memory.has(String(id));
}

function _resetMemory() {
  state.memory.clear();
}

module.exports = {
  setUploadModel,
  createUpload,
  findUploadById,
  uploadExists,
  _resetMemory,
};
