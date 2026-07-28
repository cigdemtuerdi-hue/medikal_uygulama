import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import '../models/us_address_models.dart';

/// Web lookup — calls the Google Maps JavaScript API that is loaded via the
/// script tag in `web/index.html`. Requests run inside the Maps JS library,
/// so the browser never issues a cross-origin HTTP request (no CORS errors).
class PlatformAddressLookup {
  PlatformAddressLookup._();

  static final PlatformAddressLookup instance = PlatformAddressLookup._();

  _AutocompleteService? _autocomplete;
  _Geocoder? _geocoder;

  bool get isAvailable {
    final google = globalContext.getProperty<JSObject?>('google'.toJS);
    if (google == null || google.isUndefinedOrNull) return false;
    final maps = google.getProperty<JSObject?>('maps'.toJS);
    if (maps == null || maps.isUndefinedOrNull) return false;
    final places = maps.getProperty<JSObject?>('places'.toJS);
    return places != null && !places.isUndefinedOrNull;
  }

  _AutocompleteService get _autocompleteService {
    _autocomplete ??= _AutocompleteService();
    return _autocomplete!;
  }

  _Geocoder get _geocoderService {
    _geocoder ??= _Geocoder();
    return _geocoder!;
  }

  Future<List<UsAddressSuggestion>> search(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future.value(const []);

    final completer = Completer<List<UsAddressSuggestion>>();

    _autocompleteService.getPlacePredictions(
      _AutocompleteRequest(
        input: trimmed,
        componentRestrictions: _ComponentRestrictions(country: 'us'),
        types: ['geocode'.toJS].toJS,
      ),
      ((JSArray<_Prediction>? predictions, JSString status) {
        final statusValue = status.toDart;
        if (statusValue == 'ZERO_RESULTS' || predictions == null) {
          completer.complete(const []);
          return;
        }
        if (statusValue != 'OK') {
          completer.completeError(
            Exception('Places autocomplete failed: $statusValue'),
          );
          return;
        }
        completer.complete(
          predictions.toDart
              .map(
                (prediction) => UsAddressSuggestion(
                  zipCode: '',
                  city: '',
                  state: '',
                  streetAddress: prediction.description,
                  placeId: prediction.placeId,
                  needsResolution: true,
                ),
              )
              .where((suggestion) => suggestion.primaryLine.isNotEmpty)
              .toList(),
        );
      }).toJS,
    );

    return completer.future;
  }

  Future<UsAddressSuggestion> resolve(UsAddressSuggestion suggestion) async {
    if (!suggestion.needsResolution) return suggestion;
    if (suggestion.placeId == null) return suggestion;

    final results = await _geocode(_GeocodeRequest(placeId: suggestion.placeId));
    if (results.isEmpty) return suggestion;

    return _fromGeocoderResult(results.first);
  }

  Future<UsAddressSuggestion?> findByZip(String zip) async {
    final normalized = zip.trim();
    if (normalized.length != 5 || int.tryParse(normalized) == null) {
      return null;
    }

    final results = await _geocode(
      _GeocodeRequest(
        componentRestrictions: _GeocoderComponentRestrictions(
          country: 'US',
          postalCode: normalized,
        ),
        region: 'us',
      ),
    );

    if (results.isEmpty) return null;
    return _fromGeocoderResult(results.first);
  }

  Future<List<_GeocoderResult>> _geocode(_GeocodeRequest request) {
    final completer = Completer<List<_GeocoderResult>>();

    _geocoderService.geocode(
      request,
      ((JSArray<_GeocoderResult>? results, JSString status) {
        final statusValue = status.toDart;
        if (statusValue == 'ZERO_RESULTS' || results == null) {
          completer.complete(const []);
          return;
        }
        if (statusValue != 'OK') {
          completer.completeError(Exception('Geocoding failed: $statusValue'));
          return;
        }
        completer.complete(results.toDart);
      }).toJS,
    );

    return completer.future;
  }

  UsAddressSuggestion _fromGeocoderResult(_GeocoderResult result) {
    String? streetNumber;
    String? route;
    String? city;
    String? state;
    String? zip;

    for (final component in result.addressComponents.toDart) {
      final types = component.types.toDart.map((t) => t.toDart).toSet();

      if (types.contains('street_number')) {
        streetNumber = component.longName;
      } else if (types.contains('route')) {
        route = component.longName;
      } else if (types.contains('locality') ||
          types.contains('postal_town') ||
          types.contains('sublocality') ||
          types.contains('neighborhood') ||
          types.contains('administrative_area_level_3') ||
          types.contains('administrative_area_level_2')) {
        city ??= component.longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = component.shortName;
      } else if (types.contains('postal_code')) {
        zip = component.longName;
      }
    }

    final description = result.formattedAddress ?? '';
    final streetAddress = [
      ?streetNumber,
      ?route,
    ].join(' ').trim();

    return UsAddressSuggestion(
      zipCode: zip ?? '',
      city: city ?? '',
      state: state ?? '',
      streetAddress: streetAddress.isEmpty ? description : streetAddress,
      placeId: result.placeId,
      needsResolution: false,
    );
  }
}

@JS('google.maps.places.AutocompleteService')
extension type _AutocompleteService._(JSObject _) implements JSObject {
  external factory _AutocompleteService();

  external void getPlacePredictions(
    _AutocompleteRequest request,
    JSFunction callback,
  );
}

extension type _AutocompleteRequest._(JSObject _) implements JSObject {
  external factory _AutocompleteRequest({
    required String input,
    _ComponentRestrictions? componentRestrictions,
    JSArray<JSString>? types,
  });
}

extension type _ComponentRestrictions._(JSObject _) implements JSObject {
  external factory _ComponentRestrictions({String country});
}

extension type _Prediction._(JSObject _) implements JSObject {
  external String get description;

  @JS('place_id')
  external String get placeId;
}

@JS('google.maps.Geocoder')
extension type _Geocoder._(JSObject _) implements JSObject {
  external factory _Geocoder();

  external void geocode(_GeocodeRequest request, JSFunction callback);
}

extension type _GeocodeRequest._(JSObject _) implements JSObject {
  external factory _GeocodeRequest({
    String? placeId,
    _GeocoderComponentRestrictions? componentRestrictions,
    String? region,
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
  @JS('formatted_address')
  external String? get formattedAddress;

  @JS('place_id')
  external String? get placeId;

  @JS('address_components')
  external JSArray<_GeocoderAddressComponent> get addressComponents;
}

extension type _GeocoderAddressComponent._(JSObject _) implements JSObject {
  @JS('long_name')
  external String get longName;

  @JS('short_name')
  external String get shortName;

  external JSArray<JSString> get types;
}
