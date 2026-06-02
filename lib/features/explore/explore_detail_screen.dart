import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../data/models/city_content.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/dynamic_place_facilities.dart';
import '../../core/widgets/place_network_image.dart';
import '../../data/services/place_photo_service.dart';
import '../../data/services/favorites_service.dart';
import '../../data/providers/trip_planner_provider.dart';

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
  };

  @override
  void initState() {
    super.initState();
    if (widget.place.videoUrl != null && widget.place.videoUrl!.contains('youtube.com')) {
      final videoId = YoutubePlayer.convertUrlToId(widget.place.videoUrl!);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: false,
            mute: false,
            disableDragSeek: false,
            loop: false,
            isLive: false,
            forceHD: false,
            enableCaption: true,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(
            child: Container(
              transform: Matrix4.translationValues(0, -30, 0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.only(
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
                  if (widget.place.videoUrl != null && _youtubeController != null)
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
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: const Color(0xFF172033),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            PlaceNetworkImage(
              place: widget.place,
              fit: BoxFit.cover,
              heroTag: 'place_image_${widget.place.name}',
              maxHeight: 1200,
            ),
            DecoratedBox(
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
                  const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '($reviews Yorum)',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color?.withValues(alpha: 0.6),
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: Theme.of(context).colorScheme.onSurface,
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
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontWeight: FontWeight.w500,
                      ),
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
            style: TextStyle(
              fontSize: 11.5,
              color: Theme.of(context).textTheme.bodySmall?.color,
              height: 1.35,
            ),
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50.withValues(alpha: 0.9), Colors.teal.shade100.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.teal.shade200.withValues(alpha: 0.5), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.teal.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.teal.shade800,
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
                    style: TextStyle(
                      color: Colors.teal.shade900,
                      fontWeight: FontWeight.w900,
                      fontSize: 13.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      text: '$positionType uzaklığı: ',
                      style: TextStyle(
                        color: Colors.teal.shade900.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: '${distance.toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: Colors.teal.shade900,
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
                      style: TextStyle(
                        color: Colors.teal.shade900.withValues(alpha: 0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      children: [
                        TextSpan(
                          text: timeStr,
                          style: TextStyle(
                            color: Colors.teal.shade900,
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(title: 'Tanıtım Videosu'),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: YoutubePlayer(
              controller: _youtubeController!,
              showVideoProgressIndicator: true,
              progressIndicatorColor: AppColors.primary,
            ),
          ),
        ],
      ),
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
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color,
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
                  image: DecorationImage(
                    image: NetworkImage(widget.place.gallery![index]),
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
                      side: BorderSide(color: Colors.grey.shade400),
                      foregroundColor: Theme.of(context).colorScheme.onSurface,
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
                      backgroundColor: const Color(0xFF4CAF50), // Green
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
            fontSize: 18,
            color: Theme.of(context).colorScheme.onSurface,
          ),
    );
  }
}

class _PlaceCoords {
  final double lat;
  final double lng;
  const _PlaceCoords(this.lat, this.lng);
}
