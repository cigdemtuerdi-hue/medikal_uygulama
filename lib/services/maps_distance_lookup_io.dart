import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/distance.dart';
import 'package:google_maps_webservice/geocoding.dart';

import '../config/app_config.dart';

/// Native (iOS/Android/desktop) lookup — direct HTTP calls to
/// Google Maps Web Services. CORS does not apply outside the browser.
class PlatformDistanceLookup {
  PlatformDistanceLookup._();

  static final PlatformDistanceLookup instance = PlatformDistanceLookup._();

  GoogleMapsGeocoding? _geocoding;
  GoogleDistanceMatrix? _distanceMatrix;

  GoogleMapsGeocoding get _geocoder {
    _geocoding ??= GoogleMapsGeocoding(apiKey: AppConfig.googleMapsApiKey);
    return _geocoding!;
  }

  GoogleDistanceMatrix get _matrix {
    _distanceMatrix ??= GoogleDistanceMatrix(apiKey: AppConfig.googleMapsApiKey);
    return _distanceMatrix!;
  }

  bool get isAvailable => AppConfig.hasGoogleMapsApiKey;

  Future<LatLng?> geocodeAddress(String query) async {
    final response = await _geocoder.searchByAddress(
      query,
      language: 'en',
      region: 'us',
      components: [Component(Component.country, 'us')],
    );

    if (!response.isOkay || response.results.isEmpty) return null;

    final location = response.results.first.geometry.location;
    return LatLng(location.lat, location.lng);
  }

  Future<double?> distanceMiles({
    required String origin,
    required String destination,
  }) async {
    final matrix = await _matrix.distanceWithAddress(
      [origin],
      [destination],
      unit: Unit.imperial,
      region: 'us',
      languageCode: 'en',
    );

    if (!matrix.isOkay || matrix.rows.isEmpty) return null;

    final elements = matrix.rows.first.elements;
    if (elements.isEmpty || elements.first.elementStatus != 'OK') {
      return null;
    }

    return elements.first.distance.value / 1609.344;
  }
}
