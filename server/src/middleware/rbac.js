/**
 * Role-Based Access Control for PHI / health records.
 *
 * Roles that may read/write health records:
 *   - recipient (own records only)
 *   - ngoPartner (records they are authorized to support)
 *   - admin (platform operator)
 *
 * Donors never receive PHI access.
 */

const PHI_ROLES = new Set(['recipient', 'ngoPartner', 'admin']);

function normalizeRole(role) {
  if (!role) return null;
  const r = String(role).trim();
  if (r === 'ngo' || r === 'ngo_partner') return 'ngoPartner';
  return r;
}

function canAccessPhi(role) {
  return PHI_ROLES.has(normalizeRole(role));
}

function canAccessRecord({ actorRole, actorUserId, actorEmailHash, record }) {
  const role = normalizeRole(actorRole);
  if (!canAccessPhi(role)) return false;
  if (role === 'admin') return true;
  if (!record) return false;
  if (actorUserId && record.ownerUserId === String(actorUserId)) return true;
  if (
    actorEmailHash &&
    record.ownerEmailHash &&
    actorEmailHash === record.ownerEmailHash
  ) {
    return true;
  }
  // NGO partners may only access records explicitly shared (metadata later).
  // For now: NGO may write support notes but not browse unrelated PHI.
  if (role === 'ngoPartner') {
    return false;
  }
  return false;
}

/**
 * Express middleware: requires X-User-Role header with a PHI-capable role.
 * Client also sends X-User-Id / X-User-Email-Hash for ownership checks.
 */
function requirePhiRole(req, res, next) {
  const role = normalizeRole(req.headers['x-user-role'] || req.body?.actorRole);
  if (!canAccessPhi(role)) {
    return res.status(403).json({
      success: false,
      message: 'Insufficient role to access protected health information.',
      code: 'RBAC_DENIED',
    });
  }
  req.phiActor = {
    role,
    userId: req.headers['x-user-id'] || req.body?.actorUserId || null,
    emailHash: req.headers['x-user-email-hash'] || req.body?.actorEmailHash || null,
    email: req.headers['x-user-email'] || req.body?.actorEmail || null,
  };
  return next();
}

module.exports = {
  PHI_ROLES,
  normalizeRole,
  canAccessPhi,
  canAccessRecord,
  requirePhiRole,
};
