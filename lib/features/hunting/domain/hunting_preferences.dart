import 'package:flutter/material.dart';

/// Closed launch-market list. It will be replaced by `countries` in P04.
enum SupportedCountry { it, fr, es, de, at, gb }

extension SupportedCountryX on SupportedCountry {
  String get code => name.toUpperCase();
  String get translationKey => 'zone.country_$name';
}

enum HuntingUnitType { atc, acca, coto, revier, estate }

extension HuntingUnitTypeX on HuntingUnitType {
  String get translationKey => 'zone.unit_${name}_title';
}

HuntingUnitType unitTypeFor(SupportedCountry country) => switch (country) {
  SupportedCountry.it => HuntingUnitType.atc,
  SupportedCountry.fr => HuntingUnitType.acca,
  SupportedCountry.es => HuntingUnitType.coto,
  SupportedCountry.de || SupportedCountry.at => HuntingUnitType.revier,
  SupportedCountry.gb => HuntingUnitType.estate,
};

enum CalendarView { species, date }

class HuntingShortcutDefinition {
  final IconData icon;
  final String titleKey;
  final String descriptionKey;
  final String statusKey;
  final String path;

  const HuntingShortcutDefinition({required this.icon, required this.titleKey, required this.descriptionKey, required this.statusKey, required this.path});
}