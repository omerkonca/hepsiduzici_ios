import '../../data/models/obituary_item.dart';

class ObituaryHtmlParser {
  ObituaryHtmlParser._();

  static List<ObituaryItem> parseDuziciBelTr(String html) {
    final modals = <String, String>{};
    final modalRegex = RegExp(
      r'id="modal-(\d+)"[\s\S]*?modal-body">\s*<div>\s*<p>([\s\S]*?)</p>',
      multiLine: true,
    );
    for (final match in modalRegex.allMatches(html)) {
      final id = match.group(1);
      final text = match.group(2);
      if (id == null || text == null) continue;
      modals[id] = _cleanText(_stripTags(text));
    }

    final rowRegex = RegExp(
      r'<tr class="fs14">\s*<th[^>]*>([^<]+)</th>\s*<th[^>]*>([^<]+)</th>[\s\S]*?data-target="#modal-(\d+)"',
      multiLine: true,
    );

    final items = <ObituaryItem>[];
    for (final match in rowRegex.allMatches(html)) {
      final name = _cleanText(match.group(1) ?? '');
      final dateRaw = _cleanText(match.group(2) ?? '');
      final modalId = match.group(3);
      if (name.isEmpty || modalId == null) continue;

      final detail = modals[modalId] ?? '';
      final date = _parseFlexibleDate(dateRaw) ?? DateTime.now();
      items.add(
        ObituaryItem(
          id: 'duzici-bel-$modalId',
          fullName: name,
          deathDate: date,
          scope: ObituaryScope.duzici,
          detail: detail,
          district: 'Düziçi',
          neighborhood: _extractNeighborhood(detail),
          condolenceAddress: _extractCondolence(detail),
          burialPlace: _extractBurial(detail),
          source: 'Düziçi Belediyesi',
          sourceUrl: 'https://duzici.bel.tr/vefat-edenler',
        ),
      );
    }
    return items;
  }

  static List<ObituaryItem> parseOsmaniyeBelDaily(String html, {String? pageUrl}) {
    final items = <ObituaryItem>[];
    final dateMatch = RegExp(
      r'Cenaze Bilgi Sistemi\s*TARİH:\s*([^|<]+)',
      caseSensitive: false,
    ).firstMatch(html);
    final pageDate = _parseFlexibleDate(
      _cleanText(dateMatch?.group(1) ?? ''),
    );

    final blockRegex = RegExp(
      r'Adı\s*&\s*Soyadı\s*</td>\s*<td[^>]*>\s*([^<]+)\s*</td>[\s\S]*?'
      r'(?:Taziye Adresi\s*</td>\s*<td[^>]*>\s*([^<]*)\s*</td>)?[\s\S]*?'
      r'(?:Defin Yeri\s*</td>\s*<td[^>]*>\s*([^<]*)\s*</td>)?',
      caseSensitive: false,
      multiLine: true,
    );

    var index = 0;
    for (final match in blockRegex.allMatches(html)) {
      final name = _cleanText(match.group(1) ?? '');
      if (name.isEmpty) continue;
      final condolence = _cleanText(match.group(2) ?? '');
      final burial = _cleanText(match.group(3) ?? '');
      final scope = _scopeFromBurialOrCondolence(burial, condolence, name);

      items.add(
        ObituaryItem(
          id: 'osmaniye-bel-${pageUrl ?? 'page'}-$index',
          fullName: name,
          deathDate: pageDate ?? DateTime.now(),
          scope: scope,
          district: _extractDistrictFromLocation(burial, condolence),
          neighborhood: _extractNeighborhood('$condolence $burial'),
          condolenceAddress: condolence,
          burialPlace: burial,
          source: 'Osmaniye Belediyesi',
          sourceUrl: pageUrl ?? 'https://osmaniye-bld.gov.tr/kategori/vefaat',
        ),
      );
      index++;
    }
    return items;
  }

  static List<String> extractOsmaniyeDailyLinks(String html) {
    final links = <String>{};
    final regex = RegExp(
      r'href="([^"]*?(\d{1,2}-[a-zçğıöşü]+-\d{4}-[a-zçğıöşü]+)\.html)"',
      caseSensitive: false,
    );
    for (final match in regex.allMatches(html)) {
      final href = match.group(1);
      if (href == null || href.isEmpty) continue;
      links.add(_normalizeUrl(href, 'https://osmaniye-bld.gov.tr'));
    }
    return links.toList();
  }

  static List<ObituaryItem> parseCenazeIlanlariList(
    String html, {
    required ObituaryScope defaultScope,
    required String listUrl,
  }) {
    final items = <ObituaryItem>[];
    final regex = RegExp(
      r'href="(cenazeilani/[^"]+)"[\s\S]*?<b>([^<]+)</b>'
      r'(?:\s*<span[^>]*>\s*/\s*Yaş\s*:\s*(\d+)\s*</span>)?'
      r'[\s\S]*?c-showcase-box__subtitle[^>]*>\s*([^<]+)'
      r'[\s\S]*?>(\d{2}\.\d{2}\.\d{4})</div>',
      multiLine: true,
      caseSensitive: false,
    );

    var index = 0;
    for (final match in regex.allMatches(html)) {
      final slug = match.group(1) ?? '';
      final name = _cleanText(match.group(2) ?? '');
      final age = int.tryParse(match.group(3) ?? '');
      final location = _cleanText(match.group(4) ?? '');
      final dateRaw = match.group(5) ?? '';
      if (name.isEmpty) continue;

      final parts = location
          .split('/')
          .map((e) => _cleanText(e))
          .where((e) => e.isNotEmpty)
          .toList();
      final district = parts.length > 1 ? parts[1] : '';
      final neighborhood = parts.length > 2 ? parts[2] : '';
      final scope = _scopeFromDistrict(district, defaultScope);

      items.add(
        ObituaryItem(
          id: 'cenazeilan-$slug-$index',
          fullName: name,
          deathDate: _parseFlexibleDate(dateRaw) ?? DateTime.now(),
          scope: scope,
          district: district.isEmpty ? _scopeLabel(scope) : district,
          neighborhood: neighborhood,
          age: age,
          source: 'cenazeilanlari.com.tr',
          sourceUrl: listUrl,
          detailUrl: 'https://cenazeilanlari.com.tr/$slug',
        ),
      );
      index++;
    }
    return items;
  }

  static ObituaryScope _scopeFromBurialOrCondolence(
    String burial,
    String condolence,
    String name,
  ) {
    final text = '${burial.toLowerCase()} ${condolence.toLowerCase()}';
    if (text.contains('düziçi') || text.contains('duzici')) {
      return ObituaryScope.duzici;
    }
    return ObituaryScope.osmaniye;
  }

  static ObituaryScope _scopeFromDistrict(
    String district,
    ObituaryScope fallback,
  ) {
    final d = district.toLowerCase();
    if (d.contains('düziçi') || d.contains('duzici')) {
      return ObituaryScope.duzici;
    }
    if (district.isEmpty) return fallback;
    return ObituaryScope.osmaniye;
  }

  static String _scopeLabel(ObituaryScope scope) =>
      scope == ObituaryScope.duzici ? 'Düziçi' : 'Osmaniye';

  static String _extractDistrictFromLocation(String burial, String condolence) {
    final text = '$burial $condolence';
    if (text.toLowerCase().contains('düziçi')) return 'Düziçi';
    const districts = [
      'Kadirli',
      'Bahçe',
      'Sumbas',
      'Hasanbeyli',
      'Toprakkale',
      'Merkez',
    ];
    for (final d in districts) {
      if (text.toLowerCase().contains(d.toLowerCase())) return d;
    }
    return 'Osmaniye';
  }

  static String _extractNeighborhood(String text) {
    final mahalle = RegExp(
      r'([A-Za-zÇĞİÖŞÜçğıöşü\s]+)\s+Mahalles',
      caseSensitive: false,
    ).firstMatch(text);
    if (mahalle != null) return '${_cleanText(mahalle.group(1) ?? '')} Mahallesi';

    final belde = RegExp(
      r'([A-Za-zÇĞİÖŞÜçğıöşü\s]+)\s+Beldes',
      caseSensitive: false,
    ).firstMatch(text);
    if (belde != null) return '${_cleanText(belde.group(1) ?? '')} Beldesi';
    return '';
  }

  static String _extractCondolence(String detail) {
    if (detail.toLowerCase().contains('taziye yok')) return 'Taziye yok';
    return '';
  }

  static String _extractBurial(String detail) {
    final regex = RegExp(
      r'Cenazesi\s+(.+?)\s+defnedilecektir',
      caseSensitive: false,
    );
    final match = regex.firstMatch(detail);
    return _cleanText(match?.group(1) ?? '');
  }

  static DateTime? _parseFlexibleDate(String raw) {
    final text = _cleanText(raw).toLowerCase();
    if (text.isEmpty) return null;

    final iso = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (iso != null) {
      return DateTime(
        int.parse(iso.group(1)!),
        int.parse(iso.group(2)!),
        int.parse(iso.group(3)!),
      );
    }

    final dotted = RegExp(r'(\d{1,2})\.(\d{1,2})\.(\d{4})').firstMatch(text);
    if (dotted != null) {
      return DateTime(
        int.parse(dotted.group(3)!),
        int.parse(dotted.group(2)!),
        int.parse(dotted.group(1)!),
      );
    }

    return null;
  }

  static String _normalizeUrl(String href, String base) {
    if (href.startsWith('http')) return href;
    if (href.startsWith('/')) return '$base$href';
    return '$base/$href';
  }

  static String _stripTags(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&ouml;', 'ö')
        .replaceAll('&uuml;', 'ü')
        .replaceAll('&ccedil;', 'ç')
        .replaceAll('&rsquo;', "'")
        .replaceAll('&ldquo;', '"')
        .replaceAll('&rdquo;', '"');
  }

  static String _cleanText(String value) {
    return _stripTags(value)
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
