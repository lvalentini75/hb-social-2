import 'package:intl/intl.dart';

/// Formats monetary values using the user's locale and the currency
/// conventionally used in their country. Not used for display yet (the
/// marketplace is not part of this build), but kept ready so pricing can be
/// added once the backend is connected.
class CurrencyFormatter {
  const CurrencyFormatter._();

  static const Map<String, String> _currencyByCountryCode = {
    'IT': 'EUR',
    'FR': 'EUR',
    'ES': 'EUR',
    'DE': 'EUR',
    'AT': 'EUR',
    'CH': 'CHF',
    'GB': 'GBP',
  };

  static String currencyCodeForCountry(String countryCode) =>
      _currencyByCountryCode[countryCode.toUpperCase()] ?? 'EUR';

  static String format(num amount, {required String localeCode, required String countryCode}) {
    final currencyCode = currencyCodeForCountry(countryCode);
    final format = NumberFormat.currency(locale: localeCode, name: currencyCode);
    return format.format(amount);
  }
}
