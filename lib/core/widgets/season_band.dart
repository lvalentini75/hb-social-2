import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/weather/providers/weather_providers.dart';

/// Compact, real-data summary of the user's current hunting season.
class SeasonBand extends ConsumerWidget {
  final bool compact;

  const SeasonBand({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hunting = ref.watch(huntingTodayProvider).value;
    if (hunting == null || hunting.regionName.isEmpty) return const SizedBox.shrink();
    final open = hunting.open;
    final weatherPoint = ref.watch(weatherPointProvider);
    final weather = weatherPoint.hasLocation ? ref.watch(weatherProvider(weatherPoint)).value : null;
    final todayWeather = weather?.daily.where((day) {
      final now = DateTime.now();
      return day.date.year == now.year && day.date.month == now.month && day.date.day == now.day;
    }).firstOrNull;
    final season = hunting.entries.map((item) => item.seasonLabel).where((item) => item.isNotEmpty).firstOrNull;
    final species = open.firstOrNull;
    final parts = <Widget>[
      if (season != null) _SeasonText('season.title'.tr(namedArgs: {'season': season, 'region': hunting.regionName}), strong: true),
      if (season == null) _SeasonText(hunting.regionName, strong: true),
      if (todayWeather != null) _SeasonText('season.sun'.tr(namedArgs: {'sunrise': DateFormat.Hm(context.locale.toString()).format(todayWeather.sunrise), 'sunset': DateFormat.Hm(context.locale.toString()).format(todayWeather.sunset)})),
      if (open.length > 1) _SeasonText('season.open_count'.tr(namedArgs: {'count': '${open.length}'})),
      if (open.length == 1 && species != null) _SeasonText('season.open_until'.tr(namedArgs: {'species': species.nameIt ?? species.scientificName, 'date': DateFormat.MMMd(context.locale.toString()).format(species.validTo.toLocal())})),
      if (!compact) _SeasonLink(onTap: () => context.go(AppRoutes.huntingCalendar)),
    ];
    if (parts.length <= 1 && open.isEmpty && todayWeather == null) return const SizedBox.shrink();
    return Container(
      height: compact ? 44 : 36,
      margin: compact ? const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm) : EdgeInsets.zero,
      padding: EdgeInsets.symmetric(horizontal: compact ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(compact ? AppRadius.pill : 0)),
      child: compact
          ? ListView.separated(scrollDirection: Axis.horizontal, itemCount: parts.length, separatorBuilder: (_, __) => const _SeasonSeparator(), itemBuilder: (_, index) => Center(child: parts[index]))
          : Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var index = 0; index < parts.length; index++) ...[if (index > 0) const _SeasonSeparator(), Flexible(child: parts[index])]]),
    );
  }
}

class _SeasonText extends StatelessWidget {
  final String value;
  final bool strong;
  const _SeasonText(this.value, {this.strong = false});
  @override
  Widget build(BuildContext context) => Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelMedium?.copyWith(color: LightModeColors.lightPrimary, fontWeight: strong ? FontWeight.w600 : FontWeight.w500));
}

class _SeasonSeparator extends StatelessWidget {
  const _SeasonSeparator();
  @override
  Widget build(BuildContext context) => const Padding(padding: EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Text('·', style: TextStyle(color: LightModeColors.lightPrimary)));
}

class _SeasonLink extends StatelessWidget {
  final VoidCallback onTap;
  const _SeasonLink({required this.onTap});
  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.pill), child: Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('season.calendar'.tr(), style: context.textStyles.labelMedium?.copyWith(color: LightModeColors.lightPrimary, fontWeight: FontWeight.w600))));
}