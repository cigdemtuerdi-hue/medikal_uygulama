import '../models/donation_models.dart';
import '../models/urgent_need_models.dart';

class DonationService {
  static const donorProfile = DonorProfile(
    name: 'Cigdem Yeter',
    email: 'donor@medgift.us',
    memberSince: 'March 2025',
    zipCode: '94102',
  );

  static final List<OrganizationRequest> openRequests = [
    OrganizationRequest(
      id: 'req-001',
      name: 'Rural Health Alliance',
      city: 'Boise',
      state: 'ID',
      itemNeeded: 'Hospital beds (electric preferred)',
      urgency: 'High',
      status: RequestStatus.shipped,
      requestedAt: DateTime(2026, 6, 18),
      shippedAt: DateTime(2026, 7, 2),
      unitsRequested: 4,
      unitsFulfilled: 3,
      category: DonationCategory.dme,
    ),
    OrganizationRequest(
      id: 'req-002',
      name: 'Veterans Care Network',
      city: 'San Antonio',
      state: 'TX',
      itemNeeded: 'Rollator walkers',
      urgency: 'Medium',
      status: RequestStatus.delivered,
      requestedAt: DateTime(2026, 5, 10),
      shippedAt: DateTime(2026, 5, 22),
      deliveredAt: DateTime(2026, 6, 1),
      unitsRequested: 10,
      unitsFulfilled: 10,
      category: DonationCategory.dme,
    ),
    OrganizationRequest(
      id: 'req-003',
      name: 'Community Wound Clinic',
      city: 'Cleveland',
      state: 'OH',
      itemNeeded: 'Sterile dressings & compression wraps',
      urgency: 'High',
      status: RequestStatus.pending,
      requestedAt: DateTime(2026, 7, 5),
      unitsRequested: 200,
      unitsFulfilled: 48,
      category: DonationCategory.woundCare,
      isUrgentNeed: true,
      urgentExpiresAt: DateTime.now().add(const Duration(hours: 48)),
      verificationStatus: UrgentVerificationStatus.pending,
    ),
    OrganizationRequest(
      id: 'req-004',
      name: 'Disaster Relief MedSupply',
      city: 'Miami',
      state: 'FL',
      itemNeeded: 'Oxygen concentrators',
      urgency: 'Critical',
      status: RequestStatus.pending,
      requestedAt: DateTime(2026, 7, 9),
      unitsRequested: 6,
      unitsFulfilled: 1,
      category: DonationCategory.dme,
      isUrgentNeed: true,
      urgentExpiresAt: DateTime.now().add(const Duration(hours: 60)),
      verificationStatus: UrgentVerificationStatus.verified,
      hasVerificationDoc: true,
    ),
    OrganizationRequest(
      id: 'req-005',
      name: 'Pacific Home Health',
      city: 'Portland',
      state: 'OR',
      itemNeeded: 'Shower chairs & commodes',
      urgency: 'Medium',
      status: RequestStatus.shipped,
      requestedAt: DateTime(2026, 6, 28),
      shippedAt: DateTime(2026, 7, 11),
      unitsRequested: 8,
      unitsFulfilled: 5,
      category: DonationCategory.dme,
    ),
  ];

  /// Converts expired urgent partner requests back to standard.
  static void applyUrgentExpirations({DateTime? now}) {
    final clock = now ?? DateTime.now();
    for (final request in openRequests) {
      if (!request.isUrgentNeed) continue;
      if (request.urgentExpiresAt == null) continue;
      if (!clock.isAfter(request.urgentExpiresAt!)) continue;
      request.isUrgentNeed = false;
      request.verificationStatus = UrgentVerificationStatus.expired;
    }
  }

  static final List<DonationRecord> donationHistory = [
    DonationRecord(
      id: 'don-006',
      receiptNumber: 'MG-2026-0044',
      title: 'Drive Medical Blue Streak Wheelchair',
      organizationName: 'Pacific Home Health',
      organizationEin: '93-5566778',
      category: DonationCategory.dme,
      condition: ItemCondition.good,
      quantity: 1,
      zipCode: '94102',
      donatedAt: DateTime(2026, 7, 10),
      estimatedRetailValueUsd: 150,
      taxDeductionUsd: 120,
      brand: 'Drive Medical',
      model: 'Blue Streak',
    ),
    DonationRecord(
      id: 'don-001',
      receiptNumber: 'MG-2026-0041',
      title: 'Manual Transport Wheelchair',
      organizationName: 'Veterans Care Network',
      organizationEin: '74-1234567',
      category: DonationCategory.dme,
      condition: ItemCondition.good,
      quantity: 1,
      zipCode: '94102',
      donatedAt: DateTime(2026, 5, 15),
      estimatedRetailValueUsd: 1850,
      taxDeductionUsd: 1480,
      brand: 'Invacare',
      model: 'Tracer SX5',
    ),
    DonationRecord(
      id: 'don-002',
      receiptNumber: 'MG-2026-0038',
      title: '4x4 Gauze Pads (sealed)',
      organizationName: 'Community Wound Clinic',
      organizationEin: '34-9876543',
      category: DonationCategory.woundCare,
      condition: ItemCondition.excellent,
      quantity: 12,
      zipCode: '94102',
      donatedAt: DateTime(2026, 4, 22),
      estimatedRetailValueUsd: 89.50,
      taxDeductionUsd: 89.50,
      brand: '3M',
      model: 'Kerlix Gauze',
    ),
    DonationRecord(
      id: 'don-003',
      receiptNumber: 'MG-2026-0035',
      title: '4-Wheel Rollator Walker',
      organizationName: 'Rural Health Alliance',
      organizationEin: '82-4567890',
      category: DonationCategory.dme,
      condition: ItemCondition.good,
      quantity: 1,
      zipCode: '94102',
      donatedAt: DateTime(2026, 3, 8),
      estimatedRetailValueUsd: 329.99,
      taxDeductionUsd: 265,
      brand: 'Drive Medical',
      model: 'Nitro Euro Style',
    ),
    DonationRecord(
      id: 'don-004',
      receiptNumber: 'MG-2026-0029',
      title: 'Home Oxygen Concentrator',
      organizationName: 'Disaster Relief MedSupply',
      organizationEin: '59-1122334',
      category: DonationCategory.dme,
      condition: ItemCondition.good,
      quantity: 1,
      zipCode: '94102',
      donatedAt: DateTime(2026, 2, 14),
      estimatedRetailValueUsd: 1249,
      taxDeductionUsd: 999,
      brand: 'Philips Respironics',
      model: 'EverFlo Q',
    ),
    DonationRecord(
      id: 'don-005',
      receiptNumber: 'MG-2026-0021',
      title: 'Sterile Wound Dressing Assortment',
      organizationName: 'Pacific Home Health',
      organizationEin: '93-5566778',
      category: DonationCategory.woundCare,
      condition: ItemCondition.excellent,
      quantity: 6,
      zipCode: '94102',
      donatedAt: DateTime(2026, 1, 30),
      estimatedRetailValueUsd: 89.50,
      taxDeductionUsd: 89.50,
      brand: '3M',
      model: 'Tegaderm Combo Pack',
    ),
  ];

  static final List<DonationItem> recentDonations = [
    DonationItem(
      id: donationHistory[0].id,
      title: donationHistory[0].title,
      category: donationHistory[0].category,
      condition: donationHistory[0].condition,
      quantity: donationHistory[0].quantity,
      zipCode: donationHistory[0].zipCode,
      aiConfidence: 0.91,
    ),
    DonationItem(
      id: donationHistory[1].id,
      title: donationHistory[1].title,
      category: donationHistory[1].category,
      condition: donationHistory[1].condition,
      quantity: donationHistory[1].quantity,
      zipCode: donationHistory[1].zipCode,
    ),
  ];

  static double get totalTaxDeductionsUsd {
    return donationHistory.fold(0, (sum, d) => sum + d.taxDeductionUsd);
  }

  static int get totalDonationCount => donationHistory.length;

  static String categoryLabel(DonationCategory category) {
    return switch (category) {
      DonationCategory.dme => 'DME',
      DonationCategory.woundCare => 'Wound Care',
    };
  }

  static String requestStatusLabel(RequestStatus status) {
    return switch (status) {
      RequestStatus.pending => 'Pending',
      RequestStatus.shipped => 'Shipped',
      RequestStatus.delivered => 'Delivered',
    };
  }
}

String conditionLabel(ItemCondition condition) {
  return switch (condition) {
    ItemCondition.excellent => 'Excellent — like new',
    ItemCondition.good => 'Good — fully functional',
    ItemCondition.fair => 'Fair — minor wear',
    ItemCondition.needsRepair => 'Needs repair',
    ItemCondition.notDonatable => 'Not donatable',
  };
}

String dmeTypeLabel(DmeType type) {
  return switch (type) {
    DmeType.wheelchair => 'Wheelchair',
    DmeType.walker => 'Walker / Rollator',
    DmeType.hospitalBed => 'Hospital Bed',
    DmeType.oxygenEquipment => 'Oxygen Equipment',
    DmeType.nebulizer => 'Nebulizer',
    DmeType.commode => 'Commode',
    DmeType.showerChair => 'Shower Chair',
    DmeType.other => 'Other DME',
  };
}

String woundCareTypeLabel(WoundCareType type) {
  return switch (type) {
    WoundCareType.sterileDressings => 'Sterile Dressings',
    WoundCareType.compressionWraps => 'Compression Wraps',
    WoundCareType.gauzePads => 'Gauze Pads',
    WoundCareType.adhesiveBandages => 'Adhesive Bandages',
    WoundCareType.woundCleansers => 'Wound Cleansers',
    WoundCareType.other => 'Other Wound Care',
  };
}

String formatDonationDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}
