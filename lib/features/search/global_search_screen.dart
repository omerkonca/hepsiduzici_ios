import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/target_router.dart';
import '../news/news_detail_screen.dart';
import '../events/event_detail_screen.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final TextEditingController _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final newsAsync = ref.watch(newsListProvider);
    final eventsAsync = ref.watch(eventListProvider);
    final cityContentAsync = ref.watch(cityContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Haber, etkinlik veya hizmet ara...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _controller.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
          onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
        ),
      ),
      body: _query.isEmpty
          ? const _SearchPlaceHolder()
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                children: [
                  // Services Section
                  cityContentAsync.when(
                    data: (content) {
                      final filtered = content.cityServices
                          .where((s) => s.title.toLowerCase().contains(_query))
                          .toList();
                      return _SearchSection(
                        title: 'Hizmetler',
                        isEmpty: filtered.isEmpty,
                        children: filtered.map((s) => _SearchResultTile(
                          icon: IconMapper.fromName(s.icon),
                          title: s.title,
                          subtitle: s.subtitle,
                          onTap: () => TargetRouter.handle(context, s.target),
                        )).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // News Section
                  newsAsync.when(
                    data: (news) {
                      final filtered = news
                          .where((n) => n.title.toLowerCase().contains(_query))
                          .toList();
                      return _SearchSection(
                        title: 'Haberler',
                        isEmpty: filtered.isEmpty,
                        children: filtered.map((n) => _SearchResultTile(
                          icon: Icons.article_outlined,
                          title: n.title,
                          subtitle: n.sourceName ?? 'Haber',
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(item: n))),
                        )).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Events Section
                  eventsAsync.when(
                    data: (events) {
                      final filtered = events
                          .where((e) => e.title.toLowerCase().contains(_query))
                          .toList();
                      return _SearchSection(
                        title: 'Etkinlikler',
                        isEmpty: filtered.isEmpty,
                        children: filtered.map((e) => _SearchResultTile(
                          icon: Icons.event_outlined,
                          title: e.title,
                          subtitle: e.location,
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: e))),
                        )).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Veterinarians
                  cityContentAsync.when(
                    data: (content) {
                      final filtered = content.veterinarians
                          .where((v) =>
                              v.name.toLowerCase().contains(_query) ||
                              v.address.toLowerCase().contains(_query) ||
                              v.type.toLowerCase().contains(_query))
                          .toList();
                      return _SearchSection(
                        title: 'Veteriner',
                        isEmpty: filtered.isEmpty,
                        children: [
                          if (filtered.isNotEmpty)
                            _SearchResultTile(
                              icon: Icons.pets_rounded,
                              title: 'Tüm veteriner listesi',
                              subtitle: '${filtered.length} eşleşme',
                              onTap: () => TargetRouter.handle(context, 'screen:veterinary'),
                            ),
                          ...filtered.take(5).map((v) => _SearchResultTile(
                                icon: Icons.medical_services_outlined,
                                title: v.name,
                                subtitle: v.address,
                                onTap: () => TargetRouter.handle(context, 'screen:veterinary'),
                              )),
                        ],
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),

                  // Places Section (Explore)
                  cityContentAsync.when(
                    data: (content) {
                      final filtered = content.exploreCategories
                          .expand((c) => c.places)
                          .where((p) => p.name.toLowerCase().contains(_query))
                          .toList();
                      return _SearchSection(
                        title: 'Mekanlar',
                        isEmpty: filtered.isEmpty,
                        children: filtered.map((p) => _SearchResultTile(
                          icon: Icons.place_outlined,
                          title: p.name,
                          subtitle: p.shortDescription,
                          onTap: () {}, // Detail logic for places if needed
                        )).toList(),
                      );
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SearchSection extends StatelessWidget {
  const _SearchSection({required this.title, required this.isEmpty, required this.children});
  final String title;
  final bool isEmpty;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: AppColors.primary,
              letterSpacing: 1,
            ),
          ),
        ),
        ...children,
        const Divider(indent: 20, endIndent: 20, height: 24),
      ],
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  const _SearchResultTile({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.grey[600], size: 20),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: onTap,
    );
  }
}

class _SearchPlaceHolder extends StatelessWidget {
  const _SearchPlaceHolder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_rounded, size: 80, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Text(
            'Keşfetmeye başla',
            style: TextStyle(color: Colors.grey[400], fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
