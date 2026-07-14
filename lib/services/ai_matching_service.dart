import '../models/recipient_models.dart';
import 'donation_service.dart';

/// Simulates AI matching between a recipient's needs and available donations.
class AiMatchingService {
  static const _donationPool = [
    _PoolEntry(keywords: ['wheelchair', 'transport'], zip: '90210', donors: 2),
    _PoolEntry(keywords: ['wheelchair'], zip: '94102', donors: 1),
    _PoolEntry(keywords: ['dressing', 'wound', 'gauze', 'tegaderm'], zip: '10001', donors: 3),
    _PoolEntry(keywords: ['dressing', 'wound'], zip: '44114', donors: 1),
    _PoolEntry(keywords: ['rollator', 'walker'], zip: '78701', donors: 2),
    _PoolEntry(keywords: ['oxygen', 'concentrator'], zip: '33101', donors: 1),
    _PoolEntry(keywords: ['hospital', 'bed'], zip: '83702', donors: 1),
  ];

  AiMatchingSummary matchForRecipient(RecipientProfile recipient) {
    final results = recipient.itemsNeeded.map(_matchItem).toList();
    final overall = results.isEmpty
        ? 0.0
        : results.map((r) => r.matchScore).reduce((a, b) => a + b) / results.length;

    return AiMatchingSummary(
      overallScore: overall,
      itemResults: results,
      totalDonorsInPool: DonationService.donationHistory.length + 12,
      lastUpdated: DateTime.now(),
    );
  }

  ItemMatchResult _matchItem(NeededItem item) {
    final lower = item.label.toLowerCase();

    _PoolEntry? best;
    var bestScore = 0.0;

    for (final entry in _donationPool) {
      final score = _keywordScore(lower, entry.keywords);
      if (score > bestScore) {
        bestScore = score;
        best = entry;
      }
    }

    if (best == null || bestScore < 0.3) {
      return ItemMatchResult(
        item: item,
        status: MatchStatus.searching,
        matchScore: 0.15,
        donorsFound: 0,
        nearestDonorZip: '—',
      );
    }

    final donors = best.donors;
    final status = donors >= item.quantity
        ? MatchStatus.matched
        : donors > 0
            ? MatchStatus.partial
            : MatchStatus.searching;

    return ItemMatchResult(
      item: item,
      status: status,
      matchScore: bestScore.clamp(0.0, 1.0),
      donorsFound: donors,
      nearestDonorZip: best.zip,
    );
  }

  double _keywordScore(String label, List<String> keywords) {
    var hits = 0;
    for (final keyword in keywords) {
      if (label.contains(keyword)) hits++;
    }
    if (hits == 0) return 0.1;
    return (hits / keywords.length).clamp(0.4, 1.0);
  }
}

class _PoolEntry {
  const _PoolEntry({
    required this.keywords,
    required this.zip,
    required this.donors,
  });

  final List<String> keywords;
  final String zip;
  final int donors;
}

String matchStatusLabel(MatchStatus status) {
  return switch (status) {
    MatchStatus.matched => 'Matched',
    MatchStatus.partial => 'Partial match',
    MatchStatus.searching => 'Searching',
  };
}
