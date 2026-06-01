import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/target_router.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/event_item.dart';
import '../../data/models/news_item.dart';
import '../events/event_detail_screen.dart';
import '../news/news_detail_screen.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends ConsumerState<NotificationCenterScreen> {
  bool _markedOnExit = false;

  @override
  void dispose() {
    _markInboxSeen();
    super.dispose();
  }

  void _markInboxSeen() {
    if (_markedOnExit) return;
    _markedOnExit = true;
    final notifications = ref.read(appNotificationsProvider);
    if (notifications.isEmpty) return;
    ref.read(readNotificationsProvider.notifier).markAllAsRead(
          notifications.map((n) => n.id),
        );
  }

  @override
  Widget build(BuildContext context) {
    final readState = ref.watch(readNotificationsProvider);
    final readIds = readState.ids;
    final allNotifications = ref.watch(appNotificationsProvider);

    final outagesAsync = ref.watch(stampedOutagesProvider);
    final roadClosuresAsync = ref.watch(stampedRoadClosuresProvider);
    final newsAsync = ref.watch(stampedNewsProvider);
    final eventsAsync = ref.watch(stampedEventsProvider);

    final isLoading = !readState.ready ||
        outagesAsync.isLoading ||
        newsAsync.isLoading ||
        roadClosuresAsync.isLoading ||
        eventsAsync.isLoading;

    final unreadIds = allNotifications
        .map((n) => n.id)
        .where((id) => !readIds.contains(id))
        .toList();

    final announcementList = allNotifications
        .where((n) =>
            n.type == AppNotificationType.outage ||
            n.type == AppNotificationType.roadClosure ||
            n.type == AppNotificationType.news)
        .toList();

    final reminderList =
        allNotifications.where((n) => n.type == AppNotificationType.event).toList();

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _markInboxSeen();
      },
      child: DefaultTabController(
        length: 3,
        child: Scaffold(
          backgroundColor: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF121212)
              : const Color(0xFFF8F9FA),
          appBar: AppBar(
            elevation: 0,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: const Text(
              'Bildirimler',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, letterSpacing: -0.5),
            ),
            actions: [
              if (unreadIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    ref.read(readNotificationsProvider.notifier).markAllAsRead(unreadIds);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tüm bildirimler okundu.')),
                    );
                  },
                  icon: const Icon(Icons.done_all_rounded, size: 20),
                  label: const Text('Tümünü oku'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    textStyle: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'Bildirim ayarları',
                onPressed: () =>
                    TargetRouter.handle(context, 'screen:notification_settings'),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.06)
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: TabBar(
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  indicator: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: Theme.of(context).textTheme.bodySmall?.color,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                  tabs: [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Tümü'),
                          if (unreadIds.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _CountDot(count: unreadIds.length),
                          ],
                        ],
                      ),
                    ),
                    const Tab(text: 'Duyurular'),
                    const Tab(text: 'Hatırlatıcı'),
                  ],
                ),
              ),
            ),
          ),
          body: isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  children: [
                    _NotificationList(
                      items: allNotifications,
                      readIds: readIds,
                      emptyMessage: 'Henüz bildiriminiz yok.\nKesinti, yol ve haberler burada görünür.',
                      onTap: (n) => _handleTap(context, n),
                    ),
                    _NotificationList(
                      items: announcementList,
                      readIds: readIds,
                      emptyMessage: 'Şu an şehir duyurusu veya kesinti bildirimi yok.',
                      onTap: (n) => _handleTap(context, n),
                    ),
                    _NotificationList(
                      items: reminderList,
                      readIds: readIds,
                      emptyMessage:
                          'Favori etkinlik hatırlatıcınız yok.\nTakvimden etkinlik favorileyerek ekleyebilirsiniz.',
                      onTap: (n) => _handleTap(context, n),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleTap(BuildContext context, AppNotification n) async {
    await ref.read(readNotificationsProvider.notifier).markAsRead(n.id);

    if (!context.mounted) return;
    switch (n.type) {
      case AppNotificationType.outage:
        await TargetRouter.handle(context, 'screen:outages');
        break;
      case AppNotificationType.roadClosure:
        await TargetRouter.handle(context, 'screen:closed_roads');
        break;
      case AppNotificationType.news:
        final item = n.originalData as NewsItem;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => NewsDetailScreen(item: item)),
        );
        break;
      case AppNotificationType.event:
        final item = n.originalData as EventItem;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => EventDetailScreen(event: item)),
        );
        break;
    }
  }
}

class _CountDot extends StatelessWidget {
  const _CountDot({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 99 ? '99+' : '$count';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
      child: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.readIds,
    required this.emptyMessage,
    required this.onTap,
  });

  final List<AppNotification> items;
  final Set<String> readIds;
  final String emptyMessage;
  final void Function(AppNotification) onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_rounded,
                  size: 56, color: Colors.grey.withValues(alpha: 0.35)),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isRead = readIds.contains(item.id);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(item),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isRead
                        ? Theme.of(context).dividerColor.withValues(alpha: 0.08)
                        : AppColors.primary.withValues(alpha: 0.22),
                    width: isRead ? 1 : 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.icon, color: item.color, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  item.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontWeight:
                                        isRead ? FontWeight.w700 : FontWeight.w900,
                                    fontSize: 14.5,
                                    height: 1.25,
                                  ),
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(left: 8),
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item.body,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.4,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.65),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatRelativeDate(item.dateTime),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).textTheme.bodySmall?.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(delay: (index * 35).ms).slideY(begin: 0.04, end: 0);
        },
    );
  }

  static String _formatRelativeDate(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.isNegative) {
      return 'Yaklaşıyor · ${DateFormat('d MMM, HH:mm', 'tr_TR').format(d)}';
    }
    if (diff.inDays > 0) return diff.inDays == 1 ? 'Dün' : '${diff.inDays} gün önce';
    if (diff.inHours > 0) return '${diff.inHours} saat önce';
    if (diff.inMinutes > 0) return '${diff.inMinutes} dk önce';
    return 'Az önce';
  }
}
