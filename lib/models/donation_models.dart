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
  const OrganizationRequest({
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
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String itemNeeded;
  final String urgency;
  final RequestStatus status;
  final DateTime requestedAt;
  final DateTime? shippedAt;
  final DateTime? deliveredAt;
  final int unitsRequested;
  final int unitsFulfilled;
  final DonationCategory category;
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
  driveRollator,
  woundDressingKit,
  oxygenConcentrator,
}
