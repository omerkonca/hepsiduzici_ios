import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../app/providers.dart';
import '../../core/theme/premium_city_theme.dart';
import '../../core/utils/app_navigation.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/app_pressable.dart';
import '../../core/widgets/favorite_button.dart';
import '../../core/widgets/skeleton_shimmer.dart';
import '../../data/models/event_item.dart';
import '../../data/services/favorites_service.dart';
import '../favorites/favorites_screen.dart';
import '../search/global_search_screen.dart';
import '../settings/notification_preferences_screen.dart';
import 'event_detail_screen.dart';
import 'my_calendar_screen.dart';

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  DateTime _selectedDate = DateTime(1970);
  String _selectedCity = 'Tümü';
  String _selectedDistrict = 'Tümü';
  String _selectedCategory = 'Tümü';

  final List<String> _cities = [
    'Tümü',
    'Osmaniye',
    'Adana',
    'Hatay',
    'Gaziantep',
    'Kahramanmaraş',
  ];

  final Map<String, List<String>> _districts = {
    'Tümü': ['Tümü'],
    'Osmaniye': ['Tümü', 'Düziçi', 'Merkez', 'Kadirli', 'Bahçe', 'Sumbas', 'Hasanbeyli'],
    'Adana': ['Tümü', 'Seyhan', 'Çukurova', 'Yüreğir', 'Sarıçam'],
    'Hatay': ['Tümü', 'Antakya', 'İskenderun', 'Defne', 'Kırıkhan'],
    'Gaziantep': ['Tümü', 'Şahinbey', 'Şehitkamil', 'Nizip'],
    'Kahramanmaraş': ['Tümü', 'Onikişubat', 'Dulkadiroğlu', 'Elbistan'],
  };

  final List<String> _categories = [
    'Tümü',
    'Konser',
    'Tiyatro',
    'Festival',
    'Spor',
    'Kültür & Sanat',
  ];

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventListProvider);

    return Scaffold(
      backgroundColor: PremiumCityTheme.canvas,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(stampedEventsProvider);
            await Future.delayed(const Duration(milliseconds: 500));
          },
          color: PremiumCityTheme.gold,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              SliverToBoxAdapter(
                child: _EventsHeader(
                  city: _selectedCity,
                  onSearch: () => AppNavigation.push<void>(
                    context,
                    const GlobalSearchScreen(),
                  ),
                )
                    .animate()
                    .fadeIn(duration: 420.ms)
                    .slideY(begin: 0.08, end: 0),
              ),
              SliverToBoxAdapter(
                child: _DateRail(
                  selectedDate: _selectedDate,
                  onSelected: (date) => setState(() => _selectedDate = date),
                ).animate().fadeIn(delay: 80.ms, duration: 420.ms),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PremiumCityTheme.pagePadding,
                      10,
                      PremiumCityTheme.pagePadding,
                      0),
                  child: Row(
                    children: [
                      _ActionCard(
                        icon: Icons.favorite_rounded,
                        title: 'Favorilerim',
                        subtitle: 'Beğendiğin etkinlikler',
                        color: const Color(0xFFE84B5F),
                        background: const Color(0xFFFFEEF1),
                        onTap: () => AppNavigation.push<void>(
                          context,
                          const FavoritesScreen(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ActionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Takvimim',
                        subtitle: 'Etkinliklerini yönet',
                        color: const Color(0xFF1686C8),
                        background: const Color(0xFFEAF6FF),
                        onTap: () => AppNavigation.push<void>(
                          context,
                          const MyCalendarScreen(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _ActionCard(
                        icon: Icons.notifications_active_rounded,
                        title: 'Alarmlarım',
                        subtitle: 'Hatırlatıcı ayarların',
                        color: PremiumCityTheme.gold,
                        background: const Color(0xFFFFF7DF),
                        onTap: () => AppNavigation.push<void>(
                          context,
                          const NotificationPreferencesScreen(),
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 140.ms, duration: 420.ms),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                      PremiumCityTheme.pagePadding,
                      12,
                      PremiumCityTheme.pagePadding,
                      10),
                  child: Row(
                    children: [
                      Expanded(
                        child: _DropdownFilter(
                          label: 'Konum',
                          value: '$_selectedCity, $_selectedDistrict',
                          icon: Icons.location_on_rounded,
                          onTap: _showLocationPicker,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _DropdownFilter(
                          label: 'Kategori',
                          value: _selectedCategory,
                          icon: Icons.grid_view_rounded,
                          onTap: _showCategoryPicker,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 420.ms),
              ),
              eventsAsync.when(
                data: (list) {
                  final filtered = _filterEvents(list);
                  final upcoming = _getUpcomingEvents(list);

                  return SliverMainAxisGroup(
                    slivers: [
                      if (filtered.isEmpty)
                        const SliverToBoxAdapter(child: _EmptyEventsState())
                      else
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
                              )
                                  .animate(delay: (110 + index * 35).ms)
                                  .fadeIn(duration: 360.ms)
                                  .slideY(begin: 0.06, end: 0);
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      if (upcoming.isNotEmpty) ...[
                        SliverToBoxAdapter(
                          child: _SectionHeader(
                            title: 'Yaklaşan Diğer Etkinlikler',
                            onTap: () =>
                                setState(() => _selectedDate = DateTime(1970)),
                          ),
                        ),
                        SliverToBoxAdapter(
                          child: SizedBox(
                            height: 100,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.fromLTRB(
                                  PremiumCityTheme.pagePadding, 2, PremiumCityTheme.pagePadding, 0),
                              itemCount: upcoming.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(width: 8),
                              itemBuilder: (context, index) {
                                final item = upcoming[index];
                                return _UpcomingEventCard(
                                  item: item,
                                  onTap: () => AppNavigation.push<void>(
                                    context,
                                    EventDetailScreen(event: item),
                                  ),
                                );
                              },
                            ),
                          ).animate().fadeIn(delay: 120.ms, duration: 420.ms),
                        ),
                      ],
                      const SliverToBoxAdapter(child: SizedBox(height: 88)),
                    ],
                  );
                },
                loading: () => const _EventsLoadingSliver(),
                error: (err, _) => SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Text(
                      'Etkinlikler yüklenemedi.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<EventItem> _filterEvents(List<EventItem> list) {
    final filtered = list.where((e) {
      final dateMatch = _selectedDate.year == 1970 ||
          (e.date.day == _selectedDate.day &&
              e.date.month == _selectedDate.month &&
              e.date.year == _selectedDate.year);
      final cityMatch = _selectedCity == 'Tümü' || e.city == _selectedCity;
      final districtMatch = _selectedDistrict == 'Tümü' ||
          e.district == _selectedDistrict ||
          (_selectedDistrict == 'Düziçi' &&
              (e.district.toLowerCase().contains('düziçi') ||
                  e.location.toLowerCase().contains('düziçi') ||
                  e.title.toLowerCase().contains('düziçi')));
      final categoryMatch =
          _selectedCategory == 'Tümü' || e.category == _selectedCategory;
      return dateMatch && cityMatch && districtMatch && categoryMatch;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return filtered;
  }

  List<EventItem> _getUpcomingEvents(List<EventItem> list) {
    final now = DateTime.now().subtract(const Duration(hours: 6));
    return list.where((e) {
      final isFuture = e.date.isAfter(now);
      final cityMatch = _selectedCity == 'Tümü' || e.city == _selectedCity;
      final categoryMatch =
          _selectedCategory == 'Tümü' || e.category == _selectedCategory;
      return isFuture && cityMatch && categoryMatch;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  void _showLocationPicker() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return _PremiumBottomSheet(
              title: 'Konum Seçin',
              children: [
                _SheetLabel('Şehir'),
                _SelectBox(
                  value: _selectedCity,
                  items: _cities,
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() {
                      _selectedCity = value;
                      _selectedDistrict = 'Tümü';
                    });
                    setState(() {
                      _selectedCity = value;
                      _selectedDistrict = 'Tümü';
                    });
                  },
                ),
                const SizedBox(height: 16),
                _SheetLabel('İlçe'),
                _SelectBox(
                  value: _selectedDistrict,
                  items: _districts[_selectedCity] ?? const ['Tümü'],
                  onChanged: (value) {
                    if (value == null) return;
                    setModalState(() => _selectedDistrict = value);
                    setState(() => _selectedDistrict = value);
                  },
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: PremiumCityTheme.navy,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    'Filtrele',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showCategoryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _PremiumBottomSheet(
          title: 'Kategori Seçin',
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: _categories.map((category) {
                final selected = category == _selectedCategory;
                return AppPressable(
                  onTap: () {
                    setState(() => _selectedCategory = category);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? PremiumCityTheme.navy : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: selected
                            ? PremiumCityTheme.navy
                            : const Color(0xFFE6EAF0),
                      ),
                      boxShadow: selected
                          ? PremiumCityTheme.softShadow(
                              color: PremiumCityTheme.navy,
                              alpha: 0.20,
                            )
                          : null,
                    ),
                    child: Text(
                      category,
                      style: TextStyle(
                        color: selected ? Colors.white : PremiumCityTheme.ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _EventsHeader extends StatelessWidget {
  const _EventsHeader({required this.city, required this.onSearch});

  final String city;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium?.copyWith(
          color: PremiumCityTheme.navy,
          fontSize: 22,
          height: 0.98,
          fontWeight: FontWeight.w900,
          letterSpacing: -0.4,
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PremiumCityTheme.pagePadding, 10, PremiumCityTheme.pagePadding, 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: PremiumCityTheme.gold.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.calendar_month_rounded,
              color: PremiumCityTheme.gold,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Etkinlik Takvimi', style: titleStyle),
                const SizedBox(height: 2),
                Text(
                  city == 'Tümü'
                      ? 'Bölgedeki en iyi anları yakala.'
                      : '$city etkinliklerini yakala.',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: PremiumCityTheme.muted,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          AppPressable(
            onTap: onSearch,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              width: 44,
              height: 44,
              decoration: PremiumCityTheme.card(radius: 22),
              child: const Icon(
                Icons.search_rounded,
                color: PremiumCityTheme.navy,
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateRail extends StatelessWidget {
  const _DateRail({
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            PremiumCityTheme.pagePadding, 8, PremiumCityTheme.pagePadding, 4),
        itemCount: 8,
        itemBuilder: (context, index) {
          if (index == 0) {
            final selected = selectedDate.year == 1970;
            return _DateChip(
              eyebrow: 'Genel',
              label: 'Tümü',
              selected: selected,
              onTap: () => onSelected(DateTime(1970)),
            );
          }

          final date = DateTime.now().add(Duration(days: index - 1));
          final selected = selectedDate.day == date.day &&
              selectedDate.month == date.month &&
              selectedDate.year == date.year;

          return _DateChip(
            eyebrow: DateFormat('EEE', 'tr_TR').format(date).toUpperCase(),
            label: DateFormat('d', 'tr_TR').format(date),
            selected: selected,
            onTap: () => onSelected(date),
          );
        },
      ),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({
    required this.eyebrow,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String eyebrow;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 240),
          width: 50,
          decoration: BoxDecoration(
            gradient: selected ? PremiumCityTheme.goldGradient : null,
            color: selected ? null : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? Colors.white.withValues(alpha: 0.25)
                  : const Color(0xFFE6EAF0),
            ),
            boxShadow: selected
                ? PremiumCityTheme.softShadow(
                    color: PremiumCityTheme.gold,
                    alpha: 0.24,
                  )
                : PremiumCityTheme.softShadow(alpha: 0.05),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? Colors.white : PremiumCityTheme.muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : PremiumCityTheme.ink,
                  fontSize: label.length > 2 ? 13 : 18,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.background,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          height: 72,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.75)),
            boxShadow: PremiumCityTheme.softShadow(alpha: 0.055),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 14,
                          offset: const Offset(0, 7),
                        ),
                      ],
                    ),
                    child: Icon(icon, color: color, size: 17),
                  ),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: color, size: 16),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: color,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
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
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 58,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: PremiumCityTheme.card(radius: 18),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PremiumCityTheme.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: PremiumCityTheme.gold, size: 18),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: PremiumCityTheme.muted,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: PremiumCityTheme.ink,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: PremiumCityTheme.ink,
              size: 19,
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
    final time = DateFormat('HH:mm', 'tr_TR').format(item.date);
    final date = DateFormat('d MMMM yyyy', 'tr_TR').format(item.date);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PremiumCityTheme.pagePadding, 0, PremiumCityTheme.pagePadding, 8),
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 128,
          decoration: PremiumCityTheme.card(radius: 20),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              _EventImage(item: item),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _CategoryPill(label: item.category),
                          const Spacer(),
                          _MiniIconButton(
                            icon: Icons.ios_share_rounded,
                            onTap: () => LauncherUtils.shareText(
                              '${item.title} etkinliğine göz at! ${item.link}',
                              subject: item.title,
                            ),
                          ),
                          const SizedBox(width: 6),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAFBFD),
                              borderRadius: BorderRadius.circular(14),
                              border:
                                  Border.all(color: const Color(0xFFE8EDF3)),
                            ),
                            child: FavoriteButton(
                              id: item.id,
                              category: FavoriteCategory.event,
                              size: 17,
                              padding: const EdgeInsets.all(5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: PremiumCityTheme.ink,
                          fontSize: 13.5,
                          height: 1.12,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0,
                        ),
                      ),
                      const Spacer(),
                      _DetailRow(
                        icon: Icons.location_on_rounded,
                        text: '${item.district}, ${item.city}',
                      ),
                      const SizedBox(height: 4),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        text: '$date • $time',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventImage extends StatelessWidget {
  const _EventImage({required this.item});

  final EventItem item;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 108,
      height: double.infinity,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CachedNetworkImage(
            imageUrl: item.imageUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) =>
                Container(color: const Color(0xFFE8EDF3)),
            errorWidget: (context, url, error) => Container(
              color: PremiumCityTheme.navy,
              child: const Icon(
                Icons.image_not_supported_rounded,
                color: Colors.white70,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black54, Colors.transparent, Colors.black87],
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.54),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
              ),
              child: Text(
                item.price.isEmpty ? 'Etkinlik' : item.price,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: 8,
            child: Container(
              height: 24,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: PremiumCityTheme.goldGradient,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.city.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.7,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEEE6),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Color(0xFFD4632C),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MiniIconButton extends StatelessWidget {
  const _MiniIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppPressable(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFBFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE8EDF3)),
        ),
        child: Icon(icon, size: 18, color: PremiumCityTheme.ink),
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
        Icon(icon, size: 13, color: PremiumCityTheme.gold),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PremiumCityTheme.muted,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          PremiumCityTheme.pagePadding, 12, PremiumCityTheme.pagePadding, 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: PremiumCityTheme.ink,
                fontSize: PremiumCityTheme.sectionTitleSize,
                fontWeight: FontWeight.w900,
                letterSpacing: 0,
              ),
            ),
          ),
          AppPressable(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      color: PremiumCityTheme.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 3),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: PremiumCityTheme.navy,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UpcomingEventCard extends StatelessWidget {
  const _UpcomingEventCard({required this.item, required this.onTap});

  final EventItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final day = DateFormat('dd', 'tr_TR').format(item.date);
    final month = DateFormat('MMM', 'tr_TR').format(item.date).toUpperCase();

    return SizedBox(
      width: 156,
      child: AppPressable(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: PremiumCityTheme.card(radius: 16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: SizedBox(
                  width: 44,
                  height: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: item.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: PremiumCityTheme.navy),
                      ),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              PremiumCityTheme.navy.withValues(alpha: 0.10),
                              PremiumCityTheme.navy.withValues(alpha: 0.78),
                            ],
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          '$day\n$month',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.5,
                            height: 1.05,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: PremiumCityTheme.ink,
                        fontSize: 11.5,
                        height: 1.12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_rounded,
                          color: PremiumCityTheme.gold,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.district,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: PremiumCityTheme.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyEventsState extends StatelessWidget {
  const _EmptyEventsState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: PremiumCityTheme.card(radius: 24),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: PremiumCityTheme.gold.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_busy_rounded,
                color: PremiumCityTheme.gold,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu filtrelerde etkinlik bulunamadı.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PremiumCityTheme.ink,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Tümü seçeneğiyle bölgedeki etkinlikleri görebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PremiumCityTheme.muted,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
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
            padding: const EdgeInsets.fromLTRB(
                PremiumCityTheme.pagePadding, 0, PremiumCityTheme.pagePadding, 8),
            child: const SkeletonBlock(height: 128, radius: 20),
          );
        },
        childCount: 4,
      ),
    );
  }
}

class _PremiumBottomSheet extends StatelessWidget {
  const _PremiumBottomSheet({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        10,
        20,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: PremiumCityTheme.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5DCE6),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(
                color: PremiumCityTheme.navy,
                fontSize: 22,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          color: PremiumCityTheme.ink,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SelectBox extends StatelessWidget {
  const _SelectBox({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: PremiumCityTheme.card(radius: 18),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: value,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
