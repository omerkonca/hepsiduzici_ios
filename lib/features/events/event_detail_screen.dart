import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/launcher_utils.dart';
import '../../core/widgets/favorite_button.dart';
import '../../data/models/event_item.dart';
import '../../data/services/favorites_service.dart';

class EventDetailScreen extends ConsumerWidget {
  final EventItem event;

  const EventDetailScreen({super.key, required this.event});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('d MMMM yyyy, EEEE', 'tr_TR');
    final timeFormat = DateFormat('HH:mm');
    final favEvents = ref.watch(favoritesProvider)[FavoriteCategory.event] ?? {};
    final isFavorite = favEvents.contains(event.id);
    final isMuted = ref.watch(mutedEventIdsProvider).contains(event.id);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              FavoriteButton(
                id: event.id,
                category: FavoriteCategory.event,
                size: 24,
                padding: const EdgeInsets.only(right: 16),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(
                    imageUrl: event.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.primary,
                      child: const Icon(Icons.image_not_supported, color: Colors.white, size: 48),
                    ),
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black26,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  if (isFavorite) ...[
                    const SizedBox(height: 16),
                    Material(
                      color: isMuted
                          ? Colors.orange.shade50
                          : AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        leading: Icon(
                          isMuted
                              ? Icons.notifications_off_rounded
                              : Icons.alarm_on_rounded,
                          color: isMuted ? Colors.orange.shade800 : AppColors.primary,
                        ),
                        title: Text(
                          isMuted ? 'Hatırlatıcı kapalı' : 'Hatırlatıcı açık',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                        subtitle: Text(
                          isMuted
                              ? 'Bu etkinlik için bildirim gelmiyor.'
                              : 'Etkinlikten 1 saat önce bildirim alırsınız.',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: Switch.adaptive(
                          value: !isMuted,
                          activeColor: AppColors.primary,
                          onChanged: (on) async {
                            await ref
                                .read(mutedEventIdsProvider.notifier)
                                .setMuted(event.id, !on);
                          },
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _buildInfoRow(
                    context,
                    icon: Icons.calendar_today_outlined,
                    title: dateFormat.format(event.date),
                    subtitle: 'Saat: ${timeFormat.format(event.date)}',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.location_on_outlined,
                    title: event.location,
                    subtitle: '${event.city}, ${event.district}',
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    context,
                    icon: Icons.confirmation_number_outlined,
                    title: 'Bilet Bilgisi',
                    subtitle: event.price,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Etkinlik Konumu',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: () => LauncherUtils.openMaps(event.location, event.city),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                              child: Icon(Icons.map_rounded, color: AppColors.primary, size: 32),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Haritada Gör ve Yol Tarifi Al',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Hakkında',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bu etkinlik ${event.city} şehrinde, ${event.location} mekanında gerçekleşecektir. Detaylı bilgi ve bilet işlemleri için resmi biletleme platformlarını kullanabilirsiniz.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => LauncherUtils.launchURL(event.link),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'BİLET AL / İNCELE',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: () => LauncherUtils.shareText(
                    '${event.title} etkinliğini seninle paylaşıyorum!\n\n'
                    'Tarih: ${dateFormat.format(event.date)}\n'
                    'Konum: ${event.location}\n\n'
                    'Detaylar için Hepsi Düziçi uygulamasını incele!',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context,
      {required IconData icon, required String title, required String subtitle}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
