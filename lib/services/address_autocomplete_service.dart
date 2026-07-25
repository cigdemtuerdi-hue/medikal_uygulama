import '../models/address_search_result.dart';
import '../models/us_address_models.dart';
import 'us_address_lookup.dart';

/// Live US address autocomplete backed by Google Places.
///
/// Delegates to a platform-specific lookup: the Maps JavaScript API on web
/// (avoids CORS) and Google Maps Web Services over HTTP elsewhere.
class AddressAutocompleteService {
  AddressAutocompleteService._();

  static final AddressAutocompleteService instance =
      AddressAutocompleteService._();

  PlatformAddressLookup get _lookup => PlatformAddressLookup.instance;

  Future<AddressSearchResult> search(String query) async {
    if (!_lookup.isAvailable) {
      return AddressSearchResult.manualFallback();
    }

    try {
      final suggestions = await _lookup.search(query);
      return AddressSearchResult(suggestions: suggestions);
    } catch (_) {
      return AddressSearchResult.manualFallback();
    }
  }

  Future<UsAddressSuggestion?> resolve(UsAddressSuggestion suggestion) async {
    if (!_lookup.isAvailable) return null;

    try {
      return await _lookup.resolve(suggestion);
    } catch (_) {
      return null;
    }
  }

  Future<UsAddressSuggestion?> findByZip(String zip) async {
    if (!_lookup.isAvailable) return null;

    try {
      return await _lookup.findByZip(zip);
    } catch (_) {
      return null;
    }
  }
}
