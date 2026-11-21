import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/weather/data/weather_repository.dart';
import 'package:hb_social/features/weather/domain/weather_forecast.dart';

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) => WeatherRepository(ref.watch(supabaseClientProvider)));
final weatherPointProvider = Provider<WeatherPoint>((ref) {
  final value = ref.watch(huntingContextProvider);
  if (value.municipalityId != null) return WeatherPoint.municipality(value.municipalityId!);
  if (value.lat != null && value.lng != null) return WeatherPoint.coordinates(value.lat, value.lng);
  final country = ref.watch(userSettingsProvider.select((settings) => settings.countryCode));
  final regions = country == null ? null : ref.watch(regionsProvider(country)).value;
  final region = regions?.where((item) => item.id == value.regionId).firstOrNull;
  return WeatherPoint.coordinates(region?.lat, region?.lng);
});
final weatherProvider = FutureProvider.family<WeatherForecast, WeatherPoint>((ref, point) {
  if (!point.hasLocation) throw const WeatherNoLocationException();
  return ref.watch(weatherRepositoryProvider).fetch(municipalityId: point.municipalityId, lat: point.lat, lng: point.lng);
});

class WeatherNoLocationException implements Exception {
  const WeatherNoLocationException();
}

class EventWeatherRequest {
  final double lat;
  final double lng;
  const EventWeatherRequest(this.lat, this.lng);
  WeatherPoint get point => WeatherPoint.coordinates(lat, lng);
  @override
  bool operator ==(Object other) => other is EventWeatherRequest && other.point == point;
  @override
  int get hashCode => point.hashCode;
}

final eventWeatherProvider = FutureProvider.autoDispose.family<WeatherForecast, EventWeatherRequest>((ref, request) => ref.watch(weatherRepositoryProvider).fetch(lat: request.lat, lng: request.lng));