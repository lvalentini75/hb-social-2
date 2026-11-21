import 'dart:math' as math;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/weather/domain/weather_forecast.dart';
import 'package:hb_social/features/weather/presentation/weather_formatters.dart';
import 'package:hb_social/features/weather/presentation/weather_widgets.dart';
import 'package:hb_social/features/weather/providers/weather_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';

class TodayWeatherSlot extends ConsumerStatefulWidget {
  final String? regionName;
  const TodayWeatherSlot({super.key, this.regionName});
  @override
  ConsumerState<TodayWeatherSlot> createState() => _TodayWeatherSlotState();
}

class _TodayWeatherSlotState extends ConsumerState<TodayWeatherSlot> {
  bool visible = false;
  bool locating = false;
  @override
  Widget build(BuildContext context) => VisibilityDetector(key: const ValueKey('today-weather-slot'), onVisibilityChanged: (value) { if (!visible && value.visibleFraction > 0 && mounted) setState(() => visible = true); }, child: !visible ? const SizedBox(height: 1) : _content(context));

  Widget _content(BuildContext context) {
    final point = ref.watch(weatherPointProvider);
    if (!point.hasLocation) return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [Text('weather.set_municipality'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), HBButton.ghost(label: 'weather.settings'.tr(), onPressed: () => context.go(AppRoutes.settings), size: HBButtonSize.sm), HBButton.ghost(label: 'weather.use_location'.tr(), onPressed: locating ? null : _useLocation, size: HBButtonSize.sm)]);
    final forecast = ref.watch(weatherProvider(point));
    return forecast.when(
      loading: () => const HBSkeleton(height: 54),
      error: (_, __) => Row(children: [Expanded(child: Text('weather.unavailable'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), HBButton.ghost(label: 'weather.retry'.tr(), onPressed: () => ref.invalidate(weatherProvider(point)), size: HBButtonSize.sm)]),
      data: (value) => InkWell(
        onTap: () => context.go('${AppRoutes.hunting}?tab=4'),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _weatherRow(value),
          const SizedBox(height: AppSpacing.xs),
          Wrap(spacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(_place(value), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (value.stale) Tooltip(message: 'weather.stale'.tr(namedArgs: {'time': DateFormat.Hm().format(value.fetchedAt.toLocal())}), child: const Icon(Icons.history, size: 14, color: LightModeColors.lightPrimary)), OpenMeteoAttribution(color: LightModeColors.lightOnSurfaceVariant, onTap: _openAttribution)]),
        ]),
      ),
    );
  }

  Widget _weatherRow(WeatherForecast forecast) {
    final contextValue = ref.read(huntingContextProvider);
    final today = DateUtils.isSameDay(contextValue.date, DateTime.now());
    if (!today) {
      final day = forecast.daily.where((item) => DateUtils.isSameDay(item.date, contextValue.date)).firstOrNull;
      if (day == null) return Text('weather.beyond_seven_days'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant));
      return Row(children: [WeatherConditionIcon(code: day.weatherCode, isDay: true, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('weather.daily_compact'.tr(namedArgs: {'min': day.temperatureMin.round().toString(), 'max': day.temperatureMax.round().toString(), 'rain': '${day.precipitationProbabilityMax}', 'wind': day.windSpeedMax.round().toString()}), style: context.textStyles.bodySmall)) ]);
    }
    final current = forecast.current;
    final hours = forecast.hourly.where((hour) => !hour.time.isBefore(current.time)).take(3);
    final rain = hours.fold<int>(0, (value, hour) => math.max(value, hour.precipitationProbability));
    final apparent = (current.temperature - current.apparentTemperature).abs() >= 3 ? ' (${current.apparentTemperature.round()}°)' : '';
    return Row(children: [WeatherConditionIcon(code: current.weatherCode, isDay: current.isDay, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Text('${current.temperature.round()}°$apparent', style: context.textStyles.titleMedium), const SizedBox(width: AppSpacing.md), Transform.rotate(angle: windArrowRadians(current.windDirection), child: const Icon(Icons.arrow_upward, size: 16, color: LightModeColors.lightPrimary)), Text(' ${current.windSpeed.round()} km/h ${windDirection16(current.windDirection)}', style: context.textStyles.bodySmall), const Spacer(), const Icon(Icons.water_drop_outlined, size: 16, color: LightModeColors.lightPrimary), Text(' $rain%', style: context.textStyles.bodySmall), const SizedBox(width: AppSpacing.md), MoonPhaseIcon(phaseName: forecast.moon.phaseName, size: 18, color: LightModeColors.lightPrimary), Text(' ${forecast.moon.illumination.round()}%', style: context.textStyles.bodySmall)]);
  }

  String _place(WeatherForecast value) => value.municipality != null ? 'weather.on_municipality'.tr(namedArgs: {'municipality': value.municipality!.name}) : 'weather.on_region_centroid'.tr(namedArgs: {'region': widget.regionName ?? 'weather.selected_area'.tr()});
  Future<void> _useLocation() async { setState(() => locating = true); try { var permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission(); if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw StateError('denied'); final position = await Geolocator.getCurrentPosition(); ref.read(huntingContextProvider.notifier).setPosition(position.latitude, position.longitude); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('weather.location_error'.tr()))); } finally { if (mounted) setState(() => locating = false); } }
  void _openAttribution() => launchUrl(Uri.parse('https://open-meteo.com/'), mode: LaunchMode.externalApplication);
}