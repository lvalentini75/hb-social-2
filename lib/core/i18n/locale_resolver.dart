import 'package:flutter/widgets.dart';

/// Resolves the first supported language advertised by the device or browser.
class LocaleResolver {
  static const supportedLanguageCodes = {'it', 'en', 'fr', 'es', 'de'};

  final Locale locale;
  final String? deviceCountryCode;

  const LocaleResolver._(this.locale, this.deviceCountryCode);

  factory LocaleResolver.fromDevice() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    final resolved = locales.where((item) => supportedLanguageCodes.contains(item.languageCode.toLowerCase())).firstOrNull;
    final first = locales.firstOrNull;
    final country = first?.countryCode?.trim().toUpperCase();
    return LocaleResolver._(Locale(resolved?.languageCode.toLowerCase() ?? 'en'), country?.isEmpty == true ? null : country);
  }
}