import 'dart:async';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/features/weather/domain/weather_forecast.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeatherPoint {
  final String? municipalityId;
  final double? lat;
  final double? lng;
  const WeatherPoint.municipality(String id) : municipalityId = id, lat = null, lng = null;
  const WeatherPoint.coordinates(this.lat, this.lng) : municipalityId = null;
  bool get hasLocation => municipalityId != null || lat != null && lng != null;
  String get requestKey {
    if (municipalityId != null) return 'm:$municipalityId';
    if (lat == null || lng == null) return 'none';
    // Dedupe on the same 0.05 degree cell used by the server cache.
    return 'cell:${(lat! / .05).floor()}:${(lng! / .05).floor()}';
  }
  Map<String, dynamic> body({DateTime? date}) => {
    if (municipalityId != null) 'municipality_id': municipalityId else ...{'lat': lat, 'lng': lng},
    if (date != null) 'date': '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
  };
  @override
  bool operator ==(Object other) => other is WeatherPoint && other.requestKey == requestKey;
  @override
  int get hashCode => requestKey.hashCode;
}

class WeatherRepository {
  final SupabaseClient client;
  final Map<String, _CachedWeather> _memory = {};
  final Map<String, Future<WeatherForecast>> _inFlight = {};
  WeatherRepository(this.client);

  Future<WeatherForecast> fetch({String? municipalityId, double? lat, double? lng, DateTime? date, bool forceRefresh = false}) {
    final point = municipalityId != null ? WeatherPoint.municipality(municipalityId) : WeatherPoint.coordinates(lat, lng);
    if (!point.hasLocation) throw const AppException('weather.no_location');
    final dayKey = date == null ? point.requestKey : '${point.requestKey}:${date.year}-${date.month}-${date.day}';
    final cached = _memory[dayKey];
    if (!forceRefresh && cached != null && DateTime.now().difference(cached.savedAt) < const Duration(minutes: 10)) return Future.value(cached.value);
    if (!forceRefresh && _inFlight[dayKey] != null) return _inFlight[dayKey]!;
    final future = _invoke(point, date: date, cacheKey: dayKey);
    _inFlight[dayKey] = future;
    return future.whenComplete(() => _inFlight.remove(dayKey));
  }

  Future<WeatherForecast> _invoke(WeatherPoint point, {DateTime? date, required String cacheKey}) async {
    try {
      final response = await client.functions.invoke('weather', body: point.body(date: date)).timeout(const Duration(seconds: 8));
      if (response.status < 200 || response.status >= 300 || response.data is! Map) throw response.data;
      final value = WeatherForecast.fromJson(Map<String, dynamic>.from(response.data as Map));
      final entry = _CachedWeather(value, DateTime.now());
      _memory[cacheKey] = entry;
      _memory[value.cacheKey] = entry;
      return value;
    } on TimeoutException {
      throw const AppException('weather.unavailable');
    } catch (error) {
      final text = error.toString().toLowerCase();
      final stale = _memory[cacheKey]?.value;
      if (stale != null && (text.contains('weather_unavailable') || text.contains('502'))) return stale;
      if (text.contains('municipality_not_found')) throw const AppException('weather.municipality_not_found');
      throw const AppException('weather.unavailable');
    }
  }
}

class _CachedWeather {
  final WeatherForecast value;
  final DateTime savedAt;
  const _CachedWeather(this.value, this.savedAt);
}