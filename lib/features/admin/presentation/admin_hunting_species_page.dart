import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p44_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHuntingSpeciesPage extends ConsumerStatefulWidget {
  const AdminHuntingSpeciesPage({super.key});
  @override ConsumerState<AdminHuntingSpeciesPage> createState() => _AdminHuntingSpeciesPageState();
}
class _AdminHuntingSpeciesPageState extends ConsumerState<AdminHuntingSpeciesPage> {
  String query = ''; String? category; int offset = 0;
  @override Widget build(BuildContext context) {
    final filter = (query: query, category: category, offset: offset);
    final state = ref.watch(adminP44SpeciesProvider(filter));
    final canWrite = ref.watch(adminAccessProvider).value?.canWrite('calendars') == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('admin.hunting.species.title'.tr(), style: context.textStyles.headlineSmall)), if (canWrite) HBButton.primary(label: 'admin.hunting.species.new'.tr(), icon: Icons.add, onPressed: () => showDialog(context: context, builder: (_) => const P44SpeciesEditorDialog()))]), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [SizedBox(width: 260, child: HBInput(hint: 'common.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (value) => setState(() { query = value; offset = 0; }))), SizedBox(width: 180, child: HBSelect<String>(value: category, allowClear: true, placeholder: 'admin.hunting.species.category'.tr(), options: [for (final item in const ['ungulate','small_game','migratory','waterfowl','predator','other']) HBSelectOption(value: item, label: 'admin.hunting.categories.$item'.tr())], onChanged: (value) => setState(() { category = value; offset = 0; }))) ]), const SizedBox(height: AppSpacing.md), Expanded(child: state.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.hunting.errors.load_title'.tr(), message: 'admin.hunting.errors.load_message'.tr()), data: (items) => AdminDataTable(emptyMessage: 'admin.hunting.species.empty'.tr(), headers: [for (final key in const ['image','name','scientific','category','languages','uses','active','actions']) 'admin.hunting.species.columns.$key'.tr()], columnWidths: const [70,160,190,130,190,210,90,150], rows: [for (final item in items) [item.imagePath == null ? const Icon(Icons.image_not_supported_outlined) : ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xs), child: Image.network(storagePublicUrl(ref.read(supabaseClientProvider), 'species-media', item.imagePath), width: 42, height: 42, fit: BoxFit.cover)), Text(item.names['it'] ?? '-'), Text(item.scientificName, style: context.textStyles.bodyMedium?.copyWith(fontStyle: FontStyle.italic)), Text('admin.hunting.categories.${item.category}'.tr()), Wrap(spacing: 3, children: [for (final locale in const ['it','en','fr','es','de']) HBChip(label: locale.toUpperCase(), selected: !item.missingLocales.contains(locale), tag: true)]), Text('admin.hunting.species.uses'.tr(namedArgs: {'published': '${item.publishedCalendars}', 'calendars': '${item.calendars}', 'sightings': '${item.sightings}', 'logs': '${item.logEntries}', 'alerts': '${item.alerts}'})), HBStatusChip(kind: item.isActive ? HBStatusKind.approved : HBStatusKind.neutral, label: (item.isActive ? 'admin.hunting.active' : 'admin.hunting.inactive').tr()), if (canWrite) Row(children: [HBButton.icon(icon: Icons.edit_outlined, onPressed: () => showDialog(context: context, builder: (_) => P44SpeciesEditorDialog(item: item))), HBButton.icon(icon: Icons.merge_type, onPressed: () => showDialog(context: context, builder: (_) => SpeciesMergeDialog(source: item))), HBButton.icon(icon: Icons.delete_outline, onPressed: item.uses == 0 ? () => _delete(item.id) : null)]) else const SizedBox.shrink()]]))), Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.ghost(label: 'common.previous'.tr(), onPressed: offset == 0 ? null : () => setState(() => offset -= 200)), HBButton.ghost(label: 'common.next'.tr(), onPressed: state.value?.length == 200 ? () => setState(() => offset += 200) : null)])]);
  }
  Future<void> _delete(String id) async { try { await ref.read(adminP44RepositoryProvider).deleteSpecies(id); ref.invalidate(adminP44SpeciesProvider); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
}

class P44SpeciesEditorDialog extends ConsumerStatefulWidget {
  final AdminSpeciesP44? item;
  const P44SpeciesEditorDialog({super.key, this.item});
  @override ConsumerState<P44SpeciesEditorDialog> createState() => _P44SpeciesEditorDialogState();
}
class _P44SpeciesEditorDialogState extends ConsumerState<P44SpeciesEditorDialog> {
  late final scientific = TextEditingController(text: widget.item?.scientificName); late String category = widget.item?.category ?? 'other'; late bool active = widget.item?.isActive ?? true; late final names = {for (final locale in const ['it','en','fr','es','de']) locale: TextEditingController(text: widget.item?.names[locale])}; Uint8List? image; String? extension; bool saving = false;
  Future<void> pickImage() async { final value = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['jpg','jpeg','png','webp'], withData: true); if (value?.files.single.bytes == null) return; setState(() { image = value!.files.single.bytes; extension = value.files.single.extension ?? 'jpg'; }); }
  @override Widget build(BuildContext context) => AlertDialog(title: Text((widget.item == null ? 'admin.hunting.species.new' : 'admin.hunting.species.edit').tr()), content: SizedBox(width: 620, child: SingleChildScrollView(child: HBFormSection(title: 'admin.hunting.species.data'.tr(), children: [HBFormField(label: 'admin.hunting.species.scientific'.tr(), required: true, child: HBInput(controller: scientific)), HBFormField(label: 'admin.hunting.species.category'.tr(), child: HBSelect<String>(value: category, options: [for (final item in const ['ungulate','small_game','migratory','waterfowl','predator','other']) HBSelectOption(value: item, label: 'admin.hunting.categories.$item'.tr())], onChanged: (value) => setState(() => category = value!))), for (final entry in names.entries) HBFormField(label: 'language.${entry.key}'.tr(), required: entry.key == 'it', child: HBInput(controller: entry.value)), SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('admin.hunting.active'.tr()), value: active, onChanged: (value) => setState(() => active = value)), HBButton.secondary(label: image == null ? 'admin.hunting.species.choose_image'.tr() : 'admin.hunting.species.image_selected'.tr(), icon: Icons.image_outlined, onPressed: pickImage)]))), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: _save)]);
  Future<void> _save() async { if (scientific.text.trim().isEmpty || names['it']!.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('p44.errors.species_name_it_required'.tr()))); return; } setState(() => saving = true); try { final repository = ref.read(adminP44RepositoryProvider); var id = await repository.upsertSpecies(id: widget.item?.id, scientificName: scientific.text.trim(), category: category, names: {for (final entry in names.entries) entry.key: entry.value.text.trim()}, isActive: active, imagePath: widget.item?.imagePath); if (image != null) { final path = '$id/${const Uuid().v4()}.$extension'; await ref.read(supabaseClientProvider).storage.from('species-media').uploadBinary(path, image!, fileOptions: const FileOptions(upsert: false)); await repository.upsertSpecies(id: id, scientificName: scientific.text.trim(), category: category, names: {for (final entry in names.entries) entry.key: entry.value.text.trim()}, isActive: active, imagePath: path); } ref.invalidate(adminP44SpeciesProvider); if (mounted) context.pop(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class SpeciesMergeDialog extends ConsumerStatefulWidget {
  final AdminSpeciesP44 source;
  const SpeciesMergeDialog({super.key, required this.source});
  @override ConsumerState<SpeciesMergeDialog> createState() => _SpeciesMergeDialogState();
}
class _SpeciesMergeDialogState extends ConsumerState<SpeciesMergeDialog> {
  String? target; bool saving = false;
  @override Widget build(BuildContext context) { final values = ref.watch(adminP44SpeciesProvider((query: '', category: null, offset: 0))).value ?? const <AdminSpeciesP44>[]; return AlertDialog(title: Text('admin.hunting.species.merge'.tr()), content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [Text('admin.hunting.species.merge_summary'.tr(namedArgs: {'calendars': '${widget.source.calendars}', 'sightings': '${widget.source.sightings}', 'logs': '${widget.source.logEntries}', 'alerts': '${widget.source.alerts}'})), const SizedBox(height: AppSpacing.md), HBSelect<String>(value: target, placeholder: 'admin.hunting.species.merge_into'.tr(), options: [for (final item in values.where((item) => item.id != widget.source.id)) HBSelectOption(value: item.id, label: '${item.names['it'] ?? item.scientificName} · ${item.scientificName}')], onChanged: (value) => setState(() => target = value))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), HBButton.primary(label: 'admin.hunting.species.merge'.tr(), isLoading: saving, onPressed: target == null ? null : _merge)]); }
  Future<void> _merge() async { setState(() => saving = true); try { final result = await ref.read(adminP44RepositoryProvider).mergeSpecies(widget.source.id, target!); ref.invalidate(adminP44SpeciesProvider); if (mounted) { context.pop(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.hunting.species.merge_result'.tr(namedArgs: {'calendars': '${result['calendars'] ?? 0}', 'sightings': '${result['sightings'] ?? 0}', 'logs': '${result['log_entries'] ?? 0}', 'alerts': '${result['alerts'] ?? 0}'})))); } } finally { if (mounted) setState(() => saving = false); } }
}