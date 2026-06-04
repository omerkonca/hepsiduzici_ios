import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/ui_tokens.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/skeleton_shimmer.dart';
import '../../data/models/event_item.dart';
import 'event_detail_screen.dart';
import 'my_calendar_screen.dart';
import '../../core/widgets/favorite_button.dart';
import '../../data/services/favorites_service.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime _selectedDate = DateTime.now();
  String _selectedCity = 'Tümü';
  String _selectedDistrict = 'Tümü';
  String _selectedCategory = 'Tümü';

  final List<String> _cities = ['Tümü', 'Osmaniye', 'Adana', 'Hatay', 'Gaziantep', 'Kahramanmaraş'];
  final Map<String, List<String>> _districts = {
    'Tümü': ['Tümü'],
    'Osmaniye': ['Tümü', 'Düziçi', 'Merkez', 'Kadirli', 'Bahçe'],
    'Adana': ['Tümü', 'Seyhan', 'Çukurova', 'Yüreğir', 'Sarıçam'],
    'Hatay': ['Tümü', 'Antakya', 'İskenderun', 'Defne', 'Kırıkhan'],
    'Gaziantep': ['Tümü', 'Şahinbey', 'Şehitkamil', 'Nizip'],
    'Kahramanmaraş': ['Tümü', 'Onikişubat', 'Dulkadiroğlu', 'Elbistan'],
  };

  final List<String> _categories = ['Tümü', 'Konser', 'Tiyatro', 'Festival', 'Spor', 'Kültür & Sanat'];

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventListProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(stampedEventsProvider);
          await Future.delayed(const Duration(milliseconds: 500));
        },
        color: AppColors.primaryDark,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Etkinlik Takvimi',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    color: Theme.of(context).colorScheme.onSurface,
                                    letterSpacing: -1.0,
                                  ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _selectedCity == 'Tümü' 
                                ? 'Bölgedeki en iyi anları yakala.' 
                                : '$_selectedCity\'deki en iyi anları yakala.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surface,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.045),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.16)),
                          ),
                          child: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.onSurface),
                        ),
                      ],
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: 0.1, end: 0),
            ),

            SliverToBoxAdapter(
              child: Container(
                height: 100,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 31,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedDate.year == 1970;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = DateTime(1970)),
                        child: _buildCalendarItem(
                          label: 'Genel',
                          day: 'Tümü',
                          isSelected: isSelected,
                        ),
                      );
                    }

                    final date = DateTime.now().add(Duration(days: index - 1));
                    final isSelected = _selectedDate.day == date.day &&
                        _selectedDate.month == date.month &&
                        _selectedDate.year == date.year;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: _buildCalendarItem(
                        label: DateFormat('E', 'tr_TR').format(date).toUpperCase(),
                        day: date.day.toString(),
                        isSelected: isSelected,
                      ),
                    );
                  },
                ),
              ).animate().fadeIn(delay: 100.ms),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  children: [
                    _QuickActionButton(
                      icon: Icons.favorite_rounded,
                      label: 'Favoriler',
                      color: const Color(0xFFFFF0F0),
                      iconColor: const Color(0xFFE74C3C),
                      onTap: () =>
                          AppNavigation.push<void>(context, const MyCalendarScreen()),
                    ),
                    const SizedBox(width: 12),
                    _QuickActionButton(
                      icon: Icons.calendar_today_rounded,
                      label: 'Takvimim',
                      color: const Color(0xFFF0F7FF),
                      iconColor: const Color(0xFF3498DB),
                      onTap: () =>
                          AppNavigation.push<void>(context, const MyCalendarScreen()),
                    ),
                    const SizedBox(width: 12),
                    _QuickActionButton(
                      icon: Icons.notifications_active_rounded,
                      label: 'Alarmlar',
                      color: const Color(0xFFFFF8E1),
                      iconColor: const Color(0xFFF1C40F),
                      onTap: () =>
                          AppNavigation.push<void>(context, const MyCalendarScreen()),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _DropdownFilter(
                        label: 'Konum',
                        value: '$_selectedCity, $_selectedDistrict',
                        icon: Icons.location_on_rounded,
                        onTap: () => _showLocationPicker(),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _DropdownFilter(
                        label: 'Kategori',
                        value: _selectedCategory,
                        icon: Icons.grid_view_rounded,
                        onTap: () => _showCategoryPicker(),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms),
            ),

            eventsAsync.when(
              data: (list) {
                final filtered = _filterEvents(list);
                final upcoming = _getUpcomingEvents(list);
                
                return SliverMainAxisGroup(
                  slivers: [
                    if (filtered.isNotEmpty)
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = filtered[index];
                            return _EventCard(
                              item: item,
                              onTap: () => AppNavigation.push<void>(
                                context,
                                EventDetailScreen(event: item),
                              ),
                            ).animate(delay: (200 + (index * 50)).ms).fadeIn().slideY(begin: 0.1, end: 0);
                          },
                          childCount: filtered.length,
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
                              const SizedBox(height: 16),
                              Text(
                                'Bu tarihte etkinlik bulunamadı.',
                                style: TextStyle(color: Colors.grey[500], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    
                    if (upcoming.isNotEmpty && _selectedDate.year != 1970) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                          child: Text(
                            'Yaklaşan Diğer Etkinlikler',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = upcoming[index];
                            return _EventCard(
                              item: item,
                              onTap: () => AppNavigation.push<void>(
                                context,
                                EventDetailScreen(event: item),
                              ),
                            ).animate(delay: (100 + (index * 50)).ms).fadeIn().slideY(begin: 0.1, end: 0);
                          },
                          childCount: upcoming.length,
                        ),
                      ),
                    ],
                  ],
                );
              },
              loading: () => const _EventsLoadingSliver(),
              error: (err, _) => SliverFillRemaining(
                child: Center(child: Text('Hata: $err')),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  List<EventItem> _filterEvents(List<EventItem> list) {
    return list.where((e) {
      final dateMatch = (_selectedDate.year == 1970) ||
          (e.date.day == _selectedDate.day &&
              e.date.month == _selectedDate.month &&
              e.date.year == _selectedDate.year);
      final cityMatch = _selectedCity == 'Tümü' || e.city == _selectedCity;
      final districtMatch = _selectedDistrict == 'Tümü' || e.district == _selectedDistrict;
      final categoryMatch = _selectedCategory == 'Tümü' || e.category == _selectedCategory;
      return dateMatch && cityMatch && districtMatch && categoryMatch;
    }).toList();
  }

  List<EventItem> _getUpcomingEvents(List<EventItem> list) {
    return list.where((e) {
      final isFuture = e.date.isAfter(_selectedDate.add(const Duration(days: 1)));
      final cityMatch = _selectedCity == 'Tümü' || e.city == _selectedCity;
      final categoryMatch = _selectedCategory == 'Tümü' || e.category == _selectedCategory;
      return isFuture && cityMatch && categoryMatch;
    }).toList().take(15).toList();
  }

  Widget _buildCalendarItem({
    required String label,
    required String day,
    required bool isSelected,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 64,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primaryDark : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        boxShadow: isSelected
            ? [BoxShadow(color: AppColors.primaryDark.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 6))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        border: isSelected ? null : Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white.withValues(alpha: 0.8) : AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            day,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            ),
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
                const SizedBox(height: 24),
                const Text('Konum Seçin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                Text('Şehir', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedCity,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: _cities.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() { _selectedCity = v; _selectedDistrict = 'Tümü'; });
                        setState(() { _selectedCity = v; _selectedDistrict = 'Tümü'; });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text('İlçe', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Theme.of(context).colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey[200]!)),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedDistrict,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      items: (_districts[_selectedCity] ?? ['Tümü']).map((d) => DropdownMenuItem(value: d, child: Text(d, style: const TextStyle(fontWeight: FontWeight.w600)))).toList(),
                      onChanged: (v) {
                        if (v == null) return;
                        setModalState(() => _selectedDistrict = v);
                        setState(() => _selectedDistrict = v);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                  child: const Text('Filtrele', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10)))),
              const SizedBox(height: 24),
              const Text('Kategori Seçin', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _categories.map((c) {
                  final isSelected = c == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = c);
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryDark : Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: isSelected ? AppColors.primaryDark : Theme.of(context).dividerColor.withValues(alpha: 0.2)),
                      ),
                      child: Text(c, style: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w700)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.iconColor,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiTokens.radiusCard),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark 
                ? color.withValues(alpha: 0.1) 
                : color,
            borderRadius: BorderRadius.circular(UiTokens.radiusCard),
            border: Theme.of(context).brightness == Brightness.dark 
                ? Border.all(color: iconColor.withValues(alpha: 0.3)) 
                : null,
          ),
          child: Column(
            children: [
              Icon(icon, color: iconColor, size: 28),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Theme.of(context).colorScheme.onSurface 
                      : iconColor.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DropdownFilter extends StatelessWidget {
  const _DropdownFilter({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(UiTokens.radiusControl),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          boxShadow: UiTokens.softShadow(opacity: 0.04),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryDark.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primaryDark, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.onSurface,
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

class _EventCard extends ConsumerWidget {
  const _EventCard({required this.item, required this.onTap});
  final EventItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeStr = DateFormat('HH:mm').format(item.date);
    final dateStr = DateFormat('d MMMM yyyy', 'tr_TR').format(item.date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(UiTokens.radiusCard),
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(UiTokens.radiusCard),
            border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
            boxShadow: UiTokens.softShadow(),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(UiTokens.radiusCard),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // Resim
                  Stack(
                    children: [
                      SizedBox(
                        width: 120,
                        height: double.infinity,
                        child: CachedNetworkImage(
                          imageUrl: item.imageUrl,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[100],
                            child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.broken_image_rounded, color: Colors.grey),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.price,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 10,
                        left: 10,
                        right: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item.city.toUpperCase(),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // İçerik
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD35400).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.category.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFD35400),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  _IconButton(
                                    icon: Icons.share_rounded,
                                    onTap: () => LauncherUtils.shareText(
                                      '${item.title} etkinliğine göz at! ${item.link}',
                                      subject: item.title,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FavoriteButton(
                                    id: item.id,
                                    category: FavoriteCategory.event,
                                    size: 24,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          ),
                          const Spacer(),
                          const SizedBox(height: 12),
                          _DetailRow(icon: Icons.location_on_rounded, text: '${item.district}, ${item.city}'),
                          const SizedBox(height: 4),
                          _DetailRow(icon: Icons.access_time_rounded, text: '$dateStr • $timeStr'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EventsLoadingSliver extends StatelessWidget {
  const _EventsLoadingSliver();

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SkeletonShimmer(
              child: const SkeletonBlock(
                height: 182,
                radius: UiTokens.radiusCard,
              ),
            ),
          );
        },
        childCount: 3,
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  const _IconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (Colors.grey[50] ?? Colors.white).withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200] ?? Colors.grey),
          ),
          child: Icon(icon, size: 18, color: AppColors.textMuted),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: const Color(0xFFD35400).withValues(alpha: 0.6)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
      ],
    );
  }
}
