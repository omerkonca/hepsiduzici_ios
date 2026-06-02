import 'package:flutter_test/flutter_test.dart';
import 'package:hepsi_duzici/data/models/city_content.dart';
import 'package:hepsi_duzici/data/services/place_image_policy.dart';

ExplorePlace _place(String name, {String? imageUrl}) => ExplorePlace(
      name: name,
      shortDescription: 'kisa',
      detail: 'detay',
      address: 'adres',
      tag: 'TEST',
      imageUrl: imageUrl,
    );

void main() {
  group('PlaceImagePolicy', () {
    test('returns approved override for known place', () {
      final p = _place('Düziçi Ulu Cami', imageUrl: 'https://example.com/wrong.jpg');
      final resolved = PlaceImagePolicy.safeContentImage(p);
      expect(resolved, contains('upload.wikimedia.org'));
    });

    test('rejects non-trusted image hosts', () {
      final p = _place('Bilinmeyen Yer', imageUrl: 'https://random.example.com/a.jpg');
      final resolved = PlaceImagePolicy.safeContentImage(p);
      expect(resolved, isNull);
    });

    test('accepts trusted image hosts', () {
      final p = _place(
        'Bilinmeyen Yer',
        imageUrl: 'https://upload.wikimedia.org/wikipedia/commons/a/a0/test.jpg',
      );
      final resolved = PlaceImagePolicy.safeContentImage(p);
      expect(resolved, isNotNull);
    });
  });
}
