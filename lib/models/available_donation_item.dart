import 'donation_models.dart';
import 'equipment_sizing_specs.dart';

/// A DME item available for recipients. Donor location is ZIP-level only.
class AvailableDonationItem {
  const AvailableDonationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.condition,
    required this.donorZipCode,
    this.donorCity,
    this.donorState,
    this.brand,
    this.model,
    this.dmeType,
    this.quantityAvailable = 1,
    this.sizing,
    this.handoffOption = HandoffOption.pickupOnly,
    this.priorityToUrgentRequests = false,
    this.directNgoPartnerId,
    this.directNgoPartnerName,
    this.fdaSafetyVerified = false,
    this.disasterReliefAllocation = false,
  });

  final String id;
  final String title;
  final String description;
  final ItemCondition condition;
  final String donorZipCode;
  final String? donorCity;
  final String? donorState;
  final String? brand;
  final String? model;
  final DmeType? dmeType;
  final int quantityAvailable;
  final EquipmentSizingSpecs? sizing;
  final HandoffOption handoffOption;

  /// When true, Instant Match prefers verified urgent recipient requests.
  final bool priorityToUrgentRequests;

  /// When set, this listing is routed directly to an NGO partner warehouse.
  final String? directNgoPartnerId;
  final String? directNgoPartnerName;

  /// True when the listing passed the FDA Recall & Safety Checker.
  final bool fdaSafetyVerified;

  /// When true, listing is allocated to active disaster relief zones first.
  final bool disasterReliefAllocation;

  String get donorAreaLabel {
    if (donorCity != null && donorState != null) {
      return '$donorCity, $donorState $donorZipCode';
    }
    return 'ZIP $donorZipCode area';
  }
}
