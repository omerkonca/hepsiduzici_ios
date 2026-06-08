import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/push/push_notification_service.dart';
import '../../data/services/background_fetch_service.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  late Future<_NotificationDiag> _diagFuture;

  @override
  void initState() {
    super.initState();
    _diagFuture = _loadDiag();
  }

  Future<_NotificationDiag> _loadDiag() async {
    final p = await SharedPreferences.getInstance();
    return _NotificationDiag(
      lastRunAtIso: p.getString(BackgroundFetchService.lastRunAtKey),
      lastStatus: p.getString(BackgroundFetchService.lastStatusKey),
      lastError: p.getString(BackgroundFetchService.lastErrorKey),
    );
  }

  void _refreshDiag() {
    setState(() {
      _diagFuture = _loadDiag();
    });
  }

  String _formatStatus(String? status) {
    switch (status) {
      case 'running':
        return 'Arka plan görevi şu an çalışıyor';
      case 'initialized':
        return 'İlk kurulum yapıldı (henüz bildirim gönderilmedi)';
      case 'no_change':
        return 'Yeni haber bulunmadı';
      case 'notified':
        return 'Yeni haber bulundu, sistem bildirimi gönderildi';
      case 'skipped_disabled':
        return 'Atlandı: sistem bildirimi ayarı kapalı';
      case 'skipped_bad_response':
        return 'Atlandı: sunucu yanıtı geçersiz';
      case 'skipped_bad_payload':
        return 'Atlandı: veri formatı geçersiz';
      case 'skipped_empty':
        return 'Atlandı: haber listesi boş';
      case 'error':
        return 'Hata oluştu';
      default:
        return 'Henüz arka plan çalışması kaydı yok';
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(notificationPrefsProvider);
    final notificationService = ref.read(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bildirim tercihleri')),
      body: ListView(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      children: [
        Text(
          'Haber bildirimleri',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yeni içerik çekildiğinde nasıl uyarılmak istediğini seç.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 20),
        Card(
          elevation: 0,
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.softGrey.withValues(alpha: 0.5)),
          ),
          child: Column(
            children: [
              SwitchListTile.adaptive(
                value: prefs.inAppNewNewsBanner,
                onChanged: (v) => ref.read(notificationPrefsProvider.notifier).setInAppNewNewsBanner(v),
                title: const Text('Üst bildirim çubuğu'),
                subtitle: Text(
                  'Uygulama açıkken yeniler üstten bir şerit olarak gösterilir.',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
                ),
              ),
              const Divider(height: 1),
              SwitchListTile.adaptive(
                value: prefs.systemTrayNewNews,
                onChanged: (v) async {
                  final ok =
                      await ref.read(notificationPrefsProvider.notifier).setSystemTrayNewNews(v);
                  if (!context.mounted || ok || !v) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Bildirim izni reddedildi. Ayarlardan izin verebilirsin.')),
                  );
                },
                title: const Text('Sistem bildirimi'),
                subtitle: Text(
                  'Uygulama arka plandayken kısa bir bildirim gösterilir (Android bildirim izni gerekebilir).',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<bool>(
          future: notificationService.areSystemNotificationsEnabled(),
          builder: (context, snapshot) {
            final enabled = snapshot.data ?? false;
            final loading = snapshot.connectionState == ConnectionState.waiting;
            return Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.softGrey.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Bildirim durumu',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          loading
                              ? Icons.hourglass_top_rounded
                              : (enabled ? Icons.check_circle_rounded : Icons.error_rounded),
                          size: 18,
                          color: loading
                              ? AppColors.textMuted
                              : (enabled ? Colors.green.shade600 : Colors.red.shade600),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            loading
                                ? 'Sistem bildirim izni kontrol ediliyor...'
                                : (enabled
                                    ? 'Sistem izni açık. Uygulama kapalıyken de bildirim gelebilir.'
                                    : 'Sistem bildirimi kapalı. Cihaz ayarlarından izin verin.'),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.textMuted,
                                  height: 1.3,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: () async {
                        await notificationService.showTestNotification();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test bildirimi gönderildi.')),
                        );
                      },
                      icon: const Icon(Icons.notifications_active_rounded, size: 18),
                      label: const Text('Test bildirimi gönder'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        FutureBuilder<_NotificationDiag>(
          future: _diagFuture,
          builder: (context, snapshot) {
            final diag = snapshot.data;
            final statusText = _formatStatus(diag?.lastStatus);
            return Card(
              elevation: 0,
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: AppColors.softGrey.withValues(alpha: 0.5)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Arka plan tanı',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _refreshDiag,
                          icon: const Icon(Icons.refresh_rounded, size: 16),
                          label: const Text('Yenile'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                            height: 1.3,
                          ),
                    ),
                    if (diag?.lastRunAtIso != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Son çalışma: ${diag!.lastRunAtIso}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                              height: 1.3,
                            ),
                      ),
                    ],
                    if (diag?.lastError != null && diag!.lastError!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Son hata: ${diag.lastError}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.red.shade700,
                              height: 1.3,
                            ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Not: Android batarya optimizasyonu açıksa görev gecikebilir.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted.withValues(alpha: 0.9),
                            fontSize: 11.5,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        Text(
          'Duyuru bildirimleri',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Yayıncıdan gelen günaydın mesajları, yeni özellik ve şehir duyuruları.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 16),
        const _MarketingPushCard(),
        const SizedBox(height: 24),
        Text(
          'Hatırlatıcılar',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Namaz vakti, hafta sonu eczane ve etkinlik hatırlatıcıları.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 16),
        _ReminderPrefsCard(),
        const SizedBox(height: 16),
        Text(
          'Etkinlik hatırlatıcıları için izinleri açık tuttuğundan emin ol; favori etkinliklerden 1 saat önce bildirim gelir.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                height: 1.35,
              ),
        ),
      ],
      ),
    );
  }
}

class _MarketingPushCard extends StatefulWidget {
  const _MarketingPushCard();

  @override
  State<_MarketingPushCard> createState() => _MarketingPushCardState();
}

class _MarketingPushCardState extends State<_MarketingPushCard> {
  bool? _optIn;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final v = await PushNotificationService.instance.getMarketingOptIn();
    if (mounted) setState(() => _optIn = v);
  }

  Future<void> _set(bool value) async {
    setState(() => _busy = true);
    await PushNotificationService.instance.setMarketingOptIn(value);
    if (mounted) setState(() {
      _optIn = value;
      _busy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_optIn == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.softGrey.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile.adaptive(
        value: _optIn!,
        onChanged: _busy ? null : _set,
        title: const Text('Yayıncı duyuruları'),
        subtitle: Text(
          PushNotificationService.instance.isReady
              ? 'Günaydın, yeni özellik ve önemli duyurular.'
              : 'Push henüz yapılandırılmadı; Firebase kurulumu sonrası aktif olur.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
        ),
      ),
    );
  }
}

class _ReminderPrefsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(reminderPrefsProvider);
    if (!prefs.ready) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    const minuteOptions = [5, 10, 15, 30];

    return Card(
      elevation: 0,
      color: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.softGrey.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          SwitchListTile.adaptive(
            value: prefs.prayerReminders,
            onChanged: (v) async {
              final ok = await ref.read(reminderPrefsProvider.notifier).setPrayerReminders(v);
              if (!context.mounted || ok || !v) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bildirim izni reddedildi.')),
              );
            },
            title: const Text('Namaz vakti hatırlatıcı'),
            subtitle: Text(
              'Her vakitten ${prefs.prayerMinutesBefore} dk önce bildirim.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                Text(
                  'Önceden uyar',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    children: [
                      for (final m in minuteOptions)
                        ChoiceChip(
                          label: Text('$m dk'),
                          selected: prefs.prayerMinutesBefore == m,
                          onSelected: (_) => ref
                              .read(reminderPrefsProvider.notifier)
                              .setPrayerMinutesBefore(m),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          SwitchListTile.adaptive(
            value: prefs.pharmacyReminders,
            onChanged: (v) async {
              final ok = await ref.read(reminderPrefsProvider.notifier).setPharmacyReminders(v);
              if (!context.mounted || ok || !v) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Bildirim izni reddedildi.')),
              );
            },
            title: const Text('Hafta sonu nöbetçi eczane'),
            subtitle: Text(
              'Cumartesi ve pazar sabahı nöbetçi eczane hatırlatması.',
              style: TextStyle(fontSize: 12, color: AppColors.textMuted.withValues(alpha: 0.9)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationDiag {
  const _NotificationDiag({
    this.lastRunAtIso,
    this.lastStatus,
    this.lastError,
  });

  final String? lastRunAtIso;
  final String? lastStatus;
  final String? lastError;
}
