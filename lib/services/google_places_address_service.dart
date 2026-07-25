import 'package:google_maps_webservice/geocoding.dart';
import 'package:google_maps_webservice/places.dart';

import '../config/app_config.dart';
import '../models/us_address_models.dart';

/// Live US address autocomplete via Google Maps Web Services (Places + Geocoding).
class GooglePlacesAddressService {
  GooglePlacesAddressService._();

  static final GooglePlacesAddressService instance =
      GooglePlacesAddressService._();

  static final _usComponents = [Component(Component.country, 'us')];

  GoogleMapsPlaces? _places;
  GoogleMapsGeocoding? _geocoding;
  String _sessionToken = _newSessionToken();

  GoogleMapsPlaces get places {
    _places ??= GoogleMapsPlaces(apiKey: AppConfig.googleMapsApiKey);
    return _places!;
  }

  GoogleMapsGeocoding get geocoding {
    _geocoding ??= GoogleMapsGeocoding(apiKey: AppConfig.googleMapsApiKey);
    return _geocoding!;
  }

  static String _newSessionToken() =>
      DateTime.now().microsecondsSinceEpoch.toString();

  void _resetSession() {
    _sessionToken = _newSessionToken();
  }

  Future<List<UsAddressSuggestion>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];

    final response = await places.autocomplete(
      trimmed,
      sessionToken: _sessionToken,
      language: 'en',
      region: 'us',
      types: const ['geocode'],
      components: _usComponents,
    );

    if (response.isOverQueryLimit) {
      throw Exception('Google Places quota exceeded');
    }

    if (!response.isOkay && !response.hasNoResults) {
      throw Exception(response.errorMessage ?? response.status);
    }

    return response.predictions
        .map(_fromPrediction)
        .where((suggestion) => suggestion.primaryLine.isNotEmpty)
        .toList();
  }

  Future<UsAddressSuggestion> resolve(UsAddressSuggestion suggestion) async {
    if (!suggestion.needsResolution) return suggestion;
    if (suggestion.placeId == null) return suggestion;

    final response = await places.getDetailsByPlaceId(
      suggestion.placeId!,
      sessionToken: _sessionToken,
      fields: const ['address_component', 'formatted_address'],
      language: 'en',
    );

    _resetSession();

    if (!response.isOkay) {
      throw Exception(response.errorMessage ?? response.status);
    }

    return _fromAddressComponents(
      placeId: suggestion.placeId,
      description: response.result.formattedAddress ??
          suggestion.primaryLine,
      components: response.result.addressComponents,
    );
  }

  Future<UsAddressSuggestion?> findByZip(String zip) async {
    final normalized = zip.trim();
    if (normalized.length != 5 || int.tryParse(normalized) == null) {
      return null;
    }

    final response = await geocoding.searchByComponents(
      [
        Component(Component.country, 'us'),
        Component(Component.postalCode, normalized),
      ],
      language: 'en',
      region: 'us',
    );

    if (!response.isOkay || response.results.isEmpty) return null;

    final first = response.results.first;
    return _fromAddressComponents(
      placeId: first.placeId,
      description: first.formattedAddress ?? normalized,
      components: first.addressComponents,
    );
  }

  UsAddressSuggestion _fromPrediction(Prediction prediction) {
    return UsAddressSuggestion(
      zipCode: '',
      city: '',
      state: '',
      streetAddress: prediction.description,
      placeId: prediction.placeId,
      needsResolution: true,
    );
  }

  UsAddressSuggestion _fromAddressComponents({
    required String description,
    required List<AddressComponent> components,
    String? placeId,
  }) {
    String? streetNumber;
    String? route;
    String? city;
    String? state;
    String? zip;

    for (final component in components) {
      final types = component.types.toSet();

      if (types.contains('street_number')) {
        streetNumber = component.longName;
      } else if (types.contains('route')) {
        route = component.longName;
      } else if (types.contains('locality') ||
          types.contains('postal_town') ||
          types.contains('sublocality') ||
          types.contains('neighborhood')) {
        city ??= component.longName;
      } else if (types.contains('administrative_area_level_1')) {
        state = component.shortName;
      } else if (types.contains('postal_code')) {
        zip = component.longName;
      }
    }

    final streetAddress = [
      ?streetNumber,
      ?route,
    ].join(' ').trim();

    return UsAddressSuggestion(
      zipCode: zip ?? '',
      city: city ?? '',
      state: state ?? '',
      streetAddress: streetAddress.isEmpty ? description : streetAddress,
      placeId: placeId,
      needsResolution: false,
    );
  }
}
