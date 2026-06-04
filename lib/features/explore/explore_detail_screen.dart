import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:video_player/video_player.dart';
import '../../data/models/city_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/dynamic_place_facilities.dart';
import '../../core/widgets/place_network_image.dart';
import '../../data/services/place_photo_service.dart';
import '../../data/services/favorites_service.dart';
import '../../data/providers/trip_planner_provider.dart';
import 'widgets/explore_list_theme.dart';

class ExploreDetailScreen extends StatefulWidget {
  const ExploreDetailScreen({
    super.key,
    required this.place,
    this.userLat,
    this.userLng,
    this.selectedMahalle,
    this.isActiveNavigation = false,
  });

  final ExplorePlace place;
  final double? userLat;
  final double? userLng;
  final String? selectedMahalle;
  final bool isActiveNavigation;

  @override
  State<ExploreDetailScreen> createState() => _ExploreDetailScreenState();
}

class _ExploreDetailScreenState extends State<ExploreDetailScreen> {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _videoPlayerController;
  bool _isVideoPlayerInitialized = false;
  int _currentGalleryIndex = 0;

  // Koordinat Bilgileri Eşleştirmesi
  static const Map<String, _PlaceCoords> _placeCoordinates = {
    'Berke Barajı ve göl alanı': _PlaceCoords(37.2215, 36.4710),
    'Düldül Dağı ve Dumanlı Yaylası': _PlaceCoords(37.2880, 36.5650),
    'Karasu Şelalesi (Sabun Çayı)': _PlaceCoords(37.2510, 36.4680),
    'Haruniye Kaplıcaları': _PlaceCoords(37.2620, 36.4950),
    'Harun Reşit Kalesi': _PlaceCoords(37.2580, 36.4800),
    'Saman ve Kurtlar kaleleri': _PlaceCoords(37.2650, 36.4350),
    'Taş Köprü (Fettahoğluları)': _PlaceCoords(37.2450, 36.4600),
    'Osmaniye mutfağı ve Düziçi': _PlaceCoords(37.2440, 36.4510),
    'Merkezde öğün ve çay': _PlaceCoords(37.2400, 36.4460),
    'Köy kahvaltısı ve yayla sofrası': _PlaceCoords(37.2750, 36.4900),
    'Kara yolu ile Düziçi': _PlaceCoords(37.2340, 36.4420),
    'Tren ve havaalanı bağlantıları': _PlaceCoords(37.1990, 36.4300),
    'Resmî iletişim ve güncelleme': _PlaceCoords(37.2440, 36.4510),
  };

  static const Map<String, _PlaceCoords> _mahalleler = {
    'İrfanlı Mahallesi': _PlaceCoords(37.2440, 36.4510),
    'Cumhuriyet Mahallesi': _PlaceCoords(37.2400, 36.4460),
    'Yeşilova Mahallesi': _PlaceCoords(37.2380, 36.4480),
    'Şehitler Mahallesi': _PlaceCoords(37.2420, 36.4490),
    'İstiklal Mahallesi': _PlaceCoords(37.2410, 36.4550),
    'Kurtuluş Mahallesi': _PlaceCoords(37.2340, 36.4420),
    'Üzümlü Mahallesi': _PlaceCoords(37.2280, 36.4650),
    'Karlıca Mahallesi': _PlaceCoords(37.2450, 36.4350),
    'Hürriyet Mahallesi': _PlaceCoords(37.2500, 36.4600),
    'Ellek Beldesi': _PlaceCoords(37.2880, 36.4800),
    'Yarbaşı Beldesi': _PlaceCoords(37.1990, 36.4300),
    'Kuşçu Köyü / Haruniye': _PlaceCoords(37.2750, 36.4900),
  };

  static const Map<String, double> _placeRatings = {
    'Berke Barajı ve göl alanı': 4.7,
    'Düldül Dağı ve Dumanlı Yaylası': 4.9,
    'Karasu Şelalesi (Sabun Çayı)': 4.6,
    'Haruniye Kaplıcaları': 4.5,
    'Harun Reşit Kalesi': 4.8,
    'Saman ve Kurtlar kaleleri': 4.2,
    'Taş Köprü (Fettahoğluları)': 4.4,
    'Osmaniye mutfağı ve Düziçi': 4.6,
    'Merkezde öğün ve çay': 4.5,
    'Köy kahvaltısı ve yayla sofrası': 4.7,
    'Kara yolu ile Düziçi': 4.1,
    'Tren ve havaalanı bağlantıları': 4.3,
    'Resmî iletişim ve güncelleme': 4.0,
    'Dumanlı Yaylası': 4.9,
    'Düldül Yaylası': 4.8,
    'Belediye Yaylası': 4.6,
    'Mezdağ (Mezdağı) Yaylası': 4.5,
    'Tozluyurt Yaylası': 4.7,
    'Yukarı Hacılar Yaylası': 4.4,
    'Kurtlar Yaylası': 4.3,
    'Nacar Yaylası': 4.5,
    'Hodu Yaylası': 4.6,
    'Zorkun Yaylası': 4.8,
    'Düldül Yaylası Kamp Alanı': 4.8,
    'Mezdağ (Mezdağı) Yaylası Kamp Alanı': 4.6,
    'Tozluyurt Yaylası Kamp Alanı': 4.7,
    'Kurtlar Yaylası Kamp Alanı': 4.4,
    'Hodu Yaylası Kamp Alanı': 4.5,
    'Dumanlı Yaylası Yürüyüş Parkuru': 4.7,
    'Düldül Yaylası Doğa Yürüyüşü': 4.9,
    'Mezdağ (Mezdağı) Yaylası Yürüyüş Rotası': 4.5,
    'Kurtlar Yaylası Trekking Parkuru': 4.4,
    'Hodu Yaylası Doğa Yürüyüşü': 4.6,
    'Düziçi Köy Enstitüsü Müzesi (Eğitim Tarihi Müzesi)': 4.8,
    'Karatepe-Aslantaş Açık Hava Müzesi': 4.9,
    'Osmaniye Kent Müzesi': 4.7,
  };

  static const Map<String, int> _placeReviewCounts = {
    'Berke Barajı ve göl alanı': 245,
    'Düldül Dağı ve Dumanlı Yaylası': 892,
    'Karasu Şelalesi (Sabun Çayı)': 532,
    'Haruniye Kaplıcaları': 412,
    'Harun Reşit Kalesi': 387,
    'Saman ve Kurtlar kaleleri': 48,
    'Taş Köprü (Fettahoğluları)': 114,
    'Osmaniye mutfağı ve Düziçi': 675,
    'Merkezde öğün ve çay': 310,
    'Köy kahvaltısı ve yayla sofrası': 215,
    'Kara yolu ile Düziçi': 89,
    'Tren ve havaalanı bağlantıları': 156,
    'Resmî iletişim ve güncelleme': 32,
    'Dumanlı Yaylası': 892,
    'Düldül Yaylası': 450,
    'Belediye Yaylası': 320,
    'Mezdağ (Mezdağı) Yaylası': 120,
    'Tozluyurt Yaylası': 180,
    'Yukarı Hacılar Yaylası': 95,
    'Kurtlar Yaylası': 60,
    'Nacar Yaylası': 80,
    'Hodu Yaylası': 110,
    'Zorkun Yaylası': 920,
    'Düldül Yaylası Kamp Alanı': 140,
    'Mezdağ (Mezdağı) Yaylası Kamp Alanı': 55,
    'Tozluyurt Yaylası Kamp Alanı': 70,
    'Kurtlar Yaylası Kamp Alanı': 35,
    'Hodu Yaylası Kamp Alanı': 45,
    'Dumanlı Yaylası Yürüyüş Parkuru': 280,
    'Düldül Yaylası Doğa Yürüyüşü': 320,
    'Mezdağ (Mezdağı) Yaylası Yürüyüş Rotası': 75,
    'Kurtlar Yaylası Trekking Parkuru': 42,
    'Hodu Yaylası Doğa Yürüyüşü': 85,
    'Düziçi Köy Enstitüsü Müzesi (Eğitim Tarihi Müzesi)': 156,
    'Karatepe-Aslantaş Açık Hava Müzesi': 1120,
    'Osmaniye Kent Müzesi': 340,
  };

  @override
  void initState() {
    super.initState();
    final videoUrl = widget.place.videoUrl;
    if (videoUrl != null && videoUrl.isNotEmpty) {
      final isYoutube = videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be');
      if (!isYoutube) {
        if (videoUrl.startsWith('assets/')) {
          _videoPlayerController = VideoPlayerController.asset(videoUrl)
            ..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _isVideoPlayerInitialized = true;
                });
              }
            });
        } else {
          _videoPlayerController = VideoPlayerController.networkUrl(
            Uri.parse(videoUrl),
          )..initialize().then((_) {
              if (mounted) {
                setState(() {
                  _isVideoPlayerInitialized = true;
                });
              }
            });
        }
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _videoPlayerController?.dispose();
    super.dispose();
  }

  // Koordinat ve Derece Yardımcıları
  _PlaceCoords? _getCoordsForPlace(ExplorePlace place) {
    if (place.lat != null && place.lng != null) {
      return _PlaceCoords(place.lat!, place.lng!);
    }
    if (_placeCoordinates.containsKey(place.name)) {
      return _placeCoordinates[place.name];
    }
    for (final entry in _placeCoordinates.entries) {
      if (place.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return null;
  }

  double _getRatingForPlace(ExplorePlace place) {
    if (_placeRatings.containsKey(place.name)) {
      return _placeRatings[place.name]!;
    }
    for (final entry in _placeRatings.entries) {
      if (place.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return 4.5;
  }

  int _getReviewCountForPlace(ExplorePlace place) {
    if (_placeReviewCounts.containsKey(place.name)) {
      return _placeReviewCounts[place.name]!;
    }
    for (final entry in _placeReviewCounts.entries) {
      if (place.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }
    return 120;
  }

  double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((lat2 - lat1) * p) / 2 +
        math.cos(lat1 * p) * math.cos(lat2 * p) *
            (1 - math.cos((lng2 - lng1) * p)) / 2;
    return 12742 * math.asin(math.sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ExploreListTheme.background,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: const BoxDecoration(
                color: ExploreListTheme.surface,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderInfo(),
                  _buildVisitorInfo(),
                  _buildDistanceCard(),
                  if (widget.place.videoUrl != null && widget.place.videoUrl!.isNotEmpty)
                    _buildVideoPlayer(),
                  _buildDescription(),
                  if (widget.place.gallery != null && widget.place.gallery!.isNotEmpty)
                    _buildGallery(),
                  _buildActions(),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    final hasGallery = widget.place.gallery != null && widget.place.gallery!.isNotEmpty;

    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.primaryDark,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasGallery)
              PageView.builder(
                itemCount: widget.place.gallery!.length,
                onPageChanged: (index) {
                  setState(() {
                    _currentGalleryIndex = index;
                  });
                },
                itemBuilder: (context, index) {
                  final imgPath = widget.place.gallery![index];
                  return Hero(
                    tag: index == 0 ? 'place_image_${widget.place.name}' : 'place_image_${widget.place.name}_$index',
                    child: imgPath.startsWith('assets/')
                        ? Image.asset(imgPath, fit: BoxFit.cover)
                        : Image.network(imgPath, fit: BoxFit.cover),
                  );
                },
              )
            else
              PlaceNetworkImage(
                place: widget.place,
                fit: BoxFit.cover,
                heroTag: 'place_image_${widget.place.name}',
                maxHeight: 1200,
              ),
            IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            if (hasGallery && widget.place.gallery!.length > 1)
              Positioned(
                bottom: 45,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      widget.place.gallery!.length,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentGalleryIndex == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        FavoriteButton(
          id: widget.place.name,
          category: FavoriteCategory.place,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          size: 24,
        ),
        IconButton(
          icon: const Icon(Icons.share_rounded),
          onPressed: _sharePlace,
        ),
      ],
    );
  }

  Widget _buildHeaderInfo() {
    final double rating = _getRatingForPlace(widget.place);
    final int reviews = _getReviewCountForPlace(widget.place);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  widget.place.tag.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.star_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: ExploreListTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($reviews Yorum)',
                    style: const TextStyle(
                      color: ExploreListTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            widget.place.name,
            style: ExploreListTheme.sectionTitleStyle().copyWith(
              fontSize: 26,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.place.address,
                  style: ExploreListTheme.sectionSubtitleStyle(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sharePlace() {
    final coords = _getCoordsForPlace(widget.place);
    final mapsLink = coords != null
        ? 'https://maps.google.com/?q=${coords.lat},${coords.lng}'
        : 'https://maps.google.com/?q=${Uri.encodeComponent(widget.place.address)}';
    final text = '🗺️ ${widget.place.name}\n'
        '📍 ${widget.place.address}\n\n'
        '${widget.place.shortDescription}\n\n'
        '$mapsLink\n\n'
        'Hepsi Düziçi uygulamasından paylaşıldı.';
    SharePlus.instance.share(ShareParams(text: text, subject: widget.place.name));
  }

  Widget _buildVisitorInfo() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Ziyaret Bilgileri'),
          const SizedBox(height: 4),
          Text(
            'Otopark, WC ve giriş ücreti OpenStreetMap\'ten canlı çekilir; mekânda teyit edin.',
            style: ExploreListTheme.sectionSubtitleStyle().copyWith(fontSize: 11.5),
          ),
          const SizedBox(height: 12),
          DynamicPlaceFacilities(place: widget.place),
        ],
      ),
    );
  }

  Widget _buildDistanceCard() {
    final coords = _getCoordsForPlace(widget.place);
    final double? refLat = widget.userLat ?? (widget.selectedMahalle != null ? _mahalleler[widget.selectedMahalle]!.lat : null);
    final double? refLng = widget.userLng ?? (widget.selectedMahalle != null ? _mahalleler[widget.selectedMahalle]!.lng : null);

    if (coords == null || refLat == null || refLng == null) {
      return const SizedBox.shrink();
    }

    final distance = _calculateDistance(refLat, refLng, coords.lat, coords.lng);
    // Arabayla tahmini süre (Ortalama 45 km/s hız ile dağ/yayla yolları dahil)
    final approxMinutes = (distance / 45 * 60).round();
    final timeStr = approxMinutes < 60 ? '$approxMinutes dakika' : '${approxMinutes ~/ 60} saat ${approxMinutes % 60} dakika';

    final String positionType = widget.userLat != null ? 'GPS Konumunuza' : '${widget.selectedMahalle}\'ne';

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: ExploreListTheme.infoPanelDecoration(),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.directions_car_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ulaşım ve Mesafe Bilgisi',
                    style: ExploreListTheme.sectionTitleStyle().copyWith(fontSize: 13.5),
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      text: '$positionType uzaklığı: ',
                      style: ExploreListTheme.sectionSubtitleStyle().copyWith(fontSize: 12),
                      children: [
                        TextSpan(
                          text: '${distance.toStringAsFixed(1)} km',
                          style: const TextStyle(
                            color: ExploreListTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text.rich(
                    TextSpan(
                      text: 'Tahmini Sürüş Süresi: ',
                      style: ExploreListTheme.sectionSubtitleStyle().copyWith(fontSize: 12),
                      children: [
                        TextSpan(
                          text: timeStr,
                          style: const TextStyle(
                            color: ExploreListTheme.textPrimary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoPlayer() {
    final isYoutube = widget.place.videoUrl != null &&
        (widget.place.videoUrl!.contains('youtube.com') || widget.place.videoUrl!.contains('youtu.be'));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Tanıtım Videosu'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: isYoutube
                ? InkWell(
                    onTap: () => LauncherUtils.openUrlExternal(context, widget.place.videoUrl!),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        _buildYoutubeThumbnail(),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black26,
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: const Icon(
                                  Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.open_in_new_rounded, color: Colors.white, size: 14),
                                SizedBox(width: 6),
                                Text(
                                  'YouTube\'da İzle',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : (_videoPlayerController != null && _isVideoPlayerInitialized
                    ? AspectRatio(
                        aspectRatio: _videoPlayerController!.value.aspectRatio,
                        child: Stack(
                          alignment: Alignment.bottomCenter,
                          children: [
                            VideoPlayer(_videoPlayerController!),
                            _VideoControls(controller: _videoPlayerController!),
                          ],
                        ),
                      )
                    : const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primary),
                        ),
                      )),
          ),
        ],
      ),
    );
  }

  Widget _buildYoutubeThumbnail() {
    final videoId = YoutubePlayer.convertUrlToId(widget.place.videoUrl!);
    if (videoId != null) {
      return Image.network(
        'https://img.youtube.com/vi/$videoId/hqdefault.jpg',
        width: double.infinity,
        height: 200,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            height: 200,
            color: Colors.black87,
            child: const Icon(Icons.video_library_rounded, color: Colors.white54, size: 48),
          );
        },
      );
    }
    return Container(
      width: double.infinity,
      height: 200,
      color: Colors.black87,
      child: const Icon(Icons.video_library_rounded, color: Colors.white54, size: 48),
    );
  }

  Widget _buildDescription() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Mekan Hakkında'),
          const SizedBox(height: 12),
          Text(
            widget.place.detail,
            style: ExploreListTheme.sectionSubtitleStyle().copyWith(
              height: 1.7,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(24, 32, 24, 12),
          child: _SectionTitle(title: 'Fotoğraf Galerisi'),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: widget.place.gallery!.length,
            itemBuilder: (context, index) {
              return Container(
                width: 220,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: ExploreListTheme.border),
                  image: DecorationImage(
                    image: widget.place.gallery![index].startsWith('assets/')
                        ? AssetImage(widget.place.gallery![index]) as ImageProvider
                        : NetworkImage(widget.place.gallery![index]) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActions() {
    final coords = _getCoordsForPlace(widget.place);
    final mapsUrl = PlacePhotoService.mapsUrl(widget.place);

    if (widget.isActiveNavigation) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      side: const BorderSide(color: ExploreListTheme.border),
                      foregroundColor: ExploreListTheme.textPrimary,
                    ),
                    child: const Text('Geri', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // Durağı tamamla ve bir sonraki adıma ilerle
                      TripPlannerProvider.instance.nextStep();
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Harika! Bir sonraki durak aktif edildi 🏁'),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      );
                    },
                    icon: const Icon(Icons.flag_rounded, color: Colors.white),
                    label: const Text('Rotaya Devam'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (coords != null) {
                      LauncherUtils.openMapsWithLatLng(context, coords.lat, coords.lng);
                    } else {
                      LauncherUtils.openMapsDirections(context, widget.place.address);
                    }
                  },
                  icon: const Icon(Icons.directions_car_rounded),
                  label: const Text('Navigasyon'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => LauncherUtils.openUrlExternal(context, mapsUrl),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Haritada Aç'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                    side: const BorderSide(color: ExploreListTheme.border),
                    foregroundColor: ExploreListTheme.textPrimary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: ExploreListTheme.sectionTitleStyle());
  }
}

class _PlaceCoords {
  final double lat;
  final double lng;
  const _PlaceCoords(this.lat, this.lng);
}

class _VideoControls extends StatefulWidget {
  const _VideoControls({required this.controller});
  final VideoPlayerController controller;

  @override
  State<_VideoControls> createState() => _VideoControlsState();
}

class _VideoControlsState extends State<_VideoControls> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          widget.controller.value.isPlaying
              ? widget.controller.pause()
              : widget.controller.play();
        });
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              color: widget.controller.value.isPlaying ? Colors.transparent : Colors.black38,
              child: widget.controller.value.isPlaying
                  ? const SizedBox.shrink()
                  : const Center(
                      child: Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 64,
                      ),
                    ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              widget.controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: AppColors.primary,
                bufferedColor: Colors.white30,
                backgroundColor: Colors.white10,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
