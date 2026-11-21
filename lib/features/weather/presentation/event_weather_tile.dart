import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/weather/presentation/weather_formatters.dart';
import 'package:hb_social/features/weather/presentation/weather_widgets.dart';
import 'package:hb_social/features/weather/providers/weather_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class EventWeatherTile extends ConsumerWidget {
  final HuntingEvent event;
  const EventWeatherTile({super.key, required this.event});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (event.latitude == null || event.longitude == null || event.startsAt.isBefore(DateTime.now().subtract(const Duration(days: 1))) || event.startsAt.isAfter(DateTime.now().add(const Duration(days: 7)))) return const SizedBox.shrink();
    final value = ref.watch(eventWeatherProvider(EventWeatherRequest(event.latitude!, event.longitude!)));
    return value.when(loading: () => const HBSkeleton(height: 90), error: (_, __) => const SizedBox.shrink(), data: (forecast) {
      final day = forecast.daily.where((item) => DateUtils.isSameDay(item.date, event.startsAt.toLocal())).firstOrNull;
      if (day == null) return const SizedBox.shrink();
      final eventHours = DateUtils.isSameDay(event.startsAt.toLocal(), DateTime.now()) ? forecast.hourly.where((hour) => !hour.time.isBefore(event.startsAt.toLocal()) && !hour.time.isAfter((event.endsAt ?? event.startsAt.add(const Duration(hours: 3))).toLocal())).toList() : const [];
      return HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('weather.event_title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), Row(children: [WeatherConditionIcon(code: day.weatherCode, isDay: true), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('${day.temperatureMin.round()}° / ${day.temperatureMax.round()}° · ${day.precipitationProbabilityMax}% · ${day.windSpeedMax.round()} km/h ${windDirection16(day.windDirectionDominant)}'))]), if (eventHours.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text(eventHours.map((hour) => '${DateFormat.Hm().format(hour.time)} ${hour.temperature.round()}° ${hour.precipitationProbability}%').join(' · '), style: context.textStyles.bodySmall)], const SizedBox(height: AppSpacing.sm), OpenMeteoAttribution(onTap: () => launchUrl(Uri.parse('https://open-meteo.com/'), mode: LaunchMode.externalApplication))]));
    });
  }
}