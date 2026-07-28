import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/available_donation_item.dart';
import '../models/donation_models.dart';
import '../models/profile_address.dart';
import '../models/proximity_models.dart';

/// Fast ZIP-level proximity estimates for list filters and pickup guides.
/// Uses known centroids + a deterministic US ZIP approximation (no network).
class ProximityMatchingService {
  ProximityMatchingService._();

  static final ProximityMatchingService instance = ProximityMatchingService._();

  /// Demo / catalog ZIP centroids (lat, lng).
  static const Map<String, (double, double)> _knownZipCentroids = {
    '92880': (33.9761, -117.5647), // Eastvale, CA
    '94102': (37.7793, -122.4192), // San Francisco, CA
    '90210': (34.0901, -118.4065), // Beverly Hills, CA
    '90012': (34.0615, -118.2395), // LA Civic Center area
    '92101': (32.7185, -117.1628), // San Diego downtown
    '95814': (38.5800, -121.4930), // Sacramento
    '89101': (36.1699, -115.1398), // Las Vegas
    '85004': (33.4484, -112.0740), // Phoenix
  };

  /// Local safe-exchange spot suggestions by city key.
  static const Map<String, String> _safeSpotsByCity = {
    'eastvale': 'Eastvale Community Center parking lot (well-lit public area)',
    'san francisco': 'SF Public Library — Main Branch plaza',
    'beverly hills': 'Beverly Hills Police Department visitor lot',
    'los angeles': 'LA Central Library plaza (daytime)',
  };

  /// Offline ZIP centroid for map pins when Google Geocoding is unavailable.
  LatLng? latLngForZip(String zip) {
    final centroid = _centroidForZip(zip);
    if (centroid == null) return null;
    return LatLng(centroid.$1, centroid.$2);
  }

  double? estimateMilesBetweenZips(String fromZip, String toZip) {
    final a = _centroidForZip(fromZip);
    final b = _centroidForZip(toZip);
    if (a == null || b == null) return null;
    return _haversineMiles(a.$1, a.$2, b.$1, b.$2);
  }

  double? estimateMilesToItem({
    required ProfileAddress recipient,
    required AvailableDonationItem item,
  }) {
    return estimateMilesBetweenZips(recipient.zipCode, item.donorZipCode);
  }

  bool matchesProximityFilter({
    required ProximityRange range,
    required double? miles,
    String? recipientState,
    String? donorState,
  }) {
    switch (range) {
      case ProximityRange.statewide:
        if (recipientState == null || donorState == null) {
          // If state unknown, keep item when miles are within a generous band.
          return miles == null || miles <= 400;
        }
        return recipientState.toUpperCase() == donorState.toUpperCase();
      case ProximityRange.within5:
      case ProximityRange.within10:
      case ProximityRange.within25:
        if (miles == null) return false;
        return miles <= range.maxMiles!;
    }
  }

  RoutePickupGuide buildRouteGuide({
    required ProfileAddress recipient,
    required AvailableDonationItem item,
  }) {
    final miles = estimateMilesToItem(recipient: recipient, item: item) ?? 12.0;
    final minutes = estimateDriveMinutes(miles);
    final spot = recommendSafeExchangeSpot(
      donorCity: item.donorCity,
      donorState: item.donorState,
      recipientCity: recipient.city,
      recipientState: recipient.state,
    );
    final eco = ecoTransportCo2KgSaved(miles: miles, dmeType: item.dmeType);
    final isLocal = miles <= 25;

    return RoutePickupGuide(
      distanceMiles: miles,
      driveMinutes: minutes,
      recommendedSpot: spot,
      ecoCo2KgSaved: eco,
      isLocal: isLocal,
      donorAreaLabel: item.donorAreaLabel,
      recipientAreaLabel: recipient.shortLabel,
    );
  }

  int estimateDriveMinutes(double miles) {
    // Urban / suburban mix ~22 mph average including lights.
    final minutes = (miles / 22.0) * 60.0;
    return math.max(5, minutes.round());
  }

  String recommendSafeExchangeSpot({
    String? donorCity,
    String? donorState,
    String? recipientCity,
    String? recipientState,
  }) {
    final cityKey = (donorCity ?? recipientCity ?? '').trim().toLowerCase();
    if (cityKey.isNotEmpty && _safeSpotsByCity.containsKey(cityKey)) {
      return _safeSpotsByCity[cityKey]!;
    }
    final state = (donorState ?? recipientState ?? 'your area').trim();
    if (cityKey.isNotEmpty) {
      return 'Recommended local safe exchange spot: $cityKey public library or police station lobby ($state)';
    }
    return 'Recommended local safe exchange spot: well-lit public library or community center in $state';
  }

  /// Approx kg CO₂ avoided vs long-haul shipping / courier for this hop.
  double ecoTransportCo2KgSaved({
    required double miles,
    DmeType? dmeType,
  }) {
    final base = switch (dmeType) {
      DmeType.wheelchair || DmeType.hospitalBed => 10.0,
      DmeType.oxygenEquipment => 9.0,
      DmeType.walker || DmeType.commode || DmeType.showerChair => 7.0,
      _ => 6.0,
    };
    final fromMiles = miles * 0.28;
    return (base + fromMiles).clamp(5.0, 48.0);
  }

  String formatMilesAway(double miles) {
    if (miles < 0.1) return '<0.1';
    if (miles < 10) return miles.toStringAsFixed(1);
    return miles.round().toString();
  }

  (double, double)? _centroidForZip(String zip) {
    final cleaned = zip.trim();
    if (cleaned.length < 5) return null;
    final five = cleaned.substring(0, 5);
    if (_knownZipCentroids.containsKey(five)) {
      return _knownZipCentroids[five];
    }
    return _approximateUsZipCentroid(five);
  }

  /// Deterministic lat/lng band from ZIP digits (demo-friendly, offline).
  (double, double)? _approximateUsZipCentroid(String zip5) {
    final n = int.tryParse(zip5);
    if (n == null) return null;
    // Rough US bounding box mapped across ZIP numeric space 00501–99950.
    final t = ((n - 501) / (99950 - 501)).clamp(0.0, 1.0);
    final lat = 25.0 + t * 24.0; // ~25°N to ~49°N
    final lng = -125.0 + ((n % 1000) / 1000.0) * 58.0; // west→east jitter
    return (lat, lng);
  }

  double _haversineMiles(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusMiles = 3958.8;
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMiles * c;
  }

  double _toRad(double deg) => deg * math.pi / 180.0;
}
