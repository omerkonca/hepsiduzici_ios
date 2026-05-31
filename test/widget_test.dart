import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hepsi_duzici/main.dart';

void main() {
  testWidgets('App starts and shows Hepsi Düziçi', (WidgetTester tester) async {
    // Set a realistic viewport to avoid layout overflow issues in test environment
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    await initializeDateFormatting('tr_TR', null);
    
    await tester.pumpWidget(
      const ProviderScope(
        child: HepsiDuziciApp(),
      ),
    );
    
    // Pump frames for async operations to complete without waiting for infinite looping animations
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    
    expect(find.text('Hepsi Düziçi'), findsOneWidget);
  });
}
