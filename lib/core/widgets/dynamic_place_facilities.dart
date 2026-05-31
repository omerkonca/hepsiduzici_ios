import 'package:flutter/material.dart';

import '../../data/models/city_content.dart';
import '../../data/services/place_meta_service.dart';
import 'place_facility_chips.dart';

/// OpenStreetMap + Wikipedia üzerinden canlı otopark / WC / ücret bilgisi.
class DynamicPlaceFacilities extends StatefulWidget {
  const DynamicPlaceFacilities({
    super.key,
    required this.place,
    this.compact = false,
    this.showSourceNote = true,
  });

  final ExplorePlace place;
  final bool compact;
  final bool showSourceNote;

  @override
  State<DynamicPlaceFacilities> createState() => _DynamicPlaceFacilitiesState();
}

class _DynamicPlaceFacilitiesState extends State<DynamicPlaceFacilities> {
  final _service = PlaceMetaService();
  PlaceMeta? _meta;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final meta = await _service.fetch(widget.place);
    if (!mounted) return;
    setState(() {
      _meta = meta;
      _loading = false;
      _failed = meta == null;
    });
  }

  ExplorePlace get _displayPlace {
    if (_meta == null) return widget.place;
    return ExplorePlace(
      name: widget.place.name,
      shortDescription: widget.place.shortDescription,
      detail: widget.place.detail,
      address: widget.place.address,
      tag: widget.place.tag,
      imageUrl: widget.place.imageUrl,
      videoUrl: widget.place.videoUrl,
      gallery: widget.place.gallery,
      lat: _meta!.lat ?? widget.place.lat,
      lng: _meta!.lng ?? widget.place.lng,
      parking: _meta!.parking,
      restroom: _meta!.restroom,
      entryFee: _meta!.entryFee,
      entryFeeNote: _meta!.entryFeeNote ?? widget.place.entryFeeNote,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: widget.compact ? 4 : 12),
        child: Row(
          children: [
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Text(
              'Canlı tesis bilgisi yükleniyor…',
              style: TextStyle(
                fontSize: widget.compact ? 10 : 12,
                color: Theme.of(context).textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PlaceFacilityChips(place: _displayPlace, compact: widget.compact),
        if (widget.showSourceNote && !_failed) ...[
          const SizedBox(height: 6),
          Text(
            'Kaynak: OpenStreetMap haritası (ücretsiz, API anahtarı gerekmez)',
            style: TextStyle(
              fontSize: 10,
              fontStyle: FontStyle.italic,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
        if (_failed) ...[
          const SizedBox(height: 4),
          Text(
            'Canlı veri alınamadı; yerel kayıt gösteriliyor.',
            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
