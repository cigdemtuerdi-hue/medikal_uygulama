import '../models/address_search_result.dart';
import '../models/us_address_models.dart';
import 'us_address_filter.dart';
import 'us_address_lookup.dart';
import 'us_offline_address_catalog.dart';
import 'us_zip_lookup_service.dart';

/// US-wide address autocomplete — offline catalog + Google Places.
class AddressAutocompleteService {
  AddressAutocompleteService._();

  static final AddressAutocompleteService instance =
      AddressAutocompleteService._();

  PlatformAddressLookup get _lookup => PlatformAddressLookup.instance;

  Future<AddressSearchResult> search(String query) async {
    final trimmed = query.trim();

    if (trimmed.length == 5 && int.tryParse(trimmed) != null) {
      final zipMatch = await findByZip(trimmed);
      if (zipMatch != null) {
        return AddressSearchResult(suggestions: [zipMatch]);
      }
    }

    final offline = UsOfflineAddressCatalog.search(trimmed);

    if (!_lookup.isAvailable) {
      return AddressSearchResult(
        suggestions: UsAddressFilter.onlyUnitedStates(offline),
      );
    }

    try {
      final ready = await _lookup.waitUntilReady(
        timeout: const Duration(seconds: 5),
      );
      if (!ready) {
        return AddressSearchResult(
          suggestions: UsAddressFilter.onlyUnitedStates(offline),
        );
      }

      final remote = await _lookup.search(query).timeout(
        const Duration(seconds: 10),
        onTimeout: () => const <UsAddressSuggestion>[],
      );
      final merged = _mergeSuggestions(offline, remote);
      return AddressSearchResult(
        suggestions: UsAddressFilter.onlyUnitedStates(merged),
      );
    } catch (_) {
      return AddressSearchResult(
        suggestions: UsAddressFilter.onlyUnitedStates(offline),
      );
    }
  }

  Future<UsAddressSuggestion?> resolve(UsAddressSuggestion suggestion) async {
    if (!suggestion.needsResolution) return suggestion;
    if (!_lookup.isAvailable) return suggestion;

    try {
      final ready = await _lookup.waitUntilReady(
        timeout: const Duration(seconds: 5),
      );
      if (!ready) return suggestion;
      final resolved = await _lookup.resolve(suggestion);
      if (!UsAddressFilter.matches(resolved)) return null;
      return resolved;
    } catch (_) {
      return suggestion;
    }
  }

  Future<UsAddressSuggestion?> findByZip(String zip) async {
    final offline = UsOfflineAddressCatalog.findByZip(zip);
    if (offline != null) return offline;

    // Prefer free Zippopotam before waiting on Google Maps JS (can stall).
    try {
      final fromApi = await UsZipLookupService.instance.lookup(zip).timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (fromApi != null) return fromApi;
    } catch (_) {}

    if (!_lookup.isAvailable) return null;

    try {
      final ready = await _lookup.waitUntilReady(
        timeout: const Duration(seconds: 3),
      );
      if (!ready) return null;
      final remote = await _lookup.findByZip(zip).timeout(
        const Duration(seconds: 4),
        onTimeout: () => null,
      );
      if (remote == null || !UsAddressFilter.matches(remote)) {
        return null;
      }
      return remote;
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
          '${suggestion.zipCode}|${suggestion.city}|${suggestion.state}|${suggestion.streetAddress ?? suggestion.primaryLine}';
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
