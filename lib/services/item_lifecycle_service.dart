import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/item_lifecycle_models.dart';
import 'available_items_service.dart';
import 'impact_metrics_service.dart';
import 'profile_address_service.dart';

/// Pass-It-On & Lifecycle Tracker — circular reuse journeys for DME.
class ItemLifecycleService extends ChangeNotifier {
  ItemLifecycleService._() {
    _seedDemoJourneys();
  }

  static final ItemLifecycleService instance = ItemLifecycleService._();

  final Map<String, ItemLifecycleRecord> _byLineage = {};
  final Map<String, String> _itemIdToLineage = {};

  List<ItemLifecycleRecord> get allJourneys =>
      List.unmodifiable(_byLineage.values);

  /// Items the current recipient still holds and can Pass It On.
  List<ItemLifecycleRecord> get myReceivedItems {
    return _byLineage.values
        .where((r) => r.ownedByRecipient && !r.passedOn)
        .toList()
      ..sort((a, b) => b.events.last.at.compareTo(a.events.last.at));
  }

  ItemLifecycleRecord? journeyForItemId(String itemId) {
    final lineageId = _itemIdToLineage[itemId];
    if (lineageId == null) return null;
    return _byLineage[lineageId];
  }

  ItemLifecycleRecord? journeyForLineage(String lineageId) =>
      _byLineage[lineageId];

  double co2SavedKgFor(ItemLifecycleRecord record) {
    final perLife = ImpactMetricsService.co2KgForDmeType(record.snapshot.dmeType);
    return perLife * record.livesImpacted;
  }

  /// Called when a recipient confirms delivery / inspection.
  void recordReceived({
    required AvailableDonationItem item,
    required String recipientName,
  }) {
    final existing = journeyForItemId(item.id);
    if (existing != null) {
      existing.ownedByRecipient = true;
      existing.ownerName = recipientName;
      existing.passedOn = false;
      existing.events.add(
        ItemJourneyEvent(
          type: ItemJourneyEventType.received,
          actorName: recipientName,
          at: DateTime.now(),
          locationLabel: _locationFromItem(item),
          isPresent: true,
        ),
      );
      _clearPresentFlags(existing, keepLast: true);
      notifyListeners();
      return;
    }

    final lineageId = 'lineage-${item.id}';
    final record = ItemLifecycleRecord(
      lineageId: lineageId,
      currentItemId: item.id,
      title: item.title,
      snapshot: item,
      ownedByRecipient: true,
      ownerName: recipientName,
      events: [
        ItemJourneyEvent(
          type: ItemJourneyEventType.donated,
          actorName: item.donorCity != null ? 'Prior donor' : 'Community donor',
          at: DateTime.now().subtract(const Duration(days: 14)),
          locationLabel: _locationFromItem(item),
        ),
        ItemJourneyEvent(
          type: ItemJourneyEventType.received,
          actorName: recipientName,
          at: DateTime.now(),
          locationLabel: _locationFromItem(item),
          isPresent: true,
        ),
      ],
    );
    _byLineage[lineageId] = record;
    _itemIdToLineage[item.id] = lineageId;
    notifyListeners();
  }

  /// One-tap re-list: creates a new available listing from the received item.
  PassItOnResult passItOn(String lineageId) {
    final record = _byLineage[lineageId];
    if (record == null) return PassItOnResult.itemMissing;
    if (!record.ownedByRecipient) return PassItOnResult.notOwned;
    if (record.passedOn) return PassItOnResult.alreadyPassedOn;

    final owner = record.ownerName ??
        ProfileAddressService.matchedRecipient.name;
    final now = DateTime.now();
    final newId = 'passon-${now.millisecondsSinceEpoch}';
    final src = record.snapshot;

    final relisted = AvailableDonationItem(
      id: newId,
      title: src.title,
      description: src.description,
      condition: src.condition,
      donorZipCode: src.donorZipCode,
      donorCity: src.donorCity,
      donorState: src.donorState,
      brand: src.brand,
      model: src.model,
      dmeType: src.dmeType,
      quantityAvailable: src.quantityAvailable,
      sizing: src.sizing,
      handoffOption: src.handoffOption,
      priorityToUrgentRequests: src.priorityToUrgentRequests,
      fdaSafetyVerified: src.fdaSafetyVerified,
      disasterReliefAllocation: src.disasterReliefAllocation,
    );

    AvailableItemsService.instance.addListing(relisted);

    // Close the previous "present" use and mark pass-on.
    for (var i = 0; i < record.events.length; i++) {
      final e = record.events[i];
      if (e.isPresent) {
        record.events[i] = ItemJourneyEvent(
          type: e.type,
          actorName: e.actorName,
          at: e.at,
          locationLabel: e.locationLabel,
          endedAt: now,
          durationLabel: e.durationLabel,
          isPresent: false,
        );
      }
    }

    record.events.add(
      ItemJourneyEvent(
        type: ItemJourneyEventType.passedOn,
        actorName: owner,
        at: now,
        locationLabel: _locationFromItem(src),
      ),
    );
    record.events.add(
      ItemJourneyEvent(
        type: ItemJourneyEventType.donated,
        actorName: owner,
        at: now,
        locationLabel: _locationFromItem(src),
        isPresent: true,
      ),
    );

    record.ownedByRecipient = false;
    record.passedOn = true;
    record.currentItemId = newId;
    _itemIdToLineage[newId] = lineageId;

    notifyListeners();
    return PassItOnResult.listed;
  }

  void _clearPresentFlags(ItemLifecycleRecord record, {required bool keepLast}) {
    for (var i = 0; i < record.events.length; i++) {
      final e = record.events[i];
      final isLast = i == record.events.length - 1;
      if (!e.isPresent) continue;
      if (keepLast && isLast) continue;
      record.events[i] = ItemJourneyEvent(
        type: e.type,
        actorName: e.actorName,
        at: e.at,
        locationLabel: e.locationLabel,
        endedAt: e.endedAt,
        durationLabel: e.durationLabel,
        isPresent: false,
      );
    }
  }

  String? _locationFromItem(AvailableDonationItem item) {
    if (item.donorCity != null && item.donorState != null) {
      return '${item.donorCity}, ${item.donorState}';
    }
    return 'ZIP ${item.donorZipCode}';
  }

  void _seedDemoJourneys() {
    final wheelchair = AvailableItemsService.dmeItems.firstWhere(
      (i) => i.id == 'avail-001',
      orElse: () => AvailableItemsService.dmeItems.first,
    );
    final walker = AvailableItemsService.dmeItems.firstWhere(
      (i) => i.id == 'avail-002',
      orElse: () => AvailableItemsService.dmeItems.first,
    );

    // Example journey matching product brief (Mark → Sarah → David/present).
    final journeyA = ItemLifecycleRecord(
      lineageId: 'lineage-avail-001',
      currentItemId: wheelchair.id,
      title: wheelchair.title,
      snapshot: wheelchair,
      events: [
        ItemJourneyEvent(
          type: ItemJourneyEventType.donated,
          actorName: 'Mark',
          at: DateTime(2026, 1, 12),
          locationLabel: 'Los Angeles',
        ),
        ItemJourneyEvent(
          type: ItemJourneyEventType.used,
          actorName: 'Sarah',
          at: DateTime(2026, 1, 20),
          endedAt: DateTime(2026, 4, 20),
          durationLabel: '3 months',
          locationLabel: 'recovery',
        ),
        ItemJourneyEvent(
          type: ItemJourneyEventType.passedOn,
          actorName: 'Sarah',
          at: DateTime(2026, 4, 21),
          locationLabel: 'Los Angeles',
        ),
        ItemJourneyEvent(
          type: ItemJourneyEventType.received,
          actorName: 'David',
          at: DateTime(2026, 4, 22),
          locationLabel: 'Los Angeles',
          isPresent: true,
        ),
      ],
    );
    _byLineage[journeyA.lineageId] = journeyA;
    _itemIdToLineage[wheelchair.id] = journeyA.lineageId;

    // Demo "My Received Items" entry so Pass It On is immediately usable.
    final recipient = ProfileAddressService.matchedRecipient;
    final receivedId = 'received-demo-walker';
    final receivedSnapshot = AvailableDonationItem(
      id: receivedId,
      title: walker.title,
      description: walker.description,
      condition: walker.condition,
      donorZipCode: walker.donorZipCode,
      donorCity: walker.donorCity,
      donorState: walker.donorState,
      brand: walker.brand,
      model: walker.model,
      dmeType: walker.dmeType,
      quantityAvailable: 1,
      sizing: walker.sizing,
      handoffOption: walker.handoffOption,
      fdaSafetyVerified: walker.fdaSafetyVerified,
      disasterReliefAllocation: walker.disasterReliefAllocation,
    );
    final journeyB = ItemLifecycleRecord(
      lineageId: 'lineage-received-demo',
      currentItemId: receivedId,
      title: receivedSnapshot.title,
      snapshot: receivedSnapshot,
      ownedByRecipient: true,
      ownerName: recipient.name,
      events: [
        ItemJourneyEvent(
          type: ItemJourneyEventType.donated,
          actorName: 'Elena',
          at: DateTime(2026, 3, 2),
          locationLabel: 'San Diego',
        ),
        ItemJourneyEvent(
          type: ItemJourneyEventType.used,
          actorName: recipient.name,
          at: DateTime(2026, 3, 10),
          durationLabel: '4 months',
          locationLabel: 'home recovery',
          isPresent: true,
        ),
      ],
    );
    _byLineage[journeyB.lineageId] = journeyB;
    _itemIdToLineage[receivedId] = journeyB.lineageId;
  }
}
