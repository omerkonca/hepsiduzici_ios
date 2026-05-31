import 'package:flutter/foundation.dart';

import '../models/city_content.dart';

class TripPlannerProvider extends ChangeNotifier {
  TripPlannerProvider._();
  static final TripPlannerProvider instance = TripPlannerProvider._();

  final List<ExplorePlace> _places = [];

  List<ExplorePlace> get places => List.unmodifiable(_places);
  int get count => _places.length;
  bool get isEmpty => _places.isEmpty;

  bool contains(ExplorePlace place) =>
      _places.any((p) => p.name == place.name);

  void add(ExplorePlace place) {
    if (!contains(place)) {
      _places.add(place);
      notifyListeners();
    }
  }

  void remove(ExplorePlace place) {
    _places.removeWhere((p) => p.name == place.name);
    notifyListeners();
  }

  void toggle(ExplorePlace place) =>
      contains(place) ? remove(place) : add(place);

  void reorder(int oldIndex, int newIndex) {
    final item = _places.removeAt(oldIndex);
    _places.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    notifyListeners();
  }

  void clear() {
    _places.clear();
    notifyListeners();
  }

  /// OSM OSRM ile yürüyüş rotası URL'i (koordinatlar varsa)
  String osmRouteUrl() {
    final withCoords =
        _places.where((p) => p.lat != null && p.lng != null).toList();
    if (withCoords.length < 2) {
      if (withCoords.length == 1) {
        final p = withCoords.first;
        return 'https://www.openstreetmap.org/#map=15/${p.lat}/${p.lng}';
      }
      return 'https://www.openstreetmap.org/#map=13/37.244/36.451';
    }
    // OSRM demo (driving)
    final coords = withCoords.map((p) => '${p.lng},${p.lat}').join(';');
    return 'https://router.project-osrm.org/route/v1/driving/$coords?overview=false';
  }

  /// GraphHopper / ORS harici rota - kullanıcıya OSM'de göster
  String osmVisualizationUrl() {
    final withCoords =
        _places.where((p) => p.lat != null && p.lng != null).toList();
    if (withCoords.isEmpty) return 'https://www.openstreetmap.org';
    if (withCoords.length == 1) {
      final p = withCoords.first;
      return 'https://www.openstreetmap.org/#map=15/${p.lat}/${p.lng}';
    }
    // OpenRouteService embed — her iki nokta için
    final from = withCoords.first;
    final to = withCoords.last;
    return 'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car'
        '&route=${from.lat},${from.lng};${to.lat},${to.lng}';
  }
}
