import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import '../models/city_content.dart';
import 'city_content_media.dart';

class CityContentService {
  const CityContentService(this._dio, {this.remoteUrl = ''});

  final Dio _dio;
  final String remoteUrl;

  Future<CityContent> loadContent() async {
    final bundled = await _loadBundled();
    final remote = await _loadRemote();
    if (remote == null) return bundled;
    return normalizeCityContentMedia(
      _reconcile(normalizeCityContentMedia(remote), bundled),
    );
  }

  Future<CityContent> loadBundledOnly() => _loadBundled();
  Future<CityContent?> loadRemoteOnly() => _loadRemote();
  CityContent reconcileOnly(CityContent remote, CityContent bundled) => _reconcile(remote, bundled);

  Future<CityContent> _loadBundled() async {
    final jsonString = await rootBundle.loadString('assets/data/city_content.json');
    final decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    return normalizeCityContentMedia(CityContent.fromJson(decoded));
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
      quickActions: _patchQuickActions(remote.quickActions, bundled.quickActions),
      moreSections: _patchMoreSections(remote.moreSections, bundled.moreSections),
      newsSources: remote.newsSources.isNotEmpty ? remote.newsSources : bundled.newsSources,
      cityServices: _patchCityServices(remote.cityServices, bundled.cityServices),
      headerMedia: remote.headerMedia.isNotEmpty ? remote.headerMedia : bundled.headerMedia,
    );
  }

  /// Uzak menüde eksik kalan uygulama ekranlarını paket verisinden tamamlar.
  List<QuickActionItem> _patchQuickActions(
    List<QuickActionItem> remote,
    List<QuickActionItem> bundled,
  ) {
    if (remote.isEmpty) return bundled;

    final remoteTargets = remote
        .map((action) => action.target)
        .where((target) => target.isNotEmpty)
        .toSet();

    final patched = List<QuickActionItem>.from(remote);
    for (final action in bundled) {
      if (action.target.isEmpty || remoteTargets.contains(action.target)) continue;
      patched.add(action);
      remoteTargets.add(action.target);
    }
    return patched;
  }

  /// Uzak menüde eksik kalan uygulama ekranlarını paket verisinden tamamlar.
  List<MoreSectionItem> _patchMoreSections(
    List<MoreSectionItem> remote,
    List<MoreSectionItem> bundled,
  ) {
    if (remote.isEmpty) return bundled;

    final remoteTargets = remote
        .expand((section) => section.tiles)
        .map((tile) => tile.target)
        .where((target) => target.isNotEmpty)
        .toSet();

    final patched = remote
        .map(
          (section) => MoreSectionItem(
            title: section.title,
            tiles: List<MoreTileItem>.from(section.tiles),
          ),
        )
        .toList();

    for (final bundledSection in bundled) {
      for (final tile in bundledSection.tiles) {
        if (tile.target.isEmpty || remoteTargets.contains(tile.target)) continue;

        final sectionIndex = patched.indexWhere((section) => section.title == bundledSection.title);
        if (sectionIndex >= 0) {
          final section = patched[sectionIndex];
          patched[sectionIndex] = MoreSectionItem(
            title: section.title,
            tiles: [tile, ...section.tiles],
          );
        } else {
          patched.add(MoreSectionItem(title: bundledSection.title, tiles: [tile]));
        }
        remoteTargets.add(tile.target);
      }
    }

    return patched;
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
