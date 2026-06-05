import 'package:flutter/material.dart';

import '../../../core/theme/premium_city_theme.dart';
import '../../../core/utils/target_router.dart';

class CityToolsGrid extends StatelessWidget {
  const CityToolsGrid({super.key});

  @override
  Widget build(BuildContext context) {
    const tools = [
      _ToolItem('Belediye', Icons.account_balance_rounded,
          Color(0xFF2E7D32), 'screen:municipality'),
      _ToolItem('Ulaşım', Icons.directions_bus_filled_rounded,
          Color(0xFF2563EB), 'screen:transport'),
      _ToolItem('Taksi', Icons.local_taxi_rounded, Color(0xFFE5A800),
          'screen:taxi'),
      _ToolItem('Acil Durum', Icons.phone_in_talk_rounded,
          Color(0xFFE11D48), 'screen:emergency'),
      _ToolItem('Kesintiler', Icons.bolt_rounded, Color(0xFFF97316),
          'screen:outages'),
      _ToolItem('Kapalı Yollar', Icons.route_rounded, Color(0xFF7C3AED),
          'screen:closed_roads'),
      _ToolItem('Sağlık', Icons.local_hospital_rounded, Color(0xFF0D9488),
          'screen:health'),
      _ToolItem('Akaryakıt', Icons.local_gas_station_rounded,
          Color(0xFF059669), 'screen:fuel'),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF2)),
        boxShadow: PremiumCityTheme.softShadow(alpha: 0.06),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Araçlar',
            style: TextStyle(
              color: PremiumCityTheme.ink,
              fontSize: PremiumCityTheme.sectionTitleSize,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            itemCount: tools.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 6,
              mainAxisExtent: 76,
            ),
            itemBuilder: (context, index) => _ToolCard(item: tools[index]),
          ),
        ],
      ),
    );
  }
}

class _ToolCard extends StatelessWidget {
  const _ToolCard({required this.item});

  final _ToolItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => TargetRouter.handle(context, item.target),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(item.icon, color: item.color, size: 21),
          ),
          const SizedBox(height: 5),
          Text(
            item.title,
            maxLines: 2,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: PremiumCityTheme.ink,
              fontSize: 9.5,
              height: 1.15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolItem {
  const _ToolItem(this.title, this.icon, this.color, this.target);

  final String title;
  final IconData icon;
  final Color color;
  final String target;
}
