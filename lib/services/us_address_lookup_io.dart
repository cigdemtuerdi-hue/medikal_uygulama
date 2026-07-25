import '../config/app_config.dart';
import '../models/us_address_models.dart';
import 'google_places_address_service.dart';

/// Native (iOS/Android/desktop) lookup — direct HTTP calls to
/// Google Maps Web Services. CORS does not apply outside the browser.
class PlatformAddressLookup {
  PlatformAddressLookup._();

  static final PlatformAddressLookup instance = PlatformAddressLookup._();

  bool get isAvailable => AppConfig.hasGoogleMapsApiKey;

  Future<List<UsAddressSuggestion>> search(String query) {
    return GooglePlacesAddressService.instance.search(query);
  }

  Future<UsAddressSuggestion> resolve(UsAddressSuggestion suggestion) {
    return GooglePlacesAddressService.instance.resolve(suggestion);
  }

  Future<UsAddressSuggestion?> findByZip(String zip) {
    return GooglePlacesAddressService.instance.findByZip(zip);
  }
}
