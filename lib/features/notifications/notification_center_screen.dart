import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/event_item.dart';
import '../../data/services/favorites_service.dart';
import '../events/event_detail_screen.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favorites = ref.watch(favoritesProvider);
    final eventsAsync = ref.watch(eventListProvider);
    final cityContentAsync = ref.watch(cityContentProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bildirim Merkezi', style: TextStyle(fontWeight: FontWeight.w900)),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.pushNamed(context, 'screen:notification_settings'),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          // 1. System Announcements
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Sistem Duyuruları'),
          ),
          cityContentAsync.when(
            data: (content) {
              // We can use news or special alerts here. For now, let's mock 2-3 important items.
              final announcements = [
                _Announcement(
                  title: 'Hava Durumu Uyarısı',
                  body: 'Bugün akşam saatlerinde şiddetli rüzgar bekleniyor. Lütfen tedbirli olun.',
                  date: DateTime.now(),
                  icon: Icons.wb_cloudy_rounded,
                  color: Colors.orange,
                ),
                _Announcement(
                  title: 'Planlı Su Kesintisi',
                  body: 'Kurtbeyoğlu mahallesinde bakım çalışması nedeniyle 14:00-16:00 arası su kesintisi olacaktır.',
                  date: DateTime.now().subtract(const Duration(hours: 3)),
                  icon: Icons.water_drop_rounded,
                  color: Colors.blue,
                ),
              ];
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => _AnnouncementTile(announcement: announcements[index]),
                  childCount: announcements.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (e, _) => SliverToBoxAdapter(child: Text('Hata: $e')),
          ),

          // 2. Active Reminders (Favorited Events)
          SliverToBoxAdapter(
            child: _SectionHeader(title: 'Yaklaşan Hatırlatıcılar'),
          ),
          eventsAsync.when(
            data: (events) {
              final favEventIds = favorites[FavoriteCategory.event] ?? {};
              final myEvents = events.where((e) => favEventIds.contains(e.id)).toList();
              
              if (myEvents.isEmpty) {
                return const SliverToBoxAdapter(
                  child: _EmptyState(
                    icon: Icons.notifications_none_rounded,
                    message: 'Aktif bir hatırlatıcınız bulunmuyor.\nEtkinlikleri favorileyerek hatırlatıcı kurabilirsiniz.',
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = myEvents[index];
                    return _ReminderTile(
                      event: event,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => EventDetailScreen(event: event))),
                    );
                  },
                  childCount: myEvents.length,
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
          ),
          
          const SliverToBoxAdapter(child: SizedBox(height: 40)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: Colors.grey[500],
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _Announcement {
  final String title;
  final String body;
  final DateTime date;
  final IconData icon;
  final Color color;
  _Announcement({required this.title, required this.body, required this.date, required this.icon, required this.color});
}

class _AnnouncementTile extends StatelessWidget {
  const _AnnouncementTile({required this.announcement});
  final _Announcement announcement;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: announcement.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(announcement.icon, color: announcement.color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(announcement.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    Text(
                      DateFormat('HH:mm').format(announcement.date),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  announcement.body,
                  style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({required this.event, required this.onTap});
  final EventItem event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(event.imageUrl, width: 56, height: 56, fit: BoxFit.cover),
        ),
        title: Text(event.title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  DateFormat('d MMMM, HH:mm', 'tr_TR').format(event.date),
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
        onTap: onTap,
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 40),
      child: Column(
        children: [
          Icon(icon, size: 48, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[500], fontSize: 13, height: 1.5, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
