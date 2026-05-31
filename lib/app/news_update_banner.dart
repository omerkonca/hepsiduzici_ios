import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/news_item.dart';
import '../data/models/stamped_data.dart';
import '../features/news/news_screen.dart';
import 'providers.dart';

String _headlineTrackingKey(NewsItem n) {
  final id = n.id.trim();
  if (id.isNotEmpty) return id;
  return '${n.title}|${n.createdAt.toIso8601String()}';
}

/// Haber listesi yenilendiğinde tercihlere göre üst şerit veya sistem bildirimi gösterir.
Future<void> handleStampedNewsNotification(
  BuildContext context,
  WidgetRef ref,
  Stamped<List<NewsItem>> stamped,
) async {
  final list = stamped.data;
  if (list.isEmpty) return;

  final head = list.first;
  final key = _headlineTrackingKey(head);
  final prefsSvc = ref.read(notificationPreferencesServiceProvider);
  final notifySvc = ref.read(notificationServiceProvider);

  final last = await prefsSvc.getLastSeenNewsHeadlineKey();
  if (last == null) {
    await prefsSvc.setLastSeenNewsHeadlineKey(key);
    return;
  }
  if (last == key) return;

  await prefsSvc.setLastSeenNewsHeadlineKey(key);

  final inApp = await prefsSvc.getInAppNewNewsBanner();
  final systemTray = await prefsSvc.getSystemTrayNewNews();
  final lifecycle = ref.read(appLifecycleStateProvider);
  final foreground = lifecycle == AppLifecycleState.resumed;

  if (!context.mounted) return;

  if (foreground && inApp) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16), // Bottom margin if bottom, but let's try top-ish feel
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.95),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Yeni İçerik Yayında',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.0,
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
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => messenger.hideCurrentSnackBar(),
                    child: Text(
                      'Kapat',
                      style: TextStyle(color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      messenger.hideCurrentSnackBar();
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
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      minimumSize: const Size(0, 36),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Haberler', style: TextStyle(fontWeight: FontWeight.w800)),
                  ),
                ],
              ),
            ],
          ),
        ),
        duration: const Duration(seconds: 8),
      ),
    );
    return;
  }

  if (systemTray && (!foreground || !inApp)) {
    await notifySvc.showNewsHeadlineUpdate(title: head.title);
  }
}
