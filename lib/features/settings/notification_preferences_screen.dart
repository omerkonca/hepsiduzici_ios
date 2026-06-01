import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';

class NotificationPreferencesScreen extends ConsumerWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(notificationPrefsProvider);

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
        Text(
          'Etkinlik hatırlatıcıları için izinleri açık tuttuğundan emin ol; ek ayar takvim ekranındaki kayıtta kullanılıyor.',
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
