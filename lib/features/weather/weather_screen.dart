import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../home/widgets/weather_card.dart';

class WeatherScreen extends ConsumerWidget {
  const WeatherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hava Durumu')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(stampedWeatherProvider),
        child: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: WeatherCard(),
          ),
        ),
      ),
    );
  }
}
