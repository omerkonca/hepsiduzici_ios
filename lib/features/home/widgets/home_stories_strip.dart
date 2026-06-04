import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_navigation.dart';
import '../../../data/models/city_content.dart';
import 'home_story_viewer.dart';

class HomeStoriesStrip extends ConsumerStatefulWidget {
  const HomeStoriesStrip({super.key});

  @override
  ConsumerState<HomeStoriesStrip> createState() => _HomeStoriesStripState();
}

class _HomeStoriesStripState extends ConsumerState<HomeStoriesStrip> {
  static const String _seenPrefix = 'home_story_seen_';
  final Set<String> _seenStoryIds = <String>{};

  @override
  void initState() {
    super.initState();
    _loadSeenStories();
  }

  Future<void> _loadSeenStories() async {
    final prefs = await SharedPreferences.getInstance();
    final ids = <String>{};
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_seenPrefix)) continue;
      final seen = prefs.getBool(key) ?? false;
      if (seen) ids.add(key.substring(_seenPrefix.length));
    }
    if (!mounted) return;
    setState(() {
      _seenStoryIds
        ..clear()
        ..addAll(ids);
    });
  }

  Future<void> _markSeen(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_seenPrefix$id', true);
    if (!mounted) return;
    setState(() {
      _seenStoryIds.add(id);
    });
  }

  List<HomeStoryGroup> _storyGroups(CityContent content) {
    final active = content.headerMedia.where((m) => m.isActive).toList();
    final list = active.isNotEmpty ? active : content.headerMedia;
    if (list.isEmpty) return const [];
    
    final allItems = list.asMap().entries.map((entry) {
      final i = entry.key;
      final m = entry.value;
      return HomeStoryMedia(
        id: 'story_$i',
        url: m.url,
        type: m.type,
        title: (m.title ?? '').trim().isNotEmpty ? m.title!.trim() : 'Düziçi Hikaye ${i + 1}',
      );
    }).toList();

    final Map<String, List<HomeStoryMedia>> groupsMap = {};
    for (final item in allItems) {
      groupsMap.putIfAbsent(item.title, () => []).add(item);
    }

    return groupsMap.entries.map((e) {
      return HomeStoryGroup(
        title: e.key,
        items: e.value,
      );
    }).toList();
  }

  Future<void> _openViewer(List<HomeStoryMedia> stories, int startIndex) async {
    if (!mounted) return;
    await AppNavigation.push<void>(
      context,
      HomeStoryViewer(
        items: stories,
        startIndex: startIndex,
        onViewed: _markSeen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contentAsync = ref.watch(cityContentProvider);
    return contentAsync.when(
      data: (content) {
        final groups = _storyGroups(content);
        if (groups.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: groups.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, index) {
              final group = groups[index];
              final hasNew = group.items.any((item) => !_seenStoryIds.contains(item.id));
              
              int firstUnseenIndex = group.items.indexWhere((item) => !_seenStoryIds.contains(item.id));
              if (firstUnseenIndex == -1) firstUnseenIndex = 0;
              
              return _StoryBubble(
                storyId: group.id,
                label: group.title,
                imageUrl: group.items.first.url,
                isVideo: group.items.first.isVideo,
                hasNew: hasNew,
                onTap: () => _openViewer(group.items, firstUnseenIndex),
              );
            },
          ),
        );
      },
      loading: () => const SizedBox(height: 96),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class HomeStoryGroup {
  HomeStoryGroup({
    required this.title,
    required this.items,
  });

  final String title;
  final List<HomeStoryMedia> items;

  String get id => 'group_${title.hashCode}';
}

class _StoryBubble extends StatelessWidget {
  const _StoryBubble({
    required this.storyId,
    required this.label,
    required this.imageUrl,
    required this.isVideo,
    required this.hasNew,
    required this.onTap,
  });

  final String storyId;
  final String label;
  final String imageUrl;
  final bool isVideo;
  final bool hasNew;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 68,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Hero(
                  tag: 'home_story_$storyId',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      width: 64,
                      height: 64,
                      padding: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFE3AF4C), Color(0xFFD4941A), Color(0xFFB45309)],
                        ),
                      ),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                        child: ClipOval(
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _StoryThumb(imageUrl: imageUrl),
                              if (isVideo)
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (hasNew)
                  Positioned(
                    top: 2,
                    right: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).colorScheme.surface,
                          width: 1.2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StoryThumb extends StatelessWidget {
  const _StoryThumb({required this.imageUrl});
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (!imageUrl.startsWith('http')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _fallback(),
      );
    }
    if (imageUrl.contains('youtube.com') || imageUrl.contains('youtu.be')) {
      final id = YoutubePlayer.convertUrlToId(imageUrl);
      if (id != null && id.isNotEmpty) {
        return CachedNetworkImage(
          imageUrl: 'https://img.youtube.com/vi/$id/hqdefault.jpg',
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => _fallback(),
        );
      }
    }
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => _fallback(),
    );
  }

  Widget _fallback() => const ColoredBox(
        color: Color(0xFFE9ECEF),
        child: Center(
          child: Icon(Icons.image_rounded, color: AppColors.primaryDark, size: 20),
        ),
      );
}
