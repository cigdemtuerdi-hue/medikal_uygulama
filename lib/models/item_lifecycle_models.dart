import 'available_donation_item.dart';
import 'donation_models.dart';

/// Stages in a device's circular reuse journey.
enum ItemJourneyEventType {
  donated,
  used,
  passedOn,
  received,
}

/// One stop on the Item Journey timeline.
class ItemJourneyEvent {
  const ItemJourneyEvent({
    required this.type,
    required this.actorName,
    required this.at,
    this.locationLabel,
    this.endedAt,
    this.durationLabel,
    this.isPresent = false,
  });

  final ItemJourneyEventType type;
  final String actorName;
  final DateTime at;
  final String? locationLabel;
  final DateTime? endedAt;

  /// Preformatted duration text for "used" events (e.g. "3 months").
  final String? durationLabel;
  final bool isPresent;
}

/// Full Pass-It-On lifecycle for one physical device lineage.
class ItemLifecycleRecord {
  ItemLifecycleRecord({
    required this.lineageId,
    required this.currentItemId,
    required this.title,
    required this.snapshot,
    required this.events,
    this.ownedByRecipient = false,
    this.ownerName,
    this.passedOn = false,
  });

  final String lineageId;
  String currentItemId;
  final String title;

  /// Specs used to re-list with one tap.
  final AvailableDonationItem snapshot;
  final List<ItemJourneyEvent> events;

  /// True when the current user has received this item and has not passed it on.
  bool ownedByRecipient;
  String? ownerName;
  bool passedOn;

  /// Distinct people who donated, used, received, or were passed the device.
  int get livesImpacted {
    final names = <String>{};
    for (final e in events) {
      final n = e.actorName.trim();
      if (n.isNotEmpty) names.add(n.toLowerCase());
    }
    return names.isEmpty ? 1 : names.length;
  }

  DonationCategory get category =>
      snapshot.dmeType == null &&
              snapshot.title.toLowerCase().contains('dressing')
          ? DonationCategory.woundCare
          : DonationCategory.dme;
}

enum PassItOnResult {
  listed,
  notOwned,
  alreadyPassedOn,
  itemMissing,
}
