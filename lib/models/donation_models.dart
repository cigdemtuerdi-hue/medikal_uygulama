import 'urgent_need_models.dart';

enum DonationCategory { dme, woundCare }

enum ItemCondition { excellent, good, fair, needsRepair, notDonatable }

enum DmeType {
  wheelchair,
  walker,
  hospitalBed,
  oxygenEquipment,
  nebulizer,
  commode,
  showerChair,
  other,
}

enum WoundCareType {
  sterileDressings,
  compressionWraps,
  gauzePads,
  adhesiveBandages,
  woundCleansers,
  other,
}

/// How the donor can hand off / transport the donated item.
enum HandoffOption {
  /// Recipient must pick up at the donor address.
  pickupOnly,

  /// Donor can help load / carry the item.
  assistanceAvailable,

  /// Parties can meet at a midway public location.
  meetupPossible,
}

class DonationItem {
  const DonationItem({
    required this.id,
    required this.title,
    required this.category,
    required this.condition,
    required this.quantity,
    required this.zipCode,
    this.description,
    this.aiConfidence,
  });

  final String id;
  final String title;
  final DonationCategory category;
  final ItemCondition condition;
  final int quantity;
  final String zipCode;
  final String? description;
  final double? aiConfidence;
}

enum RequestStatus { pending, shipped, delivered }

class DonorProfile {
  const DonorProfile({
    required this.name,
    required this.email,
    required this.memberSince,
    required this.zipCode,
  });

  final String name;
  final String email;
  final String memberSince;
  final String zipCode;
}

class DonationRecord {
  const DonationRecord({
    required this.id,
    required this.receiptNumber,
    required this.title,
    required this.organizationName,
    required this.organizationEin,
    required this.category,
    required this.condition,
    required this.quantity,
    required this.zipCode,
    required this.donatedAt,
    required this.estimatedRetailValueUsd,
    required this.taxDeductionUsd,
    this.brand,
    this.model,
  });

  final String id;
  final String receiptNumber;
  final String title;
  final String organizationName;
  final String organizationEin;
  final DonationCategory category;
  final ItemCondition condition;
  final int quantity;
  final String zipCode;
  final DateTime donatedAt;
  final double estimatedRetailValueUsd;
  final double taxDeductionUsd;
  final String? brand;
  final String? model;
}

class OrganizationRequest {
  OrganizationRequest({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.itemNeeded,
    required this.urgency,
    required this.status,
    required this.requestedAt,
    this.shippedAt,
    this.deliveredAt,
    required this.unitsRequested,
    required this.unitsFulfilled,
    required this.category,
    this.isUrgentNeed = false,
    this.urgentExpiresAt,
    this.verificationStatus = UrgentVerificationStatus.none,
    this.hasVerificationDoc = false,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String itemNeeded;
  final String urgency;
  RequestStatus status;
  final DateTime requestedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final int unitsRequested;
  final int unitsFulfilled;
  final DonationCategory category;

  /// Urgent Need Verification Mode (partner / org requests).
  bool isUrgentNeed;
  DateTime? urgentExpiresAt;
  UrgentVerificationStatus verificationStatus;
  final bool hasVerificationDoc;

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
}

class AiVisionResult {
  const AiVisionResult({
    required this.brand,
    required this.model,
    required this.productName,
    required this.category,
    required this.estimatedRetailValueUsd,
    required this.suggestedCondition,
    required this.confidence,
    required this.fdaNote,
    required this.recommendation,
    required this.isDme,
    required this.taxDeductionNote,
  });

  final String brand;
  final String model;
  final String productName;
  final String category;
  final double estimatedRetailValueUsd;
  final ItemCondition suggestedCondition;
  final double confidence;
  final String fdaNote;
  final String recommendation;
  final bool isDme;
  final String taxDeductionNote;
}

enum AiScanPreset {
  invacareWheelchair,
  driveBlueStreakWheelchair,
  driveRollator,
  woundDressingKit,
  oxygenConcentrator,
}
