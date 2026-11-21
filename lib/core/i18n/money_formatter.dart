import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats integer minor-unit amounts without converting stored values to doubles.
class MoneyFormatter {
  const MoneyFormatter._();
  static final Map<String, int> _minorUnits = {};

  static void registerMinorUnits(Map<String, int> values) => _minorUnits.addAll(values);

  static String format({required int amountMinor, required String currencyCode, required Locale locale}) {
    final digits = _minorUnits[currencyCode] ?? 2;
    final factor = _pow10(digits);
    final formatter = NumberFormat.simpleCurrency(locale: locale.toLanguageTag(), name: currencyCode, decimalDigits: digits);
    final absoluteMinor = amountMinor.abs();
    final whole = absoluteMinor ~/ factor;
    final fraction = (absoluteMinor % factor).toString().padLeft(digits, '0');
    final formattedWhole = formatter.format(whole);
    final separator = formatter.symbols.DECIMAL_SEP;
    final separatorIndex = formattedWhole.lastIndexOf(separator);
    final decimals = formatter.decimalDigits ?? digits;
    final suffixStart = separatorIndex + separator.length + decimals;
    final safeSuffixStart = suffixStart > formattedWhole.length ? formattedWhole.length : suffixStart;
    final unsigned = separatorIndex < 0
        ? formattedWhole
        : digits == 0 ? formattedWhole : '${formattedWhole.substring(0, separatorIndex + separator.length)}$fraction${formattedWhole.substring(safeSuffixStart)}';
    final spaced = unsigned.startsWith(currencyCode) && unsigned.length > currencyCode.length && RegExp(r'[0-9]').hasMatch(unsigned[currencyCode.length])
        ? '$currencyCode ${unsigned.substring(currencyCode.length)}'
        : unsigned;
    return amountMinor < 0 ? '${formatter.symbols.MINUS_SIGN}$spaced' : spaced;
  }

  static int _pow10(int exponent) { var value = 1; for (var index = 0; index < exponent; index++) value *= 10; return value; }
}