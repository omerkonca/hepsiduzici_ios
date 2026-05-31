import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../data/models/city_content.dart';
import '../../data/providers/trip_planner_provider.dart';
import 'explore_detail_screen.dart';

class TripPlannerScreen extends StatefulWidget {
  const TripPlannerScreen({super.key});

  @override
  State<TripPlannerScreen> createState() => _TripPlannerScreenState();
}

class _TripPlannerScreenState extends State<TripPlannerScreen> {
  final _planner = TripPlannerProvider.instance;

  @override
  void initState() {
    super.initState();
    _planner.addListener(_rebuild);
  }

  @override
  void dispose() {
    _planner.removeListener(_rebuild);
    super.dispose();
  }

  void _rebuild() => setState(() {});

  void _openRoute() {
    final url = _planner.osmVisualizationUrl();
    LauncherUtils.openUrlExternal(context, url);
  }

  @override
  Widget build(BuildContext context) {
    final places = _planner.places;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Gezi Planım'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (places.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Tümünü temizle',
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => AlertDialog(
                    title: const Text('Rotayı Temizle'),
                    content: const Text('Tüm duraklar silinecek. Onaylıyor musunuz?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () {
                          _planner.clear();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Temizle',
                          style: TextStyle(color: theme.colorScheme.error),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: places.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                _buildSummaryBar(places),
                Expanded(child: _buildList(places)),
                _buildBottomBar(),
              ],
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 80, color: AppColors.primary.withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            const Text(
              'Rotanız boş',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Gezi Rehberi\'ndeki mekânların yanındaki + butonuna basarak rotanıza ekleyin.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Mekânları Keşfet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryBar(List<ExplorePlace> places) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.route, color: AppColors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${places.length} durak — ${places.map((p) => p.name.split(' ').first).join(' → ')}',
              style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<ExplorePlace> places) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      itemCount: places.length,
      onReorder: _planner.reorder,
      proxyDecorator: (child, index, animation) => Material(
        elevation: 4,
        borderRadius: BorderRadius.circular(14),
        child: child,
      ),
      itemBuilder: (context, i) {
        final place = places[i];
        return _PlaceCard(
          key: ValueKey(place.name),
          index: i,
          total: places.length,
          place: place,
          onRemove: () => _planner.remove(place),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ExploreDetailScreen(place: place)),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _openRoute,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 2,
            ),
            icon: const Icon(Icons.directions, size: 22),
            label: const Text(
              'Rotayı OpenStreetMap\'te Aç',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaceCard extends StatelessWidget {
  const _PlaceCard({
    required super.key,
    required this.index,
    required this.total,
    required this.place,
    required this.onRemove,
    required this.onTap,
  });

  final int index;
  final int total;
  final ExplorePlace place;
  final VoidCallback onRemove;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Durak numarası
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(place.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    if (place.address.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        place.address,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (place.tag.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          place.tag,
                          style: TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Sürükle tutacağı
              const Icon(Icons.drag_handle, color: Colors.grey, size: 20),
              const SizedBox(width: 4),
              // Kaldır
              IconButton(
                onPressed: onRemove,
                icon: Icon(Icons.remove_circle_outline, color: theme.colorScheme.error, size: 20),
                tooltip: 'Rotadan çıkar',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
