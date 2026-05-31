import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/road_closure.dart';

/// Düziçi merkez — harita başlangıç noktası.
const kDuziciCenter = LatLng(37.0162, 36.4542);

class RoadClosureMap extends StatelessWidget {
  const RoadClosureMap({
    super.key,
    required this.closures,
    required this.selectedId,
    required this.onSelect,
  });

  final List<RoadClosure> closures;
  final String? selectedId;
  final ValueChanged<RoadClosure> onSelect;

  @override
  Widget build(BuildContext context) {
    final active = closures.where((c) => c.isActive && c.lat != 0 && c.lng != 0).toList();
    final points = active.map((c) => LatLng(c.lat, c.lng)).toList();

    LatLng center = kDuziciCenter;
    double zoom = 12.0;
    if (selectedId != null) {
      RoadClosure? sel;
      for (final c in closures) {
        if (c.id == selectedId) {
          sel = c;
          break;
        }
      }
      if (sel != null && sel.lat != 0) {
        center = LatLng(sel.lat, sel.lng);
        zoom = 14.0;
      }
    } else if (points.isNotEmpty) {
      center = LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 220,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: zoom,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hepsiduzici.app',
            ),
            if (points.isNotEmpty)
              MarkerLayer(
                markers: [
                  Marker(
                    point: kDuziciCenter,
                    width: 36,
                    height: 36,
                    child: const Icon(Icons.location_city_rounded, color: Color(0xFF5C6BC0), size: 28),
                  ),
                  ...active.map((c) {
                    final selected = c.id == selectedId;
                    final color = _severityColor(c.severity);
                    return Marker(
                      point: LatLng(c.lat, c.lng),
                      width: 44,
                      height: 44,
                      child: GestureDetector(
                        onTap: () => onSelect(c),
                        child: Container(
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: selected ? Colors.white : Colors.white70,
                              width: selected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.45),
                                blurRadius: selected ? 10 : 6,
                              ),
                            ],
                          ),
                          child: Icon(
                            _severityIcon(c.severity),
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
          ],
        ),
      ),
    );
  }

  static Color _severityColor(String severity) {
    switch (severity) {
      case 'full':
        return const Color(0xFFE53935);
      case 'maintenance':
        return const Color(0xFF43A047);
      default:
        return const Color(0xFFF5A623);
    }
  }

  static IconData _severityIcon(String severity) {
    switch (severity) {
      case 'full':
        return Icons.block_rounded;
      case 'maintenance':
        return Icons.construction_rounded;
      default:
        return Icons.alt_route_rounded;
    }
  }
}
