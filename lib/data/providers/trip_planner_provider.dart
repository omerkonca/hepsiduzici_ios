import 'package:flutter/foundation.dart';

import '../models/city_content.dart';
import '../services/trip_route_engine.dart';

class EditorRoute {
  const EditorRoute({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.regionLabel,
    required this.durationHint,
    required this.placeNames,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final String regionLabel;
  final String durationHint;
  final List<String> placeNames;

  RouteSummary summaryFor(List<ExplorePlace> stops) => TripRouteEngine.summarize(stops);

  String distanceLabel(List<ExplorePlace> stops) =>
      TripRouteEngine.formatDistance(summaryFor(stops).distanceKm);

  String durationLabel(List<ExplorePlace> stops) =>
      TripRouteEngine.formatDuration(summaryFor(stops).totalMinutes);

  String costLabel(List<ExplorePlace> stops) =>
      TripRouteEngine.formatCost(summaryFor(stops).costTry);
}

class TripPlannerProvider extends ChangeNotifier {
  TripPlannerProvider._();
  static final TripPlannerProvider instance = TripPlannerProvider._();

  final List<ExplorePlace> _places = [];
  bool _isActiveTrip = false;
  int _activeStepIndex = 0;
  String _activeTripName = '';
  List<LegInfo> _legs = [];

  List<ExplorePlace> get places => List.unmodifiable(_places);
  List<LegInfo> get legs => List.unmodifiable(_legs);
  int get count => _places.length;
  bool get isEmpty => _places.isEmpty;

  bool get isActiveTrip => _isActiveTrip;
  int get activeStepIndex => _activeStepIndex;
  String get activeTripName => _activeTripName;

  RouteSummary get routeSummary => TripRouteEngine.summarize(_places);

  bool contains(ExplorePlace place) => _places.any((p) => p.name == place.name);

  void add(ExplorePlace place) {
    if (!contains(place)) {
      _places.add(place);
      _recomputeLegs();
      notifyListeners();
    }
  }

  void remove(ExplorePlace place) {
    _places.removeWhere((p) => p.name == place.name);
    _recomputeLegs();
    notifyListeners();
  }

  void toggle(ExplorePlace place) => contains(place) ? remove(place) : add(place);

  void reorder(int oldIndex, int newIndex) {
    final item = _places.removeAt(oldIndex);
    _places.insert(newIndex > oldIndex ? newIndex - 1 : newIndex, item);
    _recomputeLegs();
    notifyListeners();
  }

  void clear() {
    _places.clear();
    _legs = [];
    _isActiveTrip = false;
    _activeStepIndex = 0;
    _activeTripName = '';
    notifyListeners();
  }

  void _recomputeLegs() {
    _legs = TripRouteEngine.legs(_places);
  }

  void startTrip(String name) {
    if (_places.isNotEmpty) {
      _isActiveTrip = true;
      _activeStepIndex = 0;
      _activeTripName = name;
      notifyListeners();
    }
  }

  void nextStep() {
    if (_isActiveTrip && _activeStepIndex < _places.length - 1) {
      _activeStepIndex++;
      notifyListeners();
    } else {
      endTrip();
    }
  }

  void previousStep() {
    if (_isActiveTrip && _activeStepIndex > 0) {
      _activeStepIndex--;
      notifyListeners();
    }
  }

  void endTrip() {
    _isActiveTrip = false;
    _activeStepIndex = 0;
    _activeTripName = '';
    notifyListeners();
  }

  void loadPresetRoute(String name, List<ExplorePlace> presetPlaces) {
    _places.clear();
    final ordered = TripRouteEngine.orderByNearestNeighbor(presetPlaces);
    _places.addAll(ordered);
    _recomputeLegs();
    _isActiveTrip = false;
    _activeStepIndex = 0;
    _activeTripName = name;
    notifyListeners();
  }

  String osmVisualizationUrl() {
    final withCoords = _places.where((p) => p.lat != null && p.lng != null).toList();
    if (withCoords.isEmpty) return 'https://www.openstreetmap.org/#map=13/37.244/36.451';
    if (withCoords.length == 1) {
      final p = withCoords.first;
      return 'https://www.openstreetmap.org/#map=15/${p.lat}/${p.lng}';
    }
    final coords = withCoords.map((p) => '${p.lng},${p.lat}').join(';');
    return 'https://www.openstreetmap.org/directions?engine=fossgis_osrm_car&route=$coords';
  }

  /// Editör rotaları — coğrafi olarak mantıklı, Düziçi odaklı güzergâhlar.
  static const List<EditorRoute> editorRoutes = [
    EditorRoute(
      id: 'duzici_merkez_tarih',
      name: 'Düziçi Merkez Tarih Turu',
      description:
          'Çarşıdan Ulu Cami\'ye, Taş Köprü\'den Harun Reşit Kalesi\'ne: ilçe merkezinde yarım günlük kültür hattı. Tüm duraklar birbirine yakın.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/f/fc/Hemite_Kalesi_-_Amouda_Castle_03.jpg/960px-Hemite_Kalesi_-_Amouda_Castle_03.jpg',
      regionLabel: 'Düziçi merkez · ~18 km',
      durationHint: 'Yarım gün',
      placeNames: [
        'Kurtuluş Çarşı ve Yeraltı Camii',
        'Düziçi Ulu Cami',
        'Taş Köprü (Fettahoğluları)',
        'Harun Reşit Kalesi',
      ],
    ),
    EditorRoute(
      id: 'sabun_cayi_doga',
      name: 'Sabun Çayı Doğa Rotası',
      description:
          'Karasu Şelalesi ve Sabun Çayı vadisi üzerinden Haruniye\'ye uzanan doğa güzergâhı. Düldül eteklerinde tek yönlü sürüş planı.',
      imageUrl: 'assets/images/karasu_selalesi.jpg',
      regionLabel: 'Düldül / Sabun Çayı · ~42 km',
      durationHint: 'Tam gün',
      placeNames: [
        'Karasu Şelalesi',
        'Sabun Çayı Vadisi',
        'Haruniye Kaplıcaları',
        'Berke Barajı Göl Manzarası',
      ],
    ),
    EditorRoute(
      id: 'duzici_kale_ucgeni',
      name: 'Üç Kale Hattı',
      description:
          'Harun Reşit, Saman ve Kurtlar kaleleri: Düziçi kırsalındaki savunma hattını tek rotada keşfedin.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/4/4b/Bah%C3%A7e%2C_Osmaniye_Bah%C3%A7e_kalesi.jpg/960px-Bah%C3%A7e%2C_Osmaniye_Bah%C3%A7e_kalesi.jpg',
      regionLabel: 'Düziçi kırsal · ~28 km',
      durationHint: 'Yarım gün',
      placeNames: [
        'Harun Reşit Kalesi',
        'Saman Kalesi',
        'Kurtlar Kalesi',
      ],
    ),
    EditorRoute(
      id: 'yayla_termal',
      name: 'Yayla & Termal Dinlenme',
      description:
          'Dumanlı Yaylası serinliği ve Haruniye kaplıcaları: aile dostu, araçla kuzey güzergâhı.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/d/d5/D%C3%BCld%C3%BCl_Da%C4%9F%C4%B1_-_Mount_D%C3%BCld%C3%BCl_02.JPG/960px-D%C3%BCld%C3%BCl_Da%C4%9F%C4%B1_-_Mount_D%C3%BCld%C3%BCl_02.JPG',
      regionLabel: 'Kuzey Düziçi · ~35 km',
      durationHint: 'Yarım gün',
      placeNames: [
        'Dumanlı Yaylası',
        'Haruniye Kaplıcaları',
      ],
    ),
    EditorRoute(
      id: 'osmaniye_arkeoloji',
      name: 'Osmaniye Arkeoloji Günü',
      description:
          'Karatepe-Aslantaş ve Kastabala: Düziçi\'den çıkış gerektiren tam günlük kültür turu (il merkezi yönü). Sabah erken yola çıkın.',
      imageUrl:
          'https://upload.wikimedia.org/wikipedia/commons/thumb/0/0c/Osmaniye_Stadt%C3%BCbersicht.png/960px-Osmaniye_Stadt%C3%BCbersicht.png.png',
      regionLabel: 'Osmaniye ili · ~95 km',
      durationHint: 'Tam gün (uzun yol)',
      placeNames: [
        'Karatepe-Aslantaş Açık Hava Müzesi',
        'Aslantaş Barajı',
        'Kastabala (Hierapolis) Antik Kenti',
      ],
    ),
  ];
}
