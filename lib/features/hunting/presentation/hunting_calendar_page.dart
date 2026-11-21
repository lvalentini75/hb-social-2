import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class HuntingCalendarPage extends ConsumerStatefulWidget {
  const HuntingCalendarPage({super.key});
  @override
  ConsumerState<HuntingCalendarPage> createState() => _HuntingCalendarPageState();
}

class _HuntingCalendarPageState extends ConsumerState<HuntingCalendarPage> {
  Future<void> chooseDate() async {
    final current = ref.read(huntingContextProvider).date;
    final value = await showDatePicker(context: context, initialDate: current, firstDate: DateTime.now().subtract(const Duration(days: 400)), lastDate: DateTime.now().add(const Duration(days: 400)));
    if (value != null) ref.read(huntingContextProvider.notifier).setDate(value);
  }

  @override
  Widget build(BuildContext context) {
    final selected = ref.watch(huntingContextProvider);
    final names = ref.watch(speciesNamesProvider).value ?? const <String, String>{};
    final overview = selected.regionId == null ? null : ref.watch(huntingOverviewProvider(HuntingOverviewRequest(selected.regionId!, selected.date, selected.appliesTo, selected.lat, selected.lng)));
    final country = ref.watch(selectedCountryProvider);
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      HBPageHeader(title: 'calendar.title'.tr()),
      const SizedBox(height: AppSpacing.lg),
      if (country != null && !country.hasCalendars)
        HBCard(child: HBEmptyState(icon: Icons.calendar_month_outlined, title: 'hunting.empty.country_title'.tr(namedArgs: {'country': country.name}), message: 'hunting.empty.country_message'.tr(), action: HBButton.primary(label: 'hunting.empty.report_region'.tr(), onPressed: () => context.push(AppRoutes.support))))
      else if (selected.regionId == null)
        HBCard(child: HBEmptyState(icon: Icons.location_on_outlined, title: 'calendar.empty_no_zone_title'.tr(), message: 'calendar.empty_no_zone_message'.tr(), action: HBButton.primary(label: 'calendar.set_zone'.tr(), onPressed: () => context.go(AppRoutes.huntingZone))))
      else ...[
        CalendarControls(day: selected.date, scope: selected.appliesTo, onToday: () => ref.read(huntingContextProvider.notifier).setDate(DateTime.now()), onTomorrow: () => ref.read(huntingContextProvider.notifier).setDate(DateTime.now().add(const Duration(days: 1))), onDate: chooseDate, onScope: (value) => ref.read(huntingContextProvider.notifier).setAppliesTo(value)),
        const SizedBox(height: AppSpacing.md),
        overview!.when(
          loading: () => const HBSkeleton(height: 240),
          error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'calendar.error_title'.tr(), message: 'calendar.error_message'.tr())),
          data: (value) => CalendarOverviewList(overview: value, names: names),
        ),
      ],
    ]))]));
  }
}

class CalendarControls extends StatelessWidget {
  final DateTime day;
  final String? scope;
  final VoidCallback onToday;
  final VoidCallback onTomorrow;
  final VoidCallback onDate;
  final ValueChanged<String?> onScope;
  const CalendarControls({super.key, required this.day, required this.scope, required this.onToday, required this.onTomorrow, required this.onDate, required this.onScope});

  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBChip(label: 'calendar.today'.tr(), selected: _sameDay(day, DateTime.now()), onTap: onToday), HBChip(label: 'calendar.tomorrow'.tr(), selected: _sameDay(day, DateTime.now().add(const Duration(days: 1))), onTap: onTomorrow), HBChip(label: DateFormat('d MMM yyyy', context.locale.languageCode).format(day), selected: !_sameDay(day, DateTime.now()) && !_sameDay(day, DateTime.now().add(const Duration(days: 1))), onTap: onDate)]),
    const SizedBox(height: AppSpacing.md),
    Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBChip(label: 'calendar.scope_all'.tr(), selected: scope == null, onTap: () => onScope(null)), HBChip(label: 'ATC', selected: scope == 'atc', onTap: () => onScope('atc')), HBChip(label: 'CA', selected: scope == 'ca', onTap: () => onScope('ca'))]),
  ]));

  bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
}

class CalendarOverviewList extends StatelessWidget {
  final HuntingOverview overview;
  final Map<String, String> names;
  const CalendarOverviewList({super.key, required this.overview, required this.names});

  @override
  Widget build(BuildContext context) {
    if (overview.entries.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.calendar_month_outlined, title: 'hunting.today.no_calendar'.tr(namedArgs: {'region': overview.regionName}), message: 'home.today_hunting_no_calendars_meta'.tr()));
    final categories = overview.entries.map((entry) => entry.category).toSet();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('calendar.region_season'.tr(namedArgs: {'region': overview.regionName, 'season': overview.entries.first.seasonLabel}), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      for (final category in categories) ...[
        Text('hunting.category.$category'.tr(), style: context.textStyles.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        HBCard(child: Column(children: [for (final entry in overview.entries.where((item) => item.category == category)) CalendarSpeciesRow(entry: entry, name: entry.localizedName(names))])),
        const SizedBox(height: AppSpacing.md),
      ],
      TodayCalendarSources(entries: overview.entries),
    ]);
  }
}

class CalendarSpeciesRow extends StatefulWidget {
  final CalendarDayInfo entry;
  final String name;
  const CalendarSpeciesRow({super.key, required this.entry, required this.name});
  @override
  State<CalendarSpeciesRow> createState() => _CalendarSpeciesRowState();
}

class _CalendarSpeciesRowState extends State<CalendarSpeciesRow> {
  bool notes = false;
  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final status = entry.isOpen ? 'calendar.status_open'.tr() : entry.nextOpen == null ? 'calendar.status_closed'.tr() : 'calendar.closed_next'.tr(namedArgs: {'day': DateFormat('EEEE', context.locale.languageCode).format(entry.nextOpen!)});
    return HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(widget.name, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700))), HBStatusChip(kind: entry.isOpen ? HBStatusKind.approved : HBStatusKind.neutral, label: status)]),
      const SizedBox(height: AppSpacing.xs),
      Text('calendar.period'.tr(namedArgs: {'from': DateFormat('d MMM', context.locale.languageCode).format(entry.validFrom), 'to': DateFormat('d MMM yyyy', context.locale.languageCode).format(entry.validTo)}), style: context.textStyles.bodySmall),
      if (entry.timeRule != null) Text(['sunrise_sunset', 'sunrise_sunset_plus'].contains(entry.timeRule) ? 'hunting.time_rule.${entry.timeRule}'.tr() : entry.timeRule!, style: context.textStyles.bodySmall),
      if (entry.opensAt != null && entry.closesAt != null) Text('hunting.live.hours'.tr(namedArgs: {'from': DateFormat.Hm().format(entry.opensAt!.toLocal()), 'to': DateFormat.Hm().format(entry.closesAt!.toLocal())}), style: context.textStyles.bodySmall),
      if (entry.bagDay != null || entry.bagSeason != null) Text('hunting.today.bags'.tr(namedArgs: {'day': entry.bagDay?.toString() ?? '—', 'season': entry.bagSeason?.toString() ?? '—'}), style: context.textStyles.bodySmall),
      if (entry.notes?.isNotEmpty == true) ...[InkWell(onTap: () => setState(() => notes = !notes), child: Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text('hunting.notes'.tr(), style: context.textStyles.labelMedium?.withColor(LightModeColors.lightPrimary)))), if (notes) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: Text(entry.notes!, style: context.textStyles.bodySmall))],
    ]));
  }
}

class TodayCalendarSources extends StatelessWidget {
  final List<CalendarDayInfo> entries;
  const TodayCalendarSources({super.key, required this.entries});
  @override
  Widget build(BuildContext context) {
    final sources = <String, String?>{};
    for (final entry in entries) if (entry.sourceName?.isNotEmpty == true) sources[entry.sourceName!] = entry.sourceUrl;
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('calendar.rail_source'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), for (final source in sources.entries) HBButton.ghost(label: source.key, icon: Icons.open_in_new, onPressed: source.value == null ? null : () => launchUrl(Uri.parse(source.value!), mode: LaunchMode.externalApplication)), const SizedBox(height: AppSpacing.sm), Text('hunting.today.official_warning'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]));
  }
}