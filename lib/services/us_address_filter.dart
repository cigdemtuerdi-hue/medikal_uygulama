import '../models/us_address_models.dart';

/// Keeps autocomplete and geocoding scoped to United States addresses.
abstract final class UsAddressFilter {
  static const _stateCodes = {
    'AL', 'AK', 'AZ', 'AR', 'CA', 'CO', 'CT', 'DE', 'FL', 'GA',
    'HI', 'ID', 'IL', 'IN', 'IA', 'KS', 'KY', 'LA', 'ME', 'MD',
    'MA', 'MI', 'MN', 'MS', 'MO', 'MT', 'NE', 'NV', 'NH', 'NJ',
    'NM', 'NY', 'NC', 'ND', 'OH', 'OK', 'OR', 'PA', 'RI', 'SC',
    'SD', 'TN', 'TX', 'UT', 'VT', 'VA', 'WA', 'WV', 'WI', 'WY',
    'DC',
  };

  static bool matches(UsAddressSuggestion suggestion) {
    if (suggestion.state.isNotEmpty) {
      return _stateCodes.contains(suggestion.state.toUpperCase());
    }

    final line = suggestion.primaryLine.toLowerCase();
    if (line.contains('united states') || line.contains(', usa')) {
      return true;
    }

    for (final code in _stateCodes) {
      if (line.contains(', ${code.toLowerCase()} ') ||
          line.endsWith(', ${code.toLowerCase()}')) {
        return true;
      }
    }

    // Unresolved Google prediction — allow and resolve later.
    return suggestion.needsResolution;
  }

  static List<UsAddressSuggestion> onlyUnitedStates(
    Iterable<UsAddressSuggestion> suggestions,
  ) {
    return suggestions.where(matches).toList();
  }
}
