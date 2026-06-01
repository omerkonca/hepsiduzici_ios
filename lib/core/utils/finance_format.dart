import 'package:intl/intl.dart';
import '../../data/models/finance_quote.dart';

/// Piyasa verileri için Türkçe (₺) gösterim.
class FinanceFormat {
  FinanceFormat._();

  static final NumberFormat _fx = NumberFormat('#,##0.00', 'tr_TR');
  static final NumberFormat _metal = NumberFormat('#,##0.00', 'tr_TR');
  static final NumberFormat _goldGram = NumberFormat('#,##0', 'tr_TR');

  static String formatValue(FinanceQuote quote) {
    final code = quote.code.toUpperCase();
    switch (code) {
      case 'USD':
      case 'EUR':
        return _fx.format(quote.value);
      case 'GOLD':
        return _goldGram.format(quote.value.round());
      case 'SILVER':
        return _metal.format(quote.value);
      default:
        if (quote.value >= 1000) return _goldGram.format(quote.value.round());
        if (quote.value >= 100) return _goldGram.format(quote.value.round());
        return _metal.format(quote.value);
    }
  }

  static String unitSuffix(FinanceQuote quote) => ' ₺';
}
