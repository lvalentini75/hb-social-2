import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

class UserSettings {
  final String? countryCode;
  final Locale locale;
  final String currencyCode;
  final String? regionId;
  final String? unitId;
  final MeasurementSystem measurementSystem;

  const UserSettings({this.countryCode, required this.locale, required this.currencyCode, this.regionId, this.unitId, this.measurementSystem = MeasurementSystem.metric});

  UserSettings copyWith({String? countryCode, Locale? locale, String? currencyCode, String? regionId, String? unitId, MeasurementSystem? measurementSystem}) => UserSettings(
    countryCode: countryCode ?? this.countryCode,
    locale: locale ?? this.locale,
    currencyCode: currencyCode ?? this.currencyCode,
    regionId: regionId,
    unitId: unitId,
    measurementSystem: measurementSystem ?? this.measurementSystem,
  );
}

enum MeasurementSystem { metric, imperial }

/// Session-only settings until profile preferences are persisted by Supabase.
class UserSettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    final parts = Intl.getCurrentLocale().split(RegExp('[-_]'));
    return UserSettings(locale: Locale(parts.first, parts.length > 1 ? parts[1] : null), currencyCode: 'EUR');
  }

  void setHuntingZone({required String countryCode, String? regionId, String? unitId}) => state = state.copyWith(countryCode: countryCode, regionId: regionId, unitId: unitId);
  void setLocale(Locale locale) => state = state.copyWith(locale: locale, regionId: state.regionId, unitId: state.unitId);
  void setCurrency(String currencyCode) => state = state.copyWith(currencyCode: currencyCode, regionId: state.regionId, unitId: state.unitId);
  void setMeasurementSystem(MeasurementSystem system) => state = state.copyWith(measurementSystem: system, regionId: state.regionId, unitId: state.unitId);
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(UserSettingsNotifier.new);