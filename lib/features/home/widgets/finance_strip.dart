import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/finance_format.dart';
import '../../../data/models/finance_quote.dart';

class FinanceStrip extends ConsumerWidget {
  const FinanceStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(financeQuotesProvider);
    return SizedBox(
      height: 110,
      child: async.when(
        data: (list) => _buildList(context, list),
        loading: () => const Center(
          child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        error: (_, __) => _buildError(context, ref),
      ),
    );
  }

  Widget _buildList(BuildContext context, List<FinanceQuote> list) {
    if (list.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(width: 10),
      itemBuilder: (context, i) => _FinanceCard(quote: list[i]),
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref) {
    return Center(
      child: TextButton.icon(
        onPressed: () => ref.invalidate(financeQuotesProvider),
        icon: const Icon(Icons.refresh_rounded, size: 18),
        label: const Text('Finans verisi yüklenemedi · tekrar dene'),
      ),
    );
  }
}

class _FinanceCard extends StatelessWidget {
  const _FinanceCard({required this.quote});
  final FinanceQuote quote;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(quote.code);
    final icon = _iconFor(quote.code);
    final isUp = quote.isUp;
    final changeColor = isUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828);
    return Container(
      width: 142,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softGrey.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  quote.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          Text(
            '${FinanceFormat.formatValue(quote)}${FinanceFormat.unitSuffix(quote)}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
              letterSpacing: -0.5,
            ),
          ),
          Row(
            children: [
              Icon(
                isUp ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                color: changeColor,
                size: 18,
              ),
              Text(
                '${quote.changePercent.abs().toStringAsFixed(2)}%',
                style: TextStyle(
                  color: changeColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return Icons.attach_money_rounded;
      case 'EUR':
        return Icons.euro_rounded;
      case 'GOLD':
        return Icons.workspace_premium_rounded;
      case 'SILVER':
        return Icons.shield_moon_rounded;
      default:
        return Icons.show_chart_rounded;
    }
  }

  static Color _colorFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return const Color(0xFF2E7D32);
      case 'EUR':
        return const Color(0xFF1565C0);
      case 'GOLD':
        return const Color(0xFFC98B18);
      case 'SILVER':
        return const Color(0xFF607D8B);
      default:
        return AppColors.primary;
    }
  }
}
