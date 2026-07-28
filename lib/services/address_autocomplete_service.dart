import '../models/address_search_result.dart';
import '../models/us_address_models.dart';
import 'us_address_lookup.dart';
import 'us_offline_address_catalog.dart';

/// US address autocomplete — offline catalog first, Google Places when available.
class AddressAutocompleteService {
  AddressAutocompleteService._();

  static final AddressAutocompleteService instance =
      AddressAutocompleteService._();

  PlatformAddressLookup get _lookup => PlatformAddressLookup.instance;

  Future<bool> _ensureReady() => _lookup.waitUntilReady();

  Future<AddressSearchResult> search(String query) async {
    final offline = UsOfflineAddressCatalog.search(query);

    if (!_lookup.isAvailable) {
      return AddressSearchResult(suggestions: offline);
    }

    try {
      if (!await _ensureReady()) {
        return AddressSearchResult(suggestions: offline);
      }
      final remote = await _lookup.search(query);
      return AddressSearchResult(
        suggestions: _mergeSuggestions(offline, remote),
      );
    } catch (_) {
      return AddressSearchResult(suggestions: offline);
    }
  }

  Future<UsAddressSuggestion?> resolve(UsAddressSuggestion suggestion) async {
    if (!suggestion.needsResolution) return suggestion;
    if (!_lookup.isAvailable) return suggestion;

    try {
      if (!await _ensureReady()) return suggestion;
      return await _lookup.resolve(suggestion);
    } catch (_) {
      return suggestion;
    }
  }

  Future<UsAddressSuggestion?> findByZip(String zip) async {
    final offline = UsOfflineAddressCatalog.findByZip(zip);
    if (offline != null) return offline;

    if (!_lookup.isAvailable) return null;

    try {
      if (!await _ensureReady()) return null;
      return await _lookup.findByZip(zip);
    } catch (_) {
      return null;
    }
  }

  List<UsAddressSuggestion> _mergeSuggestions(
    List<UsAddressSuggestion> offline,
    List<UsAddressSuggestion> remote,
  ) {
    if (remote.isEmpty) return offline;
    if (offline.isEmpty) return remote;

    final seen = <String>{};
    final merged = <UsAddressSuggestion>[];

    void add(UsAddressSuggestion suggestion) {
      final key =
          '${suggestion.zipCode}|${suggestion.city}|${suggestion.state}|${suggestion.streetAddress ?? ''}';
      if (seen.add(key)) merged.add(suggestion);
    }

    for (final suggestion in offline) {
      add(suggestion);
    }
    for (final suggestion in remote) {
      add(suggestion);
    }
    return merged;
  }
}
