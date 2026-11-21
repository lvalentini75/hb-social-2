import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/composer/presentation/composer_sheet.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/diary/presentation/outing_media_panel.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/events/presentation/event_map.dart';
import 'package:hb_social/features/weather/presentation/weather_widgets.dart';
import 'package:hb_social/features/map/providers/map_providers.dart';
import 'package:hb_social/features/sightings/presentation/sighting_widgets.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class OutingDetailPage extends ConsumerWidget {
  final String outingId;
  const OutingDetailPage({super.key, required this.outingId});

  Future<void> _action(BuildContext context, WidgetRef ref, Outing outing, String action) async {
    if (action == 'edit') { context.push(AppRoutes.diaryEditPath(outing.id)); return; }
    if (action == 'duplicate') { ref.read(outingFormProvider.notifier).setSource(outing, duplicate: true); context.push(AppRoutes.diaryNew); return; }
    if (action == 'delete') {
      final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('diary.delete_title'.tr()), content: Text('diary.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.secondary(label: 'diary.actions.delete'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
      if (!confirmed) return;
      try { await ref.read(diaryRepositoryProvider).deleteOuting(outing.id); ref.invalidate(diarySeasonsProvider(null)); ref.invalidate(diaryStatsProvider); ref.invalidate(todayOutingProvider); if (context.mounted) context.go(AppRoutes.diary); }
      on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(outingProvider(outingId)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.symmetric(vertical: AppSpacing.lg), child: HBSkeleton(height: 500, radius: AppRadius.lg))),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'diary.error_title'.tr(), message: 'diary.error_message'.tr()))),
    data: (outing) => outing == null ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'diary.unavailable_title'.tr(), message: 'diary.unavailable_message'.tr()))) : OutingDetailBody(outing: outing, onAction: (action) => _action(context, ref, outing, action)),
  );
}

class OutingDetailBody extends ConsumerWidget {
  final Outing outing;
  final ValueChanged<String> onAction;
  const OutingDetailBody({super.key, required this.outing, required this.onAction});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final owner = ref.watch(supabaseClientProvider).auth.currentUser?.id == outing.userId;
    final started = outing.startedAt.toLocal();
    final title = outing.title?.isNotEmpty == true ? outing.title! : 'diary.outing_on'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.languageCode).format(started)});
    final duration = outing.durationMin ?? outing.endedAt?.difference(outing.startedAt).inMinutes;
    final where = [outing.zoneName, if (outing.municipalityName != null) '${outing.municipalityName}${outing.provinceCode == null ? '' : ' (${outing.provinceCode})'}', outing.unitName, outing.regionName].whereType<String>().where((value) => value.isNotEmpty).join(' · ');
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('${DateFormat('EEEE d MMMM y · HH:mm', context.locale.languageCode).format(started)}${outing.endedAt == null ? '' : ' – ${DateFormat.Hm().format(outing.endedAt!.toLocal())}'}', style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)), if (where.isNotEmpty) ...[const SizedBox(height: AppSpacing.xs), Text(where)], const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, children: [HBChip(label: outing.method.labelKey.tr(), selected: false), HBChip(label: outing.visibility.labelKey.tr(), selected: false)])])), if (owner) PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: onAction, itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('diary.actions.edit'.tr())), PopupMenuItem(value: 'duplicate', child: Text('diary.duplicate'.tr())), PopupMenuItem(value: 'delete', child: Text('diary.actions.delete'.tr()))])]),
      if (duration != null) ...[const SizedBox(height: AppSpacing.md), Text('diary.duration_minutes'.tr(namedArgs: {'n': '$duration'}))],
      const SizedBox(height: AppSpacing.lg),
      DiaryDetailTile(title: 'diary.harvests'.tr(), icon: Icons.agriculture_outlined, child: outing.species.isEmpty ? Text('diary.no_harvests'.tr()) : Column(children: [for (final species in outing.species) Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [Expanded(child: Text(species.name)), Text('diary.species_counts'.tr(namedArgs: {'seen': '${species.seenCount}', 'shots': '${species.shots}', 'harvested': '${species.harvestCount}'}))])), const Divider(), Row(children: [Expanded(child: Text('diary.total'.tr(), style: context.textStyles.titleSmall)), Text('${outing.harvestTotal}', style: context.textStyles.titleMedium)])])),
      if (outing.dogs.isNotEmpty) DiaryDetailTile(title: 'diary.dogs'.tr(), icon: Icons.pets_outlined, child: Column(children: [for (final dog in outing.dogs) InkWell(onTap: () => context.push(AppRoutes.dogDetailPath(dog.id)), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [HBAvatar(name: dog.name, imageUrl: dog.avatarUrl, size: 40), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(dog.name), if (dog.breed != null) Text(dog.breed!, style: context.textStyles.bodySmall)])), const Icon(Icons.chevron_right_rounded)])))])),
      if (outing.weather != null) DiaryDetailTile(title: 'diary.weather.title'.tr(), icon: Icons.cloud_outlined, child: OutingWeatherDetail(weather: outing.weather!)),
      if (owner && outing.point != null) DiaryDetailTile(title: 'diary.position.title'.tr(), icon: Icons.location_on_outlined, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [EventMap(latitude: outing.point!.lat, longitude: outing.point!.lng, height: 220), const SizedBox(height: AppSpacing.sm), Text('${outing.point!.lat.toStringAsFixed(5)}, ${outing.point!.lng.toStringAsFixed(5)}'), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: 'diary.position.open_map'.tr(), icon: Icons.map_outlined, onPressed: () => context.push('${AppRoutes.map}?lat=${outing.point!.lat}&lng=${outing.point!.lng}')), HBButton.ghost(label: 'diary.position.open_maps'.tr(), icon: Icons.open_in_new_rounded, onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/search/?api=1&query=${outing.point!.lat},${outing.point!.lng}'), mode: LaunchMode.externalApplication))])])) ,
      if (owner && outing.point != null) FutureBuilder(future: ref.read(mapRepositoryProvider).unitAt(outing.point!.lat, outing.point!.lng), builder: (context, snapshot) { final detected = snapshot.data; if (detected == null || detected.id == outing.unitId) return const SizedBox.shrink(); return DiaryDetailTile(title: 'map.detected_unit'.tr(), icon: Icons.my_location_rounded, child: Text(detected.name)); }),
      if (outing.notes?.isNotEmpty == true) DiaryDetailTile(title: 'diary.notes'.tr(), icon: Icons.notes_rounded, child: Text(outing.notes!)),
      if (outing.distanceM != null) DiaryDetailTile(title: 'diary.distance'.tr(), icon: Icons.route_outlined, child: Text('diary.distance_km'.tr(namedArgs: {'n': (outing.distanceM! / 1000).toStringAsFixed(1)}))),
      OutingMediaPanel(outingId: outing.id, editable: owner),
      if (owner) OutingSightingsSection(outing: outing),
      const SizedBox(height: AppSpacing.md), HBButton.ghost(label: 'diary.stats.season_link'.tr(), icon: Icons.analytics_outlined, onPressed: () => context.go('${AppRoutes.diary}?tab=stats&season=${outing.seasonLabel ?? ''}')),
      if (owner && outing.visibility != OutingVisibility.private) ...[const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'diary.share_feed'.tr(), icon: Icons.share_outlined, onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ComposerSheet(initialText: 'diary.share_text'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.languageCode).format(started), 'zone': outing.zoneName ?? '', 'harvest': '${outing.harvestTotal}'}))))],
      const SizedBox(height: AppSpacing.xxl),
    ]))]));
  }
}

class OutingSightingsSection extends ConsumerWidget {
  final Outing outing;
  const OutingSightingsSection({super.key, required this.outing});
  void _add(BuildContext context, WidgetRef ref) { ref.read(sightingFormPrefillProvider.notifier).state = SightingFormPrefill(logId: outing.id, sightedAt: outing.startedAt, lat: outing.point?.lat, lng: outing.point?.lng, accuracyM: outing.point?.accuracyM, municipalityId: outing.municipalityId); context.push(AppRoutes.sightingsNew); }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = (season: null, speciesId: null, logId: outing.id);
    return DiaryDetailTile(title: 'sightings.outing_section.title'.tr(), icon: Icons.visibility_outlined, child: ref.watch(mySightingsProvider(request)).when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('sightings.errors.generic'.tr()), data: (state) => Column(children: [if (state.items.isEmpty) Text('sightings.outing_section.empty'.tr()), for (final item in state.items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: SightingCard(sighting: item, compact: true)), Align(alignment: Alignment.centerLeft, child: HBButton.secondary(label: 'sightings.outing_section.add'.tr(), icon: Icons.add_rounded, onPressed: () => _add(context, ref)))])));
  }
}

class DiaryDetailTile extends StatelessWidget {
  final String title; final IconData icon; final Widget child;
  const DiaryDetailTile({super.key, required this.title, required this.icon, required this.child});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Icon(icon, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Text(title, style: context.textStyles.titleMedium)]), const SizedBox(height: AppSpacing.md), child])));
}

class OutingWeatherDetail extends StatelessWidget {
  final OutingWeather weather;
  const OutingWeatherDetail({super.key, required this.weather});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [WeatherConditionIcon(code: weather.weatherCode ?? 0, isDay: weather.isDay, size: 36), const SizedBox(width: AppSpacing.sm), Text('${weather.temperature?.round()}°', style: context.textStyles.headlineSmall), if (weather.hour != null) Text(' · ${'diary.weather.at'.tr(namedArgs: {'hour': weather.hour!})}')]), const SizedBox(height: AppSpacing.sm), Text('diary.weather.details'.tr(namedArgs: {'wind': weather.windSpeed?.toStringAsFixed(0) ?? '—', 'direction': weather.windDirection?.toStringAsFixed(0) ?? '—', 'rain': weather.precipitation?.toStringAsFixed(1) ?? '—', 'humidity': '${weather.humidity ?? 0}', 'moon': weather.moonPhaseName ?? '—'})), const SizedBox(height: AppSpacing.xs), Text('diary.weather.source'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]);
}