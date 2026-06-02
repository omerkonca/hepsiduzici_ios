import 'package:flutter_test/flutter_test.dart';
import 'package:hepsi_duzici/data/json_parse_utils.dart';

void main() {
  group('JsonParseUtils.mapList', () {
    test('returns empty when raw is not list', () {
      final out = JsonParseUtils.mapList<String>({}, (json) => json['name'] as String);
      expect(out, isEmpty);
    });

    test('skips malformed items and keeps valid ones', () {
      final raw = [
        {'name': 'A'},
        'invalid',
        {'bad': true},
        {'name': 'B'},
      ];

      final out = JsonParseUtils.mapList<String>(
        raw,
        (json) {
          final name = json['name'] as String?;
          if (name == null) throw const FormatException('missing name');
          return name;
        },
      );

      expect(out, ['A', 'B']);
    });
  });
}
