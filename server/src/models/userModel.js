/**
 * Active User data-access handle.
 * Swapped at boot between Mongoose User and the in-memory store.
 */
const state = {
  model: null,
};

function setUserModel(model) {
  state.model = model;
}

function getUserModel() {
  if (!state.model) {
    throw new Error('User model is not initialized yet.');
  }
  return state.model;
}

module.exports = {
  setUserModel,
  getUserModel,
};
