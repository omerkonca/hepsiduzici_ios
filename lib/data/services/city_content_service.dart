import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../models/city_content.dart';

class CityContentService {
  const CityContentService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<CityContent> loadContent() async {
    final bundled = await _loadBundled();
    final remote = await _loadRemote();
    if (remote == null) return bundled;
    return _reconcile(remote, bundled);
  }

  Future<CityContent> loadBundledOnly() => _loadBundled();
  Future<CityContent?> loadRemoteOnly() => _loadRemote();
  CityContent reconcileOnly(CityContent remote, CityContent bundled) => _reconcile(remote, bundled);

  Future<CityContent> _loadBundled() async {
    final jsonString = await rootBundle.loadString('assets/data/city_content.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return CityContent.fromJson(decoded);
  }

  Future<CityContent?> _loadRemote() async {
    if (remoteUrl.trim().isEmpty) return null;
    try {
      final response = await _dio.get(
        remoteUrl,
        options: Options(
          receiveTimeout: const Duration(seconds: 8),
          sendTimeout: const Duration(seconds: 8),
        ),
      );
      if (response.data is Map<String, dynamic>) {
        return CityContent.fromJson(response.data as Map<String, dynamic>);
      }
      if (response.data is String) {
        final decoded = jsonDecode(response.data as String) as Map<String, dynamic>;
        return CityContent.fromJson(decoded);
      }
    } catch (_) {
      // Yerel paket verisine düşülecek.
    }
    return null;
  }

  /// Uzak API (MongoDB) bozulduğunda kritik bölümleri uygulama paketinden tamamlar.
  CityContent _reconcile(CityContent remote, CityContent bundled) {
    final exploreOk = remote.exploreCategories.any((c) => c.places.isNotEmpty);
    final vetsOk = remote.veterinarians.isNotEmpty;

    return CityContent(
      serviceTiles: remote.serviceTiles.isNotEmpty ? remote.serviceTiles : bundled.serviceTiles,
      healthFacilities:
          remote.healthFacilities.isNotEmpty ? remote.healthFacilities : bundled.healthFacilities,
      veterinarians: vetsOk ? remote.veterinarians : bundled.veterinarians,
      emergencyContacts:
          remote.emergencyContacts.isNotEmpty ? remote.emergencyContacts : bundled.emergencyContacts,
      municipalityUnits: remote.municipalityUnits.isNotEmpty
          ? remote.municipalityUnits
          : bundled.municipalityUnits,
      exploreCategories: exploreOk ? remote.exploreCategories : bundled.exploreCategories,
      exploreSuggestions: remote.exploreSuggestions.isNotEmpty
          ? remote.exploreSuggestions
          : bundled.exploreSuggestions,
      mediaSponsors: remote.mediaSponsors.isNotEmpty ? remote.mediaSponsors : bundled.mediaSponsors,
      outages: remote.outages,
      transportation: remote.transportation,
      fuel: remote.fuel ?? bundled.fuel,
      branding: remote.branding ?? bundled.branding,
      quickActions: remote.quickActions.isNotEmpty ? remote.quickActions : bundled.quickActions,
      moreSections: remote.moreSections.isNotEmpty ? remote.moreSections : bundled.moreSections,
      newsSources: remote.newsSources.isNotEmpty ? remote.newsSources : bundled.newsSources,
      cityServices: _patchCityServices(remote.cityServices, bundled.cityServices),
      headerMedia: remote.headerMedia.isNotEmpty ? remote.headerMedia : bundled.headerMedia,
    );
  }

  List<CityServiceItem> _patchCityServices(
    List<CityServiceItem> remote,
    List<CityServiceItem> bundled,
  ) {
    if (remote.isEmpty) return bundled;
    final bundledVet = bundled.where((s) => s.id == 'veterinary').firstOrNull;
    if (bundledVet == null) return remote;
    return remote
        .map((s) => s.id == 'veterinary' ? bundledVet : s)
        .toList();
  }
}
