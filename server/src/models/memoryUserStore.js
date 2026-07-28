/**
 * Tiny in-memory User store for local development when MongoDB is unavailable.
 */

const crypto = require('crypto');

class MemoryUser {
  constructor(doc = {}) {
    this._id = doc._id || crypto.randomBytes(12).toString('hex');
    this.email = doc.email;
    this.phone = doc.phone ?? null;
    this.passwordHash = doc.passwordHash ?? null;
    this.resetPasswordToken = doc.resetPasswordToken ?? null;
    this.resetPasswordExpires = doc.resetPasswordExpires ?? null;
    this.resetSmsCodeHash = doc.resetSmsCodeHash ?? null;
    this.resetSmsExpires = doc.resetSmsExpires ?? null;
    this.createdAt = doc.createdAt || new Date();
    this.updatedAt = doc.updatedAt || new Date();
  }

  async save() {
    this.updatedAt = new Date();
    const idx = store.users.findIndex((u) => u._id === this._id);
    if (idx >= 0) {
      store.users[idx] = this;
    } else {
      store.users.push(this);
    }
    return this;
  }
}

const store = {
  users: [],
};

function matchesQuery(user, query = {}) {
  if (query.email != null && user.email !== query.email) return false;
  if (query.phone != null && user.phone !== query.phone) return false;

  if (query.resetPasswordToken != null &&
      user.resetPasswordToken !== query.resetPasswordToken) {
    return false;
  }

  if (query.resetSmsCodeHash != null &&
      user.resetSmsCodeHash !== query.resetSmsCodeHash) {
    return false;
  }

  if (query.resetPasswordExpires?.$gt != null) {
    const expires = user.resetPasswordExpires
      ? new Date(user.resetPasswordExpires).getTime()
      : 0;
    const min = new Date(query.resetPasswordExpires.$gt).getTime();
    if (!(expires > min)) return false;
  }

  if (query.resetSmsExpires?.$gt != null) {
    const expires = user.resetSmsExpires
      ? new Date(user.resetSmsExpires).getTime()
      : 0;
    const min = new Date(query.resetSmsExpires.$gt).getTime();
    if (!(expires > min)) return false;
  }

  return true;
}

const MemoryUserModel = {
  async findOne(query) {
    const found = store.users.find((u) => matchesQuery(u, query));
    return found || null;
  },

  async findOneByPhoneDigits(digits) {
    const target = String(digits || '').replace(/\D/g, '');
    if (!target) return null;
    return (
      store.users.find(
        (u) => String(u.phone || '').replace(/\D/g, '') === target,
      ) || null
    );
  },

  async create(doc) {
    const user = new MemoryUser(doc);
    await user.save();
    return user;
  },

  _reset() {
    store.users = [];
  },
};

module.exports = {
  MemoryUserModel,
  MemoryUser,
};
