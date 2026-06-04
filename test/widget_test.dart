import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hepsi_duzici/main.dart';
import 'package:hepsi_duzici/app/providers.dart';
import 'package:hepsi_duzici/data/models/city_content.dart';
import 'package:hepsi_duzici/data/models/weather_info.dart';
import 'package:hepsi_duzici/data/services/notification_service.dart';

class FakeNotificationService extends NotificationService {
  @override
  Future<void> init() async {}

  @override
  Future<bool> ensureNotificationPermissions() async => true;

  @override
  Future<bool> areSystemNotificationsEnabled() async => false;
}

void main() {
  testWidgets('App starts and shows Hepsi Düziçi', (WidgetTester tester) async {
    // Set a realistic viewport to avoid layout overflow issues in test environment
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues({'has_seen_onboarding': true});
    await initializeDateFormatting('tr_TR', null);
    
    // Load bundled city content JSON directly to override network fetch
    final jsonString = await rootBundle.loadString('assets/data/city_content.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    final cityContent = CityContent.fromJson(decoded);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(FakeNotificationService()),
          cityContentProvider.overrideWith((ref) => cityContent),
          unreadNotificationsCountProvider.overrideWithValue(0),
          weatherProvider.overrideWith((ref) => const WeatherInfo(
            temperature: 24.0,
            conditionCode: 1,
            isDay: true,
          )),
          pharmacyListProvider.overrideWith((ref) => []),
        ],
        child: const HepsiDuziciApp(),
      ),
    );
    
    // Pump frames for async operations to complete without waiting for infinite looping animations
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();
    
    expect(find.text('HEPSİ'), findsOneWidget);
  });
}
