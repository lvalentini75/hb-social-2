import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_bar_chart.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/weather/domain/weather_code_info.dart';
import 'package:hb_social/features/weather/domain/weather_forecast.dart';
import 'package:hb_social/features/weather/presentation/weather_formatters.dart';
import 'package:hb_social/features/weather/presentation/weather_widgets.dart';
import 'package:hb_social/features/weather/providers/weather_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class HuntingWeatherTab extends ConsumerWidget {
  const HuntingWeatherTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final point = ref.watch(weatherPointProvider);
    if (!point.hasLocation) return WeatherNoLocation(onUseLocation: () => _useLocation(context, ref));
    final value = ref.watch(weatherProvider(point));
    return value.when(loading: () => const HBSkeleton(height: 620), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.cloud_off_outlined, title: 'weather.error_title'.tr(), message: 'weather.unavailable'.tr(), action: HBButton.primary(label: 'weather.retry'.tr(), onPressed: () => ref.invalidate(weatherProvider(point))))), data: (forecast) => WeatherDashboard(forecast: forecast, onRefresh: () async { await ref.read(weatherRepositoryProvider).fetch(municipalityId: point.municipalityId, lat: point.lat, lng: point.lng, forceRefresh: true); ref.invalidate(weatherProvider(point)); }));
  }
  Future<void> _useLocation(BuildContext context, WidgetRef ref) async { try { var permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission(); if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw StateError('denied'); final position = await Geolocator.getCurrentPosition(); ref.read(huntingContextProvider.notifier).setPosition(position.latitude, position.longitude); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('weather.location_error'.tr()))); } }
}

class WeatherNoLocation extends StatelessWidget {
  final VoidCallback onUseLocation;
  const WeatherNoLocation({super.key, required this.onUseLocation});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(children: [HBEmptyState(icon: Icons.location_on_outlined, title: 'weather.no_location_title'.tr(), message: 'weather.set_municipality'.tr()), Wrap(spacing: AppSpacing.sm, children: [HBButton.primary(label: 'weather.use_location'.tr(), icon: Icons.my_location, onPressed: onUseLocation), HBButton.secondary(label: 'weather.settings'.tr(), onPressed: () => context.go(AppRoutes.settings))])]));
}

class WeatherDashboard extends ConsumerWidget {
  final WeatherForecast forecast;
  final Future<void> Function() onRefresh;
  const WeatherDashboard({super.key, required this.forecast, required this.onRefresh});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunting = ref.watch(huntingContextProvider);
    final overview = ref.watch(huntingTodayProvider).value;
    final timed = overview?.entries.where((entry) => entry.opensAt != null && entry.closesAt != null).firstOrNull;
    final hours = _windowHours(forecast.hourly, timed?.opensAt, timed?.closesAt);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(forecast.municipality?.name ?? '${forecast.lat.toStringAsFixed(2)}, ${forecast.lng.toStringAsFixed(2)}', style: context.textStyles.titleLarge), Text('weather.updated'.tr(namedArgs: {'time': relativeTime(context, forecast.fetchedAt)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))])), Tooltip(message: 'weather.refresh'.tr(), child: HBButton.icon(icon: Icons.refresh, onPressed: () => onRefresh()))]),
      const SizedBox(height: AppSpacing.lg), WeatherNowTile(current: forecast.current, timezone: forecast.timezone),
      const SizedBox(height: AppSpacing.lg), Text('weather.hunting_window'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), WeatherHourlyStrip(hours: hours), const SizedBox(height: AppSpacing.md), HBCard(child: HbBarChart(points: [for (final hour in hours) HbBarChartPoint(day: hour.time, value: hour.precipitationProbability)], height: 150)),
      const SizedBox(height: AppSpacing.lg), Text('weather.next_days'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), HBCard(child: Column(children: [for (final day in forecast.daily) WeatherDayRow(day: day, selected: DateUtils.isSameDay(day.date, hunting.date), onTap: () => ref.read(huntingContextProvider.notifier).setDate(day.date))])),
      const SizedBox(height: AppSpacing.lg), WeatherMoonTile(moon: forecast.moon),
      const SizedBox(height: AppSpacing.md), OpenMeteoAttribution(onTap: _openAttribution), const SizedBox(height: AppSpacing.xs), Text('weather.model_note'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)),
    ]);
  }
  List<WeatherHour> _windowHours(List<WeatherHour> hours, DateTime? opens, DateTime? closes) { if (opens == null || closes == null) return hours.where((item) => !item.time.isBefore(DateTime.now())).take(12).toList(); return hours.where((item) => !item.time.isBefore(opens) && !item.time.isAfter(closes)).toList(); }
  void _openAttribution() => launchUrl(Uri.parse('https://open-meteo.com/'), mode: LaunchMode.externalApplication);
}

class WeatherNowTile extends StatelessWidget {
  final WeatherCurrent current;
  final String timezone;
  const WeatherNowTile({super.key, required this.current, required this.timezone});
  @override
  Widget build(BuildContext context) {
    final info = WeatherCodeInfo.fromCode(current.weatherCode, isDay: current.isDay);
    final feels = feelsLikeLabel(current.temperature, current.apparentTemperature);
    return HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(info.icon, size: 54, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${current.temperature.round()}°', style: context.textStyles.headlineLarge), Text(info.translationKey.tr()), if (feels != null) Text(feels, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))])), Transform.rotate(angle: windArrowRadians(current.windDirection), child: const Icon(Icons.arrow_upward, color: LightModeColors.lightPrimary)), const SizedBox(width: AppSpacing.sm), Flexible(child: Text('${windDescription(current.windSpeed, current.windDirection)} · ${current.windSpeed.round()} km/h · ${'weather.gusts'.tr(namedArgs: {'value': current.windGusts.round().toString()})}'))]), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.sm, children: [Text('weather.humidity'.tr(namedArgs: {'value': '${current.humidity}'})), Text('weather.pressure'.tr(namedArgs: {'value': current.pressure.round().toString()})), Text('weather.clouds'.tr(namedArgs: {'value': '${current.cloudCover}'})), Text('weather.current_rain'.tr(namedArgs: {'value': current.precipitation.toStringAsFixed(1)})), Text('weather.point_time'.tr(namedArgs: {'time': DateFormat.Hm().format(current.time), 'timezone': timezone}))]) ]));
  }
}

class WeatherHourlyStrip extends StatelessWidget {
  final List<WeatherHour> hours;
  const WeatherHourlyStrip({super.key, required this.hours});
  @override
  Widget build(BuildContext context) => SizedBox(height: 190, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: hours.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (_, index) => WeatherHourTile(hour: hours[index])));
}

class WeatherHourTile extends StatelessWidget {
  final WeatherHour hour;
  const WeatherHourTile({super.key, required this.hour});
  @override
  Widget build(BuildContext context) => SizedBox(width: 142, child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(DateFormat.Hm().format(hour.time), style: context.textStyles.titleSmall), WeatherConditionIcon(code: hour.weatherCode, isDay: hour.isDay), Text('${hour.temperature.round()}° · ${hour.precipitationProbability}%'), Text('${hour.precipitation.toStringAsFixed(1)} mm'), Row(children: [Transform.rotate(angle: windArrowRadians(hour.windDirection), child: const Icon(Icons.arrow_upward, size: 14)), Text(' ${hour.windSpeed.round()} km/h')]), Text(visibilityLabel(hour.visibility), style: context.textStyles.labelSmall), const Spacer(), Wrap(spacing: 4, children: [if (hour.windSpeed >= 29) HBChip(label: 'weather.warning_wind'.tr(), selected: false), if (hour.visibility < 1000) HBChip(label: 'weather.warning_fog'.tr(), selected: false)])])));
}

class WeatherDayRow extends StatelessWidget {
  final WeatherDay day;
  final bool selected;
  final VoidCallback onTap;
  const WeatherDayRow({super.key, required this.day, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm, horizontal: AppSpacing.xs), color: selected ? LightModeColors.lightPrimaryContainer : null, child: Row(children: [SizedBox(width: 82, child: Text(DateFormat('EEE d', context.locale.languageCode).format(day.date), style: context.textStyles.bodyMedium?.copyWith(fontWeight: selected ? FontWeight.w700 : FontWeight.w400))), WeatherConditionIcon(code: day.weatherCode, isDay: true), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('${day.temperatureMin.round()}° / ${day.temperatureMax.round()}° · ${day.precipitationProbabilityMax}% · ${day.precipitationSum.toStringAsFixed(1)} mm')), Expanded(child: Text('${day.windSpeedMax.round()} km/h ${windDirection16(day.windDirectionDominant)}')), Text('${DateFormat.Hm().format(day.sunrise)} / ${DateFormat.Hm().format(day.sunset)}', style: context.textStyles.labelSmall)])));
}

class WeatherMoonTile extends StatelessWidget {
  final MoonPhase moon;
  const WeatherMoonTile({super.key, required this.moon});
  @override
  Widget build(BuildContext context) => HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [MoonPhaseIcon(phaseName: moon.phaseName, size: 42, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('weather.moon_title'.tr(), style: context.textStyles.titleMedium), Text('weather.moon.${moon.phaseName}'.tr()), Text('weather.moon_values'.tr(namedArgs: {'illumination': moon.illumination.round().toString(), 'age': moon.ageDays.toStringAsFixed(1)})), const SizedBox(height: AppSpacing.sm), Text('weather.moon_note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))]))]));
}