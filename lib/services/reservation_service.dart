import 'package:flutter/foundation.dart';

import '../models/available_donation_item.dart';
import '../models/reservation_models.dart';

/// In-memory reservation state. Reserving an item locks it for 48 hours;
/// listings listen via [ChangeNotifier] to show the locked status.
class ReservationService extends ChangeNotifier {
  ReservationService._();

  static final ReservationService instance = ReservationService._();

  static const holdDuration = Duration(hours: 48);

  final Map<String, ItemReservation> _reservations = {};

  /// Active (non-expired) reservation for [itemId], or null.
  ItemReservation? reservationFor(String itemId) {
    final reservation = _reservations[itemId];
    if (reservation == null) return null;
    if (reservation.isExpired) {
      _reservations.remove(itemId);
      return null;
    }
    return reservation;
  }

  bool isReserved(String itemId) => reservationFor(itemId) != null;

  /// Locks [item] for 48 hours. Returns null if it is already reserved.
  ItemReservation? reserveItem(
    AvailableDonationItem item, {
    required String recipientName,
  }) {
    if (isReserved(item.id)) return null;

    final now = DateTime.now();
    final reservation = ItemReservation(
      itemId: item.id,
      itemTitle: item.title,
      reservedByName: recipientName,
      reservedAt: now,
      expiresAt: now.add(holdDuration),
    );
    _reservations[item.id] = reservation;
    notifyListeners();
    return reservation;
  }

  void cancelReservation(String itemId) {
    if (_reservations.remove(itemId) != null) {
      notifyListeners();
    }
  }

  /// Called by countdown widgets when a hold reaches zero so listings
  /// refresh back to "available".
  void handleExpiry(String itemId) {
    final reservation = _reservations[itemId];
    if (reservation != null && reservation.isExpired) {
      _reservations.remove(itemId);
      notifyListeners();
    }
  }
}
