class RecipientProfile {
  const RecipientProfile({
    required this.id,
    required this.name,
    required this.initials,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.phone,
    required this.email,
    required this.itemsNeeded,
  });

  final String id;
  final String name;
  final String initials;
  final String city;
  final String state;
  final String zipCode;
  final String phone;
  final String email;
  final List<NeededItem> itemsNeeded;
}

class NeededItem {
  const NeededItem({
    required this.label,
    required this.quantity,
  });

  final String label;
  final int quantity;

  String get displayText => '${quantity}x $label';
}

enum MatchStatus { matched, partial, searching }

class ItemMatchResult {
  const ItemMatchResult({
    required this.item,
    required this.status,
    required this.matchScore,
    required this.donorsFound,
    required this.nearestDonorZip,
  });

  final NeededItem item;
  final MatchStatus status;
  final double matchScore;
  final int donorsFound;
  final String nearestDonorZip;
}

class AiMatchingSummary {
  const AiMatchingSummary({
    required this.overallScore,
    required this.itemResults,
    required this.totalDonorsInPool,
    required this.lastUpdated,
  });

  final double overallScore;
  final List<ItemMatchResult> itemResults;
  final int totalDonorsInPool;
  final DateTime lastUpdated;
}
