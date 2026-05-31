import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/primary_card.dart';
import '../../data/models/news_item.dart';
import '../../data/models/event_item.dart';
import '../../data/models/city_content.dart';
import '../../data/services/favorites_service.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/utils/icon_mapper.dart';
import '../../core/utils/target_router.dart';
import '../news/news_detail_screen.dart';
import '../events/event_detail_screen.dart';
import '../explore/explore_detail_screen.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final hasAnyFav = favorites.values.any((s) => s.isNotEmpty);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorilerim', style: TextStyle(fontWeight: FontWeight.w900)),
        centerTitle: true,
      ),
      body: !hasAnyFav ? const _EmptyFavorites() : _FavoritesList(favorites: favorites),
    );
  }
}

class _FavoritesList extends ConsumerWidget {
  const _FavoritesList({required this.favorites});
  final Map<FavoriteCategory, Set<String>> favorites;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 20),
      children: [
        _CategorySection(
          category: FavoriteCategory.news,
          ids: favorites[FavoriteCategory.news] ?? {},
        ),
        _CategorySection(
          category: FavoriteCategory.event,
          ids: favorites[FavoriteCategory.event] ?? {},
        ),
        _CategorySection(
          category: FavoriteCategory.pharmacy,
          ids: favorites[FavoriteCategory.pharmacy] ?? {},
        ),
        _CategorySection(
          category: FavoriteCategory.place,
          ids: favorites[FavoriteCategory.place] ?? {},
        ),
        _CategorySection(
          category: FavoriteCategory.service,
          ids: favorites[FavoriteCategory.service] ?? {},
        ),
      ],
    );
  }
}

class _CategorySection extends ConsumerWidget {
  const _CategorySection({required this.category, required this.ids});
  final FavoriteCategory category;
  final Set<String> ids;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ids.isEmpty) return const SizedBox.shrink();

    final title = switch (category) {
      FavoriteCategory.news => 'Haberler',
      FavoriteCategory.event => 'Etkinlikler',
      FavoriteCategory.pharmacy => 'Eczaneler',
      FavoriteCategory.place => 'Mekanlar',
      FavoriteCategory.service => 'Hizmetler',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
        ),
        ...ids.map((id) => _FavoriteTile(id: id, category: category)),
        const SizedBox(height: 24),
      ],
    );
  }
}

class _FavoriteTile extends ConsumerWidget {
  const _FavoriteTile({required this.id, required this.category});
  final String id;
  final FavoriteCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (category) {
      FavoriteCategory.news => _NewsFavTile(id: id),
      FavoriteCategory.event => _EventFavTile(id: id),
      FavoriteCategory.pharmacy => _PharmacyFavTile(name: id),
      FavoriteCategory.place => _PlaceFavTile(id: id),
      FavoriteCategory.service => _ServiceFavTile(id: id),
    };
  }
}

class _NewsFavTile extends ConsumerWidget {
  const _NewsFavTile({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final newsAsync = ref.watch(newsListProvider);
    return newsAsync.when(
      data: (list) {
        final item = list.firstWhere((n) => n.id == id, orElse: () => NewsItem(id: id, title: 'Yükleniyor...', createdAt: DateTime.now()));
        return PrimaryCard(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item))),
          child: ListTile(
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            trailing: FavoriteButton(id: id, category: FavoriteCategory.news),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EventFavTile extends ConsumerWidget {
  const _EventFavTile({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventListProvider);
    return eventsAsync.when(
      data: (list) {
        final item = list.firstWhere((e) => e.id == id, orElse: () => EventItem(id: id, title: 'Yükleniyor...', location: '', date: DateTime.now(), imageUrl: '', link: '', category: '', city: '', district: '', price: ''));
        return PrimaryCard(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: item))),
          child: ListTile(
            title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text(item.location),
            trailing: FavoriteButton(id: id, category: FavoriteCategory.event),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _PharmacyFavTile extends ConsumerWidget {
  const _PharmacyFavTile({required this.name});
  final String name;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PrimaryCard(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: ListTile(
        leading: const Icon(Icons.local_pharmacy, color: Color(0xFF009688)),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
        trailing: FavoriteButton(id: name, category: FavoriteCategory.pharmacy),
      ),
    );
  }
}

class _PlaceFavTile extends ConsumerWidget {
  const _PlaceFavTile({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(cityContentProvider);
    return contentAsync.when(
      data: (content) {
        final place = content.exploreCategories
            .expand((c) => c.places)
            .firstWhere(
              (p) => p.name == id,
              orElse: () => ExplorePlace(
                name: id,
                shortDescription: 'Yükleniyor...',
                detail: '',
                address: '',
                tag: 'Mekan',
              ),
            );

        final imageUrl = place.imageUrl?.trim();

        return PrimaryCard(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: EdgeInsets.zero,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExploreDetailScreen(place: place)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                          child: const Icon(Icons.image_not_supported, size: 20),
                        ),
                      )
                    : Container(
                        color: Theme.of(context).disabledColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.place_rounded, size: 20),
                      ),
              ),
            ),
            title: Text(
              place.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(
              place.shortDescription,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
            trailing: FavoriteButton(id: id, category: FavoriteCategory.place, size: 20),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ServiceFavTile extends ConsumerWidget {
  const _ServiceFavTile({required this.id});
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(cityContentProvider);
    return contentAsync.when(
      data: (content) {
        final service = content.cityServices.firstWhere(
          (s) => s.id == id,
          orElse: () {
            final tile = content.serviceTiles.firstWhere(
              (t) => t.id == id,
              orElse: () => ServiceTileItem(id: id, icon: 'grid_view_rounded', title: 'Hizmet', subtitle: '', target: ''),
            );
            return CityServiceItem(
              id: tile.id,
              icon: tile.icon,
              title: tile.title,
              subtitle: tile.subtitle,
              color: '#009688',
              target: tile.target,
            );
          },
        );

        final color = _parseColor(service.color);

        return PrimaryCard(
          margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          padding: EdgeInsets.zero,
          onTap: () => TargetRouter.handle(context, service.target),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconMapper.fromName(service.icon),
                color: color,
                size: 22,
              ),
            ),
            title: Text(
              service.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: service.subtitle.isNotEmpty
                ? Text(
                    service.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                      fontSize: 12,
                    ),
                  )
                : null,
            trailing: FavoriteButton(id: id, category: FavoriteCategory.service, size: 20),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Color _parseColor(String hex) {
    if (hex.isEmpty) return AppColors.primary;
    try {
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return AppColors.primary;
    }
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 24),
          const Text(
            'Henüz favoriniz yok',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Beğendiğiniz haberleri, etkinlikleri ve mekanları favorilerinize ekleyerek burada görebilirsiniz.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
