import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../models/item_proximity_result.dart';
import '../models/map_distance_result.dart';
import '../models/profile_address.dart';
import 'maps_distance_lookup.dart';
import 'proximity_matching_service.dart';

/// Distance + geocoding backed by a platform-specific lookup:
/// the Maps JavaScript API on web (avoids CORS) and Google Maps
/// Web Services over HTTP elsewhere.
class MapsDistanceService {
  MapsDistanceService._();

  static final MapsDistanceService instance = MapsDistanceService._();

  static const double donorPrivacyRadiusMeters = 3218.688; // ~2 miles

  PlatformDistanceLookup get _lookup => PlatformDistanceLookup.instance;
  ProximityMatchingService get _proximity => ProximityMatchingService.instance;

  bool get isAvailable => _lookup.isAvailable;

  /// True when we can show distance even if Google APIs fail (ZIP centroids).
  bool get canShowProximity => true;

  Future<ItemProximityResult?> calculateItemProximity({
    required ProfileAddress recipient,
    required String donorZipCode,
    String? donorCity,
    String? donorState,
  }) async {
    try {
      LatLng? recipientLatLng;
      LatLng? donorAreaCenter;

      if (_lookup.isAvailable) {
        final ready = await _lookup.waitUntilReady();
        if (ready) {
          recipientLatLng = await _lookup.geocodeAddress(
            recipient.formattedAddress,
          );
          recipientLatLng ??=
              await _lookup.geocodeZip(recipient.zipCode);

          donorAreaCenter = await _lookup.geocodeZip(donorZipCode);
          donorAreaCenter ??=
              await _lookup.geocodeAddress('$donorZipCode, USA');
        }
      }

      recipientLatLng ??= _proximity.latLngForZip(recipient.zipCode);
      donorAreaCenter ??= _proximity.latLngForZip(donorZipCode);

      if (recipientLatLng == null || donorAreaCenter == null) return null;

      double? miles;
      if (_lookup.isAvailable) {
        miles = await _lookup.distanceMiles(
          origin: recipient.formattedAddress,
          destination: '$donorZipCode, USA',
        );
      }
      miles ??= _proximity.estimateMilesBetweenZips(
        recipient.zipCode,
        donorZipCode,
      );
      miles ??= _haversineMiles(recipientLatLng, donorAreaCenter);

      final donorAreaLabel = donorCity != null && donorState != null
          ? '$donorCity, $donorState $donorZipCode area'
          : 'ZIP $donorZipCode area';

      return ItemProximityResult(
        distanceText: _formatItemDistanceLabel(miles),
        distanceMiles: miles,
        recipientLocation: recipientLatLng,
        donorAreaCenter: donorAreaCenter,
        donorAreaRadiusMeters: donorPrivacyRadiusMeters,
        donorAreaLabel: donorAreaLabel,
      );
    } catch (error, stack) {
      assert(() {
        // ignore: avoid_print
        print('MapsDistanceService.calculateItemProximity failed: $error\n$stack');
        return true;
      }());
      return null;
    }
  }

  Future<MapDistanceResult?> calculateDistance({
    required ProfileAddress origin,
    required ProfileAddress destination,
  }) async {
    try {
      LatLng? originLatLng;
      LatLng? destinationLatLng;

      if (_lookup.isAvailable) {
        final ready = await _lookup.waitUntilReady();
        if (ready) {
          originLatLng = await _lookup.geocodeAddress(origin.formattedAddress);
          originLatLng ??= await _lookup.geocodeZip(origin.zipCode);

          destinationLatLng =
              await _lookup.geocodeAddress(destination.formattedAddress);
          destinationLatLng ??=
              await _lookup.geocodeZip(destination.zipCode);
        }
      }

      originLatLng ??= _proximity.latLngForZip(origin.zipCode);
      destinationLatLng ??= _proximity.latLngForZip(destination.zipCode);

      if (originLatLng == null || destinationLatLng == null) return null;

      double? miles;
      if (_lookup.isAvailable) {
        miles = await _lookup.distanceMiles(
          origin: origin.formattedAddress,
          destination: destination.formattedAddress,
        );
      }
      miles ??= _proximity.estimateMilesBetweenZips(
        origin.zipCode,
        destination.zipCode,
      );
      miles ??= _haversineMiles(originLatLng, destinationLatLng);

      return MapDistanceResult(
        distanceText: _formatDistanceLabel(miles),
        distanceMiles: miles,
        origin: originLatLng,
        destination: destinationLatLng,
        originLabel: origin.shortLabel,
        destinationLabel: destination.shortLabel,
      );
    } catch (_) {
      return null;
    }
  }

  double _haversineMiles(LatLng from, LatLng to) {
    const earthRadiusMeters = 6371000.0;
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLng = _toRadians(to.longitude - from.longitude);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(from.latitude)) *
            math.cos(_toRadians(to.latitude)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return (earthRadiusMeters * c) / 1609.344;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  String _formatItemDistanceLabel(double miles) {
    if (miles < 0.1) {
      return 'This item is in your area (same ZIP region)';
    }
    if (miles < 10) {
      return 'This item is ${miles.toStringAsFixed(1)} miles away from you';
    }
    return 'This item is ${miles.round()} miles away from you';
  }

  String _formatDistanceLabel(double miles) {
    if (miles < 0.1) return 'Less than 0.1 miles away';
    if (miles < 10) {
      return '${miles.toStringAsFixed(1)} miles away';
    }
    return '${miles.round()} miles away';
  }
}
