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
  const rows = await findOrdersBySessionId(sessionId);
  return rows[0] || null;
}

async function findOrdersBySessionId(sessionId) {
  if (!sessionId) return [];
  if (useMongo()) {
    const docs = await state.mongoModel
      .find({ stripeCheckoutSessionId: sessionId })
      .lean();
    return docs.map(normalize).filter(Boolean);
  }
  return state.memory
    .filter((r) => r.stripeCheckoutSessionId === sessionId)
    .map(normalize)
    .filter(Boolean);
}

async function findOrderByPaypalOrderId(paypalOrderId) {
  const rows = await findOrdersByPaypalOrderId(paypalOrderId);
  return rows[0] || null;
}

async function findOrdersByPaypalOrderId(paypalOrderId) {
  if (!paypalOrderId) return [];
  if (useMongo()) {
    const docs = await state.mongoModel
      .find({ paypalOrderId: String(paypalOrderId) })
      .lean();
    return docs.map(normalize).filter(Boolean);
  }
  return state.memory
    .filter((r) => r.paypalOrderId === String(paypalOrderId))
    .map(normalize)
    .filter(Boolean);
}

async function findOrdersByCartCheckoutId(cartCheckoutId) {
  if (!cartCheckoutId) return [];
  if (useMongo()) {
    const docs = await state.mongoModel
      .find({ cartCheckoutId: String(cartCheckoutId) })
      .lean();
    return docs.map(normalize).filter(Boolean);
  }
  return state.memory
    .filter((r) => r.cartCheckoutId === String(cartCheckoutId))
    .map(normalize)
    .filter(Boolean);
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
  findOrdersBySessionId,
  findOrderByPaypalOrderId,
  findOrdersByPaypalOrderId,
  findOrdersByCartCheckoutId,
  updateOrder,
};
