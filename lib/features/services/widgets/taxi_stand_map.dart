import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/city_content.dart';
import 'road_closure_map.dart';

class TaxiStandMap extends StatelessWidget {
  const TaxiStandMap({
    super.key,
    required this.stands,
    required this.selectedId,
    required this.onSelect,
  });

  final List<TaxiStandItem> stands;
  final String? selectedId;
  final ValueChanged<TaxiStandItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final mapped = stands.where((s) => s.hasCoords).toList();
    final points = mapped.map((s) => LatLng(s.lat!, s.lng!)).toList();

    var center = kDuziciCenter;
    var zoom = 12.0;
    if (selectedId != null) {
      for (final s in mapped) {
        if (s.id == selectedId) {
          center = LatLng(s.lat!, s.lng!);
          zoom = 14.0;
          break;
        }
      }
    } else if (points.length == 1) {
      center = points.first;
      zoom = 14.0;
    } else if (points.length > 1) {
      center = LatLng(
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length,
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length,
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        height: 200,
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
            if (mapped.isNotEmpty)
              MarkerLayer(
                markers: mapped.map((s) {
                  final selected = s.id == selectedId;
                  return Marker(
                    point: LatLng(s.lat!, s.lng!),
                    width: 44,
                    height: 44,
                    child: GestureDetector(
                      onTap: () => onSelect(s),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFA726),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white70,
                            width: selected ? 3 : 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFFA726).withValues(alpha: selected ? 0.55 : 0.35),
                              blurRadius: selected ? 10 : 6,
                            ),
                          ],
                        ),
                        child: const Icon(Icons.local_taxi_rounded, color: Colors.white, size: 22),
                      ),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}
