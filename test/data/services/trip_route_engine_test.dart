import 'package:flutter_test/flutter_test.dart';
import 'package:hepsi_duzici/data/models/city_content.dart';
import 'package:hepsi_duzici/data/services/trip_route_engine.dart';

ExplorePlace _place(
  String name, {
  double? lat,
  double? lng,
}) {
  return ExplorePlace(
    name: name,
    shortDescription: 'kisa',
    detail: 'detay',
    address: 'adres',
    tag: 'TEST',
    lat: lat,
    lng: lng,
  );
}

void main() {
  group('TripRouteEngine', () {
    test('summarize returns zero values for empty route', () {
      final s = TripRouteEngine.summarize(const []);
      expect(s.distanceKm, 0);
      expect(s.driveMinutes, 0);
      expect(s.totalMinutes, 0);
      expect(s.costTry, 0);
    });

    test('legs computes positive values with coordinates', () {
      final places = [
        _place('A', lat: 37.2400, lng: 36.4460),
        _place('B', lat: 37.2450, lng: 36.4600),
        _place('C', lat: 37.2510, lng: 36.4680),
      ];
      final legs = TripRouteEngine.legs(places);
      expect(legs.length, 2);
      expect(legs.first.km, greaterThan(0));
      expect(legs.first.minutes, greaterThan(0));
    });

    test('findPlace supports partial text matching', () {
      final places = [
        _place('Düziçi Ulu Cami'),
        _place('Taş Köprü (Fettahoğluları)'),
      ];
      final match = TripRouteEngine.findPlace(places, 'Ulu Cami');
      expect(match?.name, 'Düziçi Ulu Cami');
    });

    test('resolveStops removes duplicates and preserves order', () {
      final places = [
        _place('Düziçi Ulu Cami'),
        _place('Taş Köprü (Fettahoğluları)'),
      ];
      final resolved = TripRouteEngine.resolveStops(places, [
        'Ulu Cami',
        'Taş Köprü',
        'Ulu Cami',
      ]);
      expect(resolved.map((e) => e.name).toList(), [
        'Düziçi Ulu Cami',
        'Taş Köprü (Fettahoğluları)',
      ]);
    });
  });
}
