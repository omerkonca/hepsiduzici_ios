import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../theme/app_colors.dart';
import '../utils/icon_mapper.dart';

/// Tüm şehir hizmetleri ve rehber sayfaları için ortak şablon.
/// Tutarlı bir başlık yapısı, animasyonlar ve boş durumlar sağlar.
class ServicePageLayout extends StatelessWidget {
  const ServicePageLayout({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.child,
    this.onRefresh,
    this.isEmpty = false,
    this.emptyMessage = 'Henüz kayıt bulunmamaktadır.',
    this.floatingActionButton,
    this.actions,
  });

  final String title;
  final String subtitle;
  final String icon;
  final Color color;
  final Widget child;
  final Future<void> Function()? onRefresh;
  final bool isEmpty;
  final String emptyMessage;
  final Widget? floatingActionButton;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: actions,
      ),
      floatingActionButton: floatingActionButton,
      body: onRefresh != null
          ? RefreshIndicator(
              onRefresh: onRefresh!,
              color: AppColors.primary,
              child: _buildContent(context),
            )
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isEmpty) {
      return CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(IconMapper.fromName(icon), size: 48, color: AppColors.textMuted.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text(
                    emptyMessage,
                    style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildHeader(context)
              .animate()
              .fadeIn(duration: 400.ms)
              .slideY(begin: -0.05, end: 0, curve: Curves.easeOutCubic),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          sliver: child,
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    if (subtitle.trim().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withValues(alpha: 0.15),
                  color.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: color.withValues(alpha: 0.1)),
            ),
            child: Icon(IconMapper.fromName(icon), color: color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
