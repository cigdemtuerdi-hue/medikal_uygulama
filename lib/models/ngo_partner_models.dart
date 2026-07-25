/// Verified non-profit / foundation partner on MedGift.
class NgoPartner {
  const NgoPartner({
    required this.id,
    required this.name,
    required this.city,
    required this.state,
    required this.ein,
    this.verified = true,
    this.warehouseLabel,
    this.contactEmail,
  });

  final String id;
  final String name;
  final String city;
  final String state;
  final String ein;
  final bool verified;
  final String? warehouseLabel;
  final String? contactEmail;

  String get locationLabel => '$city, $state';

  String get warehouseDisplay =>
      warehouseLabel ?? '$name warehouse — $locationLabel';
}

/// A bulk equipment request filed by an NGO on behalf of members/patients.
class NgoBulkRequest {
  const NgoBulkRequest({
    required this.id,
    required this.ngoId,
    required this.ngoName,
    required this.itemNeeded,
    required this.unitsRequested,
    required this.categoryLabel,
    required this.urgency,
    required this.requestedAt,
    this.notes,
    this.unitsFulfilled = 0,
  });

  final String id;
  final String ngoId;
  final String ngoName;
  final String itemNeeded;
  final int unitsRequested;
  final String categoryLabel;
  final String urgency;
  final DateTime requestedAt;
  final String? notes;
  final int unitsFulfilled;

  double get progress =>
      unitsRequested == 0 ? 0 : unitsFulfilled / unitsRequested;
}
