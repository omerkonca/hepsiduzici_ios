import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hepsi_duzici/main.dart';

void main() {
  testWidgets('App starts and shows Hepsi Düziçi', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HepsiDuziciApp(),
      ),
    );
    expect(find.text('Hepsi Düziçi'), findsOneWidget);
  });
}
