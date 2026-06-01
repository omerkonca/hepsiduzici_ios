import 'package:flutter/material.dart';

import '../../data/models/city_content.dart';
import '../utils/place_facility_labels.dart';

class PlaceFacilityChips extends StatelessWidget {
  const PlaceFacilityChips({super.key, required this.place, this.compact = false});

  final ExplorePlace place;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[];

    if (place.parking != null && place.parking != 'bilinmiyor') {
      chips.add(_chip(
        context,
        icon: PlaceFacilityLabels.parkingIcon(place.parking),
        label: PlaceFacilityLabels.parking(place.parking),
        positive: PlaceFacilityLabels.parkingPositive(place.parking),
      ));
    }

    if (place.restroom != null && place.restroom != 'bilinmiyor') {
      chips.add(_chip(
        context,
        icon: PlaceFacilityLabels.restroomIcon(place.restroom),
        label: PlaceFacilityLabels.restroom(place.restroom),
        positive: PlaceFacilityLabels.restroomPositive(place.restroom),
      ));
    }

    if (place.entryFee != null && place.entryFee != 'bilinmiyor') {
      chips.add(_chip(
        context,
        icon: PlaceFacilityLabels.entryFeeIcon(place.entryFee),
        label: PlaceFacilityLabels.entryFee(place.entryFee, note: place.entryFeeNote),
        positive: place.entryFee == 'ucretsiz' || place.entryFee == 'free',
        neutral: false,
      ));
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    if (compact) {
      return Wrap(spacing: 6, runSpacing: 6, children: chips);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: chips.map((c) => Padding(padding: const EdgeInsets.only(bottom: 8), child: c)).toList(),
    );
  }

  Widget _chip(
    BuildContext context, {
    required IconData icon,
    required String label,
    bool positive = false,
    bool neutral = true,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color fg;
    final Color bg;
    if (positive) {
      fg = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      bg = fg.withValues(alpha: 0.15);
    } else if (!neutral && label.contains('yok')) {
      fg = isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
      bg = fg.withValues(alpha: 0.12);
    } else {
      fg = isDark 
          ? const Color(0xFF9AA3B5) 
          : Theme.of(context).colorScheme.onSurfaceVariant;
      bg = isDark 
          ? const Color(0xFF1E2638) 
          : Theme.of(context).colorScheme.surfaceContainerHigh;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 6 : 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(compact ? 10 : 14),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(icon, size: compact ? 14 : 18, color: fg),
          SizedBox(width: compact ? 5 : 10),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 10 : 13,
                fontWeight: FontWeight.w700,
                color: fg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
