import 'package:flutter/widgets.dart';

/// Supported locales for the app, in launch-market order
/// (Italy, then France, Spain, Germany, UK).
class AppLocales {
  static const Locale it = Locale('it');
  static const Locale en = Locale('en');
  static const Locale fr = Locale('fr');
  static const Locale es = Locale('es');
  static const Locale de = Locale('de');

  static const List<Locale> supported = [it, en, fr, es, de];

  static const Locale fallback = it;
  static const String translationsPath = 'assets/translations';
}
