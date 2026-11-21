import 'package:flutter/material.dart';

class WeatherCodeInfo {
  final String translationKey;
  final IconData icon;
  const WeatherCodeInfo({required this.translationKey, required this.icon});

  factory WeatherCodeInfo.fromCode(int code, {required bool isDay}) => WeatherCodeInfo(translationKey: 'weather.code.$code', icon: _icon(code, isDay));

  static IconData _icon(int code, bool isDay) {
    if (code == 0) return isDay ? Icons.wb_sunny_outlined : Icons.nightlight_outlined;
    if (code == 1 || code == 2) return isDay ? Icons.wb_cloudy_outlined : Icons.nights_stay_outlined;
    if (code == 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.blur_on_outlined;
    if ({51, 53, 55, 56, 57}.contains(code)) return Icons.grain_outlined;
    if ({61, 63, 65, 66, 67}.contains(code)) return Icons.water_drop_outlined;
    if ({71, 73, 75, 77, 85, 86}.contains(code)) return Icons.ac_unit_outlined;
    if ({80, 81, 82}.contains(code)) return Icons.shower_outlined;
    if ({96, 99}.contains(code)) return Icons.thunderstorm_outlined;
    return Icons.thunderstorm_outlined;
  }
}