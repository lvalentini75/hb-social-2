import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:url_launcher/url_launcher.dart';

class HuntingSpeciesPage extends StatelessWidget {
  final String speciesId;
  const HuntingSpeciesPage({super.key, required this.speciesId});
  @override
  Widget build(BuildContext context) => PageColumns(center: HuntingSpeciesPanel(speciesId: speciesId));
}

class HuntingSpeciesPanel extends ConsumerWidget {
  final String speciesId;
  const HuntingSpeciesPanel({super.key, required this.speciesId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(huntingContextProvider);
    ref.watch(huntingDataVersionProvider(selected.regionId));
    final day = ref.watch(huntingDayProvider(HuntingDayRequest(speciesId, selected.date)));
    return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.all(AppSpacing.lg), sliver: SliverList.list(children: [
      SpeciesContextControls(value: selected),
      const SizedBox(height: AppSpacing.md),
      day.when(loading: () => const HBSkeleton(height: 520), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'hunting.species.error_title'.tr(), message: 'calendar.error_message'.tr())), data: (value) => HuntingSpeciesContent(value: value)),
    ]))]);
  }
}

class SpeciesContextControls extends ConsumerWidget {
  final HuntingContext value;
  const SpeciesContextControls({super.key, required this.value});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
    HBChip(icon: Icons.today_outlined, label: DateFormat('d MMM yyyy', context.locale.languageCode).format(value.date), selected: true, onTap: () async { final date = await showDatePicker(context: context, initialDate: value.date, firstDate: DateTime.now().subtract(const Duration(days: 400)), lastDate: DateTime.now().add(const Duration(days: 400))); if (date != null) ref.read(huntingContextProvider.notifier).setDate(date); }),
    HBChip(icon: Icons.map_outlined, label: value.appliesTo == null ? 'calendar.scope_all'.tr() : value.appliesTo!.toUpperCase(), selected: true, onTap: () => ref.read(huntingContextProvider.notifier).setAppliesTo(value.appliesTo == null ? 'atc' : value.appliesTo == 'atc' ? 'ca' : null)),
  ]);
}

class HuntingSpeciesContent extends ConsumerWidget {
  final HuntingDayInfo value;
  const HuntingSpeciesContent({super.key, required this.value});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(speciesNamesProvider).value ?? const <String, String>{};
    final name = names[value.speciesId] ?? value.nameIt ?? value.scientificName;
    final regions = ref.watch(regionsWithCalendarsProvider).value ?? const <RegionCalendars>[];
    final region = regions.where((item) => item.regionId == value.regionId).firstOrNull?.name ?? '';
    final unit = value.huntingUnitId == null ? null : ref.watch(huntingUnitsByRegionProvider(value.regionId)).value?.where((item) => item.id == value.huntingUnitId).firstOrNull;
    final imageUrl = value.imagePath == null ? null : storagePublicUrl(ref.read(supabaseClientProvider), 'species-media', value.imagePath);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (imageUrl?.isNotEmpty == true) ...[ClipRRect(borderRadius: BorderRadius.circular(AppRadius.cardWeb), child: Image.network(imageUrl!, height: 220, width: double.infinity, fit: BoxFit.cover)), const SizedBox(height: AppSpacing.md)],
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(name, style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w700)), Text(value.scientificName, style: context.textStyles.bodyMedium?.copyWith(fontStyle: FontStyle.italic)), const SizedBox(height: AppSpacing.xs), Text('${'hunting.category.${value.category}'.tr()} · $region · ${value.seasonLabel}', style: context.textStyles.bodySmall)])), HBStatusChip(kind: value.isOpen ? HBStatusKind.approved : HBStatusKind.neutral, label: (value.isOpen ? 'hunting.species.open_today' : 'hunting.species.closed_today').tr())]),
      if (unit != null) ...[const SizedBox(height: AppSpacing.sm), HBStatusChip(kind: HBStatusKind.info, label: 'hunting.species.unit_calendar'.tr(namedArgs: {'unit': unit.name}))],
      if (!value.isOpen && value.closedReason != null) ...[const SizedBox(height: AppSpacing.sm), Text('hunting.species.reason_${value.closedReason}'.tr(), style: context.textStyles.bodyMedium)],
      if (value.nextOpen != null) Text('hunting.species.next_open'.tr(namedArgs: {'date': DateFormat.yMMMMd(context.locale.languageCode).format(value.nextOpen!)}), style: context.textStyles.bodySmall),
      if (value.lastOpenDay != null) Text('hunting.species.last_open'.tr(namedArgs: {'date': DateFormat.yMMMMd(context.locale.languageCode).format(value.lastOpenDay!)}), style: context.textStyles.bodySmall),
      const SizedBox(height: AppSpacing.lg),
      SpeciesDayCard(value: value),
      const SizedBox(height: AppSpacing.md),
      if (value.validFrom != null && value.validTo != null) SeasonStrip(value: value),
      const SizedBox(height: AppSpacing.md),
      SpeciesMonthCalendar(speciesId: value.speciesId),
      const SizedBox(height: AppSpacing.md),
      RulesBlock(rules: value.rules),
      const SizedBox(height: AppSpacing.md),
      SourceBlock(value: value),
      const SizedBox(height: AppSpacing.md),
      HBButton.primary(label: 'hunting.species.share'.tr(), icon: Icons.share_outlined, onPressed: () => showComposerSheet(context, initialText: 'hunting.species.share_text'.tr(namedArgs: {'species': name, 'region': region, 'status': (value.isOpen ? 'hunting.species.open_short' : 'hunting.species.closed_short').tr(), 'hours': _hours(value)}))),
    ]);
  }

  String _hours(HuntingDayInfo value) => value.opensAt == null || value.closesAt == null ? 'hunting.species.hours_unavailable'.tr() : '${DateFormat.Hm().format(value.opensAt!.toLocal())}-${DateFormat.Hm().format(value.closesAt!.toLocal())}';
}

class SpeciesDayCard extends StatelessWidget {
  final HuntingDayInfo value;
  const SpeciesDayCard({super.key, required this.value});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('hunting.species.day_title'.tr(), style: context.textStyles.titleMedium),
    const SizedBox(height: AppSpacing.md),
    Text(value.opensAt == null || value.closesAt == null ? 'hunting.species.hours_unavailable'.tr() : 'hunting.live.hours'.tr(namedArgs: {'from': DateFormat.Hm().format(value.opensAt!.toLocal()), 'to': DateFormat.Hm().format(value.closesAt!.toLocal())}), style: context.textStyles.bodyMedium),
    const SizedBox(height: AppSpacing.sm),
    Row(children: [for (var day = 1; day <= 7; day++) Expanded(child: Container(margin: const EdgeInsets.only(right: 4), padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), decoration: BoxDecoration(color: value.allowedDays.contains(day) ? LightModeColors.lightPrimarySoft : LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.xs)), child: Text('admin.hunting.weekday_letters.$day'.tr(), textAlign: TextAlign.center, style: context.textStyles.labelSmall?.withColor(value.allowedDays.contains(day) ? LightModeColors.lightPrimary : LightModeColors.lightTextTertiary))))]),
    const SizedBox(height: AppSpacing.sm),
    Text('hunting.species.bag'.tr(namedArgs: {'day': value.bagDay?.toString() ?? '-', 'season': value.bagSeason?.toString() ?? '-'}), style: context.textStyles.bodySmall),
    Text('hunting.species.applies_to'.tr(namedArgs: {'scope': value.appliesTo?.toUpperCase() ?? 'calendar.scope_all'.tr()}), style: context.textStyles.bodySmall),
  ]));
}

class SeasonStrip extends StatelessWidget {
  final HuntingDayInfo value;
  const SeasonStrip({super.key, required this.value});
  @override
  Widget build(BuildContext context) {
    final total = value.validTo!.difference(value.validFrom!).inDays.clamp(1, 9999);
    final progress = value.day.difference(value.validFrom!).inDays.clamp(0, total) / total;
    final periods = value.rules.where((rule) => rule.dateFrom != null && rule.dateTo != null && ['open_period', 'closed_period'].contains(rule.kind)).toList();
    final preopenings = value.rules.where((rule) => rule.kind == 'preopening' && rule.dateFrom != null).toList();
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('hunting.species.season_strip'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), LayoutBuilder(builder: (context, constraints) => SizedBox(height: 18, child: Stack(children: [Container(decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.pill))), for (final rule in periods) Positioned(left: (rule.dateFrom!.difference(value.validFrom!).inDays.clamp(0, total) / total) * constraints.maxWidth, right: (value.validTo!.difference(rule.dateTo!).inDays.clamp(0, total) / total) * constraints.maxWidth, top: 0, bottom: 0, child: Container(color: rule.kind == 'open_period' ? LightModeColors.lightPrimarySoft : LightModeColors.lightErrorContainer)), for (final rule in preopenings) Positioned(left: (rule.dateFrom!.difference(value.validFrom!).inDays.clamp(0, total) / total) * constraints.maxWidth, top: 0, bottom: 0, child: Container(width: 2, color: LightModeColors.lightWarning)), Positioned(left: progress * constraints.maxWidth, top: 0, bottom: 0, child: Container(width: 3, color: LightModeColors.lightPrimary))]))), const SizedBox(height: AppSpacing.xs), Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text(DateFormat('d MMM').format(value.validFrom!), style: context.textStyles.labelSmall), Text(DateFormat('d MMM').format(value.validTo!), style: context.textStyles.labelSmall)])]));
  }
}

class SpeciesMonthCalendar extends ConsumerWidget {
  final String speciesId;
  const SpeciesMonthCalendar({super.key, required this.speciesId});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(huntingContextProvider).date;
    final days = ref.watch(monthHuntingDaysProvider(HuntingDayRequest(speciesId, selected)));
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [HBButton.icon(icon: Icons.chevron_left, onPressed: () => ref.read(huntingContextProvider.notifier).setDate(DateTime(selected.year, selected.month - 1, selected.day.clamp(1, DateTime(selected.year, selected.month, 0).day))), size: HBButtonSize.sm), Expanded(child: Text(DateFormat.yMMMM(context.locale.languageCode).format(selected), textAlign: TextAlign.center, style: context.textStyles.titleMedium)), HBButton.icon(icon: Icons.chevron_right, onPressed: () => ref.read(huntingContextProvider.notifier).setDate(DateTime(selected.year, selected.month + 1, selected.day.clamp(1, DateTime(selected.year, selected.month + 2, 0).day))), size: HBButtonSize.sm)]),
      const SizedBox(height: AppSpacing.sm),
      days.when(loading: () => const LinearProgressIndicator(color: LightModeColors.lightPrimary), error: (_, __) => Text('calendar.error_message'.tr()), data: (items) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), itemCount: items.length, gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 4, crossAxisSpacing: 4), itemBuilder: (context, index) { final item = items[index]; return InkWell(onTap: () => ref.read(huntingContextProvider.notifier).setDate(item.day), child: Container(alignment: Alignment.center, decoration: BoxDecoration(color: item.isOpen ? LightModeColors.lightPrimarySoft : LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.xs)), child: Text('${item.day.day}', style: context.textStyles.labelMedium?.withColor(item.isOpen ? LightModeColors.lightPrimary : LightModeColors.lightOnSurfaceVariant)))); })),
    ]));
  }
}

class RulesBlock extends StatelessWidget {
  final List<CalendarRule> rules;
  const RulesBlock({super.key, required this.rules});
  @override
  Widget build(BuildContext context) {
    final scopes = rules.map((rule) => rule.appliesTo ?? 'all').toSet();
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('hunting.species.rules'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), if (rules.isEmpty) Text('hunting.species.rules_empty'.tr()) else for (final scope in scopes) ...[Text(scope == 'all' ? 'calendar.scope_all'.tr() : scope.toUpperCase(), style: context.textStyles.labelLarge), const SizedBox(height: AppSpacing.xs), for (final rule in rules.where((item) => (item.appliesTo ?? 'all') == scope)) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(_ruleText(context, rule), style: context.textStyles.bodyMedium), if (rule.notes?.isNotEmpty == true) Text(rule.notes!, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])))] ]));
  }

  String _ruleText(BuildContext context, CalendarRule rule) {
    final from = rule.dateFrom == null ? '' : DateFormat('d MMM', context.locale.languageCode).format(rule.dateFrom!);
    final to = rule.dateTo == null ? '' : DateFormat('d MMM', context.locale.languageCode).format(rule.dateTo!);
    final days = rule.allowedDays.map((day) => 'admin.hunting.weekdays.$day'.tr().substring(0, 3).toLowerCase()).join(', ');
    if (rule.kind == 'allowed_days') return 'hunting.species.rule_days'.tr(namedArgs: {'days': days, 'from': from, 'to': to});
    if (rule.kind == 'bag_limit') return 'hunting.species.rule_bag'.tr(namedArgs: {'limit': '${rule.bagLimit ?? '-'}', 'period': rule.bagPeriod == 'season' ? 'hunting.species.season'.tr() : 'hunting.species.day'.tr()});
    if (rule.kind == 'closed_period') return 'hunting.species.rule_closed'.tr(namedArgs: {'from': from, 'to': to});
    if (rule.kind == 'open_period') return 'hunting.species.rule_open'.tr(namedArgs: {'from': from, 'to': to});
    return 'hunting.species.rule_time'.tr(namedArgs: {'value': rule.timeRule ?? '-'});
  }
}

class SourceBlock extends StatelessWidget {
  final HuntingDayInfo value;
  const SourceBlock({super.key, required this.value});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('calendar.rail_source'.tr(), style: context.textStyles.titleMedium), if (value.sourceName != null) HBButton.ghost(label: value.sourceName!, icon: Icons.open_in_new, onPressed: value.sourceUrl == null ? null : () => launchUrl(Uri.parse(value.sourceUrl!), mode: LaunchMode.externalApplication)), if (value.notes?.isNotEmpty == true) Text(value.notes!, style: context.textStyles.bodySmall), const SizedBox(height: AppSpacing.sm), Text('hunting.today.official_warning'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]));
}