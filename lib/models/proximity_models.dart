/// Radius filter options for Smart Proximity matching.
enum ProximityRange {
  within5,
  within10,
  within25,
  statewide,
}

extension ProximityRangeX on ProximityRange {
  double? get maxMiles => switch (this) {
        ProximityRange.within5 => 5,
        ProximityRange.within10 => 10,
        ProximityRange.within25 => 25,
        ProximityRange.statewide => null,
      };

  String get l10nKey => switch (this) {
        ProximityRange.within5 => 'proximity.within5',
        ProximityRange.within10 => 'proximity.within10',
        ProximityRange.within25 => 'proximity.within25',
        ProximityRange.statewide => 'proximity.statewide',
      };
}

/// Estimated logistics summary for the Route & Pickup Guide.
class RoutePickupGuide {
  const RoutePickupGuide({
    required this.distanceMiles,
    required this.driveMinutes,
    required this.recommendedSpot,
    required this.ecoCo2KgSaved,
    required this.isLocal,
    this.donorAreaLabel,
    this.recipientAreaLabel,
  });

  final double distanceMiles;
  final int driveMinutes;
  final String recommendedSpot;
  final double ecoCo2KgSaved;
  final bool isLocal;
  final String? donorAreaLabel;
  final String? recipientAreaLabel;

  String get formattedMiles {
    if (distanceMiles < 0.1) return '<0.1';
    if (distanceMiles < 10) return distanceMiles.toStringAsFixed(1);
    return distanceMiles.round().toString();
  }
}
