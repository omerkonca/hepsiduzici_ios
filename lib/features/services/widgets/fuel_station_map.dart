import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../data/models/fuel_price.dart';
import 'road_closure_map.dart';

class FuelStationMap extends StatelessWidget {
  const FuelStationMap({
    super.key,
    required this.stations,
    required this.selectedId,
    required this.onSelect,
  });

  final List<FuelStationItem> stations;
  final String? selectedId;
  final ValueChanged<FuelStationItem> onSelect;

  @override
  Widget build(BuildContext context) {
    final mapped = stations.where((s) => s.hasCoords).toList();
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
                    width: 42,
                    height: 42,
                    child: GestureDetector(
                      onTap: () => onSelect(s),
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF4511E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? Colors.white : Colors.white70,
                            width: selected ? 3 : 1.5,
                          ),
                        ),
                        child: const Icon(Icons.local_gas_station_rounded, color: Colors.white, size: 20),
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
