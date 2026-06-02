import 'package:flutter/material.dart';

import '../../../data/models/city_content.dart';
import '../../../data/providers/trip_planner_provider.dart';
import 'trip_place_image.dart';
import 'trip_planner_theme.dart';

/// Üst özet: süre · mesafe · bütçe
class TripRouteStatsBar extends StatelessWidget {
  const TripRouteStatsBar({
    super.key,
    required this.duration,
    required this.distance,
    required this.cost,
  });

  final String duration;
  final String distance;
  final String cost;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: TripPlannerTheme.surfaceCard(radius: 22),
      child: Row(
        children: [
          _StatCell(
            icon: Icons.schedule_rounded,
            label: 'Süre',
            value: duration,
          ),
          _divider(),
          _StatCell(
            icon: Icons.route_rounded,
            label: 'Mesafe',
            value: distance,
          ),
          _divider(),
          _StatCell(
            icon: Icons.payments_rounded,
            label: 'Bütçe',
            value: '$cost / Kişi',
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 36,
        color: Colors.white.withValues(alpha: 0.08),
      );
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 18, color: TripPlannerTheme.gold),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: TripPlannerTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
              color: TripPlannerTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Gradient palettes for editor route cards (no unreliable external images)
const _kRouteGradients = [
  [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],  // Deep navy – tarihi
  [Color(0xFF0D2137), Color(0xFF1B4332), Color(0xFF40916C)],  // Forest green – doğa
  [Color(0xFF2D1B33), Color(0xFF4A2040), Color(0xFF8B3A8B)],  // Royal purple – kale
  [Color(0xFF1A0A00), Color(0xFF5D2E0C), Color(0xFFD4AF37)],  // Amber gold – yayla
  [Color(0xFF0C1B33), Color(0xFF1A3A5C), Color(0xFF1E6FA6)],  // Ocean blue – arkeoloji
];

// Category icons for editor routes
const _kRouteIcons = [
  Icons.account_balance_rounded,   // tarihi
  Icons.water_rounded,             // doğa/nehir
  Icons.fort_rounded,              // kale
  Icons.landscape_rounded,         // yayla
  Icons.museum_rounded,            // müze/arkeoloji
];

/// Editör rotası kapak kartı — gradient + ikon (güvenilmez fotoğraf yok)
class TripEditorRouteCard extends StatefulWidget {
  const TripEditorRouteCard({
    super.key,
    required this.route,
    required this.onTap,
    required this.index,
  });

  final EditorRoute route;
  final VoidCallback onTap;
  final int index;

  @override
  State<TripEditorRouteCard> createState() => _TripEditorRouteCardState();
}

class _TripEditorRouteCardState extends State<TripEditorRouteCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.index % _kRouteGradients.length;
    final gradColors = _kRouteGradients[i];
    final routeIcon = _kRouteIcons[i];
    final stopCount = widget.route.placeNames.length;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) { setState(() => _pressed = false); widget.onTap(); },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 130),
        child: Container(
          height: 220,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradColors,
            ),
            boxShadow: [
              BoxShadow(
                color: gradColors.last.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                // Background decorative icon
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    routeIcon,
                    size: 160,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
                // Subtle grid pattern
                Positioned.fill(
                  child: CustomPaint(painter: _DotGridPainter()),
                ),
                // Gold badge top-left
                Positioned(
                  top: 14,
                  left: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: TripPlannerTheme.gold.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Editör Rotası ${widget.index + 1}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1A1508),
                      ),
                    ),
                  ),
                ),
                // Stop count badge top-right
                Positioned(
                  top: 14,
                  right: 14,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.place_rounded, size: 11, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '$stopCount durak',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Main content at bottom
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Route icon row
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                            ),
                            child: Icon(routeIcon, size: 20, color: Colors.white),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.route.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.route.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _meta(Icons.place_rounded, widget.route.regionLabel),
                          const SizedBox(width: 14),
                          _meta(Icons.schedule_rounded, widget.route.durationHint),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _DotGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;
    for (double x = 20; x < size.width; x += 30) {
      for (double y = 20; y < size.height; y += 30) {
        canvas.drawCircle(Offset(x, y), 1.5, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter _) => false;
}

/// Zaman tüneli durağı — beyaz kart + altın çizgi
class TripTimelineStop extends StatelessWidget {
  const TripTimelineStop({
    super.key,
    required this.index,
    required this.place,
    required this.isLast,
    required this.legKm,
    required this.legMinutes,
    required this.onTap,
  });

  final int index;
  final ExplorePlace place;
  final bool isLast;
  final double? legKm;
  final int? legMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              TripPlannerTheme.goldStepBadge(index + 1),
              TripPlannerTheme.timelineConnector(height: isLast ? 0 : 118, isLast: isLast),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    borderRadius: BorderRadius.circular(18),
                    child: Ink(
                      decoration: TripPlannerTheme.timelineCard(),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: TripPlaceImage(
                                place: place,
                                width: 72,
                                height: 72,
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFF3D6),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      place.tag.toUpperCase(),
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF8B6914),
                                        letterSpacing: 0.4,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    place.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 14,
                                      color: TripPlannerTheme.textOnCard,
                                      letterSpacing: -0.25,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    place.shortDescription,
                                    style: const TextStyle(
                                      fontSize: 11.5,
                                      color: TripPlannerTheme.textMutedOnCard,
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right_rounded,
                              color: TripPlannerTheme.goldMuted,
                              size: 22,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (!isLast && legKm != null) ...[
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.directions_car_filled_outlined,
                          size: 15,
                          color: TripPlannerTheme.textSecondary.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${legKm!.toStringAsFixed(1)} km (${legMinutes ?? 0} dk sürüş)',
                          style: const TextStyle(
                            color: TripPlannerTheme.textSecondary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ] else
                  const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
