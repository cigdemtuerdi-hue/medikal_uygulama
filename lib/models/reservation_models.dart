/// An active hold that locks an item for a recipient for 48 hours.
class ItemReservation {
  const ItemReservation({
    required this.itemId,
    required this.itemTitle,
    required this.reservedByName,
    required this.reservedAt,
    required this.expiresAt,
  });

  final String itemId;
  final String itemTitle;
  final String reservedByName;
  final DateTime reservedAt;
  final DateTime expiresAt;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get remaining {
    final left = expiresAt.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }
}
