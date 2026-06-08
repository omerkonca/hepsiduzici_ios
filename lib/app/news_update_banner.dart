import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/news_item.dart';
import '../data/models/stamped_data.dart';
import '../data/services/news_notification_utils.dart';
import '../features/news/news_screen.dart';
import 'providers.dart';

/// Haber listesi yenilendiğinde tercihlere göre üst şerit veya sistem bildirimi gösterir.
Future<void> handleStampedNewsNotification(
  BuildContext context,
  WidgetRef ref,
  Stamped<List<NewsItem>> stamped,
) async {
  final list = stamped.data;
  if (list.isEmpty) return;

  final head = list.first;
  final key = NewsNotificationUtils.headlineTrackingKey(head);
  final prefsSvc = ref.read(notificationPreferencesServiceProvider);
  final notifySvc = ref.read(notificationServiceProvider);

  final last = await prefsSvc.getLastSeenNewsHeadlineKey();
  if (last == null) {
    await prefsSvc.setLastSeenNewsHeadlineKey(key);
    return;
  }
  if (last == key) return;

  final inApp = await prefsSvc.getInAppNewNewsBanner();
  final systemTray = await prefsSvc.getSystemTrayNewNews();
  final lifecycle = ref.read(appLifecycleStateProvider);
  final foreground = lifecycle == AppLifecycleState.resumed;

  var notified = false;

  if (systemTray) {
    var granted = await notifySvc.areSystemNotificationsEnabled();
    if (!granted && defaultTargetPlatform == TargetPlatform.iOS) {
      await notifySvc.ensureNotificationPermissions();
      granted = await notifySvc.areSystemNotificationsEnabled();
    }
    if (granted) {
      final trackingKey = head.id.trim().isNotEmpty ? head.id.trim() : head.title.trim();
      await notifySvc.showNewsHeadlineUpdate(
        title: head.title,
        trackingKey: trackingKey,
      );
      notified = true;
    }
  }

  if (!context.mounted) return;

  if (foreground && inApp) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearMaterialBanners();
    messenger.showMaterialBanner(
      MaterialBanner(
        backgroundColor: Theme.of(context).colorScheme.surface.withValues(alpha: 0.98),
        elevation: 1,
        dividerColor: Colors.transparent,
        forceActionsBelow: false,
        content: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.notifications_active_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Yeni Haber',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    head.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => messenger.hideCurrentMaterialBanner(),
            child: const Text('Kapat'),
          ),
          FilledButton(
            onPressed: () {
              messenger.hideCurrentMaterialBanner();
              ref.read(currentIndexProvider.notifier).state = 0;
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => Scaffold(
                    appBar: AppBar(title: const Text('Haberler')),
                    body: const NewsScreen(),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(
              minimumSize: const Size(0, 36),
              padding: const EdgeInsets.symmetric(horizontal: 14),
            ),
            child: const Text('Haberler'),
          ),
        ],
      ),
    );
    Future<void>.delayed(const Duration(seconds: 8), () {
      if (!context.mounted) return;
      messenger.hideCurrentMaterialBanner();
    });
  }

  if (notified || (foreground && inApp)) {
    await prefsSvc.setLastSeenNewsHeadlineKey(key);
  }
}
