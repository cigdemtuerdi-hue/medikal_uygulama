import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/services/address_autocomplete_service.dart';

void main() {
  test('findByZip resolves a nationwide ZIP via Zippopotam', () async {
    final result = await AddressAutocompleteService.instance.findByZip('90210');
    expect(result, isNotNull);
    expect(result!.zipCode, '90210');
    expect(result.state, 'CA');
    expect(result.city.toLowerCase(), contains('beverly'));
  }, skip: false);
}
