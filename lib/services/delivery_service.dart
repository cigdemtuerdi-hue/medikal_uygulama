import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/delivery_models.dart';
import 'item_lifecycle_service.dart';
import 'reservation_service.dart';

/// Tracks deliveries confirmed via QR scan. Confirming a delivery releases
/// the reservation hold and marks the item as delivered everywhere.
class DeliveryService extends ChangeNotifier {
  DeliveryService._();

  static final DeliveryService instance = DeliveryService._();

  static const _qrPrefix = 'MEDGIFT:DELIVERY:';

  final Map<String, DeliveryConfirmation> _delivered = {};

  /// QR payload printed on the donation label for [itemId].
  static String qrPayloadFor(String itemId) => '$_qrPrefix$itemId';

  /// Extracts the item id from a scanned QR payload, or null if the code
  /// is not a MedGift delivery code.
  static String? parseItemId(String? payload) {
    if (payload == null) return null;
    final trimmed = payload.trim();
    if (!trimmed.startsWith(_qrPrefix)) return null;
    final id = trimmed.substring(_qrPrefix.length);
    return id.isEmpty ? null : id;
  }

  bool isDelivered(String itemId) => _delivered.containsKey(itemId);

  DeliveryConfirmation? deliveryFor(String itemId) => _delivered[itemId];

  List<DeliveryConfirmation> get allDeliveries =>
      List.unmodifiable(_delivered.values);

  DeliveryConfirmation confirmDelivery(
    AvailableDonationItem item, {
    required String confirmedBy,
  }) {
    final confirmation = DeliveryConfirmation(
      itemId: item.id,
      itemTitle: item.title,
      confirmedBy: confirmedBy,
      confirmedAt: DateTime.now(),
    );
    _delivered[item.id] = confirmation;

    // The hold is fulfilled — release the reservation lock.
    ReservationService.instance.cancelReservation(item.id);

    // Start / update Pass-It-On ownership + journey timeline.
    ItemLifecycleService.instance.recordReceived(
      item: item,
      recipientName: confirmedBy,
    );

    notifyListeners();
    return confirmation;
  }
}
