/// Goreceli zaman formatlama yardimcilari (Turkce).
class RelativeTime {
  static const _months = [
    'Oca', 'Şub', 'Mar', 'Nis', 'May', 'Haz',
    'Tem', 'Ağu', 'Eyl', 'Eki', 'Kas', 'Ara',
  ];

  /// "az önce", "5 dk önce", "2 sa önce", "Dün 14:30", "12 Nis 09:15" gibi.
  static String format(DateTime fetchedAt, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(fetchedAt);

    if (diff.inSeconds < 30) return 'az önce';
    if (diff.inSeconds < 60) return '${diff.inSeconds} sn önce';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün ${_hhmm(fetchedAt)}';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';

    final isSameYear = n.year == fetchedAt.year;
    final dayMonth = '${fetchedAt.day} ${_months[fetchedAt.month - 1]}';
    if (isSameYear) return '$dayMonth ${_hhmm(fetchedAt)}';
    return '$dayMonth ${fetchedAt.year}';
  }

  /// "14:35" tarzi sade saat.
  static String hhmm(DateTime t) => _hhmm(t);

  /// "30.04.2026 14:35" tam tarih+saat.
  static String full(DateTime t) {
    final d = t.day.toString().padLeft(2, '0');
    final m = t.month.toString().padLeft(2, '0');
    return '$d.$m.${t.year} ${_hhmm(t)}';
  }

  static String _hhmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}
