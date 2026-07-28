import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Reads Google Maps callback status values safely (string or JSString).
String readGoogleMapsStatus(JSAny? status) {
  if (status == null) return '';
  if (status.isA<JSString>()) return (status as JSString).toDart;
  final dartified = status.dartify();
  return dartified?.toString() ?? '';
}

/// Reads a `google.maps.LatLng` from Geocoder / Places responses.
LatLng? readGoogleLatLng(JSAny? location) {
  if (location == null) return null;

  try {
    final latLng = location as _JsLatLng;
    return LatLng(latLng.lat(), latLng.lng());
  } catch (_) {
    // Some responses expose lat/lng as callable properties.
  }

  try {
    final object = location as JSObject;
    final latValue = object.callMethod('lat'.toJS);
    final lngValue = object.callMethod('lng'.toJS);
    final lat = _readJsNumber(latValue);
    final lng = _readJsNumber(lngValue);
    if (lat == null || lng == null) return null;
    return LatLng(lat, lng);
  } catch (_) {
    return null;
  }
}

double? _readJsNumber(JSAny? value) {
  if (value == null) return null;
  if (value.isA<JSNumber>()) return (value as JSNumber).toDartDouble;
  final dartified = value.dartify();
  if (dartified is num) return dartified.toDouble();
  return double.tryParse(dartified?.toString() ?? '');
}

extension type _JsLatLng._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
}
