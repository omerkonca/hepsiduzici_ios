import 'dart:math' as math;

import '../models/city_content.dart';

/// Rota mesafe/süre hesabı ve mekân eşleştirme.
class TripRouteEngine {
  TripRouteEngine._();

  static const double _avgSpeedKmh = 48;
  static const int _visitMinutesPerStop = 40;

  static double distanceKm(ExplorePlace a, ExplorePlace b) {
    if (a.lat == null || a.lng == null || b.lat == null || b.lng == null) return 0;
    const r = 6371.0;
    double deg(double d) => d * math.pi / 180;
    final dLat = deg(b.lat! - a.lat!);
    final dLng = deg(b.lng! - a.lng!);
    final x = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(deg(a.lat!)) * math.cos(deg(b.lat!)) * math.sin(dLng / 2) * math.sin(dLng / 2);
    return r * 2 * math.atan2(math.sqrt(x), math.sqrt(1 - x));
  }

  static RouteSummary summarize(List<ExplorePlace> stops) {
    if (stops.isEmpty) {
      return const RouteSummary(distanceKm: 0, driveMinutes: 0, totalMinutes: 0, costTry: 0);
    }
    var driveKm = 0.0;
    for (var i = 0; i < stops.length - 1; i++) {
      final d = distanceKm(stops[i], stops[i + 1]);
      driveKm += d > 0 ? d : 4.5;
    }
    final driveMin = (driveKm / _avgSpeedKmh * 60).round();
    final visitMin = stops.length * _visitMinutesPerStop;
    final totalMin = driveMin + visitMin;
    final cost = 80 + stops.length * 45 + (driveKm * 2.8).round();
    return RouteSummary(
      distanceKm: driveKm,
      driveMinutes: driveMin,
      totalMinutes: totalMin,
      costTry: cost,
    );
  }

  static String formatDistance(double km) => '${km.toStringAsFixed(1)} km';

  static String formatDuration(int totalMinutes) {
    if (totalMinutes < 60) return '$totalMinutes dk';
    final h = totalMinutes ~/ 60;
    final m = totalMinutes % 60;
    if (m == 0) return '$h sa';
    return '$h sa $m dk';
  }

  static String formatCost(int tryAmount) => '₺$tryAmount';

  /// En yakın komşu sıralaması (güzergâh optimizasyonu — basit greedy).
  static List<ExplorePlace> orderByNearestNeighbor(List<ExplorePlace> input) {
    if (input.length <= 2) return List.of(input);
    final remaining = List<ExplorePlace>.from(input);
    final ordered = <ExplorePlace>[];
    ordered.add(remaining.removeAt(0));
    while (remaining.isNotEmpty) {
      final last = ordered.last;
      var bestIdx = 0;
      var bestDist = double.infinity;
      for (var i = 0; i < remaining.length; i++) {
        final d = distanceKm(last, remaining[i]);
        if (d < bestDist) {
          bestDist = d;
          bestIdx = i;
        }
      }
      ordered.add(remaining.removeAt(bestIdx));
    }
    return ordered;
  }

  static List<LegInfo> legs(List<ExplorePlace> ordered) {
    final result = <LegInfo>[];
    for (var i = 0; i < ordered.length - 1; i++) {
      final km = distanceKm(ordered[i], ordered[i + 1]);
      final effective = km > 0 ? km : 5.0;
      final min = ((effective / _avgSpeedKmh) * 60).round() + 1;
      result.add(LegInfo(km: effective, minutes: min));
    }
    return result;
  }

  /// JSON’daki tam / kısmi isim eşleştirme.
  static ExplorePlace? findPlace(List<ExplorePlace> all, String query) {
    final q = query.toLowerCase().trim();
    for (final p in all) {
      final n = p.name.toLowerCase();
      if (n == q || n.contains(q) || q.contains(n)) return p;
    }
    final tokens = q.split(RegExp(r'[\s\(\)]+')).where((t) => t.length > 3);
    ExplorePlace? best;
    var bestScore = 0;
    for (final p in all) {
      final n = p.name.toLowerCase();
      var score = 0;
      for (final t in tokens) {
        if (n.contains(t)) score++;
      }
      if (score > bestScore) {
        bestScore = score;
        best = p;
      }
    }
    return bestScore >= 1 ? best : null;
  }

  static List<ExplorePlace> resolveStops(List<ExplorePlace> all, List<String> names) {
    final out = <ExplorePlace>[];
    for (final name in names) {
      final match = findPlace(all, name);
      if (match != null && !out.any((p) => p.name == match.name)) {
        out.add(match);
      }
    }
    return out;
  }
}

class RouteSummary {
  const RouteSummary({
    required this.distanceKm,
    required this.driveMinutes,
    required this.totalMinutes,
    required this.costTry,
  });

  final double distanceKm;
  final int driveMinutes;
  final int totalMinutes;
  final int costTry;
}

class LegInfo {
  const LegInfo({required this.km, required this.minutes});
  final double km;
  final int minutes;
}
