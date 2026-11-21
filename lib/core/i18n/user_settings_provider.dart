import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/locale_resolver.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';

class UserSettings {
  final String? countryCode;
  final Locale locale;
  final String currencyCode;
  final String? regionId;
  final String? unitId;
  final String? municipalityId;
  final MeasurementSystem measurementSystem;
  final DateTime? birthDate;
  final DateTime? onboardingCompletedAt;
  final bool showSensitive;
  final bool autoTranslate;

  const UserSettings({this.countryCode, required this.locale, required this.currencyCode, this.regionId, this.unitId, this.municipalityId, this.measurementSystem = MeasurementSystem.metric, this.birthDate, this.onboardingCompletedAt, this.showSensitive = false, this.autoTranslate = true});

  UserSettings copyWith({String? countryCode, Locale? locale, String? currencyCode, String? regionId, String? unitId, String? municipalityId, MeasurementSystem? measurementSystem, DateTime? birthDate, DateTime? onboardingCompletedAt, bool? showSensitive, bool? autoTranslate}) => UserSettings(
    countryCode: countryCode ?? this.countryCode,
    locale: locale ?? this.locale,
    currencyCode: currencyCode ?? this.currencyCode,
    regionId: regionId,
    unitId: unitId,
    municipalityId: municipalityId,
    measurementSystem: measurementSystem ?? this.measurementSystem,
    birthDate: birthDate ?? this.birthDate,
    onboardingCompletedAt: onboardingCompletedAt ?? this.onboardingCompletedAt,
    showSensitive: showSensitive ?? this.showSensitive,
    autoTranslate: autoTranslate ?? this.autoTranslate,
  );
}

enum MeasurementSystem { metric, imperial }

class UserSettingsNotifier extends Notifier<UserSettings> {
  @override
  UserSettings build() {
    final deviceLocale = LocaleResolver.fromDevice().locale;
    ref.listen(currentProfileProvider, (_, next) => next.whenData((profile) {
      if (profile != null) state = UserSettings(countryCode: profile.countryCode, locale: Locale(profile.locale), currencyCode: profile.currencyCode, regionId: profile.homeRegionId, unitId: profile.huntingUnitId, municipalityId: profile.homeMunicipalityId, measurementSystem: profile.unitSystem == 'imperial' ? MeasurementSystem.imperial : MeasurementSystem.metric, birthDate: state.birthDate, onboardingCompletedAt: state.onboardingCompletedAt, showSensitive: state.showSensitive);
    }), fireImmediately: true);
    ref.listen(privateUserSettingsProvider, (_, next) => next.whenData((record) {
      if (record != null) state = state.copyWith(regionId: state.regionId, unitId: state.unitId, municipalityId: state.municipalityId, birthDate: record.birthDate, onboardingCompletedAt: record.onboardingCompletedAt, showSensitive: record.showSensitive, autoTranslate: record.autoTranslate);
    }), fireImmediately: true);
    return UserSettings(locale: deviceLocale, currencyCode: 'EUR');
  }

  void setHuntingZone({required String countryCode, String? regionId, String? unitId, String? municipalityId}) => state = state.copyWith(countryCode: countryCode, regionId: regionId, unitId: unitId, municipalityId: municipalityId);
  void setLocale(Locale locale) => state = state.copyWith(locale: locale, regionId: state.regionId, unitId: state.unitId, municipalityId: state.municipalityId);
  void setCurrency(String currencyCode) => state = state.copyWith(currencyCode: currencyCode, regionId: state.regionId, unitId: state.unitId, municipalityId: state.municipalityId);
  void setMeasurementSystem(MeasurementSystem system) => state = state.copyWith(measurementSystem: system, regionId: state.regionId, unitId: state.unitId, municipalityId: state.municipalityId);
  void setShowSensitive(bool value) => state = state.copyWith(regionId: state.regionId, unitId: state.unitId, municipalityId: state.municipalityId, showSensitive: value);
  void setAutoTranslate(bool value) => state = state.copyWith(regionId: state.regionId, unitId: state.unitId, municipalityId: state.municipalityId, autoTranslate: value);
}

final userSettingsProvider = NotifierProvider<UserSettingsNotifier, UserSettings>(UserSettingsNotifier.new);