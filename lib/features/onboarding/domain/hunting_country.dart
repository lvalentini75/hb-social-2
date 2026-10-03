/// Reference data for the country/region picker in onboarding. Only Italy
/// ships with a full region list for now; the other launch markets only
/// require a country.
class HuntingCountry {
  final String code;
  final String translationKey;
  final List<String> regionCodes;

  const HuntingCountry({required this.code, required this.translationKey, this.regionCodes = const []});
}

const List<String> italianRegionCodes = [
  'abruzzo',
  'basilicata',
  'calabria',
  'campania',
  'emilia_romagna',
  'friuli_venezia_giulia',
  'lazio',
  'liguria',
  'lombardia',
  'marche',
  'molise',
  'piemonte',
  'puglia',
  'sardegna',
  'sicilia',
  'toscana',
  'trentino_alto_adige',
  'umbria',
  'valle_d_aosta',
  'veneto',
];

const List<HuntingCountry> huntingCountries = [
  HuntingCountry(code: 'IT', translationKey: 'onboarding.country_it', regionCodes: italianRegionCodes),
  HuntingCountry(code: 'FR', translationKey: 'onboarding.country_fr'),
  HuntingCountry(code: 'ES', translationKey: 'onboarding.country_es'),
  HuntingCountry(code: 'DE', translationKey: 'onboarding.country_de'),
  HuntingCountry(code: 'AT', translationKey: 'onboarding.country_at'),
  HuntingCountry(code: 'CH', translationKey: 'onboarding.country_ch'),
  HuntingCountry(code: 'GB', translationKey: 'onboarding.country_gb'),
];

String regionTranslationKey(String regionCode) => 'onboarding.region_$regionCode';
