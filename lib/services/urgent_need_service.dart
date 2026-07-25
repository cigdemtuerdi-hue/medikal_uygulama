import '../models/donation_models.dart';
import '../models/urgent_need_models.dart';
import '../models/wishlist_models.dart';
import 'donation_service.dart';
import 'wishlist_service.dart';

/// Coordinates 72-hour urgent expiry and priority sorting across requests.
class UrgentNeedService {
  UrgentNeedService._();

  static final UrgentNeedService instance = UrgentNeedService._();

  static const Duration validityWindow = UrgentNeedRules.validityWindow;

  /// Refresh wishlist + partner-request urgency windows.
  void refreshExpirations({DateTime? now}) {
    WishlistService.instance.applyUrgentExpirations(now: now);
    DonationService.applyUrgentExpirations(now: now);
  }

  /// Partner requests with active verified urgent needs first.
  List<OrganizationRequest> sortedPartnerRequests(
    Iterable<OrganizationRequest> source, {
    DateTime? now,
  }) {
    final list = source.toList();
    list.sort((a, b) {
      final rankA = UrgentNeedRules.priorityRank(
        isActivelyUrgent: a.isActivelyUrgent(now: now),
        status: a.effectiveVerificationStatus(now: now),
      );
      final rankB = UrgentNeedRules.priorityRank(
        isActivelyUrgent: b.isActivelyUrgent(now: now),
        status: b.effectiveVerificationStatus(now: now),
      );
      if (rankA != rankB) return rankA.compareTo(rankB);
      return b.requestedAt.compareTo(a.requestedAt);
    });
    return list;
  }

  /// Wishlist entries: verified urgent → pending urgent → standard.
  List<WishlistEntry> sortedWishlistEntries(
    Iterable<WishlistEntry> source, {
    DateTime? now,
  }) {
    final list = source.toList();
    list.sort((a, b) {
      final rankA = UrgentNeedRules.priorityRank(
        isActivelyUrgent: a.isActivelyUrgent(now: now),
        status: a.effectiveVerificationStatus(now: now),
      );
      final rankB = UrgentNeedRules.priorityRank(
        isActivelyUrgent: b.isActivelyUrgent(now: now),
        status: b.effectiveVerificationStatus(now: now),
      );
      if (rankA != rankB) return rankA.compareTo(rankB);
      return b.createdAt.compareTo(a.createdAt);
    });
    return list;
  }
}
