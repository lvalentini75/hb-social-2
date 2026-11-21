import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_hunting_providers.dart';
import 'package:hb_social/features/admin/providers/admin_p44_providers.dart';
import 'package:share_plus/share_plus.dart';

class AdminHuntingCalendarsPage extends ConsumerStatefulWidget {
  const AdminHuntingCalendarsPage({super.key});
  @override ConsumerState<AdminHuntingCalendarsPage> createState() => _AdminHuntingCalendarsPageState();
}

class _AdminHuntingCalendarsPageState extends ConsumerState<AdminHuntingCalendarsPage> {
  String? country, region, season, speciesId;
  String status = 'all', query = '';
  int offset = 0;
  bool queryLoaded = false;

  @override
  Widget build(BuildContext context) {
    final references = ref.watch(adminHuntingReferencesProvider);
    if (references.isLoading) return const Center(child: CircularProgressIndicator());
    if (references.hasError) return HBEmptyState(icon: Icons.cloud_off_outlined, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr());
    final data = references.value!;
    country ??= data.countries.firstOrNull?.code;
    if (!queryLoaded) { queryLoaded = true; region = GoRouterState.of(context).uri.queryParameters['region']; }
    final regions = data.regions.where((item) => item.countryCode == country).toList();
    final filter = (country: country, regionId: region, season: season, status: status, speciesId: speciesId, query: query, offset: offset);
    final state = ref.watch(adminP44CalendarsProvider(filter));
    final rows = state.value ?? const <AdminCalendarRowP44>[];
    final canWrite = ref.watch(adminAccessProvider).value?.canWrite('calendars') == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.hunting.calendars.title'.tr(), style: context.textStyles.headlineSmall), Text('admin.hunting.calendars.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))])), if (canWrite) HBButton.primary(label: 'admin.hunting.calendars.new'.tr(), icon: Icons.add, onPressed: () => context.push('/admin/hunting/calendars/new'))]),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
        for (final item in data.countries) HBChip(label: item.code, selected: country == item.code, onTap: () => setState(() { country = item.code; region = null; offset = 0; })),
        SizedBox(width: 190, child: HBSelect<String>(value: region, allowClear: true, placeholder: 'admin.hunting.filters.region'.tr(), options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() { region = value; offset = 0; }))),
        SizedBox(width: 150, child: HBInput(hint: 'admin.hunting.filters.season'.tr(), onChanged: (value) => setState(() { season = value.trim().isEmpty ? null : value.trim(); offset = 0; }))),
        for (final item in const ['all','draft','published','archived']) HBChip(label: 'admin.hunting.status.$item'.tr(), selected: status == item, onTap: () => setState(() { status = item; offset = 0; })),
        SizedBox(width: 240, child: HBSelect<String>(value: speciesId, allowClear: true, placeholder: 'admin.hunting.filters.species'.tr(), options: [for (final item in data.species) HBSelectOption(value: item.id, label: item.nameFor('it'))], onChanged: (value) => setState(() { speciesId = value; offset = 0; }))),
        SizedBox(width: 220, child: HBInput(hint: 'common.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (value) => setState(() { query = value; offset = 0; }))),
      ]),
      if (canWrite) ...[const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.secondary(label: 'admin.hunting.calendars.clone'.tr(), icon: Icons.copy_outlined, onPressed: () => showDialog(context: context, builder: (_) => CalendarCloneDialog(references: data))), HBButton.secondary(label: 'admin.hunting.calendars.bulk_publish'.tr(), icon: Icons.publish_outlined, onPressed: () => showDialog(context: context, builder: (_) => CalendarBulkPublishDialog(references: data))), HBButton.secondary(label: 'admin.hunting.calendars.import_csv'.tr(), icon: Icons.upload_file_outlined, onPressed: () => showDialog(context: context, builder: (_) => CalendarCsvImportDialog(references: data)))])],
      const SizedBox(height: AppSpacing.md),
      Expanded(child: AdminDataTable(
        isLoading: state.isLoading,
        emptyMessage: 'admin.hunting.calendars.empty'.tr(),
        headers: [for (final key in const ['species','category','scope','season','period','rules','status','published','updated']) 'admin.hunting.calendars.columns.$key'.tr()],
        columnWidths: const [220,130,180,100,190,90,110,170,140],
        rows: [for (final item in rows) [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.speciesName), Text(item.scientificName, style: context.textStyles.bodySmall?.copyWith(fontStyle: FontStyle.italic))]),
          Text('admin.hunting.categories.${item.category}'.tr()), Text(item.unitName ?? item.regionName),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.seasonLabel), if (item.isCurrent) HBChip(label: 'admin.hunting.calendars.current'.tr(), selected: true, tag: true)]),
          Text('${DateFormat.yMd(context.locale.languageCode).format(item.validFrom)} - ${DateFormat.yMd(context.locale.languageCode).format(item.validTo)}'),
          Row(children: [Text('${item.rulesCount}'), if (item.hasTimeRule) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.schedule, size: 16))]),
          HBStatusChip(kind: _status(item.status), label: 'admin.hunting.status.${item.status}'.tr()),
          Text(item.publishedByName == null ? '-' : '${item.publishedByName}\n${item.publishedAt == null ? '' : DateFormat.yMd().format(item.publishedAt!)}'),
          Text(DateFormat.yMd().add_Hm().format(item.updatedAt.toLocal())),
        ]],
        rowCallbacks: [for (final item in rows) () => context.push('/admin/hunting/calendars/${item.id}')],
      )),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.ghost(label: 'common.previous'.tr(), onPressed: offset == 0 ? null : () => setState(() => offset = (offset - 200).clamp(0, 1000000))), const SizedBox(width: AppSpacing.sm), Text('${offset + 1}-${offset + rows.length}'), const SizedBox(width: AppSpacing.sm), HBButton.ghost(label: 'common.next'.tr(), onPressed: rows.length < 200 ? null : () => setState(() => offset += 200))]),
    ]);
  }
}

class CalendarCloneDialog extends ConsumerStatefulWidget {
  final AdminHuntingReferenceData references;
  const CalendarCloneDialog({super.key, required this.references});
  @override ConsumerState<CalendarCloneDialog> createState() => _CalendarCloneDialogState();
}
class _CalendarCloneDialogState extends ConsumerState<CalendarCloneDialog> {
  String? region; final from = TextEditingController(); final to = TextEditingController(); bool saving = false;
  @override Widget build(BuildContext context) => AlertDialog(title: Text('admin.hunting.calendars.clone'.tr()), content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [HBSelect<String>(value: region, placeholder: 'admin.hunting.filters.region'.tr(), options: [for (final item in widget.references.regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => region = value)), const SizedBox(height: AppSpacing.sm), Row(children: [Expanded(child: HBInput(controller: from, hint: 'admin.hunting.calendars.from_season'.tr(), onChanged: (value) { final match = RegExp(r'^(\d{4})/(\d{2})$').firstMatch(value); if (match != null) to.text = '${int.parse(match.group(1)!) + 1}/${(int.parse(match.group(2)!) + 1).toString().padLeft(2, '0')}'; })), const SizedBox(width: AppSpacing.sm), Expanded(child: HBInput(controller: to, hint: 'admin.hunting.calendars.to_season'.tr()))])])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'admin.hunting.calendars.clone'.tr(), isLoading: saving, onPressed: region == null ? null : _save)]);
  Future<void> _save() async { setState(() => saving = true); try { final result = await ref.read(adminP44RepositoryProvider).cloneSeason(regionId: region!, fromSeason: from.text.trim(), toSeason: to.text.trim()); if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.hunting.calendars.clone_result'.tr(namedArgs: {'created': '${result['created'] ?? 0}', 'skipped': '${result['skipped'] ?? 0}'})))); } } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class CalendarBulkPublishDialog extends ConsumerStatefulWidget {
  final AdminHuntingReferenceData references;
  const CalendarBulkPublishDialog({super.key, required this.references});
  @override ConsumerState<CalendarBulkPublishDialog> createState() => _CalendarBulkPublishDialogState();
}
class _CalendarBulkPublishDialogState extends ConsumerState<CalendarBulkPublishDialog> {
  String? region; final season = TextEditingController(); bool saving = false;
  @override Widget build(BuildContext context) => AlertDialog(title: Text('admin.hunting.calendars.bulk_publish'.tr()), content: SizedBox(width: 480, child: Column(mainAxisSize: MainAxisSize.min, children: [HBSelect<String>(value: region, placeholder: 'admin.hunting.filters.region'.tr(), options: [for (final item in widget.references.regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => region = value)), const SizedBox(height: AppSpacing.sm), HBInput(controller: season, hint: 'admin.hunting.filters.season'.tr())])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'admin.hunting.calendars.bulk_publish'.tr(), isLoading: saving, onPressed: region == null ? null : _save)]);
  Future<void> _save() async { setState(() => saving = true); try { final result = await ref.read(adminP44RepositoryProvider).bulkStatus(regionId: region!, season: season.text.trim()); if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.hunting.calendars.bulk_result'.tr(namedArgs: {'changed': '${result['changed'] ?? 0}', 'skipped': '${(result['skipped'] as List?)?.length ?? 0}'})))); } } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class CalendarCsvImportDialog extends ConsumerStatefulWidget {
  final AdminHuntingReferenceData references;
  const CalendarCsvImportDialog({super.key, required this.references});
  @override ConsumerState<CalendarCsvImportDialog> createState() => _CalendarCsvImportDialogState();
}
class _CalendarCsvImportDialogState extends ConsumerState<CalendarCsvImportDialog> {
  String? region; final season = TextEditingController(); List<Map<String, dynamic>> rows = const []; Map<String, dynamic>? result; bool saving = false;
  static const headers = ['species','valid_from','valid_to','source_name','source_url','notes','unit_code','allowed_days','time_rule','bag_day','bag_season','closed_from','closed_to'];
  Future<void> pick() async { final file = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['csv'], withData: true); if (file?.files.single.bytes == null) return; final text = utf8.decode(file!.files.single.bytes!); setState(() => rows = _parseCsv(text)); }
  @override Widget build(BuildContext context) => AlertDialog(
    title: Text('admin.hunting.calendars.import_csv'.tr()),
    content: SizedBox(width: 820, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HBSelect<String>(value: region, placeholder: 'admin.hunting.filters.region'.tr(), options: [for (final item in widget.references.regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => region = value)),
      const SizedBox(height: AppSpacing.sm), HBInput(controller: season, hint: 'admin.hunting.filters.season'.tr()), const SizedBox(height: AppSpacing.sm),
      Wrap(spacing: AppSpacing.sm, children: [HBButton.secondary(label: 'admin.hunting.calendars.choose_csv'.tr(), icon: Icons.upload_file, onPressed: pick), HBButton.ghost(label: 'admin.hunting.calendars.download_template'.tr(), onPressed: _downloadTemplate), if (rows.isNotEmpty) Text('admin.hunting.calendars.rows_recognized'.tr(namedArgs: {'n': '${rows.length}'}))]),
      if (rows.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), AdminDataTable(emptyMessage: 'admin.hunting.calendars.empty'.tr(), headers: headers.take(7).toList(), columnWidths: const [160,100,100,130,130,140,100], rows: [for (final row in rows.take(20)) [for (final key in headers.take(7)) Text(row[key]?.toString() ?? '-')]])],
      if (result != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text('admin.hunting.calendars.import_result'.tr(namedArgs: {'created': '${result!['created'] ?? 0}', 'updated': '${result!['updated'] ?? 0}', 'errors': '${(result!['errors'] as List?)?.length ?? 0}'}))),
    ]))),
    actions: [HBButton.ghost(label: 'common.close'.tr(), onPressed: context.pop), HBButton.primary(label: 'admin.hunting.calendars.import_csv'.tr(), isLoading: saving, onPressed: region == null || rows.isEmpty ? null : _import)],
  );
  Future<void> _downloadTemplate() => Share.shareXFiles([XFile.fromData(Uint8List.fromList(utf8.encode('${headers.join(',')}\n')), mimeType: 'text/csv', name: 'calendars-template.csv')]);
  Future<void> _import() async { setState(() => saving = true); try { final value = await ref.read(adminP44RepositoryProvider).importCalendars(regionId: region!, season: season.text.trim(), rows: rows); if (mounted) setState(() => result = value); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
  List<Map<String, dynamic>> _parseCsv(String text) { final lines = const LineSplitter().convert(text).where((line) => line.trim().isNotEmpty).toList(); if (lines.length < 2) return const []; final separator = lines.first.split(';').length > lines.first.split(',').length ? ';' : ','; final columns = _split(lines.first, separator); return [for (final line in lines.skip(1).take(500)) () { final values = _split(line, separator); final row = <String, dynamic>{for (var i = 0; i < columns.length && i < values.length; i++) columns[i]: values[i]}; final rules = <Map<String, dynamic>>[]; if ((row['allowed_days'] as String?)?.isNotEmpty == true) rules.add({'kind': 'allowed_days', 'allowed_days': row['allowed_days'].toString().split(RegExp(r'[,| ]+')).map(int.tryParse).whereType<int>().toList()}); if ((row['time_rule'] as String?)?.isNotEmpty == true) rules.add({'kind': 'time_rule', 'time_rule': row['time_rule']}); if ((row['bag_day'] as String?)?.isNotEmpty == true) rules.add({'kind': 'bag_limit', 'bag_limit': int.tryParse(row['bag_day']), 'bag_period': 'day'}); if ((row['bag_season'] as String?)?.isNotEmpty == true) rules.add({'kind': 'bag_limit', 'bag_limit': int.tryParse(row['bag_season']), 'bag_period': 'season'}); if ((row['closed_from'] as String?)?.isNotEmpty == true) rules.add({'kind': 'closed_period', 'date_from': row['closed_from'], 'date_to': row['closed_to']}); return {for (final key in headers.take(7)) key: row[key], if (rules.isNotEmpty) 'rules': rules}; }()]; }
  List<String> _split(String line, String separator) { final values = <String>[]; var current = '', quoted = false; for (var i = 0; i < line.length; i++) { final char = line[i]; if (char == '"') quoted = !quoted; else if (char == separator && !quoted) { values.add(current.trim()); current = ''; } else { current += char; } } values.add(current.trim()); return values; }
}

HBStatusKind _status(String value) => switch (value) { 'published' => HBStatusKind.approved, 'draft' => HBStatusKind.pending, 'archived' => HBStatusKind.neutral, _ => HBStatusKind.info };