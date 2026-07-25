/// Urgent Need Verification Mode — shared types.
enum UrgentVerificationStatus {
  /// Not flagged as urgent.
  none,

  /// Flagged urgent; optional medical proof not yet provided / under review.
  pending,

  /// Flagged urgent with uploaded proof (demo: auto-verified on upload).
  verified,

  /// Was urgent; 72-hour window elapsed → treated as standard request.
  expired,
}

/// Helpers for active urgent windows (72 hours).
abstract final class UrgentNeedRules {
  static const Duration validityWindow = Duration(hours: 72);

  static DateTime expiresAtFrom(DateTime flaggedAt) =>
      flaggedAt.add(validityWindow);

  static bool isWithinWindow(DateTime? expiresAt, {DateTime? now}) {
    if (expiresAt == null) return false;
    return !(now ?? DateTime.now()).isAfter(expiresAt);
  }

  /// Sort key: verified urgent (0) → pending urgent (1) → standard (2).
  static int priorityRank({
    required bool isActivelyUrgent,
    required UrgentVerificationStatus status,
  }) {
    if (!isActivelyUrgent) return 2;
    if (status == UrgentVerificationStatus.verified) return 0;
    return 1;
  }
}
