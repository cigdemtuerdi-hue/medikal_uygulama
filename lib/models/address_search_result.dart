import '../models/us_address_models.dart';

class AddressSearchResult {
  const AddressSearchResult({
    this.suggestions = const [],
    this.manualFallback = false,
  });

  final List<UsAddressSuggestion> suggestions;
  final bool manualFallback;

  factory AddressSearchResult.manualFallback() {
    return const AddressSearchResult(manualFallback: true);
  }
}

class AddressAutocompleteMessages {
  static const apiUnavailable =
      'Could not retrieve addresses. Please enter manually.';
}
