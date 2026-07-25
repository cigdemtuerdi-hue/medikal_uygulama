import '../models/item_proximity_result.dart';
import '../models/map_distance_result.dart';
import '../models/profile_address.dart';
import 'maps_distance_lookup.dart';

/// Distance + geocoding backed by a platform-specific lookup:
/// the Maps JavaScript API on web (avoids CORS) and Google Maps
/// Web Services over HTTP elsewhere.
class MapsDistanceService {
  MapsDistanceService._();

  static final MapsDistanceService instance = MapsDistanceService._();

  static const double donorPrivacyRadiusMeters = 3218.688; // ~2 miles

  PlatformDistanceLookup get _lookup => PlatformDistanceLookup.instance;

  Future<ItemProximityResult?> calculateItemProximity({
    required ProfileAddress recipient,
    required String donorZipCode,
    String? donorCity,
    String? donorState,
  }) async {
    if (!_lookup.isAvailable) return null;

    try {
      final recipientLatLng = await _lookup.geocodeAddress(
        recipient.formattedAddress,
      );
      final donorAreaCenter = await _lookup.geocodeAddress(
        '$donorZipCode, USA',
      );
      if (recipientLatLng == null || donorAreaCenter == null) return null;

      final miles = await _lookup.distanceMiles(
        origin: recipient.formattedAddress,
        destination: '$donorZipCode, USA',
      );
      if (miles == null) return null;

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
    } catch (_) {
      return null;
    }
  }

  Future<MapDistanceResult?> calculateDistance({
    required ProfileAddress origin,
    required ProfileAddress destination,
  }) async {
    if (!_lookup.isAvailable) return null;

    try {
      final originLatLng = await _lookup.geocodeAddress(origin.formattedAddress);
      final destinationLatLng =
          await _lookup.geocodeAddress(destination.formattedAddress);
      if (originLatLng == null || destinationLatLng == null) return null;

      final miles = await _lookup.distanceMiles(
        origin: origin.formattedAddress,
        destination: destination.formattedAddress,
      );
      if (miles == null) return null;

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

  String _formatItemDistanceLabel(double miles) {
    if (miles < 0.1) {
      return 'This item is less than 0.1 miles away from you';
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
