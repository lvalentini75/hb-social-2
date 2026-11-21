import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/home/presentation/widgets/hunting_species_link.dart';
import 'package:hb_social/features/home/presentation/widgets/today_hunting_card.dart';
import 'package:hb_social/features/hunting/presentation/hunting_calendar_page.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/weather/presentation/weather_tab.dart';
import 'package:hb_social/features/sightings/presentation/species_activity_card.dart';

class HuntingHubPage extends ConsumerStatefulWidget {
  const HuntingHubPage({super.key});
  @override
  ConsumerState<HuntingHubPage> createState() => _HuntingHubPageState();
}

class _HuntingHubPageState extends ConsumerState<HuntingHubPage> {
  int tab = 0;
  bool initialized = false;
  @override
  Widget build(BuildContext context) {
    final regionId = ref.watch(huntingContextProvider.select((value) => value.regionId));
    ref.watch(huntingDataVersionProvider(regionId));
    if (!initialized) { initialized = true; tab = int.tryParse(GoRouterState.of(context).uri.queryParameters['tab'] ?? '')?.clamp(0, 4) ?? 0; }
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
    Text('hunting.title'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
    const SizedBox(height: AppSpacing.xs),
    Text('hunting.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
    const SizedBox(height: AppSpacing.lg),
    HBSegmentedTabs(labels: ['hunting.tabs.today'.tr(), 'hunting.tabs.calendar'.tr(), 'hunting.tabs.upcoming'.tr(), 'hunting.tabs.sun'.tr(), 'weather.tab'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value), scrollable: true),
    const SizedBox(height: AppSpacing.lg),
    switch (tab) { 0 => const Column(children: [TodayHuntingCard(isWide: true), SizedBox(height: AppSpacing.lg), SpeciesActivityCard()]), 1 => const HuntingCalendarTab(), 2 => const HuntingUpcomingTab(), 3 => const HuntingSunTab(), _ => const HuntingWeatherTab() },
    const SizedBox(height: AppSpacing.lg),
    HBCard(child: HBEmptyState(icon: Icons.menu_book_outlined, title: 'hunting.future_tools'.tr(), message: 'hunting.future_tools_message'.tr())),
  ]))]));
  }
}

class HuntingCalendarTab extends ConsumerWidget {
  const HuntingCalendarTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(huntingTodayProvider);
    final names = ref.watch(speciesNamesProvider).value ?? const <String, String>{};
    return value.when(loading: () => const HBSkeleton(height: 280), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'calendar.error_title'.tr(), message: 'calendar.error_message'.tr())), data: (overview) => overview == null ? HBCard(child: HBEmptyState(icon: Icons.location_on_outlined, title: 'calendar.empty_no_zone_title'.tr(), message: 'calendar.empty_no_zone_message'.tr())) : CalendarOverviewList(overview: overview, names: names));
  }
}

class HuntingUpcomingTab extends ConsumerWidget {
  const HuntingUpcomingTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final changes = ref.watch(nextChangesProvider(60));
    final names = ref.watch(speciesNamesProvider).value ?? const <String, String>{};
    return changes.when(loading: () => const HBSkeleton(height: 240), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'hunting.live.changes_error'.tr(), message: 'calendar.error_message'.tr())), data: (items) {
      if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.event_available_outlined, title: 'hunting.live.no_changes'.tr(), message: 'hunting.live.no_changes_message'.tr()));
      final dates = items.map((item) => DateUtils.dateOnly(item.changeDate)).toSet();
      return Column(children: [for (final date in dates) ...[Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Align(alignment: Alignment.centerLeft, child: Text(DateFormat.yMMMMd(context.locale.languageCode).format(date), style: context.textStyles.titleMedium))), HBCard(child: Column(children: [for (final item in items.where((change) => DateUtils.isSameDay(change.changeDate, date))) InkWell(onTap: () => openHuntingSpecies(context, item.speciesId), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [Expanded(child: Text(item.localizedName(names))), HBStatusChip(kind: _kind(item.kind), label: 'hunting.live.kind_${item.kind}'.tr())])))]))]]);
    });
  }
  HBStatusKind _kind(String value) => switch (value) { 'opens' => HBStatusKind.approved, 'closes' => HBStatusKind.rejected, _ => HBStatusKind.pending };
}

class HuntingSunTab extends ConsumerWidget {
  const HuntingSunTab({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final huntingContext = ref.watch(huntingContextProvider);
    if (huntingContext.lat == null || huntingContext.lng == null) return HBCard(child: Column(children: [HBEmptyState(icon: Icons.my_location_outlined, title: 'hunting.sun.position_title'.tr(), message: 'hunting.sun.position_message'.tr()), Wrap(spacing: AppSpacing.sm, children: [HBButton.soft(label: 'hunting.live.use_location'.tr(), icon: Icons.my_location, onPressed: () => _useLocation(context, ref)), HBButton.ghost(label: 'hunting.live.set_municipality'.tr(), onPressed: () => context.go(AppRoutes.settings))])]));
    final days = ref.watch(huntingSunWeekProvider);
    return days.when(loading: () => const HBSkeleton(height: 260), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'hunting.sun.error'.tr(), message: 'calendar.error_message'.tr())), data: (items) => HBCard(child: Column(children: [HBTile(child: Row(children: [Expanded(child: Text('hunting.sun.day'.tr())), Expanded(child: Text('calendar.sunrise'.tr())), Expanded(child: Text('calendar.sunset'.tr())), Expanded(child: Text('hunting.sun.hunting_hours'.tr()))])), for (final item in items) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [Expanded(child: Text(DateFormat('EEE d MMM', context.locale.languageCode).format(item.sun.day))), Expanded(child: Text(DateFormat.Hm().format(item.sun.sunrise.toLocal()))), Expanded(child: Text(DateFormat.Hm().format(item.sun.sunset.toLocal()))), Expanded(child: Text(item.opensAt == null || item.closesAt == null ? '-' : '${DateFormat.Hm().format(item.opensAt!.toLocal())}-${DateFormat.Hm().format(item.closesAt!.toLocal())}'))]))])));
  }

  Future<void> _useLocation(BuildContext context, WidgetRef ref) async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw StateError('denied');
      final position = await Geolocator.getCurrentPosition();
      ref.read(huntingContextProvider.notifier).setPosition(position.latitude, position.longitude);
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('hunting.live.location_error'.tr())));
    }
  }
}