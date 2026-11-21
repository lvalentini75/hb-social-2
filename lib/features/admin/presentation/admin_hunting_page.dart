import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_country_picker.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_hunting_providers.dart';
import 'package:hb_social/features/admin/presentation/admin_unit_boundaries.dart';
import 'package:hb_social/features/hunting/domain/hunting_calendar.dart';

class AdminHuntingPage extends ConsumerStatefulWidget {
  final int initialTab;
  const AdminHuntingPage({super.key, this.initialTab = 0});
  @override ConsumerState<AdminHuntingPage> createState() => _AdminHuntingPageState();
}

class _AdminHuntingPageState extends ConsumerState<AdminHuntingPage> {
  late int tab = widget.initialTab;
  String? country;

  @override Widget build(BuildContext context) {
    final access = ref.watch(adminAccessProvider).value;
    final allowed = access?.canRead('calendars') == true;
    if (!allowed) return HBEmptyState(icon: Icons.lock_outline, title: 'admin.hunting.denied_title'.tr(), message: 'admin.hunting.denied_message'.tr());
    final references = ref.watch(adminHuntingReferencesProvider);
    return references.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => HBEmptyState(icon: Icons.cloud_off_outlined, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(adminHuntingReferencesProvider))),
      data: (data) {
        country ??= data.countries.firstOrNull?.code;
        if (country == null) return HBEmptyState(icon: Icons.public_off_outlined, title: 'admin.hunting.empty'.tr(), message: 'admin.hunting.empty_message'.tr());
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.hunting.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('admin.hunting.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))])), SizedBox(width: 260, child: HBCountryPicker(value: country, onChanged: (value) => setState(() => country = value.code)))]),
          const SizedBox(height: AppSpacing.md),
          HBSegmentedTabs(labels: [for (final key in const ['calendars','species','units','municipalities','regions']) 'admin.hunting.tabs.$key'.tr()], selectedIndex: tab, onChanged: (value) { setState(() => tab = value); context.go(['/admin/hunting/calendars','/admin/hunting/species','/admin/hunting/units','/admin/hunting/municipalities','/admin/hunting/regions'][value]); }),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: switch (tab) { 0 => AdminHuntingCalendarsTab(countryCode: country!, references: data), 1 => const AdminHuntingSpeciesTab(), 2 => AdminHuntingUnitsTab(countryCode: country!, references: data), 3 => AdminMunicipalitiesTab(enabled: country == 'IT'), _ => AdminRegionsTab(countryCode: country!, references: data) }),
        ]);
      },
    );
  }
}

class AdminHuntingCalendarsTab extends ConsumerStatefulWidget {
  final String countryCode;
  final AdminHuntingReferenceData references;
  const AdminHuntingCalendarsTab({super.key, required this.countryCode, required this.references});
  @override ConsumerState<AdminHuntingCalendarsTab> createState() => _AdminHuntingCalendarsTabState();
}

class _AdminHuntingCalendarsTabState extends ConsumerState<AdminHuntingCalendarsTab> {
  String? region;
  String? season;
  String? status;
  String search = '';

  @override Widget build(BuildContext context) {
    final regions = widget.references.regions.where((item) => item.countryCode == widget.countryCode).toList();
    if (region != null && !regions.any((item) => item.id == region)) region = null;
    final filter = (country: widget.countryCode, region: region, season: season, status: status, search: search);
    final calendars = ref.watch(adminHuntingCalendarsProvider(filter));
    final items = calendars.value ?? const <AdminCalendarRecord>[];
    final seasons = items.map((item) => item.calendar.seasonLabel).toSet().toList()..sort();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        SizedBox(width: 210, child: HBSelect<String>(value: region, options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], allowClear: true, placeholder: 'admin.hunting.filters.region'.tr(), onChanged: (value) => setState(() => region = value))),
        SizedBox(width: 170, child: HBSelect<String>(value: season, options: [for (final item in seasons) HBSelectOption(value: item, label: item)], allowClear: true, placeholder: 'admin.hunting.filters.season'.tr(), onChanged: (value) => setState(() => season = value))),
        SizedBox(width: 170, child: HBSelect<String>(value: status, options: [for (final item in const ['draft','published','archived']) HBSelectOption(value: item, label: 'admin.hunting.status.$item'.tr())], allowClear: true, placeholder: 'admin.hunting.filters.status'.tr(), onChanged: (value) => setState(() => status = value))),
        SizedBox(width: 250, child: HBInput(hint: 'admin.hunting.filters.species'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (value) => setState(() => search = value))),
        HBButton.secondary(label: 'admin.hunting.calendars.duplicate'.tr(), icon: Icons.copy_outlined, onPressed: region == null || season == null ? null : () => _duplicate(items.length)),
        HBButton.primary(label: 'admin.hunting.calendars.new'.tr(), icon: Icons.add, onPressed: () => context.push('/admin/hunting/calendars/new')),
      ]),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: AdminDataTable(headers: [for (final key in const ['species','region','unit','period','rules','status','source']) 'admin.hunting.calendars.columns.$key'.tr()], columnWidths: const [220,150,150,180,80,120,200], isLoading: calendars.isLoading, emptyMessage: 'admin.hunting.calendars.empty'.tr(), rows: [for (final item in items) [Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.calendar.species.nameFor('it')), Text(item.calendar.species.scientificName, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary))]), Text(item.regionName), Text(item.huntingUnitName ?? 'common.unavailable'.tr()), Text('${DateFormat.yMd().format(item.calendar.validFrom)} - ${DateFormat.yMd().format(item.calendar.validTo)}'), Text('${item.calendar.rules.length}'), HBStatusChip(kind: _statusKind(item.calendar.status), label: 'admin.hunting.status.${item.calendar.status}'.tr()), Text(item.calendar.sourceName ?? 'common.unavailable'.tr(), overflow: TextOverflow.ellipsis)]], rowCallbacks: [for (final item in items) () => context.push('/admin/hunting/calendars/${item.calendar.id}')]))
    ]);
  }

  Future<void> _duplicate(int count) async {
    final target = TextEditingController();
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('admin.hunting.calendars.duplicate'.tr()), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('admin.hunting.calendars.duplicate_message'.tr(namedArgs: {'count': '$count'})), const SizedBox(height: AppSpacing.md), HBInput(controller: target, hint: 'admin.hunting.calendars.new_season'.tr())]), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'admin.hunting.calendars.duplicate'.tr(), onPressed: () => dialogContext.pop(true))]));
    if (confirmed != true || target.text.trim().isEmpty || !mounted) return;
    try { final copied = await ref.read(adminHuntingRepositoryProvider).duplicateSeason(regionId: region!, fromSeason: season!, toSeason: target.text.trim()); ref.invalidate(adminHuntingCalendarsProvider); if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.hunting.calendars.duplicated'.tr(namedArgs: {'count': '$copied'})))); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }
  }
}

class AdminHuntingSpeciesTab extends ConsumerWidget {
  const AdminHuntingSpeciesTab({super.key});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminHuntingSpeciesProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      HBButton.primary(label: 'admin.hunting.species.new'.tr(), icon: Icons.add, onPressed: () => showDialog(context: context, builder: (_) => const SpeciesEditorDialog())),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr()),
        data: (items) => AdminDataTable(
          headers: [for (final key in const ['name','scientific','category','missing','actions']) 'admin.hunting.species.columns.$key'.tr()],
          columnWidths: const [180,220,150,160,150],
          emptyMessage: 'admin.hunting.species.empty'.tr(),
          rows: [for (final item in items) [
            Text(item.species.nameFor('it')),
            Text(item.species.scientificName),
            HBChip(label: 'admin.hunting.categories.${item.species.category}'.tr(), selected: false),
            Row(mainAxisSize: MainAxisSize.min, children: [HBBadge.count(count: 5 - item.species.names.length), const SizedBox(width: 6), Text('admin.hunting.species.missing'.tr(namedArgs: {'count': '${5 - item.species.names.length}'}))]),
            Row(children: [HBButton.icon(icon: Icons.edit_outlined, onPressed: () => showDialog(context: context, builder: (_) => SpeciesEditorDialog(species: item.species))), HBButton.icon(icon: Icons.delete_outline, onPressed: () => _delete(context, ref, item.species.id))]),
          ]],
        ),
      )),
    ]);
  }
  Future<void> _delete(BuildContext context, WidgetRef ref, String id) async { try { await ref.read(adminHuntingRepositoryProvider).deleteSpecies(id); ref.invalidate(adminHuntingSpeciesProvider); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); } }
}

class SpeciesEditorDialog extends ConsumerStatefulWidget {
  final SpeciesInfo? species;
  const SpeciesEditorDialog({super.key, this.species});
  @override ConsumerState<SpeciesEditorDialog> createState() => _SpeciesEditorDialogState();
}
class _SpeciesEditorDialogState extends ConsumerState<SpeciesEditorDialog> {
  late final scientific = TextEditingController(text: widget.species?.scientificName);
  late String category = widget.species?.category ?? 'other';
  late final names = {for (final locale in const ['it','en','fr','es','de']) locale: TextEditingController(text: widget.species?.names[locale])};
  bool saving = false;
  @override Widget build(BuildContext context) => AlertDialog(title: Text(widget.species == null ? 'admin.hunting.species.new'.tr() : 'admin.hunting.species.edit'.tr()), content: SizedBox(width: 560, child: HBFormSection(title: 'admin.hunting.species.data'.tr(), children: [HBFormField(label: 'admin.hunting.species.scientific'.tr(), required: true, child: HBInput(controller: scientific)), HBFormField(label: 'admin.hunting.species.category'.tr(), child: HBSelect<String>(value: category, options: [for (final value in const ['ungulate','small_game','migratory','waterfowl','predator','other']) HBSelectOption(value: value, label: 'admin.hunting.categories.$value'.tr())], onChanged: (value) => setState(() => category = value!))), for (final entry in names.entries) HBFormField(label: 'language.${entry.key}'.tr(), required: entry.key == 'it', child: HBInput(controller: entry.value))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: saving ? null : context.pop), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: _save)]);
  Future<void> _save() async { if (scientific.text.trim().isEmpty || names['it']!.text.trim().isEmpty) return; setState(() => saving = true); try { await ref.read(adminHuntingRepositoryProvider).saveSpecies(id: widget.species?.id, scientificName: scientific.text.trim(), category: category, names: {for (final entry in names.entries) if (entry.value.text.trim().isNotEmpty) entry.key: entry.value.text.trim()}); ref.invalidate(adminHuntingSpeciesProvider); if (mounted) context.pop(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); } finally { if (mounted) setState(() => saving = false); } }
}

class AdminHuntingUnitsTab extends ConsumerStatefulWidget {
  final String countryCode;
  final AdminHuntingReferenceData references;
  const AdminHuntingUnitsTab({super.key, required this.countryCode, required this.references});
  @override ConsumerState<AdminHuntingUnitsTab> createState() => _AdminHuntingUnitsTabState();
}
class _AdminHuntingUnitsTabState extends ConsumerState<AdminHuntingUnitsTab> {
  String? region; String? type; int subsection = 0;
  @override Widget build(BuildContext context) {
    final regions = widget.references.regions.where((item) => item.countryCode == widget.countryCode).toList();
    final types = widget.references.unitTypes.where((item) => item.countryCode == widget.countryCode).toList();
    final state = ref.watch(adminHuntingUnitsProvider((country: widget.countryCode, region: region, type: type)));
    final boundariesState = ref.watch(adminUnitBoundariesProvider((country: widget.countryCode, region: region)));
    final boundaries = boundariesState.value ?? const <AdminUnitBoundary>[];
    final boundaryByUnit = {for (final item in boundaries) item.unitId: item};
    return Column(children: [
      Align(alignment: Alignment.centerLeft, child: SizedBox(width: 360, child: HBSegmentedTabs(labels: ['admin.hunting.units.data'.tr(), 'map.layers.units'.tr()], selectedIndex: subsection, onChanged: (value) => setState(() => subsection = value)))),
      const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        SizedBox(width: 210, child: HBSelect<String>(value: region, options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], allowClear: true, placeholder: 'admin.hunting.filters.region'.tr(), onChanged: (value) => setState(() => region = value))),
        SizedBox(width: 180, child: HBSelect<String>(value: type, options: [for (final item in types) HBSelectOption(value: item.code, label: item.label(context.locale.languageCode))], allowClear: true, placeholder: 'admin.hunting.filters.type'.tr(), onChanged: (value) => setState(() => type = value))),
        if (subsection == 0) HBButton.secondary(label: 'admin.hunting.units.import'.tr(), icon: Icons.upload_file_outlined, onPressed: region == null || type == null ? null : () => showDialog(context: context, builder: (_) => UnitImportDialog(countryCode: widget.countryCode, regionId: region!, type: type!))),
        HBButton.secondary(label: 'admin.hunting.units.import_boundaries'.tr(), icon: Icons.map_outlined, onPressed: region == null || type == null ? null : () => showDialog(context: context, builder: (_) => UnitAreasImportDialog(regionId: region!, unitType: type!))),
        if (subsection == 0) HBButton.primary(label: 'admin.hunting.units.new'.tr(), icon: Icons.add, onPressed: () => showDialog(context: context, builder: (_) => UnitEditorDialog(countryCode: widget.countryCode, references: widget.references))),
      ]),
      const SizedBox(height: AppSpacing.md),
      if (subsection == 1) Expanded(child: boundariesState.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr()), data: (items) => AdminBoundariesOverview(boundaries: type == null ? items : items.where((item) => item.unitType == type).toList()))) else Expanded(child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr()),
        data: (items) => AdminDataTable(headers: ['admin.hunting.units.columns.type'.tr(), 'admin.hunting.units.columns.code'.tr(), 'admin.hunting.units.columns.name'.tr(), 'admin.hunting.units.columns.municipality'.tr(), 'map.layers.units'.tr(), 'admin.hunting.units.columns.actions'.tr()], columnWidths: const [90,110,190,160,300,180], emptyMessage: 'admin.hunting.units.empty'.tr(), rows: [for (final item in items) [Text(item.unitType.toUpperCase()), Text(item.code), Text(item.name), Text(item.municipalityName ?? 'common.unavailable'.tr()), AdminBoundaryStatus(boundary: boundaryByUnit[item.id]), Row(children: [HBButton.icon(icon: Icons.edit_outlined, onPressed: () => showDialog(context: context, builder: (_) => UnitEditorDialog(countryCode: widget.countryCode, references: widget.references, unit: item))), HBButton.icon(icon: Icons.upload_file_outlined, onPressed: () => _boundary(item, boundaryByUnit[item.id])), HBButton.icon(icon: Icons.delete_outline, onPressed: () => _delete(item.id))])]]),
      )),
    ]);
  }
  Future<void> _delete(String id) async { try { await ref.read(adminHuntingRepositoryProvider).deleteUnit(id); ref.invalidate(adminHuntingUnitsProvider); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); } }
  Future<void> _boundary(AdminHuntingUnit unit, AdminUnitBoundary? existing) async { final changed = await showDialog<bool>(context: context, builder: (_) => UnitBoundaryEditorDialog(unit: unit, existing: existing)); if (changed == true) ref.invalidate(adminUnitBoundariesProvider); }
}

class UnitEditorDialog extends ConsumerStatefulWidget {
  final String countryCode; final AdminHuntingReferenceData references; final AdminHuntingUnit? unit;
  const UnitEditorDialog({super.key, required this.countryCode, required this.references, this.unit});
  @override ConsumerState<UnitEditorDialog> createState() => _UnitEditorDialogState();
}
class _UnitEditorDialogState extends ConsumerState<UnitEditorDialog> {
  late String? region = widget.unit?.regionId; late String? type = widget.unit?.unitType; String? municipalityId;
  late final code = TextEditingController(text: widget.unit?.code); late final name = TextEditingController(text: widget.unit?.name); late final municipality = TextEditingController(text: widget.unit?.municipalityName); late final website = TextEditingController(text: widget.unit?.website); late final notes = TextEditingController(text: widget.unit?.notes);
  @override Widget build(BuildContext context) { final regions = widget.references.regions.where((item) => item.countryCode == widget.countryCode).toList(); final types = widget.references.unitTypes.where((item) => item.countryCode == widget.countryCode).toList(); return AlertDialog(title: Text(widget.unit == null ? 'admin.hunting.units.new'.tr() : 'admin.hunting.units.edit'.tr()), content: SizedBox(width: 600, child: HBFormSection(title: 'admin.hunting.units.data'.tr(), children: [HBFormField(label: 'admin.hunting.filters.region'.tr(), required: true, child: HBSelect<String>(value: region, options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => region = value))), HBFormField(label: 'admin.hunting.filters.type'.tr(), required: true, child: HBSelect<String>(value: type, options: [for (final item in types) HBSelectOption(value: item.code, label: item.label(context.locale.languageCode))], onChanged: (value) => setState(() => type = value))), HBFormField(label: 'admin.hunting.units.code'.tr(), required: true, child: HBInput(controller: code)), HBFormField(label: 'admin.hunting.units.name'.tr(), required: true, child: HBInput(controller: name)), if (widget.countryCode == 'IT') HBFormField(label: 'admin.hunting.units.municipality'.tr(), child: HBPlaceField<AdminMunicipality>(controller: municipality, hint: 'admin.hunting.municipalities.search'.tr(), search: (query) async => [for (final item in await ref.read(adminHuntingRepositoryProvider).searchMunicipalities(query)) HBPlaceSuggestion(value: item, title: item.name, subtitle: item.provinceName)], onSelected: (value) => municipalityId = value.id)), HBFormField(label: 'admin.hunting.units.website'.tr(), child: HBInput(controller: website)), HBFormField(label: 'admin.hunting.units.notes'.tr(), child: HBInput(controller: notes, maxLines: 3))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'common.save'.tr(), onPressed: _save)]); }
  Future<void> _save() async { if (region == null || type == null || code.text.trim().isEmpty || name.text.trim().isEmpty) return; try { await ref.read(adminHuntingRepositoryProvider).saveUnit(id: widget.unit?.id, values: {'country_code': widget.countryCode, 'region_id': region, 'unit_type': type, 'code': code.text.trim(), 'name': name.text.trim(), 'municipality_id': municipalityId ?? widget.unit?.municipalityId, 'website': website.text.trim().isEmpty ? null : website.text.trim(), 'notes': notes.text.trim().isEmpty ? null : notes.text.trim()}); ref.invalidate(adminHuntingUnitsProvider); if (mounted) context.pop(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); } }
}

class UnitImportDialog extends ConsumerStatefulWidget { final String countryCode; final String regionId; final String type; const UnitImportDialog({super.key, required this.countryCode, required this.regionId, required this.type}); @override ConsumerState<UnitImportDialog> createState() => _UnitImportDialogState(); }
class _UnitImportDialogState extends ConsumerState<UnitImportDialog> {
  final controller = TextEditingController();
  List<(String, String)> get rows { final seen = <String>{}; return controller.text.split('\n').map((line) => line.split(';')).where((parts) => parts.length == 2 && parts[0].trim().isNotEmpty && parts[1].trim().isNotEmpty).map((parts) => (parts[0].trim(), parts[1].trim())).where((row) => seen.add(row.$1.toLowerCase())).take(200).toList(); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text('admin.hunting.units.import'.tr()), content: SizedBox(width: 600, child: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(controller: controller, hint: 'admin.hunting.units.import_hint'.tr(), maxLines: 10, onChanged: (_) => setState(() {})), const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerLeft, child: Text('admin.hunting.units.import_preview'.tr(namedArgs: {'count': '${rows.length}'})))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'admin.hunting.units.import'.tr(), onPressed: rows.isEmpty ? null : _save)]);
  Future<void> _save() async { await ref.read(adminHuntingRepositoryProvider).importUnits([for (final row in rows) {'country_code': widget.countryCode, 'region_id': widget.regionId, 'unit_type': widget.type, 'code': row.$1, 'name': row.$2}]); ref.invalidate(adminHuntingUnitsProvider); if (mounted) context.pop(); }
}

class AdminMunicipalitiesTab extends ConsumerStatefulWidget { final bool enabled; const AdminMunicipalitiesTab({super.key, required this.enabled}); @override ConsumerState<AdminMunicipalitiesTab> createState() => _AdminMunicipalitiesTabState(); }
class _AdminMunicipalitiesTabState extends ConsumerState<AdminMunicipalitiesTab> {
  final search = TextEditingController(); List<AdminMunicipality> items = const []; bool loading = false;
  @override Widget build(BuildContext context) { if (!widget.enabled) return HBEmptyState(icon: Icons.location_off_outlined, title: 'admin.hunting.municipalities.only_it'.tr(), message: 'admin.hunting.municipalities.only_it_message'.tr()); return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.hunting.municipalities.source'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.sm), HBPlaceField<String>(controller: search, hint: 'admin.hunting.municipalities.search'.tr(), search: (query) async { final values = await ref.read(adminHuntingRepositoryProvider).searchMunicipalities(query); if (mounted) setState(() => items = values); return [for (final item in values) HBPlaceSuggestion(value: item.id, title: item.name, subtitle: item.provinceName)]; }, onSelected: (_) {}), const SizedBox(height: AppSpacing.md), Expanded(child: AdminDataTable(headers: [for (final key in const ['name','alt','province','region','active','actions']) 'admin.hunting.municipalities.columns.$key'.tr()], columnWidths: const [180,180,180,180,100,100], isLoading: loading, emptyMessage: 'admin.hunting.municipalities.empty'.tr(), rows: [for (final item in items) [Text(item.name), Text(item.nameAlt ?? 'common.unavailable'.tr()), Text('${item.provinceName ?? ''} ${item.provinceCode ?? ''}'), Text(item.regionName), HBStatusChip(kind: item.isActive ? HBStatusKind.approved : HBStatusKind.neutral, label: item.isActive ? 'admin.hunting.active'.tr() : 'admin.hunting.inactive'.tr()), HBButton.icon(icon: Icons.edit_outlined, onPressed: () => showDialog(context: context, builder: (_) => MunicipalityEditorDialog(item: item, onSaved: () => setState(() => items = const []))))]]))]); }
}
class MunicipalityEditorDialog extends ConsumerStatefulWidget { final AdminMunicipality item; final VoidCallback onSaved; const MunicipalityEditorDialog({super.key, required this.item, required this.onSaved}); @override ConsumerState<MunicipalityEditorDialog> createState() => _MunicipalityEditorDialogState(); }
class _MunicipalityEditorDialogState extends ConsumerState<MunicipalityEditorDialog> { late final name = TextEditingController(text: widget.item.name); late final alt = TextEditingController(text: widget.item.nameAlt); late final provinceCode = TextEditingController(text: widget.item.provinceCode); late final provinceName = TextEditingController(text: widget.item.provinceName); late bool active = widget.item.isActive; @override Widget build(BuildContext context) => AlertDialog(title: Text('admin.hunting.municipalities.edit'.tr()), content: SizedBox(width: 520, child: HBFormSection(title: 'admin.hunting.municipalities.data'.tr(), children: [HBFormField(label: 'admin.hunting.municipalities.name'.tr(), child: HBInput(controller: name)), HBFormField(label: 'admin.hunting.municipalities.alt'.tr(), child: HBInput(controller: alt)), HBFormField(label: 'admin.hunting.municipalities.province_code'.tr(), child: HBInput(controller: provinceCode)), HBFormField(label: 'admin.hunting.municipalities.province_name'.tr(), child: HBInput(controller: provinceName)), SwitchListTile(value: active, title: Text('admin.hunting.active'.tr()), onChanged: (value) => setState(() => active = value))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'common.save'.tr(), onPressed: () async { await ref.read(adminHuntingRepositoryProvider).updateMunicipality(widget.item.id, {'name': name.text.trim(), 'name_alt': alt.text.trim().isEmpty ? null : alt.text.trim(), 'province_code': provinceCode.text.trim().isEmpty ? null : provinceCode.text.trim(), 'province_name': provinceName.text.trim().isEmpty ? null : provinceName.text.trim(), 'is_active': active}); widget.onSaved(); if (context.mounted) context.pop(); })]); }

class AdminRegionsTab extends ConsumerWidget {
  final String countryCode; final AdminHuntingReferenceData references;
  const AdminRegionsTab({super.key, required this.countryCode, required this.references});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminHuntingRegionsProvider(countryCode));
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      HBButton.primary(label: 'admin.hunting.regions.new'.tr(), icon: Icons.add, onPressed: () => showDialog(context: context, builder: (_) => RegionEditorDialog(countryCode: countryCode))),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr()),
        data: (items) => AdminDataTable(headers: [for (final key in const ['code','name','kind','municipalities','calendars','actions']) 'admin.hunting.regions.columns.$key'.tr()], columnWidths: const [120,220,150,130,130,100], emptyMessage: 'admin.hunting.regions.empty'.tr(), rows: [for (final item in items) [Text(item.code), Text(item.name), Text(item.kind), Text('${item.municipalityCount}'), Text('${item.calendarCount}'), HBButton.icon(icon: Icons.edit_outlined, onPressed: () => showDialog(context: context, builder: (_) => RegionEditorDialog(countryCode: countryCode, region: item)))]]),
      )),
    ]);
  }
}
class RegionEditorDialog extends ConsumerStatefulWidget { final String countryCode; final AdminHuntingRegion? region; const RegionEditorDialog({super.key, required this.countryCode, this.region}); @override ConsumerState<RegionEditorDialog> createState() => _RegionEditorDialogState(); }
class _RegionEditorDialogState extends ConsumerState<RegionEditorDialog> { late final code = TextEditingController(text: widget.region?.code); late final name = TextEditingController(text: widget.region?.name); late final kind = TextEditingController(text: widget.region?.kind ?? 'region'); @override Widget build(BuildContext context) => AlertDialog(title: Text(widget.region == null ? 'admin.hunting.regions.new'.tr() : 'admin.hunting.regions.edit'.tr()), content: SizedBox(width: 480, child: HBFormSection(title: 'admin.hunting.regions.data'.tr(), children: [HBFormField(label: 'admin.hunting.regions.code'.tr(), child: HBInput(controller: code, enabled: widget.region == null)), HBFormField(label: 'admin.hunting.regions.name'.tr(), child: HBInput(controller: name)), HBFormField(label: 'admin.hunting.regions.kind'.tr(), child: HBInput(controller: kind, enabled: widget.region == null))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'common.save'.tr(), onPressed: () async { await ref.read(adminHuntingRepositoryProvider).saveRegion(id: widget.region?.id, values: {'country_code': widget.countryCode, 'code': code.text.trim(), 'name': name.text.trim(), 'kind': kind.text.trim()}); ref.invalidate(adminHuntingRegionsProvider(widget.countryCode)); if (context.mounted) context.pop(); })]); }

HBStatusKind _statusKind(String status) => switch (status) { 'published' => HBStatusKind.approved, 'draft' => HBStatusKind.pending, 'archived' => HBStatusKind.neutral, _ => HBStatusKind.info };