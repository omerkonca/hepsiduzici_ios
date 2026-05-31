import 'package:shared_preferences/shared_preferences.dart';

enum FavoriteCategory {
  news('fav_news'),
  event('fav_events'),
  pharmacy('fav_pharmacies'),
  place('fav_places'),
  service('fav_services');

  final String key;
  const FavoriteCategory(this.key);
}

class FavoritesService {
  Future<Set<String>> getFavorites(FavoriteCategory category) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(category.key) ?? [];
    return list.toSet();
  }

  Future<void> toggleFavorite(FavoriteCategory category, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(category.key)?.toSet() ?? {};
    
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    
    await prefs.setStringList(category.key, current.toList());
  }

  Future<bool> isFavorite(FavoriteCategory category, String id) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(category.key) ?? [];
    return current.contains(id);
  }

  Future<Map<FavoriteCategory, Set<String>>> getAllFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final result = <FavoriteCategory, Set<String>>{};
    
    for (final category in FavoriteCategory.values) {
      result[category] = (prefs.getStringList(category.key) ?? []).toSet();
    }
    
    return result;
  }
}
