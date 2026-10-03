import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Formats integer minor-unit amounts without converting stored values to doubles.
class MoneyFormatter {
  const MoneyFormatter._();

  static String format({required int amountMinor, required String currencyCode, required Locale locale}) {
    final formatter = NumberFormat.simpleCurrency(locale: locale.toLanguageTag(), name: currencyCode, decimalDigits: 2);
    final absoluteMinor = amountMinor.abs();
    final whole = absoluteMinor ~/ 100;
    final fraction = (absoluteMinor % 100).toString().padLeft(2, '0');
    final formattedWhole = formatter.format(whole);
    final separator = formatter.symbols.DECIMAL_SEP;
    final separatorIndex = formattedWhole.lastIndexOf(separator);
    final unsigned = separatorIndex < 0 ? formattedWhole : '${formattedWhole.substring(0, separatorIndex + separator.length)}$fraction';
    return amountMinor < 0 ? '${formatter.symbols.MINUS_SIGN}$unsigned' : unsigned;
  }
}