class WeatherForecast {
  final String cacheKey;
  final bool cached;
  final bool stale;
  final DateTime fetchedAt;
  final DateTime expiresAt;
  final double lat;
  final double lng;
  final double? elevation;
  final String timezone;
  final WeatherMunicipality? municipality;
  final WeatherCurrent current;
  final List<WeatherHour> hourly;
  final List<WeatherDay> daily;
  final MoonPhase moon;
  final String attribution;

  const WeatherForecast({required this.cacheKey, required this.cached, required this.stale, required this.fetchedAt, required this.expiresAt, required this.lat, required this.lng, this.elevation, required this.timezone, this.municipality, required this.current, required this.hourly, required this.daily, required this.moon, required this.attribution});

  factory WeatherForecast.fromJson(Map<String, dynamic> json) => WeatherForecast(
    cacheKey: json['cache_key'] as String, cached: json['cached'] as bool? ?? false, stale: json['stale'] as bool? ?? false,
    fetchedAt: DateTime.parse(json['fetched_at'] as String), expiresAt: DateTime.parse(json['expires_at'] as String),
    lat: (json['lat'] as num).toDouble(), lng: (json['lng'] as num).toDouble(), elevation: (json['elevation'] as num?)?.toDouble(), timezone: json['timezone'] as String? ?? '',
    municipality: json['municipality'] is Map ? WeatherMunicipality.fromJson(Map<String, dynamic>.from(json['municipality'] as Map)) : null,
    current: WeatherCurrent.fromJson(Map<String, dynamic>.from(json['current'] as Map)),
    hourly: [for (final row in json['hourly'] as List? ?? const []) WeatherHour.fromJson(Map<String, dynamic>.from(row as Map))],
    daily: [for (final row in json['daily'] as List? ?? const []) WeatherDay.fromJson(Map<String, dynamic>.from(row as Map))],
    moon: MoonPhase.fromJson(Map<String, dynamic>.from(json['moon'] as Map)), attribution: json['attribution'] as String? ?? 'Weather data by Open-Meteo.com',
  );
}

class WeatherMunicipality {
  final String id;
  final String name;
  final String? provinceCode;
  const WeatherMunicipality({required this.id, required this.name, this.provinceCode});
  factory WeatherMunicipality.fromJson(Map<String, dynamic> json) => WeatherMunicipality(id: json['id'] as String, name: json['name'] as String, provinceCode: json['province_code'] as String?);
}

class WeatherCurrent {
  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final int humidity;
  final double precipitation;
  final double rain;
  final double snowfall;
  final int weatherCode;
  final int cloudCover;
  final double pressure;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final bool isDay;
  const WeatherCurrent({required this.time, required this.temperature, required this.apparentTemperature, required this.humidity, required this.precipitation, required this.rain, required this.snowfall, required this.weatherCode, required this.cloudCover, required this.pressure, required this.windSpeed, required this.windDirection, required this.windGusts, required this.isDay});
  factory WeatherCurrent.fromJson(Map<String, dynamic> json) => WeatherCurrent(time: parsePointTime(json['time']), temperature: _double(json['temperature']), apparentTemperature: _double(json['apparent_temperature']), humidity: _int(json['humidity']), precipitation: _double(json['precipitation']), rain: _double(json['rain']), snowfall: _double(json['snowfall']), weatherCode: _int(json['weather_code']), cloudCover: _int(json['cloud_cover']), pressure: _double(json['pressure']), windSpeed: _double(json['wind_speed']), windDirection: _double(json['wind_direction']), windGusts: _double(json['wind_gusts']), isDay: _bool(json['is_day']));
}

class WeatherHour {
  final DateTime time;
  final double temperature;
  final double apparentTemperature;
  final int precipitationProbability;
  final double precipitation;
  final int weatherCode;
  final int cloudCover;
  final double visibility;
  final double windSpeed;
  final double windDirection;
  final double windGusts;
  final int humidity;
  final bool isDay;
  const WeatherHour({required this.time, required this.temperature, required this.apparentTemperature, required this.precipitationProbability, required this.precipitation, required this.weatherCode, required this.cloudCover, required this.visibility, required this.windSpeed, required this.windDirection, required this.windGusts, required this.humidity, required this.isDay});
  factory WeatherHour.fromJson(Map<String, dynamic> json) => WeatherHour(time: parsePointTime(json['time']), temperature: _double(json['temperature']), apparentTemperature: _double(json['apparent_temperature']), precipitationProbability: _int(json['precipitation_probability']), precipitation: _double(json['precipitation']), weatherCode: _int(json['weather_code']), cloudCover: _int(json['cloud_cover']), visibility: _double(json['visibility']), windSpeed: _double(json['wind_speed']), windDirection: _double(json['wind_direction']), windGusts: _double(json['wind_gusts']), humidity: _int(json['humidity']), isDay: _bool(json['is_day']));
}

class WeatherDay {
  final DateTime date;
  final int weatherCode;
  final double temperatureMax;
  final double temperatureMin;
  final DateTime sunrise;
  final DateTime sunset;
  final double precipitationSum;
  final int precipitationProbabilityMax;
  final double windSpeedMax;
  final double windGustsMax;
  final double windDirectionDominant;
  final double uvIndexMax;
  const WeatherDay({required this.date, required this.weatherCode, required this.temperatureMax, required this.temperatureMin, required this.sunrise, required this.sunset, required this.precipitationSum, required this.precipitationProbabilityMax, required this.windSpeedMax, required this.windGustsMax, required this.windDirectionDominant, required this.uvIndexMax});
  factory WeatherDay.fromJson(Map<String, dynamic> json) => WeatherDay(date: parsePointTime(json['date']), weatherCode: _int(json['weather_code']), temperatureMax: _double(json['temperature_max']), temperatureMin: _double(json['temperature_min']), sunrise: parsePointTime(json['sunrise']), sunset: parsePointTime(json['sunset']), precipitationSum: _double(json['precipitation_sum']), precipitationProbabilityMax: _int(json['precipitation_probability_max']), windSpeedMax: _double(json['wind_speed_max']), windGustsMax: _double(json['wind_gusts_max']), windDirectionDominant: _double(json['wind_direction_dominant']), uvIndexMax: _double(json['uv_index_max']));
}

class MoonPhase {
  final double phase;
  final double ageDays;
  final double illumination;
  final String phaseName;
  const MoonPhase({required this.phase, required this.ageDays, required this.illumination, required this.phaseName});
  factory MoonPhase.fromJson(Map<String, dynamic> json) => MoonPhase(phase: _double(json['phase']), ageDays: _double(json['age_days']), illumination: _double(json['illumination']), phaseName: json['phase_name'] as String? ?? 'new');
}

/// Open-Meteo returns local wall-clock strings. Keeping them non-UTC prevents
/// Dart from silently shifting a forecast to the device timezone.
DateTime parsePointTime(Object? value) {
  final text = value?.toString() ?? '';
  final parsed = DateTime.parse(text);
  return parsed.isUtc ? parsed.toLocal() : parsed;
}

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
int _int(Object? value) => (value as num?)?.toInt() ?? 0;
bool _bool(Object? value) => value == true || value == 1;