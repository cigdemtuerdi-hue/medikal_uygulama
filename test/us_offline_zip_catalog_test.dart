import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/services/us_offline_address_catalog.dart';

void main() {
  test('offline catalog resolves Irvine 92606 instantly', () {
    final result = UsOfflineAddressCatalog.findByZip('92606');
    expect(result, isNotNull);
    expect(result!.city, 'Irvine');
    expect(result.state, 'CA');
    expect(result.zipCode, '92606');
  });
}
