import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Web lookup — calls the Google Maps JavaScript API loaded in
/// `web/index.html`. Requests run inside the Maps JS library, so the
/// browser never issues a cross-origin HTTP request (no CORS errors).
class PlatformDistanceLookup {
  PlatformDistanceLookup._();

  static final PlatformDistanceLookup instance = PlatformDistanceLookup._();

  _Geocoder? _geocoder;
  _DistanceMatrixService? _matrix;

  bool get isAvailable {
    final google = globalContext.getProperty<JSObject?>('google'.toJS);
    if (google == null || google.isUndefinedOrNull) return false;
    final maps = google.getProperty<JSObject?>('maps'.toJS);
    return maps != null && !maps.isUndefinedOrNull;
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
    final completer = Completer<LatLng?>();

    _geocoderService.geocode(
      _GeocodeRequest(
        address: query,
        region: 'us',
        componentRestrictions: _GeocoderComponentRestrictions(country: 'US'),
      ),
      ((JSArray<_GeocoderResult>? results, JSString status) {
        final statusValue = status.toDart;
        if (statusValue != 'OK' || results == null) {
          completer.complete(null);
          return;
        }
        final list = results.toDart;
        if (list.isEmpty) {
          completer.complete(null);
          return;
        }
        final location = list.first.geometry.location;
        completer.complete(LatLng(location.lat(), location.lng()));
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
      ((_DistanceMatrixResponse? response, JSString status) {
        final statusValue = status.toDart;
        if (statusValue != 'OK' || response == null) {
          completer.complete(null);
          return;
        }

        final rows = response.rows.toDart;
        if (rows.isEmpty) {
          completer.complete(null);
          return;
        }

        final elements = rows.first.elements.toDart;
        if (elements.isEmpty || elements.first.status != 'OK') {
          completer.complete(null);
          return;
        }

        completer.complete(elements.first.distance.value / 1609.344);
      }).toJS,
    );

    return completer.future;
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
  external factory _GeocoderComponentRestrictions({String? country});
}

extension type _GeocoderResult._(JSObject _) implements JSObject {
  external _Geometry get geometry;
}

extension type _Geometry._(JSObject _) implements JSObject {
  external _JsLatLng get location;
}

extension type _JsLatLng._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
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
