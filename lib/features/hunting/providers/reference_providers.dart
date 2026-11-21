import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/features/hunting/data/unit_types_repository.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/locale_resolver.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) => ReferenceRepository(ref.watch(supabaseClientProvider)));
final countriesProvider = FutureProvider<List<ReferenceCountry>>((ref) {
  final locale = ref.watch(userSettingsProvider.select((settings) => settings.locale.languageCode));
  return ref.watch(referenceRepositoryProvider).getCountries(locale);
});
final regionsProvider = FutureProvider.family<List<ReferenceRegion>, String>((ref, countryCode) => ref.watch(referenceRepositoryProvider).getRegions(countryCode));
final currenciesProvider = FutureProvider<List<ReferenceCurrency>>((ref) async {
  final values = await ref.watch(referenceRepositoryProvider).getCurrencies();
  MoneyFormatter.registerMinorUnits({for (final item in values) item.code: item.minorUnits});
  return values;
});
final selectedCountryProvider = Provider<ReferenceCountry?>((ref) {
  final code = ref.watch(userSettingsProvider.select((settings) => settings.countryCode));
  return ref.watch(countriesProvider).value?.where((item) => item.code == code).firstOrNull;
});
final effectiveCountryCodeProvider = Provider<String>((ref) {
  final saved = ref.watch(userSettingsProvider.select((settings) => settings.countryCode));
  if (saved != null) return saved;
  final countries = ref.watch(countriesProvider).value ?? const <ReferenceCountry>[];
  final device = LocaleResolver.fromDevice().deviceCountryCode;
  return countries.any((item) => item.code == device) ? device! : 'IT';
});
final speciesProvider = FutureProvider<List<Species>>((ref) {
  final locale = ref.watch(userSettingsProvider.select((settings) => settings.locale.languageCode));
  return ref.watch(referenceRepositoryProvider).getSpecies(locale);
});
final huntingUnitsByRegionProvider = FutureProvider.family<List<HuntingUnit>, String>((ref, regionId) => ref.watch(referenceRepositoryProvider).getHuntingUnits(regionId));
final municipalityProvider = FutureProvider.family<Municipality?, String>((ref, id) => ref.watch(referenceRepositoryProvider).getMunicipality(id));
final speciesNamesProvider = FutureProvider<Map<String, String>>((ref) {
  final locale = ref.watch(userSettingsProvider.select((settings) => settings.locale.languageCode));
  return ref.watch(referenceRepositoryProvider).getSpeciesNames(locale);
});
final unitTypesRepositoryProvider = Provider<UnitTypesRepository>((ref) => UnitTypesRepository(ref.watch(supabaseClientProvider)));
final unitTypesProvider = FutureProvider.family<List<HuntingUnitTypeInfo>, String>((ref, countryCode) => ref.watch(unitTypesRepositoryProvider).forCountry(countryCode));
final selectedUnitTypeProvider = FutureProvider<String?>((ref) {
  final unitId = ref.watch(userSettingsProvider.select((settings) => settings.unitId));
  return ref.watch(unitTypesRepositoryProvider).typeForUnit(unitId);
});