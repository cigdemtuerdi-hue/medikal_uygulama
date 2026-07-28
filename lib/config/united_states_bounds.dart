import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Approximate bounding box for the contiguous United States.
abstract final class UnitedStatesBounds {
  static const double minLat = 24.396308;
  static const double maxLat = 49.384358;
  static const double minLng = -124.848974;
  static const double maxLng = -66.885444;

  static const LatLng southwest = LatLng(minLat, minLng);
  static const LatLng northeast = LatLng(maxLat, maxLng);

  static LatLngBounds get latLngBounds =>
      LatLngBounds(southwest: southwest, northeast: northeast);
}
