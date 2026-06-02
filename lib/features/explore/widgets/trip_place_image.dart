import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../data/models/city_content.dart';
import '../../../data/services/place_image_policy.dart';
import 'trip_planner_theme.dart';

/// Planlayıcıda yalnızca içerikteki görsel kullanılır (Wikipedia API devre dışı).
class TripPlaceImage extends StatelessWidget {
  const TripPlaceImage({
    super.key,
    required this.place,
    this.width,
    this.height,
    this.borderRadius,
  });

  final ExplorePlace place;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final url = PlaceImagePolicy.safeContentImage(place);
    Widget child;
    if (url != null && url.isNotEmpty) {
      child = url.startsWith('assets/')
          ? Image.asset(url, width: width, height: height, fit: BoxFit.cover)
          : CachedNetworkImage(
              imageUrl: url,
              width: width,
              height: height,
              fit: BoxFit.cover,
              placeholder: (_, __) => _placeholder(),
              errorWidget: (_, __, ___) => _placeholder(),
            );
    } else {
      child = _placeholder();
    }
    if (borderRadius != null) {
      child = ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: TripPlannerTheme.surfaceElevated,
      child: const Icon(Icons.landscape_rounded, color: TripPlannerTheme.textSecondary, size: 28),
    );
  }
}
