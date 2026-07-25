import 'donation_models.dart';
import 'urgent_need_models.dart';

enum WishlistAddResult { added, duplicate, empty, missingFeatures }

/// A recipient need tracked for Instant Match alerts.
class WishlistEntry {
  const WishlistEntry({
    required this.id,
    required this.label,
    required this.quantity,
    required this.createdAt,
    this.category = DonationCategory.dme,
    this.dmeType,
    this.queryText,
    this.isUrgentNeed = false,
    this.urgentExpiresAt,
    this.verificationDocPath,
    this.verificationDocLabel,
    this.verificationStatus = UrgentVerificationStatus.none,
    this.requiredFeaturesDescription,
  });

  final String id;
  final String label;
  final int quantity;
  final DateTime createdAt;
  final DonationCategory category;
  final DmeType? dmeType;

  /// Free-text search keywords used when [dmeType] is null.
  final String? queryText;

  /// Urgent Need Verification Mode flag.
  final bool isUrgentNeed;
  final DateTime? urgentExpiresAt;
  final String? verificationDocPath;
  final String? verificationDocLabel;
  final UrgentVerificationStatus verificationStatus;

  /// Required specs/features so donors can check fit before donating.
  /// Mandatory when [isUrgentNeed] is true.
  final String? requiredFeaturesDescription;

  String get displayText => quantity > 1 ? '${quantity}x $label' : label;

  bool get hasDonorRequirements =>
      requiredFeaturesDescription != null &&
      requiredFeaturesDescription!.trim().isNotEmpty;

  bool isActivelyUrgent({DateTime? now}) {
    if (!isUrgentNeed) return false;
    if (verificationStatus == UrgentVerificationStatus.expired) return false;
    if (urgentExpiresAt == null) return true;
    return UrgentNeedRules.isWithinWindow(urgentExpiresAt, now: now);
  }

  UrgentVerificationStatus effectiveVerificationStatus({DateTime? now}) {
    if (!isUrgentNeed) return UrgentVerificationStatus.none;
    if (!isActivelyUrgent(now: now)) return UrgentVerificationStatus.expired;
    return verificationStatus;
  }

  int? hoursRemaining({DateTime? now}) {
    if (!isActivelyUrgent(now: now) || urgentExpiresAt == null) return null;
    final remaining = urgentExpiresAt!.difference(now ?? DateTime.now());
    if (remaining.isNegative) return 0;
    return remaining.inHours.clamp(0, 72);
  }

  WishlistEntry copyWith({
    bool? isUrgentNeed,
    DateTime? urgentExpiresAt,
    String? verificationDocPath,
    String? verificationDocLabel,
    UrgentVerificationStatus? verificationStatus,
    String? requiredFeaturesDescription,
    bool clearVerificationDoc = false,
  }) {
    return WishlistEntry(
      id: id,
      label: label,
      quantity: quantity,
      createdAt: createdAt,
      category: category,
      dmeType: dmeType,
      queryText: queryText,
      isUrgentNeed: isUrgentNeed ?? this.isUrgentNeed,
      urgentExpiresAt: urgentExpiresAt ?? this.urgentExpiresAt,
      verificationDocPath: clearVerificationDoc
          ? null
          : (verificationDocPath ?? this.verificationDocPath),
      verificationDocLabel: clearVerificationDoc
          ? null
          : (verificationDocLabel ?? this.verificationDocLabel),
      verificationStatus: verificationStatus ?? this.verificationStatus,
      requiredFeaturesDescription:
          requiredFeaturesDescription ?? this.requiredFeaturesDescription,
    );
  }
}

/// Simulated Instant Match notification when a listing fits a wishlist entry.
class InstantMatchAlert {
  const InstantMatchAlert({
    required this.id,
    required this.wishlistEntryId,
    required this.itemId,
    required this.itemTitle,
    required this.wishlistLabel,
    required this.recipientName,
    required this.recipientEmail,
    required this.createdAt,
    this.emailSimulated = true,
    this.read = false,
    this.priorityMatch = false,
  });

  final String id;
  final String wishlistEntryId;
  final String itemId;
  final String itemTitle;
  final String wishlistLabel;
  final String recipientName;
  final String recipientEmail;
  final DateTime createdAt;
  final bool emailSimulated;
  final bool read;
  final bool priorityMatch;

  InstantMatchAlert copyWith({bool? read}) {
    return InstantMatchAlert(
      id: id,
      wishlistEntryId: wishlistEntryId,
      itemId: itemId,
      itemTitle: itemTitle,
      wishlistLabel: wishlistLabel,
      recipientName: recipientName,
      recipientEmail: recipientEmail,
      createdAt: createdAt,
      emailSimulated: emailSimulated,
      read: read ?? this.read,
      priorityMatch: priorityMatch,
    );
  }
}
