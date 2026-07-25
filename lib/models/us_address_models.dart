class UsAddressSuggestion {
  const UsAddressSuggestion({
    required this.zipCode,
    required this.city,
    required this.state,
    this.streetAddress,
    this.placeId,
    this.needsResolution = false,
  });

  final String zipCode;
  final String city;
  final String state;
  final String? streetAddress;
  final String? placeId;
  final bool needsResolution;

  String get primaryLine {
    if (streetAddress != null && streetAddress!.isNotEmpty) {
      if (needsResolution) return streetAddress!;
      if (zipCode.isNotEmpty && city.isNotEmpty && state.isNotEmpty) {
        return '$streetAddress, $city, $state $zipCode';
      }
      return streetAddress!;
    }
    if (city.isNotEmpty && state.isNotEmpty && zipCode.isNotEmpty) {
      return '$city, $state $zipCode';
    }
    return streetAddress ?? '';
  }

  String get secondaryLine {
    if (needsResolution) return 'United States';
    if (streetAddress != null && city.isNotEmpty) {
      return '$city, $state $zipCode';
    }
    return 'United States';
  }
}
