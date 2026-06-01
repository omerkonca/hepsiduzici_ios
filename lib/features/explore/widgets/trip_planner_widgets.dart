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

/// Editör rotası kapak kartı
class TripEditorRouteCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(
                image: route.imageUrl.startsWith('assets/')
                    ? AssetImage(route.imageUrl)
                    : NetworkImage(route.imageUrl) as ImageProvider,
                fit: BoxFit.cover,
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.88),
                    ],
                    stops: const [0.35, 1.0],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: TripPlannerTheme.gold.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Editör Rotası ${index + 1}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF1A1508),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      route.name,
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
                      route.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _meta(Icons.place_rounded, route.regionLabel),
                        const SizedBox(width: 12),
                        _meta(Icons.schedule_rounded, route.durationHint),
                      ],
                    ),
                  ],
                ),
              ),
            ],
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
