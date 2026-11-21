import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/providers/admin_hunting_providers.dart';
import 'package:hb_social/features/admin/providers/admin_p44_providers.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';

class AdminCalendarEditorPage extends ConsumerStatefulWidget {
  final String? calendarId;
  const AdminCalendarEditorPage({super.key, this.calendarId});
  @override ConsumerState<AdminCalendarEditorPage> createState() => _AdminCalendarEditorPageState();
}

class _AdminCalendarEditorPageState extends ConsumerState<AdminCalendarEditorPage> {
  String? regionId; String? unitId; String? speciesId; String status = 'draft'; String? savedId;
  DateTime? validFrom; DateTime? validTo;
  final season = TextEditingController(); final sourceName = TextEditingController(); final sourceUrl = TextEditingController(); final notes = TextEditingController();
  bool initialized = false; bool saving = false;

  @override Widget build(BuildContext context) {
    final references = ref.watch(adminHuntingReferencesProvider);
    final record = widget.calendarId == null ? const AsyncValue<AdminCalendarRecord?>.data(null) : ref.watch(adminHuntingCalendarProvider(widget.calendarId!));
    if (references.isLoading || record.isLoading) return const Center(child: CircularProgressIndicator());
    if (references.hasError || record.hasError) return HBEmptyState(icon: Icons.error_outline, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr());
    final data = references.value!; final current = record.value;
    if (widget.calendarId != null && current == null) return HBEmptyState(icon: Icons.event_busy_outlined, title: 'admin.hunting.calendars.not_found'.tr(), message: 'admin.hunting.errors.load_message'.tr());
    if (!initialized) { initialized = true; savedId = current?.calendar.id; regionId = current?.calendar.regionId; unitId = current?.calendar.huntingUnitId; speciesId = current?.calendar.speciesId; status = current?.calendar.status ?? 'draft'; validFrom = current?.calendar.validFrom; validTo = current?.calendar.validTo; season.text = current?.calendar.seasonLabel ?? ''; sourceName.text = current?.calendar.sourceName ?? ''; sourceUrl.text = current?.calendar.sourceUrl ?? ''; notes.text = current?.calendar.notes ?? ''; }
    final country = regionId == null ? data.countries.firstOrNull?.code ?? 'IT' : data.regions.where((item) => item.id == regionId).firstOrNull?.countryCode ?? 'IT';
    final regions = data.regions.where((item) => item.countryCode == country).toList();
    final unitsState = regionId == null ? const AsyncValue<List<AdminHuntingUnit>>.data([]) : ref.watch(adminHuntingUnitsProvider((country: country, region: regionId, type: null)));
    final wide = MediaQuery.sizeOf(context).width >= 1120;
    final form = HBCard(child: Padding(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 700 ? AppSpacing.xs : 0), child: Column(children: [
      HBFormSection(title: 'admin.hunting.calendars.data'.tr(), children: [
        HBFormField(label: 'admin.hunting.filters.region'.tr(), required: true, child: HBSelect<String>(value: regionId, options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() { regionId = value; unitId = null; }))),
        HBFormField(label: 'admin.hunting.calendars.unit_optional'.tr(), child: HBSelect<String>(value: unitId, options: [for (final item in unitsState.value ?? const <AdminHuntingUnit>[]) HBSelectOption(value: item.id, label: '${item.code} - ${item.name}')], allowClear: true, placeholder: 'admin.hunting.calendars.everywhere'.tr(), onChanged: (value) => setState(() => unitId = value))),
        HBFormField(label: 'admin.hunting.calendars.species'.tr(), required: true, child: HBSelect<String>(value: speciesId, options: [for (final item in data.species) HBSelectOption(value: item.id, label: '${item.nameFor('it')} - ${item.scientificName}')], onChanged: (value) => setState(() => speciesId = value))),
        HBFormField(label: 'admin.hunting.filters.season'.tr(), required: true, child: HBInput(controller: season, hint: 'admin.hunting.calendars.season_hint'.tr())),
        Row(children: [Expanded(child: HBFormField(label: 'admin.hunting.calendars.from'.tr(), required: true, child: AdminDateButton(value: validFrom, onChanged: (value) => setState(() => validFrom = value)))), const SizedBox(width: AppSpacing.md), Expanded(child: HBFormField(label: 'admin.hunting.calendars.to'.tr(), required: true, child: AdminDateButton(value: validTo, onChanged: (value) => setState(() => validTo = value))))]),
        HBFormField(label: 'admin.hunting.calendars.source_name'.tr(), child: HBInput(controller: sourceName)),
        HBFormField(label: 'admin.hunting.calendars.source_url'.tr(), child: HBInput(controller: sourceUrl)),
        HBFormField(label: 'admin.hunting.units.notes'.tr(), child: HBInput(controller: notes, maxLines: 4)),
      ]),
      const HBFormSectionDivider(),
      CalendarRulesEditor(calendarId: savedId, rules: current?.calendar.rules ?? const [], onChanged: _reload),
      HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _save, loading: saving, secondaryLabel: 'common.back'.tr(), onSecondary: () => context.go('/admin/hunting/calendars')),
      if (savedId != null) ...[const SizedBox(height: AppSpacing.md), CalendarLifecycleActions(calendar: current!.calendar, onChanged: _reload)],
      if (status == 'published') ...[const SizedBox(height: AppSpacing.md), HBCard(child: Row(children: [const Icon(Icons.info_outline, color: LightModeColors.lightInfo), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('admin.hunting.calendars.live_within_minute'.tr()))]))],
    ])));
    final preview = CalendarDayPreview(calendarId: savedId);
    return wide ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: SingleChildScrollView(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: form))), const SizedBox(width: AppSpacing.lg), SizedBox(width: 320, child: preview)]) : CustomScrollView(slivers: [SliverToBoxAdapter(child: form), const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)), SliverToBoxAdapter(child: preview)]);
  }

  Future<void> _save() async {
    if (regionId == null || speciesId == null || validFrom == null || validTo == null || season.text.trim().isEmpty) return;
    if (validTo!.isBefore(validFrom!)) { _message('admin.hunting.errors.invalid_dates'.tr()); return; }
    setState(() => saving = true);
    try {
      final refs = ref.read(adminHuntingReferencesProvider).value!; final country = refs.regions.firstWhere((item) => item.id == regionId).countryCode;
      final id = await ref.read(adminHuntingRepositoryProvider).saveCalendar(id: savedId, values: {'country_code': country, 'region_id': regionId, 'hunting_unit_id': unitId, 'species_id': speciesId, 'season_label': season.text.trim(), 'valid_from': _date(validFrom!), 'valid_to': _date(validTo!), 'source_name': _optional(sourceName.text), 'source_url': _optional(sourceUrl.text), 'notes': _optional(notes.text), 'status': status});
      savedId = id; _message('admin.hunting.saved'.tr()); _reload();
      if (widget.calendarId == null && mounted) context.go('/admin/hunting/calendars/$id');
    } on AppException catch (error) { _message(error.messageKey.tr(namedArgs: error.namedArgs)); } finally { if (mounted) setState(() => saving = false); }
  }
  void _reload() { if (savedId != null) ref.invalidate(adminHuntingCalendarProvider(savedId!)); ref.invalidate(adminHuntingCalendarsProvider); }
  void _message(String text) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text))); }
  String _date(DateTime value) => value.toIso8601String().substring(0, 10);
  String? _optional(String value) => value.trim().isEmpty ? null : value.trim();
}

class AdminDateButton extends StatelessWidget {
  final DateTime? value; final ValueChanged<DateTime> onChanged;
  const AdminDateButton({super.key, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => InkWell(borderRadius: BorderRadius.circular(AppRadius.sm), onTap: () async { final selected = await showDatePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime(2040), initialDate: value ?? DateTime.now()); if (selected != null) onChanged(selected); }, child: Container(height: 48, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Row(children: [const Icon(Icons.calendar_today_outlined, size: 18), const SizedBox(width: AppSpacing.sm), Text(value == null ? 'common.select'.tr() : DateFormat.yMd().format(value!))])));
}

class CalendarRulesEditor extends ConsumerWidget {
  final String? calendarId; final List<CalendarRule> rules; final VoidCallback onChanged;
  const CalendarRulesEditor({super.key, required this.calendarId, required this.rules, required this.onChanged});
  @override Widget build(BuildContext context, WidgetRef ref) => HBFormSection(title: 'admin.hunting.rules.title'.tr(), children: [
    if (calendarId == null) Text('admin.hunting.rules.save_first'.tr()) else if (rules.isEmpty) HBEmptyState(icon: Icons.rule_outlined, title: 'admin.hunting.rules.empty'.tr(), message: 'admin.hunting.rules.empty_message'.tr()),
    for (var index = 0; index < rules.length; index++) HBTile(child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.hunting.rules.kinds.${rules[index].kind}'.tr(), style: context.textStyles.titleSmall), const SizedBox(height: 4), Text(_summary(context, rules[index]), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBButton.icon(icon: Icons.arrow_upward, onPressed: index == 0 ? null : () => _move(ref, index, -1)), HBButton.icon(icon: Icons.arrow_downward, onPressed: index == rules.length - 1 ? null : () => _move(ref, index, 1)), HBButton.icon(icon: Icons.edit_outlined, onPressed: () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => RuleEditorSheet(calendarId: calendarId!, rule: rules[index], sortOrder: index, onSaved: onChanged))), HBButton.icon(icon: Icons.delete_outline, onPressed: () async { final ok = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('admin.hunting.rules.delete_title'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'common.remove'.tr(), onPressed: () => dialogContext.pop(true))])); if (ok == true) { await ref.read(adminHuntingRepositoryProvider).deleteRule(rules[index].id); onChanged(); } })])),
    Align(alignment: Alignment.centerLeft, child: HBButton.secondary(label: 'admin.hunting.rules.add'.tr(), icon: Icons.add, onPressed: calendarId == null ? null : () => showModalBottomSheet(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => RuleEditorSheet(calendarId: calendarId!, sortOrder: rules.length, onSaved: onChanged))))
  ]);
  Future<void> _move(WidgetRef ref, int index, int delta) async { final reordered = [...rules]; final item = reordered.removeAt(index); reordered.insert(index + delta, item); await ref.read(adminHuntingRepositoryProvider).reorderRules(reordered); onChanged(); }
  String _summary(BuildContext context, CalendarRule rule) => [if (rule.dateFrom != null) DateFormat.yMd().format(rule.dateFrom!), if (rule.dateTo != null) DateFormat.yMd().format(rule.dateTo!), if (rule.allowedDays.isNotEmpty) rule.allowedDays.map((day) => 'admin.hunting.weekdays.$day'.tr()).join(', '), if (rule.timeRule != null) rule.timeRule!, if (rule.bagLimit != null) '${rule.bagLimit}/${rule.bagPeriod}', if (rule.appliesTo != null) rule.appliesTo!.toUpperCase(), if (rule.notes?.isNotEmpty == true) rule.notes!].join(' · ');
}

class RuleEditorSheet extends ConsumerStatefulWidget {
  final String calendarId; final CalendarRule? rule; final int sortOrder; final VoidCallback onSaved;
  const RuleEditorSheet({super.key, required this.calendarId, this.rule, required this.sortOrder, required this.onSaved});
  @override ConsumerState<RuleEditorSheet> createState() => _RuleEditorSheetState();
}
class _RuleEditorSheetState extends ConsumerState<RuleEditorSheet> {
  late String kind = widget.rule?.kind ?? 'open_period'; late DateTime? from = widget.rule?.dateFrom; late DateTime? to = widget.rule?.dateTo; late Set<int> days = widget.rule?.allowedDays.toSet() ?? {};
  late String timeMode = widget.rule?.timeRule?.contains(':') == true ? 'fixed' : widget.rule?.timeRule ?? 'sunrise-1h/sunset'; late String? appliesTo = widget.rule?.appliesTo; late String bagPeriod = widget.rule?.bagPeriod ?? 'day';
  late final bag = TextEditingController(text: widget.rule?.bagLimit?.toString()); late final fixedFrom = TextEditingController(text: widget.rule?.timeRule?.split('-').firstOrNull); late final fixedTo = TextEditingController(text: widget.rule?.timeRule?.split('-').lastOrNull); late final otherScope = TextEditingController(text: const ['atc','ca','afv','aatv','zps'].contains(widget.rule?.appliesTo) ? '' : widget.rule?.appliesTo); late final notes = TextEditingController(text: widget.rule?.notes);
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: SizedBox(height: MediaQuery.sizeOf(context).height * 0.82, child: ListView(children: [
    Text('admin.hunting.rules.editor_title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.md),
    HBFormField(label: 'admin.hunting.rules.type'.tr(), child: HBChoice<String>(options: const ['open_period','closed_period','allowed_days','time_rule','bag_limit'], value: kind, onChanged: (value) => setState(() => kind = value), labelBuilder: (value) => 'admin.hunting.rules.kinds.$value'.tr())),
    const SizedBox(height: AppSpacing.md),
    if (kind == 'open_period' || kind == 'closed_period') Row(children: [Expanded(child: AdminDateButton(value: from, onChanged: (value) => setState(() => from = value))), const SizedBox(width: AppSpacing.md), Expanded(child: AdminDateButton(value: to, onChanged: (value) => setState(() => to = value)))]),
    if (kind == 'allowed_days') Wrap(spacing: AppSpacing.xs, children: [for (var day = 1; day <= 7; day++) HBChip(label: 'admin.hunting.weekday_letters.$day'.tr(), selected: days.contains(day), onTap: () => setState(() => days.contains(day) ? days.remove(day) : days.add(day)))]),
    if (kind == 'time_rule') ...[HBSelect<String>(value: timeMode, options: [for (final value in const ['sunrise-1h/sunset','sunset+1h','fixed']) HBSelectOption(value: value, label: 'admin.hunting.rules.time.$value'.tr())], onChanged: (value) => setState(() => timeMode = value!)), if (timeMode == 'fixed') ...[const SizedBox(height: AppSpacing.sm), Row(children: [Expanded(child: HBInput(controller: fixedFrom, hint: 'HH:MM')), const SizedBox(width: AppSpacing.md), Expanded(child: HBInput(controller: fixedTo, hint: 'HH:MM'))])]],
    if (kind == 'bag_limit') Row(children: [Expanded(child: HBInput(controller: bag, hint: 'admin.hunting.rules.bag'.tr(), keyboardType: TextInputType.number)), const SizedBox(width: AppSpacing.md), Expanded(child: HBSelect<String>(value: bagPeriod, options: [HBSelectOption(value: 'day', label: 'admin.hunting.rules.day'.tr()), HBSelectOption(value: 'season', label: 'admin.hunting.rules.season'.tr())], onChanged: (value) => setState(() => bagPeriod = value!)))]),
    const SizedBox(height: AppSpacing.md), HBFormField(label: 'admin.hunting.rules.scope'.tr(), child: HBSelect<String>(value: appliesTo ?? 'everywhere', options: [for (final value in const ['everywhere','atc','ca','afv','aatv','zps','other']) HBSelectOption(value: value, label: 'admin.hunting.rules.scopes.$value'.tr())], onChanged: (value) => setState(() => appliesTo = value == 'everywhere' ? null : value))),
    if (appliesTo == 'other') ...[const SizedBox(height: AppSpacing.sm), HBInput(controller: otherScope, hint: 'admin.hunting.rules.other_scope'.tr())],
    const SizedBox(height: AppSpacing.md), HBFormField(label: 'admin.hunting.rules.validity_optional'.tr(), child: Row(children: [Expanded(child: AdminDateButton(value: from, onChanged: (value) => setState(() => from = value))), const SizedBox(width: AppSpacing.md), Expanded(child: AdminDateButton(value: to, onChanged: (value) => setState(() => to = value)))])),
    const SizedBox(height: AppSpacing.md), HBFormField(label: 'admin.hunting.units.notes'.tr(), child: HBInput(controller: notes, maxLines: 3)),
    HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _save, secondaryLabel: 'common.cancel'.tr(), onSecondary: context.pop),
  ])));
  Future<void> _save() async { final scope = appliesTo == 'other' ? otherScope.text.trim() : appliesTo; final time = kind == 'time_rule' ? timeMode == 'fixed' ? '${fixedFrom.text.trim()}-${fixedTo.text.trim()}' : timeMode : null; await ref.read(adminHuntingRepositoryProvider).saveRule(id: widget.rule?.id, values: {'calendar_id': widget.calendarId, 'kind': kind, 'date_from': from?.toIso8601String().substring(0, 10), 'date_to': to?.toIso8601String().substring(0, 10), 'allowed_days': kind == 'allowed_days' ? (days.toList()..sort()) : null, 'time_rule': time, 'bag_limit': kind == 'bag_limit' ? int.tryParse(bag.text) : null, 'bag_period': kind == 'bag_limit' ? bagPeriod : null, 'notes': notes.text.trim().isEmpty ? null : notes.text.trim(), 'applies_to': scope?.isEmpty == true ? null : scope, 'sort_order': widget.sortOrder}); widget.onSaved(); if (mounted) context.pop(); }
}

class CalendarDayPreview extends ConsumerStatefulWidget { final String? calendarId; const CalendarDayPreview({super.key, required this.calendarId}); @override ConsumerState<CalendarDayPreview> createState() => _CalendarDayPreviewState(); }
class _CalendarDayPreviewState extends ConsumerState<CalendarDayPreview> {
  DateTime date = DateTime.now(); String? scope; List<bool>? week; bool? open;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _load()); }
  @override void didUpdateWidget(CalendarDayPreview oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.calendarId != widget.calendarId) _load(); }
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.hunting.preview.title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), AdminDateButton(value: date, onChanged: (value) { date = value; _load(); }), const SizedBox(height: AppSpacing.sm), HBSelect<String>(value: scope ?? 'everywhere', options: [for (final value in const ['everywhere','atc','ca','afv','aatv','zps']) HBSelectOption(value: value, label: 'admin.hunting.rules.scopes.$value'.tr())], onChanged: (value) { scope = value == 'everywhere' ? null : value; _load(); }), const SizedBox(height: AppSpacing.md), if (widget.calendarId == null) Text('admin.hunting.preview.save_first'.tr()) else if (open == null) const Center(child: CircularProgressIndicator()) else Center(child: HBStatusChip(kind: open! ? HBStatusKind.approved : HBStatusKind.rejected, label: open! ? 'admin.hunting.preview.open'.tr() : 'admin.hunting.preview.closed'.tr())), const SizedBox(height: AppSpacing.md), if (week != null) Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [for (var i = 0; i < 7; i++) Column(children: [Text('admin.hunting.weekday_letters.${i + 1}'.tr()), const SizedBox(height: 6), Container(width: 14, height: 14, decoration: BoxDecoration(shape: BoxShape.circle, color: week![i] ? LightModeColors.lightSuccess : LightModeColors.lightTextTertiary))])]) ]));
  Future<void> _load() async { if (widget.calendarId == null) return; setState(() { open = null; week = null; }); final repository = ref.read(adminHuntingRepositoryProvider); final monday = date.subtract(Duration(days: date.weekday - 1)); final values = await Future.wait([for (var i = 0; i < 7; i++) repository.calendarOpen(widget.calendarId!, monday.add(Duration(days: i)), scope)]); final selected = await repository.calendarOpen(widget.calendarId!, date, scope); if (mounted) setState(() { week = values; open = selected; }); }
}

class CalendarLifecycleActions extends ConsumerStatefulWidget { final HuntingCalendar calendar; final VoidCallback onChanged; const CalendarLifecycleActions({super.key, required this.calendar, required this.onChanged}); @override ConsumerState<CalendarLifecycleActions> createState() => _CalendarLifecycleActionsState(); }
class _CalendarLifecycleActionsState extends ConsumerState<CalendarLifecycleActions> {
  CalendarValidation? validation;
  @override void initState() { super.initState(); WidgetsBinding.instance.addPostFrameCallback((_) => _validate()); }
  @override void didUpdateWidget(CalendarLifecycleActions oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.calendar != widget.calendar) _validate(); }
  Future<void> _validate() async { try { final value = await ref.read(adminP44RepositoryProvider).validateCalendar(widget.calendar.id); if (mounted) setState(() => validation = value); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.hunting.validation.title'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), if (validation == null) const LinearProgressIndicator() else if (validation!.issues.isEmpty) Row(children: [const Icon(Icons.check_circle_outline, color: LightModeColors.lightSuccess), const SizedBox(width: AppSpacing.xs), Text('admin.hunting.validation.ok'.tr())]) else for (final issue in validation!.issues) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xs), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Icon(issue.severity == 'error' ? Icons.error_outline : issue.severity == 'warning' ? Icons.warning_amber_outlined : Icons.info_outline, size: 18, color: issue.severity == 'error' ? LightModeColors.lightError : issue.severity == 'warning' ? LightModeColors.lightWarning : LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.xs), Expanded(child: Text('hunting.issues.${issue.code}'.tr(namedArgs: {'detail': issue.detail?.toString() ?? ''}))) ])), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (widget.calendar.status != 'published') Tooltip(message: validation?.ok == true ? '' : 'admin.hunting.validation.fix_errors'.tr(), child: HBButton.primary(label: 'admin.hunting.actions.publish'.tr(), onPressed: validation?.ok == true ? () => _status('published') : null)), if (widget.calendar.status != 'draft') HBButton.secondary(label: 'admin.hunting.actions.draft'.tr(), onPressed: () => _status('draft')), if (widget.calendar.status != 'archived') HBButton.secondary(label: 'admin.hunting.actions.archive'.tr(), onPressed: () => _status('archived'))]) ]));
  Future<void> _status(String status) async { try { await ref.read(adminP44RepositoryProvider).setCalendarStatus(widget.calendar.id, status); widget.onChanged(); await _validate(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
}