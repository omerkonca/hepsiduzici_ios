import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/relative_time.dart';
import '../../../data/models/finance_quote.dart';
import '../../../core/utils/target_router.dart';
import '../../../data/models/fuel_price.dart';
import '../../../data/models/prayer_times.dart';
import '../../../core/utils/weather_wmo_tr.dart';
import '../../../data/models/stamped_data.dart';
import '../../../data/models/weather_report.dart';
import '../../prayer/prayer_screen.dart' show PrayerScreen;
import '../../weather/weather_screen.dart';
import 'weather_widget.dart';

/// Tam genislikte tek kart, sayfa sayfa kaydirilir.
/// Kartlar:
///   1) Hava Durumu
///   2) Sıradaki Namaz Vakti
///   3) Piyasa Verileri (dokununca acilir/kapanir)
///   4) Akaryakit Fiyatlari (dokununca acilir/kapanir)
class HighlightsStrip extends ConsumerStatefulWidget {
  const HighlightsStrip({super.key});

  @override
  ConsumerState<HighlightsStrip> createState() => _HighlightsStripState();
}

class _HighlightsStripState extends ConsumerState<HighlightsStrip> {
  static const int _weatherPageIndex = 0;
  static const int _financePageIndex = 2;
  static const int _fuelPageIndex = 3;
  static const double _collapsedHeight = 76;

  final PageController _controller = PageController();
  int _index = 0;
  bool _weatherExpanded = false;
  bool _financeExpanded = false;
  bool _fuelExpanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }


  void _onPageChanged(int i) {
    setState(() {
      _index = i;
      if (i != _weatherPageIndex) _weatherExpanded = false;
      if (i != _financePageIndex) _financeExpanded = false;
      if (i != _fuelPageIndex) _fuelExpanded = false;
    });
  }

  void _toggleWeather() {
    setState(() => _weatherExpanded = !_weatherExpanded);
  }

  void _toggleFinance() {
    setState(() => _financeExpanded = !_financeExpanded);
  }

  void _toggleFuel() {
    setState(() => _fuelExpanded = !_fuelExpanded);
  }

  void _openWeather() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Hava Durumu')),
          body: const WeatherScreen(),
        ),
      ),
    );
  }

  void _openPrayer() {
    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: const Text('Namaz Vakitleri')),
          body: const PrayerScreen(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Saniyelik tik (live "X dk önce" guncelle)
    final tickAsync = ref.watch(nowTickerProvider);
    final now = tickAsync.maybeWhen(data: (t) => t, orElse: () => DateTime.now());

    final weatherAsync = ref.watch(stampedWeatherProvider);
    final prayerAsync = ref.watch(stampedPrayerProvider);
    final financeAsync = ref.watch(stampedFinanceProvider);
    final fuelAsync = ref.watch(stampedFuelProvider);

    final financeStamped = financeAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    final fuelStamped = fuelAsync.maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    final quotes = financeStamped?.data ?? const <FinanceQuote>[];
    final fuelList = fuelStamped?.data ?? const <FuelPrice>[];
    final weatherReport = weatherAsync.maybeWhen(
      data: (s) => s.data,
      orElse: () => null,
    );

    const cardCount = 4;

    double height = _collapsedHeight;
    if (_index == _weatherPageIndex && _weatherExpanded) {
      height = _collapsedHeight + _weatherExpandedExtra(weatherReport);
    } else if (_index == _financePageIndex && _financeExpanded) {
      height = _collapsedHeight + 16 + (quotes.length * 40.0) + 24;
    } else if (_index == _fuelPageIndex && _fuelExpanded) {
      height = _collapsedHeight + 16 + (fuelList.length * 40.0) + 24;
    }

    final lockSwipe = _weatherExpanded || _financeExpanded || _fuelExpanded;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          child: SizedBox(
            height: height,
            child: PageView(
              controller: _controller,
              onPageChanged: _onPageChanged,
              physics: lockSwipe
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              children: [
                _padded(_weatherCard(weatherAsync, now)),
                _padded(_prayerCard(prayerAsync, now)),
                _padded(_financeCard(financeStamped, financeAsync.isLoading, now)),
                _padded(_fuelCard(fuelStamped, fuelAsync.isLoading, now)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        _Dots(count: cardCount, current: _index),
      ],
    );
  }

  Widget _padded(Widget child) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: child);

  /// Genişletilmiş hava kartı gövdesi için tahmini yükseklik.
  static double _weatherExpandedExtra(WeatherReport? report) {
    var extra = 150.0;
    if (report?.daily.isNotEmpty ?? false) extra += 80;
    return extra + 56; // damga, bağlantı, güvenlik payı
  }

  String _stamp(DateTime fetchedAt, DateTime now) =>
      RelativeTime.format(fetchedAt, now: now);

  Widget _weatherCard(AsyncValue<Stamped<WeatherReport>> async, DateTime now) {
    final stamped = async.maybeWhen(data: (s) => s, orElse: () => null);
    final code = stamped?.data.current.conditionCode ?? 2;
    final theme = weatherVisualTheme(code);
    final precip = precipitationLevelTr(code);
    final value = async.when(
      data: (s) => '${s.data.current.temperature.round()}°C',
      loading: () => '...',
      error: (_, __) => '--',
    );
    final sub = async.when(
      data: (s) {
        final w = s.data.current;
        final wind = windSummaryTr(w.windSpeed, w.windGust);
        final detail = precip == null ? wind : '$wind · $precip';
        return '${w.conditionLabel} · $detail · ${_stamp(s.fetchedAt, now)}';
      },
      loading: () => 'Yükleniyor',
      error: (_, __) => 'Veri yok',
    );
    return _WeatherHighlightCard(
      weatherCode: code,
      label: 'Hava Durumu',
      value: value,
      sub: sub,
      gradient: [theme.gradientStart, theme.gradientEnd],
      expanded: _weatherExpanded,
      report: stamped?.data,
      fetchedAt: stamped?.fetchedAt,
      now: now,
      loading: async.isLoading && stamped == null,
      onTap: stamped?.data != null ? _toggleWeather : null,
      onOpenFull: _openWeather,
    );
  }

  Widget _prayerCard(AsyncValue<Stamped<PrayerTimes>> async, DateTime now) {
    final value = async.when(
      data: (s) {
        final p = s.data;
        final cur = RelativeTime.hhmm(now);
        return (p.nextPrayer(cur) ?? p.allTimes.first).time;
      },
      loading: () => '--:--',
      error: (_, __) => '--:--',
    );
    final sub = async.when(
      data: (s) {
        final p = s.data;
        final cur = RelativeTime.hhmm(now);
        final name = (p.nextPrayer(cur) ?? p.allTimes.first).name;
        return '$name · ${_stamp(s.fetchedAt, now)}';
      },
      loading: () => 'Yükleniyor',
      error: (_, __) => 'Vakit yok',
    );
    return _SimpleHighlightCard(
      icon: Icons.mosque_rounded,
      label: 'Sıradaki Vakit',
      value: value,
      sub: sub,
      gradient: const [Color(0xFF1E8A53), Color(0xFF3FAE73)],
      onTap: _openPrayer,
    );
  }

  Widget _financeCard(Stamped<List<FinanceQuote>>? stamped, bool loading, DateTime now) {
    return _FinanceHighlightCard(
      quotes: stamped?.data ?? const [],
      fetchedAt: stamped?.fetchedAt,
      now: now,
      expanded: _financeExpanded,
      loading: loading && (stamped?.data.isEmpty ?? true),
      onTap: () {
        if ((stamped?.data ?? const []).isEmpty) return;
        _toggleFinance();
      },
    );
  }

  Widget _fuelCard(Stamped<List<FuelPrice>>? stamped, bool loading, DateTime now) {
    return _FuelHighlightCard(
      prices: stamped?.data ?? const [],
      fetchedAt: stamped?.fetchedAt,
      now: now,
      expanded: _fuelExpanded,
      loading: loading && (stamped?.data.isEmpty ?? true),
      onTap: () {
        if ((stamped?.data ?? const []).isEmpty) return;
        _toggleFuel();
      },
      onOpenDetail: (stamped?.data ?? const []).isEmpty
          ? null
          : () => TargetRouter.handle(context, 'screen:fuel'),
    );
  }
}

class _WeatherHighlightCard extends StatelessWidget {
  const _WeatherHighlightCard({
    required this.weatherCode,
    required this.label,
    required this.value,
    required this.sub,
    required this.gradient,
    required this.expanded,
    required this.now,
    required this.loading,
    this.report,
    this.fetchedAt,
    this.onTap,
    this.onOpenFull,
  });

  final int weatherCode;
  final String label;
  final String value;
  final String sub;
  final List<Color> gradient;
  final bool expanded;
  final WeatherReport? report;
  final DateTime? fetchedAt;
  final DateTime now;
  final bool loading;
  final VoidCallback? onTap;
  final VoidCallback? onOpenFull;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    _IconBadge(
                      icon: weatherCodeIcon(weatherCode),
                      weatherCode: weatherCode,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            expanded && report != null
                                ? report!.location
                                : label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            expanded && report != null
                                ? report!.current.conditionText
                                : sub,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        duration: const Duration(milliseconds: 240),
                        turns: expanded ? 0.5 : 0,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 26,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (expanded && report != null) ...[
                const SizedBox(height: 6),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                ),
                const SizedBox(height: 8),
                WeatherExpandableDetails(
                  report: report!,
                  showLocationHeader: false,
                ),
                if (fetchedAt != null) _StampFooter(fetchedAt: fetchedAt!, now: now),
                if (onOpenFull != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: onOpenFull,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Tam hava durumu',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontWeight: FontWeight.w700,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 13,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ] else if (loading) ...[
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  color: Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(2),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SimpleHighlightCard extends StatelessWidget {
  const _SimpleHighlightCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.gradient,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final String sub;
  final List<Color> gradient;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: 0.25),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              _IconBadge(icon: icon),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: 6),
                Icon(Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.85), size: 22),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceHighlightCard extends StatelessWidget {
  const _FinanceHighlightCard({
    required this.quotes,
    required this.fetchedAt,
    required this.now,
    required this.expanded,
    required this.loading,
    required this.onTap,
  });

  final List<FinanceQuote> quotes;
  final DateTime? fetchedAt;
  final DateTime now;
  final bool expanded;
  final bool loading;
  final VoidCallback onTap;

  static const _gradient = [Color(0xFF6E2BE6), Color(0xFF9B5BFF)];

  @override
  Widget build(BuildContext context) {
    final summary = _summary(quotes, fetchedAt, now, loading);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: _gradient.first.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    const _IconBadge(icon: Icons.show_chart_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Piyasa Verileri',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 240),
                      turns: expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded && quotes.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                ...quotes.map((q) => _FinanceRow(quote: q)),
                if (fetchedAt != null) _StampFooter(fetchedAt: fetchedAt!, now: now),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _summary(List<FinanceQuote> quotes, DateTime? fetchedAt, DateTime now, bool loading) {
    if (loading) return 'Yükleniyor...';
    if (quotes.isEmpty) return 'Veri bekleniyor';
    final names = quotes.map((q) => q.code.toUpperCase()).join(' • ');
    if (fetchedAt == null) return names;
    return '$names · ${RelativeTime.format(fetchedAt, now: now)}';
  }
}

class _FuelHighlightCard extends StatelessWidget {
  const _FuelHighlightCard({
    required this.prices,
    required this.fetchedAt,
    required this.now,
    required this.expanded,
    required this.loading,
    required this.onTap,
    this.onOpenDetail,
  });

  final List<FuelPrice> prices;
  final DateTime? fetchedAt;
  final DateTime now;
  final bool expanded;
  final bool loading;
  final VoidCallback onTap;
  final VoidCallback? onOpenDetail;

  static const _gradient = [Color(0xFFE25C2A), Color(0xFFF38755)];

  @override
  Widget build(BuildContext context) {
    final summary = _summary(prices, fetchedAt, now, loading);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: _gradient,
            ),
            boxShadow: [
              BoxShadow(
                color: _gradient.first.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 52,
                child: Row(
                  children: [
                    const _IconBadge(icon: Icons.local_gas_station_rounded),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Akaryakıt Fiyatları',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontWeight: FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 240),
                      turns: expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: Colors.white.withValues(alpha: 0.9),
                        size: 26,
                      ),
                    ),
                  ],
                ),
              ),
              if (expanded && prices.isNotEmpty) ...[
                const SizedBox(height: 4),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.18),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                ),
                ...prices.map((p) => _FuelRow(price: p)),
                if (onOpenDetail != null)
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: onOpenDetail,
                      child: Text(
                        'Detaylı gör',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                if (fetchedAt != null) _StampFooter(fetchedAt: fetchedAt!, now: now),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static String _summary(List<FuelPrice> prices, DateTime? fetchedAt, DateTime now, bool loading) {
    if (loading) return 'Yükleniyor...';
    if (prices.isEmpty) return 'Veri bekleniyor';
    final codes = prices.map((p) => p.code.toUpperCase()).join(' • ');
    if (fetchedAt == null) return codes;
    return '$codes · ${RelativeTime.format(fetchedAt, now: now)}';
  }
}

class _FuelRow extends StatelessWidget {
  const _FuelRow({required this.price});
  final FuelPrice price;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(_iconFor(price.code),
              color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              price.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            '₺${price.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              price.unit,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String code) {
    switch (code.toUpperCase()) {
      case 'GASOLINE':
        return Icons.local_gas_station_rounded;
      case 'DIESEL':
        return Icons.local_shipping_rounded;
      case 'LPG':
        return Icons.propane_tank_rounded;
      default:
        return Icons.local_gas_station_rounded;
    }
  }
}

class _FinanceRow extends StatelessWidget {
  const _FinanceRow({required this.quote});
  final FinanceQuote quote;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Icon(_iconFor(quote.code),
              color: Colors.white.withValues(alpha: 0.9), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              quote.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          Text(
            _formatValue(quote.value),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 14,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (quote.isUp
                      ? const Color(0xFF1FCB7A)
                      : const Color(0xFFE5484D))
                  .withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  quote.isUp
                      ? Icons.arrow_drop_up_rounded
                      : Icons.arrow_drop_down_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                Text(
                  '${quote.changePercent.abs().toStringAsFixed(2)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String code) {
    switch (code.toUpperCase()) {
      case 'USD':
        return Icons.attach_money_rounded;
      case 'EUR':
        return Icons.euro_rounded;
      case 'GOLD':
        return Icons.workspace_premium_rounded;
      case 'SILVER':
        return Icons.shield_moon_rounded;
      default:
        return Icons.show_chart_rounded;
    }
  }

  static String _formatValue(double v) {
    if (v >= 100) {
      return v.toStringAsFixed(0).replaceAllMapped(
            RegExp(r'(\d)(?=(\d{3})+$)'),
            (m) => '${m[1]}.',
          );
    }
    return v.toStringAsFixed(2);
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, this.weatherCode});
  final IconData icon;
  final int? weatherCode;

  @override
  Widget build(BuildContext context) {
    final bg = weatherCode == null
        ? Colors.white.withValues(alpha: 0.18)
        : weatherVisualTheme(weatherCode!).iconBackground;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: weatherCode == null
            ? Icon(icon, color: Colors.white, size: 22)
            : WeatherAnimatedIcon(conditionCode: weatherCode!, size: 22),
      ),
    );
  }
}

class _StampFooter extends StatelessWidget {
  const _StampFooter({required this.fetchedAt, required this.now});
  final DateTime fetchedAt;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Icon(Icons.access_time_rounded,
              size: 11, color: Colors.white.withValues(alpha: 0.75)),
          const SizedBox(width: 4),
          Text(
            'Son güncelleme: ${RelativeTime.format(fetchedAt, now: now)} (${RelativeTime.hhmm(fetchedAt)})',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontWeight: FontWeight.w600,
              fontSize: 10,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.current});
  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 6,
          height: 6,
          decoration: BoxDecoration(
            color: active ? AppColors.primaryDark : Theme.of(context).disabledColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }),
    );
  }
}
