import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/features/home/presentation/widgets/hunting_species_link.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/weather/presentation/today_weather_slot.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/map/providers/map_providers.dart';
import 'package:hb_social/features/support/presentation/support_ticket_form.dart';
import 'package:hb_social/features/support/providers/support_providers.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:url_launcher/url_launcher.dart';

/// Compact mobile entry point that keeps hunting details out of the feed until
/// the user explicitly opens them.
class MobileTodayHuntingPanel extends StatefulWidget {
  const MobileTodayHuntingPanel({super.key});

  @override
  State<MobileTodayHuntingPanel> createState() => _MobileTodayHuntingPanelState();
}

class _MobileTodayHuntingPanelState extends State<MobileTodayHuntingPanel> with SingleTickerProviderStateMixin {
  late final AnimationController _attentionController;
  late final Animation<double> _attentionScale;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _attentionController = AnimationController(duration: const Duration(milliseconds: 850), vsync: this);
    _attentionScale = Tween<double>(begin: 0.9, end: 1.12).animate(CurvedAnimation(parent: _attentionController, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncAttentionAnimation();
  }

  void _syncAttentionAnimation() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_expanded || reduceMotion) {
      _attentionController.stop();
      _attentionController.value = 0.5;
    } else if (!_attentionController.isAnimating) {
      _attentionController.repeat(reverse: true);
    }
  }

  void _toggle() {
    setState(() => _expanded = !_expanded);
    _syncAttentionAnimation();
  }

  @override
  void dispose() {
    _attentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    expanded: _expanded,
    child: Column(children: [
      SizedBox(
        width: double.infinity,
        child: HBButton.primary(
          label: 'home.today_hunting_title'.tr(),
          onPressed: _toggle,
          leading: ScaleTransition(
            scale: _attentionScale,
            child: AnimatedRotation(
              turns: _expanded ? 0.5 : 0,
              duration: AppMotion.of(context).medium,
              curve: AppMotion.enter,
              child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: Colors.white),
            ),
          ),
        ),
      ),
      AnimatedSize(
        duration: AppMotion.of(context).medium,
        curve: AppMotion.enter,
        alignment: Alignment.topCenter,
        child: _expanded ? const Padding(padding: EdgeInsets.only(top: AppSpacing.sm), child: TodayHuntingCard()) : const SizedBox(width: double.infinity),
      ),
    ]),
  );
}

class TodayHuntingCard extends ConsumerStatefulWidget {
  final bool isWide;
  const TodayHuntingCard({super.key, this.isWide = false});

  @override
  ConsumerState<TodayHuntingCard> createState() => _TodayHuntingCardState();
}

class _TodayHuntingCardState extends ConsumerState<TodayHuntingCard> {
  Timer? timer;
  DateTime now = DateTime.now();
  bool locating = false;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(minutes: 1), (_) { if (mounted) setState(() => now = DateTime.now()); });
  }

  @override
  void dispose() { timer?.cancel(); super.dispose(); }

  Future<void> useLocation() async {
    setState(() => locating = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw StateError('denied');
      final position = await Geolocator.getCurrentPosition();
      final unit = await ref.read(mapRepositoryProvider).unitAt(position.latitude, position.longitude);
      ref.read(huntingContextProvider.notifier).setPositionUnit(position.latitude, position.longitude, regionId: unit?.regionId, unitId: unit?.id, unitType: unit?.unitType);
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('hunting.live.location_error'.tr())));
    } finally {
      if (mounted) setState(() => locating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final huntingContext = ref.watch(huntingContextProvider);
    ref.watch(huntingDataVersionProvider(huntingContext.regionId));
    final dataUpdated = ref.watch(huntingDataUpdatedProvider(huntingContext.regionId));
    final overview = ref.watch(huntingTodayProvider);
    final names = ref.watch(speciesNamesProvider).value ?? const <String, String>{};
    final regions = ref.watch(regionsWithCalendarsProvider);
    final changes = ref.watch(nextChangesProvider(30));
    final todayOuting = ref.watch(todayOutingProvider);
    final country = ref.watch(selectedCountryProvider);
    if (country != null && !country.hasCalendars) {
      return HBCard(radius: widget.isWide ? AppRadius.cardWeb : AppRadius.cardMobile, padding: const EdgeInsets.all(20), child: HBEmptyState(icon: Icons.calendar_month_outlined, title: 'hunting.empty.country_title'.tr(namedArgs: {'country': country.name}), message: 'hunting.empty.country_message'.tr(), action: HBButton.primary(label: 'hunting.empty.report_region'.tr(), onPressed: () => _reportMissingCountry(country.name))));
    }
    final selectedRegion = (regions.value ?? const <RegionCalendars>[]).where((item) => item.regionId == huntingContext.regionId).firstOrNull;
    return HBCard(
      radius: widget.isWide ? AppRadius.cardWeb : AppRadius.cardMobile,
      padding: const EdgeInsets.all(20),
      child: Stack(children: [
        Positioned(right: -20, bottom: -20, child: Image.asset('assets/images/today_illustration.png', width: 180, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const SizedBox.shrink())),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('home.today_hunting_title'.tr(), style: AppText.title.withColor(LightModeColors.text))), if (dataUpdated) Padding(padding: const EdgeInsets.only(right: AppSpacing.xs), child: HBChip(label: 'hunting.data_updated'.tr(), selected: true)), if (selectedRegion != null) HuntingRegionPill(label: selectedRegion.name, onTap: () => HuntingLiveControls.showRegionMenu(context, ref, regions.value ?? const []))]),
        const SizedBox(height: AppSpacing.sm),
        HuntingLiveControls(value: huntingContext, regions: regions.value ?? const [], onChooseDate: chooseDate),
        const SizedBox(height: AppSpacing.md),
        overview.when(
          loading: () => const HBSkeleton(height: 180),
          error: (_, __) => Text('home.today_hunting_error'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
          data: (value) => TodayHuntingContent(overview: value, names: names, now: now, onUseLocation: useLocation, locating: locating),
        ),
        const SizedBox(height: AppSpacing.md),
        TodayWeatherSlot(regionName: overview.value?.regionName),
        const SizedBox(height: AppSpacing.md),
        const Divider(height: 1, color: LightModeColors.lightDivider),
        const SizedBox(height: AppSpacing.md),
        Text('hunting.live.next_changes'.tr(), style: context.textStyles.titleSmall),
        const SizedBox(height: AppSpacing.xs),
        changes.when(loading: () => const HBSkeleton(height: 56), error: (_, __) => Text('hunting.live.changes_error'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), data: (items) => items.isEmpty ? Text('hunting.live.no_changes'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)) : Column(children: [for (final item in items.take(3)) HuntingChangeRow(change: item, names: names)])),
        const SizedBox(height: AppSpacing.sm),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: 'hunting.live.all'.tr(), onPressed: () => context.go('${AppRoutes.hunting}?tab=2'), size: HBButtonSize.sm), if (todayOuting.value != null) HBChip(label: 'diary.today.registered'.tr(), selected: true, icon: Icons.check_rounded, onTap: () => context.push(AppRoutes.diaryDetailPath(todayOuting.value!.id))) else HBButton.primary(label: 'diary.today.record'.tr(), icon: Icons.add_rounded, size: HBButtonSize.sm, onPressed: todayOuting.isLoading ? null : () { ref.read(outingFormProvider.notifier).setPrefill(startedAt: DateTime.now(), municipalityId: huntingContext.municipalityId); context.push(AppRoutes.diaryNew); }), if (huntingContext.regionId == null) HBButton.secondary(label: 'home.today_hunting_set_zone'.tr(), onPressed: () => context.go(AppRoutes.huntingZone), size: HBButtonSize.sm)]),
      ]),
      ]),
    );
  }

  Future<void> _reportMissingCountry(String countryName) async {
    if (ref.read(authSessionProvider).value == null) { context.push(AppRoutes.login); return; }
    final categories = await ref.read(supportCategoriesProvider.future);
    final preferred = categories.contains('content') ? 'content' : categories.firstOrNull;
    if (!mounted) return;
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => SupportTicketForm(initialCategory: preferred, initialSubject: 'hunting.empty.ticket_subject'.tr(namedArgs: {'country': countryName}), initialBody: 'hunting.empty.ticket_body'.tr(namedArgs: {'country': countryName})));
  }

  Future<void> chooseDate() async {
    final current = ref.read(huntingContextProvider).date;
    final today = DateTime.now();
    final value = await showDatePicker(context: context, initialDate: current, firstDate: today.subtract(const Duration(days: 400)), lastDate: today.add(const Duration(days: 400)));
    if (value != null) ref.read(huntingContextProvider.notifier).setDate(value);
  }
}

class HuntingLiveControls extends ConsumerWidget {
  final HuntingContext value;
  final List<RegionCalendars> regions;
  final VoidCallback onChooseDate;
  const HuntingLiveControls({super.key, required this.value, required this.regions, required this.onChooseDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRegion = regions.where((item) => item.regionId == value.regionId).firstOrNull;
    final today = DateTime.now();
    final dateLabel = _sameDay(value.date, today) ? 'calendar.today'.tr() : _sameDay(value.date, today.add(const Duration(days: 1))) ? 'calendar.tomorrow'.tr() : DateFormat('d MMM', context.locale.languageCode).format(value.date);
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
      if (selectedRegion == null) HBChip(icon: Icons.location_on_outlined, label: 'hunting.live.region'.tr(), onTap: () => showRegionMenu(context, ref, regions)),
      HBChip(icon: Icons.today_outlined, label: dateLabel, onTap: () => _dateMenu(context, ref)),
      HBChip(icon: Icons.map_outlined, label: value.appliesTo == null ? 'calendar.scope_all'.tr() : value.appliesTo!.toUpperCase(), onTap: () => _scopeMenu(context, ref)),
      if (value.unitId != null && value.lat != null) HBChip(icon: Icons.my_location_rounded, label: 'hunting.live.times_position'.tr(), selected: true),
    ]);
  }

  static Future<void> showRegionMenu(BuildContext context, WidgetRef ref, List<RegionCalendars> regions) async {
    final box = context.findRenderObject() as RenderBox;
    final offset = box.localToGlobal(Offset.zero);
    final selected = await showMenu<String>(context: context, position: RelativeRect.fromLTRB(offset.dx, offset.dy + 40, 24, 0), items: [for (final region in regions) PopupMenuItem(value: region.regionId, child: Text(region.calendars == 0 ? 'hunting.live.region_none'.tr(namedArgs: {'region': region.name}) : 'hunting.live.region_count'.tr(namedArgs: {'region': region.name, 'count': '${region.calendars}'})))]);
    if (selected != null) ref.read(huntingContextProvider.notifier).setRegion(selected);
  }

  Future<void> _dateMenu(BuildContext context, WidgetRef ref) async {
    final selected = await showMenu<int>(context: context, position: const RelativeRect.fromLTRB(120, 180, 20, 0), items: [PopupMenuItem(value: 0, child: Text('calendar.today'.tr())), PopupMenuItem(value: 1, child: Text('calendar.tomorrow'.tr())), PopupMenuItem(value: 2, child: Text('hunting.live.choose_date'.tr()))]);
    if (selected == 0) ref.read(huntingContextProvider.notifier).setDate(DateTime.now());
    if (selected == 1) ref.read(huntingContextProvider.notifier).setDate(DateTime.now().add(const Duration(days: 1)));
    if (selected == 2) onChooseDate();
  }

  Future<void> _scopeMenu(BuildContext context, WidgetRef ref) async {
    final selected = await showMenu<String>(context: context, position: const RelativeRect.fromLTRB(240, 180, 20, 0), items: [PopupMenuItem(value: 'all', child: Text('calendar.scope_all'.tr())), const PopupMenuItem(value: 'atc', child: Text('ATC')), const PopupMenuItem(value: 'ca', child: Text('CA'))]);
    if (selected != null) ref.read(huntingContextProvider.notifier).setAppliesTo(selected == 'all' ? null : selected);
  }

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class TodayHuntingContent extends StatelessWidget {
  final HuntingOverview? overview;
  final Map<String, String> names;
  final DateTime now;
  final VoidCallback onUseLocation;
  final bool locating;
  const TodayHuntingContent({super.key, required this.overview, required this.names, required this.now, required this.onUseLocation, required this.locating});

  @override
  Widget build(BuildContext context) {
    final value = overview;
    if (value == null) return Text('home.today_hunting_cta_subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant));
    if (value.entries.isEmpty) return Text('home.today_hunting_no_calendars'.tr(namedArgs: {'region': value.regionName}), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant));
    final timed = value.entries.where((item) => item.opensAt != null && item.closesAt != null).firstOrNull;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (timed != null) HuntingHoursRow(entry: timed, now: now),
      const SizedBox(height: AppSpacing.xs),
      HuntingPositionNote(regionName: value.regionName, onUseLocation: onUseLocation, locating: locating),
      const SizedBox(height: AppSpacing.md),
      if (value.open.isEmpty) Text(value.firstNextOpen == null ? 'home.today_hunting_none_open'.tr() : 'hunting.today.all_closed_next'.tr(namedArgs: {'date': DateFormat('EEEE d MMMM', context.locale.languageCode).format(value.firstNextOpen!)}), style: context.textStyles.bodyMedium),
      for (final category in value.open.map((item) => item.category).toSet()) TodayCategoryGroup(category: category, entries: value.open.where((item) => item.category == category).toList(), names: names),
      if (value.closed.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Text('hunting.today.closed_count'.tr(namedArgs: {'count': '${value.closed.length}'}), style: context.textStyles.labelMedium?.withColor(LightModeColors.lightOnSurfaceVariant)), for (final entry in value.closed) TodaySpeciesRow(entry: entry, name: entry.localizedName(names), closed: true)],
      const SizedBox(height: AppSpacing.md),
      TodaySources(entries: value.entries),
    ]);
  }
}

class HuntingPositionNote extends ConsumerWidget {
  final String regionName;
  final VoidCallback onUseLocation;
  final bool locating;
  const HuntingPositionNote({super.key, required this.regionName, required this.onUseLocation, required this.locating});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(huntingContextProvider);
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpacing.sm, children: [Text(value.municipalityName != null ? 'hunting.live.times_municipality'.tr(namedArgs: {'municipality': value.municipalityName!}) : value.lat != null ? 'hunting.live.times_position'.tr() : 'hunting.live.times_centroid'.tr(namedArgs: {'region': regionName}), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (value.lat == null) HBButton.ghost(label: value.municipalityName == null ? 'hunting.live.use_location'.tr() : 'hunting.live.set_municipality'.tr(), onPressed: locating ? null : onUseLocation, size: HBButtonSize.sm)]);
  }
}

class HuntingHoursRow extends StatelessWidget {
  final CalendarDayInfo entry;
  final DateTime now;
  const HuntingHoursRow({super.key, required this.entry, required this.now});
  @override
  Widget build(BuildContext context) {
    final opens = entry.opensAt!.toLocal();
    final closes = entry.closesAt!.toLocal();
    String status;
    if (now.isBefore(opens)) status = 'hunting.live.opens_in'.tr(namedArgs: _duration(opens.difference(now)));
    else if (now.isBefore(closes)) status = 'hunting.live.open_now'.tr(namedArgs: _duration(closes.difference(now)));
    else status = 'hunting.live.closed_today'.tr();
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.wb_twilight_outlined, color: LightModeColors.lightPrimary, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('hunting.live.hours'.tr(namedArgs: {'from': DateFormat.Hm().format(opens), 'to': DateFormat.Hm().format(closes)}), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), Text(status, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))]);
  }
  Map<String, String> _duration(Duration value) => {'hours': '${value.inHours}', 'minutes': '${value.inMinutes.remainder(60)}'};
}

class TodayCategoryGroup extends StatelessWidget {
  final String category;
  final List<CalendarDayInfo> entries;
  final Map<String, String> names;
  const TodayCategoryGroup({super.key, required this.category, required this.entries, required this.names});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('hunting.category.$category'.tr(), style: context.textStyles.labelMedium?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.xs), for (final entry in entries) TodaySpeciesRow(entry: entry, name: entry.localizedName(names))]));
}

class TodaySpeciesRow extends StatelessWidget {
  final CalendarDayInfo entry;
  final String name;
  final bool closed;
  const TodaySpeciesRow({super.key, required this.entry, required this.name, this.closed = false});
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => openHuntingSpecies(context, entry.speciesId), child: Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [Expanded(child: Text(name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: closed ? FontWeight.w500 : FontWeight.w700))), if (closed && entry.nextOpen != null) Text(DateFormat('EEE d MMM', context.locale.languageCode).format(entry.nextOpen!), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(width: AppSpacing.xs), const Icon(Icons.chevron_right, color: LightModeColors.lightPrimary, size: 18)])));
}

class HuntingChangeRow extends StatelessWidget {
  final CalendarChange change;
  final Map<String, String> names;
  const HuntingChangeRow({super.key, required this.change, required this.names});
  @override
  Widget build(BuildContext context) => InkWell(onTap: () => openHuntingSpecies(context, change.speciesId), child: Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 58, child: Text(DateFormat('d MMM', context.locale.languageCode).format(change.changeDate), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))), Expanded(child: Text('hunting.live.change_${change.kind}'.tr(namedArgs: {'species': change.localizedName(names)}), style: context.textStyles.bodySmall)), const Icon(Icons.chevron_right, color: LightModeColors.lightPrimary, size: 16)])));
}

class TodaySources extends StatelessWidget {
  final List<CalendarDayInfo> entries;
  const TodaySources({super.key, required this.entries});
  @override
  Widget build(BuildContext context) {
    final sources = <String, String?>{};
    for (final entry in entries) if (entry.sourceName?.isNotEmpty == true) sources[entry.sourceName!] = entry.sourceUrl;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [for (final source in sources.entries) InkWell(onTap: source.value == null ? null : () => launchUrl(Uri.parse(source.value!), mode: LaunchMode.externalApplication), child: Text(source.key, style: context.textStyles.labelSmall?.withColor(LightModeColors.lightPrimary))), const SizedBox(height: AppSpacing.xs), Text('hunting.today.official_warning'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightOnSurfaceVariant))]);
  }
}

class HuntingRegionPill extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const HuntingRegionPill({super.key, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => Material(color: LightModeColors.bosco, borderRadius: BorderRadius.circular(AppRadius.pill), child: InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.pill), child: Container(height: 36, alignment: Alignment.center, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.place_outlined, size: 16, color: Colors.white), const SizedBox(width: AppSpacing.xs), Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.buttonSm.withColor(Colors.white)))]))));
}