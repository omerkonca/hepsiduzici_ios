import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../data/services/favorites_service.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({
    super.key,
    required this.id,
    required this.category,
    this.size = 24,
    this.padding = const EdgeInsets.all(8),
  });

  final String id;
  final FavoriteCategory category;
  final double size;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoritesProvider.notifier).isFavorite(category, id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => ref.read(favoritesProvider.notifier).toggle(category, id),
      borderRadius: BorderRadius.circular(999),
      child: Padding(
        padding: padding,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: Icon(
            isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
            key: ValueKey(isFavorite),
            size: size,
            color: isFavorite 
              ? Colors.redAccent 
              : (isDark ? Colors.white70 : Colors.black45),
          ),
        ),
      ),
    );
  }
}
