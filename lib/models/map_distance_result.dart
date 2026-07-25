import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapDistanceResult {
  const MapDistanceResult({
    required this.distanceText,
    required this.distanceMiles,
    required this.origin,
    required this.destination,
    required this.originLabel,
    required this.destinationLabel,
  });

  final String distanceText;
  final double distanceMiles;
  final LatLng origin;
  final LatLng destination;
  final String originLabel;
  final String destinationLabel;
}
