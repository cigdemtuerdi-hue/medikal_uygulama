import 'package:google_maps_flutter/google_maps_flutter.dart';

class ItemProximityResult {
  const ItemProximityResult({
    required this.distanceText,
    required this.distanceMiles,
    required this.recipientLocation,
    required this.donorAreaCenter,
    required this.donorAreaRadiusMeters,
    required this.donorAreaLabel,
  });

  final String distanceText;
  final double distanceMiles;
  final LatLng recipientLocation;
  final LatLng donorAreaCenter;
  final double donorAreaRadiusMeters;
  final String donorAreaLabel;
}
