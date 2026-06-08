import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/target_router.dart';
import '../../data/models/app_notification.dart';
import '../../data/models/custom_reminder.dart';
import '../../data/models/event_item.dart';
import '../../data/models/news_item.dart';
import '../events/event_detail_screen.dart';
import '../news/news_detail_screen.dart';
import 'add_custom_reminder_sheet.dart';

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

  Future<void> _addCustomReminder() async {
    final added = await showAddCustomReminderSheet(context);
    if (added && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı oluşturuldu.')),
      );
    }
  }

  Future<void> _showEventMuteSheet(EventItem event) async {
    final muted = ref.read(mutedEventIdsProvider).contains(event.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        decoration: BoxDecoration(
          color: Theme.of(ctx).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              event.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                muted ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                color: AppColors.primary,
              ),
              title: Text(muted ? 'Hatırlatıcıyı aç' : 'Hatırlatıcıyı sessize al'),
              subtitle: Text(
                muted
                    ? 'Bu etkinlik için tekrar bildirim alırsınız.'
                    : 'Favori olsa bile bu etkinlik için bildirim gelmez.',
              ),
              onTap: () async {
                await ref
                    .read(mutedEventIdsProvider.notifier)
                    .setMuted(event.id, !muted);
                if (ctx.mounted) Navigator.pop(ctx);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      muted ? 'Etkinlik hatırlatıcısı açıldı.' : 'Etkinlik sessize alındı.',
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
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

    final reminderList = allNotifications
        .where((n) =>
            n.type == AppNotificationType.event ||
            n.type == AppNotificationType.custom ||
            n.type == AppNotificationType.pharmacy)
        .toList();

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
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _addCustomReminder,
            backgroundColor: AppColors.primary,
            icon: const Icon(Icons.add_alarm_rounded),
            label: const Text('Hatırlatıcı'),
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
                      onLongPress: (n) => _handleLongPress(n),
                    ),
                    _NotificationList(
                      items: announcementList,
                      readIds: readIds,
                      emptyMessage: 'Şu an şehir duyurusu veya kesinti bildirimi yok.',
                      onTap: (n) => _handleTap(context, n),
                      onLongPress: (n) => _handleLongPress(n),
                    ),
                    _NotificationList(
                      items: reminderList,
                      readIds: readIds,
                      emptyMessage:
                          'Henüz hatırlatıcınız yok.\nEtkinlik favorileyin veya özel hatırlatıcı ekleyin.',
                      emptyActions: [
                        _EmptyAction(
                          label: 'Hatırlatıcı ekle',
                          icon: Icons.add_alarm_rounded,
                          onTap: _addCustomReminder,
                        ),
                        _EmptyAction(
                          label: 'Etkinliklere git',
                          icon: Icons.event_rounded,
                          onTap: () => TargetRouter.handle(context, 'screen:calendar'),
                        ),
                      ],
                      onTap: (n) => _handleTap(context, n),
                      onLongPress: (n) => _handleLongPress(n),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _handleLongPress(AppNotification n) async {
    if (n.type == AppNotificationType.event) {
      await _showEventMuteSheet(n.originalData as EventItem);
    } else if (n.type == AppNotificationType.custom) {
      final item = n.originalData as CustomReminder;
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Hatırlatıcıyı sil'),
          content: Text('“${item.title}” hatırlatıcısı silinsin mi?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Vazgeç')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Sil')),
          ],
        ),
      );
      if (confirm != true || !mounted) return;
      await ref.read(reminderSchedulerServiceProvider).removeCustomReminder(item.id);
      ref.invalidate(customRemindersProvider);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hatırlatıcı silindi.')),
      );
    }
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
      case AppNotificationType.pharmacy:
        ref.read(currentIndexProvider.notifier).state = 0;
        if (context.mounted) Navigator.pop(context);
        break;
      case AppNotificationType.custom:
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

class _EmptyAction {
  const _EmptyAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({
    required this.items,
    required this.readIds,
    required this.emptyMessage,
    required this.onTap,
    this.onLongPress,
    this.emptyActions = const [],
  });

  final List<AppNotification> items;
  final Set<String> readIds;
  final String emptyMessage;
  final List<_EmptyAction> emptyActions;
  final void Function(AppNotification) onTap;
  final void Function(AppNotification)? onLongPress;

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
              if (emptyActions.isNotEmpty) ...[
                const SizedBox(height: 20),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final action in emptyActions)
                      FilledButton.icon(
                        onPressed: action.onTap,
                        icon: Icon(action.icon, size: 18),
                        label: Text(action.label),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      );
    }

    return ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          final isRead = readIds.contains(item.id);

          return Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => onTap(item),
              onLongPress: onLongPress != null ? () => onLongPress!(item) : null,
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
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
                          if (item.categoryLabel != null) ...[
                            Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: item.isMunicipality
                                    ? const Color(0xFF1565C0).withValues(alpha: 0.12)
                                    : item.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                item.categoryLabel!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: item.isMunicipality
                                      ? const Color(0xFF1565C0)
                                      : item.color,
                                ),
                              ),
                            ),
                          ],
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
