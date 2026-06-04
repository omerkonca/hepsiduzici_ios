import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

class HomeStoryMedia {
  const HomeStoryMedia({
    required this.id,
    required this.url,
    required this.type,
    required this.title,
  });

  final String id;
  final String url;
  final String type;
  final String title;

  bool get isVideo => type.toLowerCase() == 'video';
}

class HomeStoryViewer extends StatefulWidget {
  const HomeStoryViewer({
    super.key,
    required this.items,
    required this.startIndex,
    required this.onViewed,
  });

  final List<HomeStoryMedia> items;
  final int startIndex;
  final ValueChanged<String> onViewed;

  @override
  State<HomeStoryViewer> createState() => _HomeStoryViewerState();
}

class _HomeStoryViewerState extends State<HomeStoryViewer> {
  late final PageController _pageController;
  late int _index;
  double _activeProgress = 0;

  @override
  void initState() {
    super.initState();
    _index = widget.startIndex.clamp(0, widget.items.length - 1);
    _pageController = PageController(initialPage: _index);
    widget.onViewed(widget.items[_index].id);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (!mounted) return;
    if (_index >= widget.items.length - 1) {
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  void _goPrev() {
    if (!mounted || _index <= 0) return;
    _pageController.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.items.length,
              onPageChanged: (value) {
                setState(() {
                  _index = value;
                  _activeProgress = 0;
                });
                widget.onViewed(widget.items[value].id);
              },
              itemBuilder: (context, i) {
                final item = widget.items[i];
                return _StoryPageMedia(
                  key: ValueKey('${item.id}_$i'),
                  item: item,
                  isActive: i == _index,
                  onProgress: (p) {
                    if (!mounted || i != _index) return;
                    setState(() {
                      _activeProgress = p.clamp(0, 1);
                    });
                  },
                  onComplete: () {
                    if (i == _index) _goNext();
                  },
                );
              },
            ),
            Positioned(
              top: 10,
              left: 10,
              right: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
                    ),
                    child: Row(
                      children: List.generate(widget.items.length, (i) {
                        final value = i < _index ? 1.0 : (i == _index ? _activeProgress : 0.0);
                        return Expanded(
                          child: Container(
                            height: 3,
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: value,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 22,
              left: 12,
              right: 12,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.items[_index].title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                  ),
                ],
              ),
            ),
            Positioned.fill(
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goPrev,
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: _goNext,
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
}

class _StoryPageMedia extends StatefulWidget {
  const _StoryPageMedia({
    super.key,
    required this.item,
    required this.isActive,
    required this.onProgress,
    required this.onComplete,
  });

  final HomeStoryMedia item;
  final bool isActive;
  final ValueChanged<double> onProgress;
  final VoidCallback onComplete;

  @override
  State<_StoryPageMedia> createState() => _StoryPageMediaState();
}

class _StoryPageMediaState extends State<_StoryPageMedia> with SingleTickerProviderStateMixin {
  AnimationController? _imageProgress;
  Timer? _videoPoll;
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(covariant _StoryPageMedia oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive || oldWidget.item.url != widget.item.url) {
      _disposePlayers();
      _setup();
    }
  }

  void _setup() {
    if (!widget.isActive) return;
    if (!widget.item.isVideo) {
      _imageProgress = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 6),
      )
        ..addListener(() {
          widget.onProgress(_imageProgress!.value);
        })
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) _emitComplete();
        })
        ..forward();
      return;
    }

    if (_isYoutube(widget.item.url)) {
      final id = YoutubePlayer.convertUrlToId(widget.item.url);
      if (id == null) return;
      _youtubeController = YoutubePlayerController(
        initialVideoId: id,
        flags: const YoutubePlayerFlags(
          autoPlay: true,
          mute: false,
          hideControls: true,
          disableDragSeek: true,
          loop: false,
        ),
      );
      _youtubeController!.addListener(() {
        final value = _youtubeController!.value;
        final total = value.metaData.duration.inMilliseconds;
        final pos = value.position.inMilliseconds;
        if (total > 0) widget.onProgress((pos / total).clamp(0, 1));
        if (value.playerState == PlayerState.ended) _emitComplete();
      });
      return;
    }

    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.item.url))
      ..initialize().then((_) {
        if (!mounted || !widget.isActive) return;
        _videoController!.play();
        _videoPoll = Timer.periodic(const Duration(milliseconds: 120), (_) {
          final c = _videoController;
          if (c == null || !c.value.isInitialized) return;
          final total = c.value.duration.inMilliseconds;
          final pos = c.value.position.inMilliseconds;
          if (total > 0) widget.onProgress((pos / total).clamp(0, 1));
          if (pos >= total && total > 0) _emitComplete();
        });
        setState(() {});
      });
  }

  bool _isYoutube(String url) => url.contains('youtube.com') || url.contains('youtu.be');

  void _emitComplete() {
    if (_completed) return;
    _completed = true;
    widget.onComplete();
  }

  void _disposePlayers() {
    _completed = false;
    _imageProgress?.dispose();
    _imageProgress = null;
    _videoPoll?.cancel();
    _videoPoll = null;
    _videoController?.dispose();
    _videoController = null;
    _youtubeController?.dispose();
    _youtubeController = null;
  }

  @override
  void dispose() {
    _disposePlayers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget withHero(Widget child) {
      return Hero(
        tag: 'home_story_${widget.item.id}',
        child: Material(
          color: Colors.transparent,
          child: child,
        ),
      );
    }

    if (widget.item.isVideo) {
      if (_youtubeController != null) {
        return withHero(Center(
          child: YoutubePlayer(
            controller: _youtubeController!,
            showVideoProgressIndicator: false,
          ),
        ));
      }
      if (_videoController != null && _videoController!.value.isInitialized) {
        return withHero(SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ));
      }
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    final isAsset = !widget.item.url.startsWith('http');
    if (isAsset) {
      return withHero(
        Image.asset(
          widget.item.url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    return withHero(
      CachedNetworkImage(
        imageUrl: widget.item.url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (_, __) =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        errorWidget: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image_rounded, color: Colors.white)),
      ),
    );
  }
}

