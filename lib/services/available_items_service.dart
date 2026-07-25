import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/donation_models.dart';
import '../models/equipment_sizing_specs.dart';
import '../models/wishlist_models.dart';
import 'donation_service.dart';
import 'ngo_partner_service.dart';
import 'wishlist_service.dart';

class AvailableItemsService extends ChangeNotifier {
  AvailableItemsService._();

  static final AvailableItemsService instance = AvailableItemsService._();

  static const List<AvailableDonationItem> dmeItems = [
    AvailableDonationItem(
      id: 'avail-001',
      title: 'Drive Medical Blue Streak Wheelchair',
      description:
          'Lightweight transport wheelchair in good condition. Foldable frame, '
          'removable footrests, and comfortable padded armrests.',
      condition: ItemCondition.good,
      donorZipCode: '92880',
      donorCity: 'Eastvale',
      donorState: 'CA',
      brand: 'Drive Medical',
      model: 'Blue Streak',
      dmeType: DmeType.wheelchair,
      handoffOption: HandoffOption.assistanceAvailable,
      priorityToUrgentRequests: true,
      fdaSafetyVerified: true,
      disasterReliefAllocation: true,
      sizing: EquipmentSizingSpecs(
        seatWidthInches: 18,
        weightCapacityLbs: 250,
        widthInches: 24,
        depthInches: 42,
        heightInches: 36,
        seatToFloorInches: 19.5,
        wheelSizeInches: 24,
        minUserHeightInches: 60,
        maxUserHeightInches: 74,
        notes: 'Fits most standard interior doorways when folded.',
      ),
    ),
    AvailableDonationItem(
      id: 'avail-002',
      title: '4-Wheel Rollator Walker with Seat',
      description:
          'Euro-style rollator with padded seat, hand brakes, and storage pouch. '
          'Ideal for indoor and outdoor mobility support.',
      condition: ItemCondition.good,
      donorZipCode: '92880',
      donorCity: 'Eastvale',
      donorState: 'CA',
      brand: 'Drive Medical',
      model: 'Nitro Euro Style',
      dmeType: DmeType.walker,
      handoffOption: HandoffOption.meetupPossible,
      fdaSafetyVerified: true,
      sizing: EquipmentSizingSpecs(
        seatWidthInches: 17.5,
        weightCapacityLbs: 300,
        widthInches: 23,
        depthInches: 27.75,
        heightInches: 33.5,
        seatToFloorInches: 20.5,
        minUserHeightInches: 61,
        maxUserHeightInches: 75,
      ),
    ),
    AvailableDonationItem(
      id: 'avail-003',
      title: 'Manual Transport Wheelchair',
      description:
          'Durable manual wheelchair suitable for short-distance transport. '
          'Recently serviced and sanitized.',
      condition: ItemCondition.good,
      donorZipCode: '94102',
      donorCity: 'San Francisco',
      donorState: 'CA',
      brand: 'Invacare',
      model: 'Tracer SX5',
      dmeType: DmeType.wheelchair,
      handoffOption: HandoffOption.pickupOnly,
      fdaSafetyVerified: true,
      disasterReliefAllocation: true,
      sizing: EquipmentSizingSpecs(
        seatWidthInches: 16,
        weightCapacityLbs: 250,
        widthInches: 23.5,
        depthInches: 41,
        heightInches: 35,
        seatToFloorInches: 18.5,
        wheelSizeInches: 24,
        minUserHeightInches: 58,
        maxUserHeightInches: 70,
      ),
    ),
    AvailableDonationItem(
      id: 'avail-004',
      title: 'Home Oxygen Concentrator (5 LPM)',
      description:
          'Quiet home oxygen concentrator with low maintenance requirements. '
          'Includes tubing and basic accessories.',
      condition: ItemCondition.good,
      donorZipCode: '90210',
      donorCity: 'Beverly Hills',
      donorState: 'CA',
      brand: 'Philips Respironics',
      model: 'EverFlo Q',
      dmeType: DmeType.oxygenEquipment,
      handoffOption: HandoffOption.assistanceAvailable,
      fdaSafetyVerified: true,
      sizing: EquipmentSizingSpecs(
        weightCapacityLbs: null,
        widthInches: 15,
        depthInches: 9.5,
        heightInches: 23,
        notes: 'Stationary home unit — not for continuous ambulatory use.',
      ),
    ),
  ];

  final List<AvailableDonationItem> _listedItems = [];

  /// Catalog items plus newly submitted listings (newest first).
  List<AvailableDonationItem> get allItems => [
        ..._listedItems,
        ...dmeItems,
      ];

  /// Registers a new listing so its donation-label QR code can be scanned.
  /// Also runs Instant Match against recipient wishlists.
  List<InstantMatchAlert> addListing(AvailableDonationItem item) {
    _listedItems.insert(0, item);
    if (item.directNgoPartnerId != null) {
      NgoPartnerService.instance.recordDirectDonation(item);
    }
    notifyListeners();
    return WishlistService.instance.evaluateNewListing(item);
  }

  AvailableDonationItem? findById(String id) {
    for (final item in allItems) {
      if (item.id == id) return item;
    }

    // Labels downloaded from My Items / donation history use record IDs.
    for (final record in DonationService.donationHistory) {
      if (record.id == id) {
        return AvailableDonationItem(
          id: record.id,
          title: record.title,
          description: 'Donated item — confirm delivery by scanning the label.',
          condition: record.condition,
          donorZipCode: record.zipCode,
          brand: record.brand,
          model: record.model,
          quantityAvailable: record.quantity,
        );
      }
    }
    return null;
  }
}
