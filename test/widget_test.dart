import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/main.dart';

void main() {
  testWidgets('MedGift app loads home screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MedGiftApp());
    await tester.pumpAndSettle();

    expect(find.text('MedGift US'), findsOneWidget);
    expect(find.text('Donate DME & Wound Care Supplies'), findsOneWidget);
  });
}
