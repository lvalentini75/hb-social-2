import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/weather/domain/weather_code_info.dart';

class WeatherConditionIcon extends StatelessWidget {
  final int code;
  final bool isDay;
  final double size;
  final Color? color;
  const WeatherConditionIcon({super.key, required this.code, required this.isDay, this.size = 28, this.color});
  @override
  Widget build(BuildContext context) => Icon(WeatherCodeInfo.fromCode(code, isDay: isDay).icon, size: size, color: color);
}

class MoonPhaseIcon extends StatelessWidget {
  final String phaseName;
  final double size;
  final Color? color;
  const MoonPhaseIcon({super.key, required this.phaseName, this.size = 24, this.color});
  @override
  Widget build(BuildContext context) => Icon(_icon, size: size, color: color);
  IconData get _icon => switch (phaseName) { 'new' => Icons.circle_outlined, 'full' => Icons.circle, 'first_quarter' => Icons.brightness_2_outlined, 'last_quarter' => Icons.brightness_3_outlined, _ => Icons.nightlight_round };
}

class OpenMeteoAttribution extends StatelessWidget {
  final VoidCallback onTap;
  final Color? color;
  const OpenMeteoAttribution({super.key, required this.onTap, this.color});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Text('weather.attribution'.tr(), style: context.textStyles.labelSmall?.withColor(color ?? LightModeColors.lightTextTertiary).copyWith(decoration: TextDecoration.underline)));
}