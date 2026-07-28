import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/services/address_autocomplete_service.dart';
import 'package:medikal_uygulama/services/us_offline_address_catalog.dart';

void main() {
  test('offline catalog finds Eastvale ZIP 92880', () {
    final match = UsOfflineAddressCatalog.findByZip('92880');
    expect(match, isNotNull);
    expect(match!.city, 'Eastvale');
    expect(match.state, 'CA');
  });

  test('offline catalog search by partial zip', () {
    final matches = UsOfflineAddressCatalog.search('9288');
    expect(matches, isNotEmpty);
    expect(matches.any((entry) => entry.zipCode == '92880'), isTrue);
  });

  test('address service returns offline suggestions without Google', () async {
    final result = await AddressAutocompleteService.instance.search('92880');
    expect(result.manualFallback, isFalse);
    expect(result.suggestions, isNotEmpty);
    expect(result.suggestions.first.zipCode, '92880');
  });
}
