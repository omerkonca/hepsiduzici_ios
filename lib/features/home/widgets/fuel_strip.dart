import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/models/fuel_price.dart';

class FuelStrip extends ConsumerWidget {
  const FuelStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(fuelPricesProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: async.when(
        data: (list) {
          if (list.isEmpty) return const SizedBox.shrink();
          return Row(
            children: [
              for (var i = 0; i < list.length; i++) ...[
                Expanded(child: _FuelCard(price: list[i])),
                if (i < list.length - 1) const SizedBox(width: 10),
              ],
            ],
          );
        },
        loading: () => const SizedBox(
          height: 90,
          child: Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))),
        ),
        error: (_, __) => Center(
          child: TextButton.icon(
            onPressed: () => ref.invalidate(fuelPricesProvider),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Akaryakıt fiyatları yüklenemedi'),
          ),
        ),
      ),
    );
  }
}

class _FuelCard extends StatelessWidget {
  const _FuelCard({required this.price});
  final FuelPrice price;

  @override
  Widget build(BuildContext context) {
    final color = _colorFor(price.code);
    final icon = _iconFor(price.code);
    return Container(
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
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(height: 8),
          Text(
            price.name,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price.price.toStringAsFixed(2),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                price.unit,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String code) {
    switch (code.toUpperCase()) {
      case 'GASOLINE':
        return Icons.local_gas_station_rounded;
      case 'DIESEL':
        return Icons.local_shipping_rounded;
      case 'LPG':
        return Icons.propane_tank_rounded;
      default:
        return Icons.local_gas_station_rounded;
    }
  }

  static Color _colorFor(String code) {
    switch (code.toUpperCase()) {
      case 'GASOLINE':
        return const Color(0xFFE53935);
      case 'DIESEL':
        return const Color(0xFF1565C0);
      case 'LPG':
        return const Color(0xFF6A1B9A);
      default:
        return AppColors.primary;
    }
  }
}
