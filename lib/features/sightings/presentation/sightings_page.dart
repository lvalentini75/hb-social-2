import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/events/data/photon_place_service.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/presentation/sighting_widgets.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:hb_social/core/widgets/hb_page_header.dart';

class SightingsPage extends ConsumerStatefulWidget {
  final int initialTab;
  final String? initialSpeciesId;
  final int initialDays;
  final double initialRadius;
  final double? initialLat, initialLng;
  const SightingsPage({super.key, this.initialTab = 0, this.initialSpeciesId, this.initialDays = 90, this.initialRadius = 25, this.initialLat, this.initialLng});
  @override ConsumerState<SightingsPage> createState() => _SightingsPageState();
}

class _SightingsPageState extends ConsumerState<SightingsPage> {
  late int tab = widget.initialTab;
  late String? speciesId = widget.initialSpeciesId;
  late int days = widget.initialDays;
  late double radius = widget.initialRadius;
  String? season;
  SightingKind? kind;
  void _add() => ref.read(supabaseClientProvider).auth.currentUser == null ? context.push(AppRoutes.login) : context.push(AppRoutes.sightingsNew);

  @override Widget build(BuildContext context) {
    final species = ref.watch(speciesProvider).value ?? const <Species>[];
    final activeAlerts = ref.watch(mySightingAlertsProvider).value?.where((item) => item.isActive).length ?? 0;
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.lg), sliver: SliverList.list(children: [
      HBPageHeader(title: 'sightings.title'.tr(), subtitle: 'sightings.subtitle'.tr(), action: MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? null : Row(mainAxisSize: MainAxisSize.min, children: [HBButton.soft(label: 'sighting_alerts.button'.tr(namedArgs: {'count': '$activeAlerts'}), icon: Icons.notifications_active_outlined, onPressed: () => context.push(AppRoutes.sightingAlerts)), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'sightings.actions.add'.tr(), icon: Icons.add_rounded, onPressed: _add)])),
      const SizedBox(height: AppSpacing.md),
      ConstrainedBox(constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? double.infinity : 420), child: HBSegmentedTabs(labels: ['sightings.tabs.mine'.tr(), 'p30b.nearby.tab'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value))),
      const SizedBox(height: AppSpacing.md),
      if (MediaQuery.sizeOf(context).width < AppBreakpoints.mobile) ...[Row(children: [Expanded(child: HBButton.soft(label: 'sighting_alerts.button'.tr(namedArgs: {'count': '$activeAlerts'}), icon: Icons.notifications_active_outlined, onPressed: () => context.push(AppRoutes.sightingAlerts))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.primary(label: 'sightings.actions.add'.tr(), icon: Icons.add_rounded, onPressed: _add))]), const SizedBox(height: AppSpacing.md)],
      if (tab == 0) MySightingsTab(season: season, speciesId: speciesId, kind: kind, onSeason: (value) => setState(() => season = value), onSpecies: (value) => setState(() => speciesId = value), onKind: (value) => setState(() => kind = value), onAdd: _add)
      else NearbySightingsTab(species: species, speciesId: speciesId, days: days, radius: radius, kind: kind, initialLat: widget.initialLat, initialLng: widget.initialLng, onSpecies: (value) => setState(() => speciesId = value), onDays: (value) => setState(() => days = value), onRadius: (value) => setState(() => radius = value), onKind: (value) => setState(() => kind = value)),
      const SizedBox(height: AppSpacing.xxl),
    ]))]));
  }
}

class MySightingsTab extends ConsumerWidget {
  final String? season, speciesId; final SightingKind? kind; final ValueChanged<String?> onSeason, onSpecies; final ValueChanged<SightingKind?> onKind; final VoidCallback onAdd;
  const MySightingsTab({super.key, this.season, this.speciesId, this.kind, required this.onSeason, required this.onSpecies, required this.onKind, required this.onAdd});
  @override Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(supabaseClientProvider).auth.currentUser == null) return HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'p30b.guest.title'.tr(), message: 'p30b.guest.message'.tr(), action: HBButton.primary(label: 'auth.login'.tr(), onPressed: () => context.push(AppRoutes.login))));
    final seasons = ref.watch(diarySeasonsProvider(null)).value ?? const [];
    final selectedSeason = season ?? ref.watch(diaryCurrentSeasonProvider).value;
    final species = ref.watch(speciesProvider).value ?? const <Species>[];
    final request = (season: selectedSeason, speciesId: speciesId, logId: null);
    final value = ref.watch(mySightingsProvider(request));
    return Column(children: [HBCard(child: Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [SizedBox(width: 210, child: HBSelect<String>(value: selectedSeason, placeholder: 'sightings.filters.season'.tr(), options: [for (final item in seasons) HBSelectOption(value: item.seasonLabel, label: item.seasonLabel)], onChanged: onSeason)), SizedBox(width: 230, child: HBSelect<String>(value: speciesId, placeholder: 'sightings.filters.species'.tr(), allowClear: true, options: [for (final item in species) HBSelectOption(value: item.id, label: item.localizedName)], onChanged: onSpecies)), SizedBox(width: 210, child: HBSelect<SightingKind>(value: kind, placeholder: 'sightings.filters.kind'.tr(), allowClear: true, options: [for (final item in SightingKind.values) HBSelectOption(value: item, label: item.labelKey.tr())], onChanged: onKind))])), const SizedBox(height: AppSpacing.md), value.when(loading: () => const HBListSkeleton(count: 4), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'sightings.errors.title'.tr(), message: 'sightings.errors.generic'.tr())), data: (state) { final items = kind == null ? state.items : state.items.where((item) => item.kind == kind).toList(); if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.visibility_outlined, title: 'sightings.empty.title'.tr(), message: 'sightings.empty.message'.tr(), action: HBButton.primary(label: 'sightings.actions.add'.tr(), onPressed: onAdd))); return SightingsList(items: items, hasMore: state.hasMore, loadingMore: state.loadingMore, onLoadMore: () => ref.read(mySightingsProvider(request).notifier).loadMore()); })]);
  }
}

class NearbySightingsTab extends ConsumerWidget {
  final List<Species> species; final String? speciesId; final int days; final double radius; final SightingKind? kind; final double? initialLat, initialLng; final ValueChanged<String?> onSpecies; final ValueChanged<int> onDays; final ValueChanged<double> onRadius; final ValueChanged<SightingKind?> onKind;
  const NearbySightingsTab({super.key, required this.species, this.speciesId, required this.days, required this.radius, this.kind, this.initialLat, this.initialLng, required this.onSpecies, required this.onDays, required this.onRadius, required this.onKind});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final hunting = ref.watch(huntingContextProvider); final lat = initialLat ?? hunting.lat, lng = initialLng ?? hunting.lng;
    if (lat == null || lng == null) return HBCard(child: HBEmptyState(icon: Icons.location_on_outlined, title: 'p30b.nearby.no_location_title'.tr(), message: 'p30b.nearby.no_location_message'.tr(), action: const SizedBox(width: 280, child: NearbyCenterPicker())));
    final request = (lat: lat, lng: lng, radiusKm: radius, speciesId: speciesId, days: days); final value = ref.watch(nearbySightingsProvider(request));
    return Column(children: [HBCard(child: Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.md, crossAxisAlignment: WrapCrossAlignment.center, children: [const SizedBox(width: 260, child: NearbyCenterPicker()), HBChoice<double>(options: const [5, 10, 25, 50], value: radius, onChanged: onRadius, labelBuilder: (value) => '${value.toInt()} km'), SizedBox(width: 220, child: HBSelect<String>(value: speciesId, allowClear: true, placeholder: 'sightings.filters.species'.tr(), options: [for (final item in species) HBSelectOption(value: item.id, label: item.localizedName)], onChanged: onSpecies)), HBChoice<int>(options: const [7, 30, 90, 365], value: days, onChanged: onDays, labelBuilder: (value) => value == 365 ? 'sightings.filters.season'.tr() : 'p30b.days'.tr(namedArgs: {'days': '$value'})), SizedBox(width: 180, child: HBSelect<SightingKind>(value: kind, allowClear: true, placeholder: 'sightings.filters.kind'.tr(), options: [for (final item in SightingKind.values) HBSelectOption(value: item, label: item.labelKey.tr())], onChanged: onKind))])), const SizedBox(height: AppSpacing.md), value.when(loading: () => const HBListSkeleton(count: 5), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'sightings.errors.title'.tr(), message: 'sightings.errors.generic'.tr())), data: (rows) { final items = kind == null ? rows : rows.where((item) => item.kind == kind).toList(); if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.travel_explore_outlined, title: 'p30b.nearby.empty_title'.tr(), message: 'p30b.nearby.empty_message'.tr())); final counts = <String, int>{}; for (final item in items) counts[item.species.id] = (counts[item.species.id] ?? 0) + 1; final top = counts.entries.toList()..sort((a, b) => b.value.compareTo(a.value)); return Column(children: [HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('p30b.nearby.summary'.tr(namedArgs: {'count': '${items.length}', 'species': '${counts.length}', 'last': timeago.format(items.first.sightedAt.toLocal(), locale: context.locale.languageCode)}), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, children: [for (final entry in top.take(3)) HBChip(label: items.firstWhere((item) => item.species.id == entry.key).species.name, selected: speciesId == entry.key, onTap: () => onSpecies(entry.key))])])), const SizedBox(height: AppSpacing.md), for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: NearbySightingCard(item: item))]); })]);
  }
}

class NearbyCenterPicker extends ConsumerStatefulWidget { const NearbyCenterPicker({super.key}); @override ConsumerState<NearbyCenterPicker> createState() => _NearbyCenterPickerState(); }
class _NearbyCenterPickerState extends ConsumerState<NearbyCenterPicker> { final controller = TextEditingController(); @override void dispose() { controller.dispose(); super.dispose(); } @override Widget build(BuildContext context) => HBPlaceField<PhotonPlace>(controller: controller, hint: 'p30b.nearby.choose_location'.tr(), search: (query) async => [for (final place in await PhotonPlaceService().search(query, language: context.locale.languageCode)) HBPlaceSuggestion(value: place, title: place.name, subtitle: place.address)], onSelected: (place) => ref.read(huntingContextProvider.notifier).setPosition(place.latitude, place.longitude)); }

class NearbySightingCard extends ConsumerWidget {
  final NearbySighting item; const NearbySightingCard({super.key, required this.item});
  @override Widget build(BuildContext context, WidgetRef ref) { final image = ref.watch(sightingsRepositoryProvider).publicUrl(item.thumbnailPath ?? item.mediaPath); final distance = '${(item.distanceM / 1000).toStringAsFixed(1)} km${item.isExact ? '' : ' ${'p30b.nearby.about'.tr()}'}'; return HBCard(padding: EdgeInsets.zero, child: InkWell(onTap: () => context.push(AppRoutes.sightingDetailPath(item.id)), child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: SizedBox.square(dimension: 72, child: image == null ? ColoredBox(color: LightModeColors.lightPrimarySoft, child: Icon(item.kind.icon, color: LightModeColors.lightPrimary)) : Image.network(image, fit: BoxFit.cover))), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('sightings.animals'.plural(item.animalsCount, namedArgs: {'count': '${item.animalsCount}', 'species': item.species.name}), style: context.textStyles.titleMedium), Text('${item.kind.labelKey.tr()} · ${timeago.format(item.sightedAt.toLocal(), locale: context.locale.languageCode)}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), Row(children: [HBAvatar(name: item.author.displayName, imageUrl: item.author.avatarUrl, size: 24), const SizedBox(width: 6), Expanded(child: Text(item.isMine ? 'p30b.you'.tr() : item.author.displayName, overflow: TextOverflow.ellipsis))]), Text('${item.municipality?.name ?? 'p30b.nearby.area'.tr()} · $distance', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (!item.isExact) HBChip(label: 'p30b.nearby.cell'.tr(), selected: false)])), const Icon(Icons.chevron_right_rounded)])))); }
}