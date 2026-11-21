import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';

String windDirection16(double degrees) {
  const values = ['N', 'NNE', 'NE', 'ENE', 'E', 'ESE', 'SE', 'SSE', 'S', 'SSW', 'SW', 'WSW', 'W', 'WNW', 'NW', 'NNW'];
  return values[((degrees % 360) / 22.5).round() % 16];
}

double windArrowTurns(double degrees) => (degrees % 360) / 360;
double windArrowRadians(double degrees) => degrees * math.pi / 180;

String beaufortKey(double speed) {
  if (speed < 2) return 'calm';
  if (speed < 6) return 'light_air';
  if (speed < 12) return 'light_breeze';
  if (speed < 20) return 'fresh_breeze';
  if (speed < 29) return 'moderate';
  if (speed < 39) return 'strong_breeze';
  if (speed < 50) return 'fresh_wind';
  if (speed < 62) return 'strong_wind';
  return 'gale';
}

String windDescription(double speed, double direction) => 'weather.wind_description'.tr(namedArgs: {'force': 'weather.beaufort.${beaufortKey(speed)}'.tr(), 'direction': windDirection16(direction)});
String visibilityLabel(double meters) => meters > 10000 ? 'weather.visibility_over'.tr() : 'weather.visibility_km'.tr(namedArgs: {'value': (meters / 1000).toStringAsFixed(1)});
String? feelsLikeLabel(double temperature, double apparent) => (temperature - apparent).abs() >= 3 ? 'weather.feels_like'.tr(namedArgs: {'value': apparent.round().toString()}) : null;