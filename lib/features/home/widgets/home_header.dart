import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/target_router.dart';
import '../../../core/utils/weather_wmo_tr.dart';
import '../../../data/models/city_content.dart';

class HomeHeader extends ConsumerStatefulWidget {
  const HomeHeader({super.key, this.imagesOnly = false});

  /// Video oynatıcıyı kapatır; yalnızca görseller döner (Keşfet için).
  final bool imagesOnly;

  @override
  ConsumerState<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends ConsumerState<HomeHeader> {
  Timer? _timer;
  int _currentIndex = 0;
  bool _isAutoPlaying = true;


  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_isAutoPlaying) return;

    final content = ref.read(cityContentProvider).value;
    if (content == null) return;

    final mediaItems = _mediaItems(content);
    if (mediaItems.isEmpty) return;

    final currentMedia = mediaItems[_currentIndex % mediaItems.length];
    
    final duration = currentMedia.type == 'video' 
        ? const Duration(seconds: 40) 
        : const Duration(seconds: 12);

    _timer = Timer(duration, () => _navigate(1));
  }

  List<HeaderMediaItem> _mediaItems(CityContent content) {
    final active = content.headerMedia.where((m) => m.isActive).toList();
    final items = active.isNotEmpty ? active : content.headerMedia;
    if (!widget.imagesOnly) return items;
    return items.where((m) => m.type != 'video').toList();
  }

  void _navigate(int delta) {
    if (!mounted) return;
    final content = ref.read(cityContentProvider).value;
    if (content == null) return;

    final mediaItems = _mediaItems(content);
    if (mediaItems.isEmpty) return;

    setState(() {
      _currentIndex = (_currentIndex + delta) % mediaItems.length;
      if (_currentIndex < 0) _currentIndex = mediaItems.length - 1;
    });
    _startTimer();
  }

  void _onManualNavigate(int index) {
    final content = ref.read(cityContentProvider).value;
    if (content == null) return;

    final mediaItems = _mediaItems(content);
    if (mediaItems.isEmpty) return;

    setState(() {
      _isAutoPlaying = false;
      _currentIndex = index;
    });
    _timer?.cancel();
    
    // Resume auto-play after 60s
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        setState(() => _isAutoPlaying = true);
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cityContentAsync = ref.watch(cityContentProvider);
    final weatherAsync = ref.watch(weatherProvider);

    return cityContentAsync.when(
      data: (content) {
        var mediaItems = _mediaItems(content);
        if (mediaItems.isEmpty) {
          mediaItems = [
            const HeaderMediaItem(
              url: 'assets/images/duzici_castle_header.png',
              type: 'image',
              isActive: true,
            ),
          ];
        }

        final safeIndex = _currentIndex.clamp(0, mediaItems.length - 1);
        if (safeIndex != _currentIndex) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _currentIndex = safeIndex);
          });
        }

        if (_timer == null && _isAutoPlaying) _startTimer();

        final currentMedia = mediaItems[safeIndex];

        return SizedBox(
          height: 360,
          width: double.infinity,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // 0. Background layer to fill clipped corners
              Positioned.fill(
                child: Container(color: Theme.of(context).colorScheme.surface),
              ),
              // 1. Extreme Optimized Media Layer (Single Item + Cross-fade)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(48),
                    bottomRight: Radius.circular(48),
                  ),
                  child: Container(
                    color: AppColors.background,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 1000),
                      switchInCurve: Curves.easeIn,
                      switchOutCurve: Curves.easeOut,
                      layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
                        return Stack(
                          fit: StackFit.expand,
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      child: KeyedSubtree(
                        key: ValueKey('media_$safeIndex'),
                        child: _MediaItem(
                          item: currentMedia,
                          onVideoEnded: () => _isAutoPlaying ? _navigate(1) : null,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // 2. Persistent Overlays (Performance: These don't rebuild on media change)
              IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(48),
                      bottomRight: Radius.circular(48),
                    ),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.4, 1.0],
                      colors: [
                        Colors.black.withValues(alpha: 0.35),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                ),
              ),

              // 3. Navigation Areas
              if (mediaItems.length > 1) ...[
                Positioned(
                  left: 0,
                  top: 100,
                  bottom: 100,
                  width: 80,
                  child: GestureDetector(onTap: () => _navigate(-1)),
                ),
                Positioned(
                  right: 40,
                  top: 100,
                  bottom: 100,
                  width: 80,
                  child: GestureDetector(onTap: () => _navigate(1)),
                ),
              ],

              // 4. Indicators
              if (mediaItems.length > 1)
                Positioned(
                  top: 130,
                  right: 20,
                  child: Column(
                    children: List.generate(mediaItems.length, (i) {
                      final isActive = i == _currentIndex;
                      return GestureDetector(
                        onTap: () => _onManualNavigate(i),
                        behavior: HitTestBehavior.opaque,
                        child: AnimatedContainer(
                          duration: 300.ms,
                          margin: const EdgeInsets.only(bottom: 8),
                          width: 14,
                          height: isActive ? 32 : 12,
                          alignment: Alignment.center,
                          child: Container(
                            width: 5,
                            height: isActive ? 32 : 8,
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.primary : Colors.white.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

              _HeaderOverlayContent(weatherAsync: weatherAsync),
              const _FloatingSearchBar(),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 360),
      error: (e, _) => const SizedBox(height: 360),
    );
  }
}

class _MediaItem extends StatefulWidget {
  const _MediaItem({required this.item, this.onVideoEnded});
  final HeaderMediaItem item;
  final VoidCallback? onVideoEnded;

  @override
  State<_MediaItem> createState() => _MediaItemState();
}

class _MediaItemState extends State<_MediaItem> {
  YoutubePlayerController? _youtubeController;
  VideoPlayerController? _fileController;
  bool _isPlayerReady = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  void _init() {
    if (widget.item.type == 'video') {
      final isYoutube = widget.item.url.contains('youtube.com') || widget.item.url.contains('youtu.be');
      if (isYoutube) {
        _initYoutube();
      } else {
        _initFileVideo();
      }
    }
  }

  void _initYoutube() {
    final id = YoutubePlayer.convertUrlToId(widget.item.url);
    if (id != null) {
      _youtubeController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: true,
          loop: false,
          hideControls: true,
          disableDragSeek: true,
          useHybridComposition: false, // Performance: standard texture usually faster for BG
        ),
      );
      _youtubeController!.addListener(() {
        if (_youtubeController!.value.playerState == PlayerState.ended) {
          widget.onVideoEnded?.call();
        }
      });
    }
  }

  void _initFileVideo() {
    _fileController = VideoPlayerController.networkUrl(
      Uri.parse(widget.item.url),
      videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
    )..initialize().then((_) {
        if (mounted) {
          setState(() => _isPlayerReady = true);
          _fileController?.setVolume(0);
          _fileController?.setLooping(false);
          _fileController?.play();
          _fileController?.addListener(() {
            if (_fileController!.value.position >= _fileController!.value.duration) {
              widget.onVideoEnded?.call();
            }
          });
        }
      });
  }

  @override
  void dispose() {
    _youtubeController?.dispose();
    _fileController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.item.type == 'video') {
      if (_youtubeController != null) {
        return IgnorePointer(
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: false,
            onReady: () => setState(() => _isPlayerReady = true),
          ),
        );
      } else if (_fileController != null) {
        return _isPlayerReady
            ? SizedBox.expand(
                child: FittedBox(
                  fit: BoxFit.cover,
                  child: SizedBox(
                    width: _fileController!.value.size.width,
                    height: _fileController!.value.size.height,
                    child: VideoPlayer(_fileController!),
                  ),
                ),
              )
            : const Center(child: CircularProgressIndicator(strokeWidth: 2));
      }
    }

    final isAsset = !widget.item.url.startsWith('http');
    if (isAsset) {
      return Image.asset(widget.item.url, fit: BoxFit.cover, cacheWidth: 1080);
    }

    return CachedNetworkImage(
      imageUrl: widget.item.url,
      fit: BoxFit.cover,
      memCacheWidth: 1080,
      placeholder: (context, url) => Container(color: Colors.black12),
      errorWidget: (context, url, error) => const Icon(Icons.error),
    );
  }
}

class _HeaderOverlayContent extends StatelessWidget {
  const _HeaderOverlayContent({required this.weatherAsync});
  final AsyncValue weatherAsync;

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, topPadding + 12, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _LiveBadge(),
              weatherAsync.when(
                data: (dynamic w) => _GlassWeatherChip(
                  temp: w.temperature,
                  condition: w.conditionCode,
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
          const Spacer(),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hepsi Düziçi',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.8,
                  height: 1,
                  shadows: [
                    Shadow(color: Colors.black45, offset: Offset(0, 4), blurRadius: 12),
                  ],
                ),
              ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 10),
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 3,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'AKDENİZ\'İN İNCİSİ DÜZİÇİ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
          const SizedBox(height: 75),
        ],
      ),
    );
  }
}

class _FloatingSearchBar extends ConsumerWidget {
  const _FloatingSearchBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Positioned(
      bottom: -28,
      left: 24,
      right: 24,
      child: Hero(
        tag: 'main_search',
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.black.withValues(alpha: 0.3) 
                    : Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: Material(
            type: MaterialType.transparency,
            child: Row(
              children: [
                const Icon(Icons.search_rounded, color: AppColors.primary, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    readOnly: true,
                    onTap: () => TargetRouter.handle(context, 'screen:search'),
                    decoration: const InputDecoration(
                      hintText: 'Haber, etkinlik veya hizmet ara...',
                      hintStyle: TextStyle(
                        color: Color(0xFF8E99AF),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.mic_none_rounded, color: AppColors.primary, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Color(0xFF4CAF50),
              shape: BoxShape.circle,
            ),
          ).animate(onPlay: (c) => c.repeat()).scale(
                duration: 1000.ms,
                begin: const Offset(1, 1),
                end: const Offset(1.4, 1.4),
              ).fadeOut(),
          const SizedBox(width: 8),
          const Text(
            'CANLI AKIŞ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassWeatherChip extends StatelessWidget {
  const _GlassWeatherChip({required this.temp, required this.condition});
  final double temp;
  final int condition;

  @override
  Widget build(BuildContext context) {
    final theme = weatherVisualTheme(condition);
    return GestureDetector(
      onTap: () => TargetRouter.handle(context, 'screen:weather'),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: theme.gradientStart.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.accent.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                WeatherAnimatedIcon(
                  conditionCode: condition,
                  isDay: DateTime.now().hour > 6 && DateTime.now().hour < 19,
                  size: 20,
                  color: theme.accent,
                ),
                const SizedBox(width: 8),
                Text(
                  '${temp.round()}°',
                  style: TextStyle(
                    color: theme.accent,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
