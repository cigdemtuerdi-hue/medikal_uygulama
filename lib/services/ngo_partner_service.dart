import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/donation_models.dart';
import '../models/ngo_partner_models.dart';
import '../models/user_onboarding_models.dart';
import 'donation_service.dart';

/// NGO Partner Portal — verified non-profits, bulk requests, direct donations.
class NgoPartnerService extends ChangeNotifier {
  NgoPartnerService._() {
    _seedPartners();
  }

  static final NgoPartnerService instance = NgoPartnerService._();

  final List<NgoPartner> _partners = [];
  final List<NgoBulkRequest> _bulkRequests = [];
  final List<AvailableDonationItem> _directDonations = [];
  NgoPartner? _sessionPartner;

  List<NgoPartner> get verifiedPartners =>
      List.unmodifiable(_partners.where((p) => p.verified));

  List<NgoPartner> get allPartners => List.unmodifiable(_partners);

  NgoPartner? get sessionPartner => _sessionPartner;

  bool get hasVerifiedSession => _sessionPartner?.verified == true;

  List<NgoBulkRequest> get bulkRequestsForSession {
    final id = _sessionPartner?.id;
    if (id == null) return const [];
    return _bulkRequests.where((r) => r.ngoId == id).toList()
      ..sort((a, b) => b.requestedAt.compareTo(a.requestedAt));
  }

  List<NgoBulkRequest> get allBulkRequests =>
      List.unmodifiable(_bulkRequests);

  List<AvailableDonationItem> directDonationsFor(String ngoId) {
    return _directDonations
        .where((i) => i.directNgoPartnerId == ngoId)
        .toList();
  }

  List<AvailableDonationItem> get sessionDirectDonations {
    final id = _sessionPartner?.id;
    if (id == null) return const [];
    return directDonationsFor(id);
  }

  NgoPartner? findById(String id) {
    for (final p in _partners) {
      if (p.id == id) return p;
    }
    return null;
  }

  /// Called after NGO onboarding completes — marks session as verified partner.
  void activateSessionFromProfile(UserOnboardingProfile profile) {
    if (profile.role != UserRole.ngoPartner) return;

    final orgName = (profile.organizationName?.trim().isNotEmpty ?? false)
        ? profile.organizationName!.trim()
        : '${profile.fullName} Foundation';
    final id = 'ngo-session-${profile.email.hashCode.abs()}';

    final existing = findById(id);
    if (existing != null) {
      _sessionPartner = existing;
      notifyListeners();
      return;
    }

    final partner = NgoPartner(
      id: id,
      name: orgName,
      city: profile.city ?? 'San Francisco',
      state: profile.state ?? 'CA',
      ein: profile.organizationEin?.trim().isNotEmpty == true
          ? profile.organizationEin!.trim()
          : 'XX-DEMO${profile.email.hashCode.abs() % 10000}',
      verified: true,
      warehouseLabel: '$orgName community warehouse',
      contactEmail: profile.email,
    );
    _partners.insert(0, partner);
    _sessionPartner = partner;
    notifyListeners();
  }

  /// Demo: treat current user as a seeded NGO when opening portal without onboard.
  void ensureDemoSession() {
    if (_sessionPartner != null) return;
    _sessionPartner = _partners.first;
    notifyListeners();
  }

  NgoBulkRequest addBulkRequest({
    required String itemNeeded,
    required int unitsRequested,
    required String categoryLabel,
    required String urgency,
    String? notes,
  }) {
    final ngo = _sessionPartner ?? _partners.first;
    final request = NgoBulkRequest(
      id: 'bulk-${DateTime.now().millisecondsSinceEpoch}',
      ngoId: ngo.id,
      ngoName: ngo.name,
      itemNeeded: itemNeeded.trim(),
      unitsRequested: unitsRequested < 1 ? 1 : unitsRequested,
      categoryLabel: categoryLabel,
      urgency: urgency,
      requestedAt: DateTime.now(),
      notes: notes?.trim().isEmpty == true ? null : notes?.trim(),
    );
    _bulkRequests.insert(0, request);

    // Mirror into partner Requests board for platform visibility.
    DonationService.openRequests.insert(
      0,
      OrganizationRequest(
        id: request.id,
        name: ngo.name,
        city: ngo.city,
        state: ngo.state,
        itemNeeded: request.itemNeeded,
        urgency: request.urgency,
        status: RequestStatus.pending,
        requestedAt: request.requestedAt,
        unitsRequested: request.unitsRequested,
        unitsFulfilled: 0,
        category: categoryLabel.toLowerCase().contains('wound')
            ? DonationCategory.woundCare
            : DonationCategory.dme,
      ),
    );

    notifyListeners();
    return request;
  }

  void recordDirectDonation(AvailableDonationItem item) {
    if (item.directNgoPartnerId == null) return;
    _directDonations.insert(0, item);
    notifyListeners();
  }

  void _seedPartners() {
    _partners.addAll(const [
      NgoPartner(
        id: 'ngo-pacific-health',
        name: 'Pacific Health Collective',
        city: 'Oakland',
        state: 'CA',
        ein: '94-1122334',
        warehouseLabel: 'Oakland DME depot',
        contactEmail: 'intake@pacifichealth.example',
      ),
      NgoPartner(
        id: 'ngo-veterans-care',
        name: 'Veterans Care Network',
        city: 'San Antonio',
        state: 'TX',
        ein: '74-1234567',
        warehouseLabel: 'San Antonio warehouse',
        contactEmail: 'donate@veteranscare.example',
      ),
      NgoPartner(
        id: 'ngo-community-wound',
        name: 'Community Wound Clinic Foundation',
        city: 'Cleveland',
        state: 'OH',
        ein: '34-9988776',
        warehouseLabel: 'Clinic supply room',
        contactEmail: 'supplies@woundclinic.example',
      ),
    ]);

    _bulkRequests.add(
      NgoBulkRequest(
        id: 'bulk-seed-001',
        ngoId: 'ngo-pacific-health',
        ngoName: 'Pacific Health Collective',
        itemNeeded: 'Transport wheelchairs (18" seat)',
        unitsRequested: 12,
        unitsFulfilled: 3,
        categoryLabel: 'DME',
        urgency: 'High',
        requestedAt: DateTime(2026, 7, 8),
        notes: 'For post-discharge patients this month.',
      ),
    );
  }
}
