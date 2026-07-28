import 'dart:async';
import 'dart:js_interop';

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_config.dart';
import 'google_maps_js_helpers_web.dart';
import 'google_maps_ready.dart';

/// Web lookup — calls the Google Maps JavaScript API loaded in
/// `web/index.html`. Requests run inside the Maps JS library, so the
/// browser never issues a cross-origin HTTP request (no CORS errors).
class PlatformDistanceLookup {
  PlatformDistanceLookup._();

  static final PlatformDistanceLookup instance = PlatformDistanceLookup._();

  _Geocoder? _geocoder;
  _DistanceMatrixService? _matrix;

  bool get isAvailable =>
      AppConfig.hasGoogleMapsApiKey || isGoogleMapsScriptReady;

  Future<bool> waitUntilReady({
    Duration timeout = const Duration(seconds: 20),
  }) async {
    if (!AppConfig.hasGoogleMapsApiKey && !isGoogleMapsScriptReady) {
      return false;
    }
    return waitForGoogleMapsReady(timeout: timeout);
  }

  _Geocoder get _geocoderService {
    _geocoder ??= _Geocoder();
    return _geocoder!;
  }

  _DistanceMatrixService get _matrixService {
    _matrix ??= _DistanceMatrixService();
    return _matrix!;
  }

  Future<LatLng?> geocodeAddress(String query) {
    return _geocode(
      _GeocodeRequest(
        address: query,
        region: 'us',
        componentRestrictions: _GeocoderComponentRestrictions(country: 'US'),
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  Future<LatLng?> geocodeZip(String zip) {
    final normalized = zip.trim();
    if (normalized.length != 5 || int.tryParse(normalized) == null) {
      return Future.value(null);
    }

    return _geocode(
      _GeocodeRequest(
        componentRestrictions: _GeocoderComponentRestrictions(
          country: 'US',
          postalCode: normalized,
        ),
        region: 'us',
      ),
    ).timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }

  Future<LatLng?> _geocode(_GeocodeRequest request) {
    final completer = Completer<LatLng?>();

    _geocoderService.geocode(
      request,
      ((JSAny? results, JSAny? status) {
        try {
          final statusValue = readGoogleMapsStatus(status);
          if (statusValue != 'OK' || results == null) {
            completer.complete(null);
            return;
          }

          final list = (results as JSArray).toDart;
          if (list.isEmpty) {
            completer.complete(null);
            return;
          }

          final first = list.first as _GeocoderResult;
          completer.complete(readGoogleLatLng(first.geometry.location));
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      }).toJS,
    );

    return completer.future;
  }

  Future<double?> distanceMiles({
    required String origin,
    required String destination,
  }) {
    final completer = Completer<double?>();

    _matrixService.getDistanceMatrix(
      _DistanceMatrixRequest(
        origins: [origin.toJS].toJS,
        destinations: [destination.toJS].toJS,
        travelMode: 'DRIVING',
        region: 'us',
      ),
      ((JSAny? response, JSAny? status) {
        try {
          final statusValue = readGoogleMapsStatus(status);
          if (statusValue != 'OK' || response == null) {
            completer.complete(null);
            return;
          }

          final matrix = response as _DistanceMatrixResponse;
          final rows = matrix.rows.toDart;
          if (rows.isEmpty) {
            completer.complete(null);
            return;
          }

          final elements = rows.first.elements.toDart;
          if (elements.isEmpty) {
            completer.complete(null);
            return;
          }

          final element = elements.first;
          if (element.status != 'OK') {
            completer.complete(null);
            return;
          }

          completer.complete(element.distance.value / 1609.344);
        } catch (_) {
          if (!completer.isCompleted) completer.complete(null);
        }
      }).toJS,
    );

    return completer.future.timeout(
      const Duration(seconds: 10),
      onTimeout: () => null,
    );
  }
}

@JS('google.maps.Geocoder')
extension type _Geocoder._(JSObject _) implements JSObject {
  external factory _Geocoder();

  external void geocode(_GeocodeRequest request, JSFunction callback);
}

extension type _GeocodeRequest._(JSObject _) implements JSObject {
  external factory _GeocodeRequest({
    String? address,
    String? region,
    _GeocoderComponentRestrictions? componentRestrictions,
  });
}

extension type _GeocoderComponentRestrictions._(JSObject _)
    implements JSObject {
  external factory _GeocoderComponentRestrictions({
    String? country,
    String? postalCode,
  });
}

extension type _GeocoderResult._(JSObject _) implements JSObject {
  external _Geometry get geometry;
}

extension type _Geometry._(JSObject _) implements JSObject {
  external JSAny? get location;
}

@JS('google.maps.DistanceMatrixService')
extension type _DistanceMatrixService._(JSObject _) implements JSObject {
  external factory _DistanceMatrixService();

  external void getDistanceMatrix(
    _DistanceMatrixRequest request,
    JSFunction callback,
  );
}

extension type _DistanceMatrixRequest._(JSObject _) implements JSObject {
  external factory _DistanceMatrixRequest({
    JSArray<JSString> origins,
    JSArray<JSString> destinations,
    String travelMode,
    String? region,
  });
}

extension type _DistanceMatrixResponse._(JSObject _) implements JSObject {
  external JSArray<_DistanceMatrixRow> get rows;
}

extension type _DistanceMatrixRow._(JSObject _) implements JSObject {
  external JSArray<_DistanceMatrixElement> get elements;
}

extension type _DistanceMatrixElement._(JSObject _) implements JSObject {
  external String get status;
  external _DistanceValue get distance;
}

extension type _DistanceValue._(JSObject _) implements JSObject {
  external int get value;
}
