const crypto = require('crypto');

const state = {
  mongoModel: null,
  memory: [],
};

function useMongo() {
  return Boolean(state.mongoModel);
}

function setOrderModel(model) {
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

async function createOrder(doc) {
  if (useMongo()) {
    const created = await state.mongoModel.create(doc);
    return normalize(created);
  }
  const now = new Date();
  const row = {
    ...doc,
    _id: crypto.randomBytes(12).toString('hex'),
    status: doc.status || 'pending',
    createdAt: now,
    updatedAt: now,
  };
  state.memory.push(row);
  return normalize(row);
}

async function findOrderById(id) {
  if (useMongo()) {
    const doc = await state.mongoModel.findById(id).lean();
    return normalize(doc);
  }
  return normalize(state.memory.find((r) => String(r._id) === String(id)));
}

async function findOrderBySessionId(sessionId) {
  if (!sessionId) return null;
  if (useMongo()) {
    const doc = await state.mongoModel
      .findOne({ stripeCheckoutSessionId: sessionId })
      .lean();
    return normalize(doc);
  }
  return normalize(
    state.memory.find((r) => r.stripeCheckoutSessionId === sessionId),
  );
}

async function findOrderByPaypalOrderId(paypalOrderId) {
  if (!paypalOrderId) return null;
  if (useMongo()) {
    const doc = await state.mongoModel
      .findOne({ paypalOrderId: String(paypalOrderId) })
      .lean();
    return normalize(doc);
  }
  return normalize(
    state.memory.find((r) => r.paypalOrderId === String(paypalOrderId)),
  );
}

async function updateOrder(id, patch) {
  if (useMongo()) {
    const doc = await state.mongoModel
      .findByIdAndUpdate(id, { $set: patch }, { new: true })
      .lean();
    return normalize(doc);
  }
  const row = state.memory.find((r) => String(r._id) === String(id));
  if (!row) return null;
  Object.assign(row, patch, { updatedAt: new Date() });
  return normalize(row);
}

module.exports = {
  setOrderModel,
  createOrder,
  findOrderById,
  findOrderBySessionId,
  findOrderByPaypalOrderId,
  updateOrder,
};
