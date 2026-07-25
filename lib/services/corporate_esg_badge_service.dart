import '../services/impact_metrics_service.dart';

/// Corporate / sponsor ESG recognition tiers.
enum CorporateEsgBadgeTier {
  ecoSponsor,
  communityImpactLeader,
  zeroWasteHero,
}

class CorporateEsgBadge {
  const CorporateEsgBadge({
    required this.tier,
    required this.organizationName,
    required this.organizationId,
    required this.equipmentSaved,
    required this.co2SavedKg,
    this.year = 2026,
  });

  final CorporateEsgBadgeTier tier;
  final String organizationName;
  final String organizationId;
  final int equipmentSaved;
  final double co2SavedKg;
  final int year;

  String get verifiedLabel => 'MedGift Verified ESG Partner $year';

  String embedHtml({required String badgeTitle}) {
    final src =
        'https://medgift.us/badge/${tier.name}?org=$organizationId&year=$year';
    return '''<!-- $verifiedLabel -->
<iframe
  src="$src"
  title="$badgeTitle — $organizationName"
  width="340"
  height="200"
  style="border:0;border-radius:16px;overflow:hidden;"
  loading="lazy"
  referrerpolicy="no-referrer-when-downgrade">
</iframe>
<p style="font:12px/1.4 system-ui,sans-serif;color:#455A64;margin:8px 0 0;">
  <a href="https://medgift.us/partners/$organizationId" style="color:#1A5FA8;text-decoration:none;">
    $verifiedLabel
  </a>
  · Powered by MedGift US
</p>''';
  }

  String get badgeImageUrl =>
      'https://medgift.us/static/badges/${tier.name}-$year.png';
}

/// Resolves badge tiers and sample corporate sponsors from live impact metrics.
class CorporateEsgBadgeService {
  CorporateEsgBadgeService._();

  static final CorporateEsgBadgeService instance = CorporateEsgBadgeService._();

  /// Thresholds for earning each recognition level (equipment diverted).
  static const int ecoSponsorMin = 5;
  static const int communityLeaderMin = 25;
  static const int zeroWasteHeroMin = 60;

  List<CorporateEsgBadgeTier> tiersForImpact(ImpactMetrics metrics) {
    final earned = <CorporateEsgBadgeTier>[];
    if (metrics.equipmentSaved >= ecoSponsorMin) {
      earned.add(CorporateEsgBadgeTier.ecoSponsor);
    }
    if (metrics.equipmentSaved >= communityLeaderMin ||
        metrics.co2SavedKg >= 800) {
      earned.add(CorporateEsgBadgeTier.communityImpactLeader);
    }
    if (metrics.equipmentSaved >= zeroWasteHeroMin ||
        metrics.co2SavedKg >= 2000) {
      earned.add(CorporateEsgBadgeTier.zeroWasteHero);
    }
    if (earned.isEmpty) {
      earned.add(CorporateEsgBadgeTier.ecoSponsor);
    }
    return earned;
  }

  /// Badges for the signed-in donor / organization profile (live metrics).
  List<CorporateEsgBadge> badgesForCurrentProfile({
    required String organizationName,
    required String organizationId,
  }) {
    final metrics = ImpactMetricsService.instance.metrics;
    return tiersForImpact(metrics)
        .map(
          (tier) => CorporateEsgBadge(
            tier: tier,
            organizationName: organizationName,
            organizationId: organizationId,
            equipmentSaved: metrics.equipmentSaved,
            co2SavedKg: metrics.co2SavedKg,
          ),
        )
        .toList();
  }

  /// Featured corporate sponsors shown on Home.
  List<CorporateEsgBadge> get featuredSponsors {
    final metrics = ImpactMetricsService.instance.metrics;
    // Scale showcase sponsors relative to live platform impact.
    final baseEquip = metrics.equipmentSaved.clamp(12, 9999);
    final baseCo2 = metrics.co2SavedKg.clamp(120.0, 99999.0);

    return [
      CorporateEsgBadge(
        tier: CorporateEsgBadgeTier.ecoSponsor,
        organizationName: 'Pacific Health Collective',
        organizationId: 'pacific-health',
        equipmentSaved: (baseEquip * 0.35).round().clamp(ecoSponsorMin, 9999),
        co2SavedKg: baseCo2 * 0.3,
      ),
      CorporateEsgBadge(
        tier: CorporateEsgBadgeTier.communityImpactLeader,
        organizationName: 'Horizon Mobility Corp',
        organizationId: 'horizon-mobility',
        equipmentSaved:
            (baseEquip * 0.7).round().clamp(communityLeaderMin, 9999),
        co2SavedKg: baseCo2 * 0.65,
      ),
      CorporateEsgBadge(
        tier: CorporateEsgBadgeTier.zeroWasteHero,
        organizationName: 'GreenCare Industries',
        organizationId: 'greencare',
        equipmentSaved: baseEquip.clamp(zeroWasteHeroMin, 9999),
        co2SavedKg: baseCo2,
      ),
    ];
  }
}
