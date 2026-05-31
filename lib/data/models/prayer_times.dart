class PrayerTimes {
  const PrayerTimes({
    required this.imsak,
    required this.gunes,
    required this.ogle,
    required this.ikindi,
    required this.aksam,
    required this.yatsi,
  });

  final String imsak;
  final String gunes;
  final String ogle;
  final String ikindi;
  final String aksam;
  final String yatsi;

  List<({String name, String time})> get allTimes => [
        (name: 'İmsak', time: imsak),
        (name: 'Güneş', time: gunes),
        (name: 'Öğle', time: ogle),
        (name: 'İkindi', time: ikindi),
        (name: 'Akşam', time: aksam),
        (name: 'Yatsı', time: yatsi),
      ];

  /// Sıradaki vakti bulur (basit string karşılaştırma).
  ({String name, String time})? nextPrayer(String currentTime) {
    final times = allTimes;
    for (final t in times) {
      if (t.time.compareTo(currentTime) > 0) return t;
    }
    return times.isNotEmpty ? times.first : null;
  }

  factory PrayerTimes.fromJson(Map<String, dynamic> json) {
    final times = json['timings'] as Map<String, dynamic>? ?? json;
    String get(String key) => (times[key] as String?)?.split(' ').first ?? '--:--';
    return PrayerTimes(
      imsak: get('Fajr'),
      gunes: get('Sunrise'),
      ogle: get('Dhuhr'),
      ikindi: get('Asr'),
      aksam: get('Maghrib'),
      yatsi: get('Isha'),
    );
  }
}
