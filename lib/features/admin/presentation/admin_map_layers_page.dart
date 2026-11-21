import 'dart:convert';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_country_picker.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/domain/admin_p44_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_hunting_providers.dart';
import 'package:hb_social/features/admin/providers/admin_p44_providers.dart';
import 'package:hb_social/features/map/domain/map_models.dart';
import 'package:hb_social/features/map/presentation/map_page.dart' show formatMapArea, mapColorHex, mapStoredColor;
import 'package:latlong2/latlong.dart';

class AdminMapLayersPage extends ConsumerStatefulWidget {
  const AdminMapLayersPage({super.key});
  @override ConsumerState<AdminMapLayersPage> createState() => _AdminMapLayersPageState();
}
class _AdminMapLayersPageState extends ConsumerState<AdminMapLayersPage> {
  String? country, region, status;
  @override Widget build(BuildContext context) {
    final references = ref.watch(adminHuntingReferencesProvider).value;
    country ??= references?.countries.firstOrNull?.code;
    final regions = references?.regions.where((item) => item.countryCode == country).toList() ?? const <AdminHuntingRegion>[];
    final filter = (country: country, regionId: region, status: status);
    final state = ref.watch(adminP44MapLayersProvider(filter));
    final canWrite = ref.watch(adminAccessProvider).value?.canWrite('maps') == true;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Row(children: [Expanded(child: Text('admin.layers.title'.tr(), style: context.textStyles.headlineSmall)), if (canWrite && references != null) HBButton.primary(label: 'admin.layers.new'.tr(), icon: Icons.add, onPressed: () => showDialog(context: context, builder: (_) => MapLayerEditorDialog(references: references)))]), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, children: [SizedBox(width: 240, child: HBCountryPicker(value: country, onChanged: (value) => setState(() { country = value.code; region = null; }))), SizedBox(width: 200, child: HBSelect<String>(value: region, allowClear: true, placeholder: 'admin.hunting.filters.region'.tr(), options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => region = value))), SizedBox(width: 170, child: HBSelect<String>(value: status, allowClear: true, placeholder: 'admin.hunting.filters.status'.tr(), options: [for (final item in const ['draft','published','archived']) HBSelectOption(value: item, label: 'admin.hunting.status.$item'.tr())], onChanged: (value) => setState(() => status = value)))]), const SizedBox(height: AppSpacing.md), Expanded(child: state.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => HBEmptyState(icon: Icons.cloud_off_outlined, title: 'admin.layers.error'.tr(), message: 'admin.layers.error_help'.tr()), data: (items) => AdminDataTable(emptyMessage: 'admin.layers.empty'.tr(), headers: [for (final key in const ['name','kind','scope','features','area','size','validity','status','updated']) 'admin.layers.columns.$key'.tr()], columnWidths: const [200,150,160,90,110,90,180,110,190], rows: [for (final item in items) [Text(item.name), Row(children: [Icon(Icons.circle, size: 10, color: mapStoredColor(item.color)), const SizedBox(width: 6), Text('map.layers.kind.${item.kind}'.tr())]), Text(item.regionName ?? item.countryCode), Text('${item.featureCount}'), Text(formatMapArea(item.areaM2)), Text('${item.sizeKb} KB'), Text('${item.validFrom == null ? '-' : DateFormat.yMd().format(item.validFrom!)} - ${item.validTo == null ? '-' : DateFormat.yMd().format(item.validTo!)}'), HBStatusChip(kind: item.status == 'published' ? HBStatusKind.approved : item.status == 'draft' ? HBStatusKind.pending : HBStatusKind.neutral, label: 'admin.hunting.status.${item.status}'.tr()), InkWell(onTap: canWrite ? () => showDialog(context: context, builder: (_) => MapLayerEditorDialog(references: references!, item: item)) : null, child: Text('${item.updatedByName ?? '-'}\n${item.updatedAt == null ? '-' : DateFormat.yMd().add_Hm().format(item.updatedAt!.toLocal())}'))]]))) ]);
  }
}

class MapLayerEditorDialog extends ConsumerStatefulWidget {
  final AdminHuntingReferenceData references; final AdminMapLayerP44? item;
  const MapLayerEditorDialog({super.key, required this.references, this.item});
  @override ConsumerState<MapLayerEditorDialog> createState() => _MapLayerEditorDialogState();
}
class _MapLayerEditorDialogState extends ConsumerState<MapLayerEditorDialog> {
  late String? country = widget.item?.countryCode ?? widget.references.countries.firstOrNull?.code; late String? region = widget.item?.regionId; late String kind = widget.item?.kind ?? 'other';
  late final name = TextEditingController(text: widget.item?.name); late final description = TextEditingController(text: widget.item?.description); late final color = TextEditingController(text: widget.item?.color); late final sourceName = TextEditingController(text: widget.item?.sourceName); late final sourceUrl = TextEditingController(text: widget.item?.sourceUrl);
  Map<String, dynamic>? geoJson; String? savedId; int? featureCount; double? area; bool saving = false;
  static const kinds = ['protected_area','no_hunting','repopulation','training_ground','wildlife_park','hunting_unit','other'];
  Future<void> pickGeoJson() async { final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['geojson','json'], withData: true); if (result == null) return; if (result.files.single.size > 12 * 1024 * 1024) { _message('p44.errors.layer_geojson_too_large'); return; } try { final value = jsonDecode(utf8.decode(result.files.single.bytes!)); if (value is! Map) throw const FormatException(); final parsed = Map<String, dynamic>.from(value); final geometry = OfficialLayerGeometry.fromJson(parsed); if (geometry.features.isEmpty || geometry.features.any((feature) => feature.rings.isEmpty)) throw const FormatException(); setState(() { geoJson = parsed; featureCount = geometry.features.length; }); } catch (_) { _message('p44.errors.layer_geojson_invalid'); } }
  @override Widget build(BuildContext context) { final regions = widget.references.regions.where((item) => item.countryCode == country).toList(); final palette = [LightModeColors.lightPrimary, LightModeColors.lightInfo, LightModeColors.lightWarning, LightModeColors.lightError, LightModeColors.lightSuccess, LightModeColors.lightSecondary]; return AlertDialog(title: Text((widget.item == null ? 'admin.layers.new' : 'admin.layers.edit').tr()), content: SizedBox(width: 860, child: SingleChildScrollView(child: Column(children: [HBFormSection(title: 'admin.layers.data'.tr(), children: [HBFormField(label: 'admin.hunting.country'.tr(), child: HBCountryPicker(value: country, onChanged: (value) => setState(() { country = value.code; region = null; }))), HBFormField(label: 'admin.hunting.filters.region'.tr(), child: HBSelect<String>(value: region, allowClear: true, options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() => region = value))), HBFormField(label: 'admin.layers.kind'.tr(), child: HBSelect<String>(value: kind, options: [for (final item in kinds) HBSelectOption(value: item, label: 'map.layers.kind.$item'.tr())], onChanged: (value) => setState(() => kind = value!))), HBFormField(label: 'admin.layers.name'.tr(), required: true, child: HBInput(controller: name)), HBFormField(label: 'admin.layers.description'.tr(), child: HBInput(controller: description, maxLines: 3)), HBFormField(label: 'admin.layers.color'.tr(), child: Column(children: [Wrap(spacing: AppSpacing.sm, children: [for (final item in palette) GestureDetector(onTap: () => setState(() => color.text = mapColorHex(item)), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: item, shape: BoxShape.circle)))]), const SizedBox(height: AppSpacing.xs), HBInput(controller: color, hint: 'admin.layers.color_hint'.tr())])), HBFormField(label: 'admin.layers.source'.tr(), child: HBInput(controller: sourceName)), HBFormField(label: 'admin.layers.source_url'.tr(), child: HBInput(controller: sourceUrl))]), const SizedBox(height: AppSpacing.md), HBFormSection(title: 'admin.layers.geometry'.tr(), children: [HBButton.secondary(label: 'admin.layers.choose_geojson'.tr(), icon: Icons.upload_file, onPressed: pickGeoJson), if (featureCount != null) Text('admin.layers.geometry_summary'.tr(namedArgs: {'features': '$featureCount', 'area': area == null ? '-' : formatMapArea(area!)})), if (geoJson != null) LayerGeometryPreview(geoJson: geoJson!, color: mapStoredColor(color.text))])]))), actions: [if (widget.item != null) HBButton.ghost(label: 'common.remove'.tr(), onPressed: _delete), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: context.pop), if ((widget.item?.featureCount ?? 0) > 0 || geoJson != null) HBButton.secondary(label: widget.item?.status == 'published' ? 'admin.hunting.actions.draft'.tr() : 'admin.hunting.actions.publish'.tr(), onPressed: _toggleStatus), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: _save)]); }
  Future<void> _save() async { setState(() => saving = true); try { final repository = ref.read(adminP44RepositoryProvider); savedId = await repository.upsertMapLayer(id: widget.item?.id, countryCode: country, regionId: region, kind: kind, name: name.text.trim(), description: description.text, color: color.text.trim().isEmpty ? null : color.text.trim(), sourceName: sourceName.text, sourceUrl: sourceUrl.text); if (geoJson != null) { final result = await repository.setMapLayerGeoJson(savedId!, geoJson); setState(() { featureCount = (result['feature_count'] as num?)?.toInt(); area = (result['area_m2'] as num?)?.toDouble(); }); } ref.invalidate(adminP44MapLayersProvider); if (mounted && geoJson == null) context.pop(); } on AppException catch (error) { _message(error.messageKey); } finally { if (mounted) setState(() => saving = false); } }
  Future<void> _toggleStatus() async { final id = savedId ?? widget.item?.id; if (id == null) return; try { await ref.read(adminP44RepositoryProvider).setMapLayerStatus(id, widget.item?.status == 'published' ? 'draft' : 'published'); ref.invalidate(adminP44MapLayersProvider); if (mounted) context.pop(); } on AppException catch (error) { _message(error.messageKey); } }
  Future<void> _delete() async { await ref.read(adminP44RepositoryProvider).deleteMapLayer(widget.item!.id); ref.invalidate(adminP44MapLayersProvider); if (mounted) context.pop(); }
  void _message(String key) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr()))); }
}

class LayerGeometryPreview extends StatelessWidget {
  final Map<String, dynamic> geoJson; final Color color;
  const LayerGeometryPreview({super.key, required this.geoJson, required this.color});
  @override Widget build(BuildContext context) { final features = OfficialLayerGeometry.fromJson(geoJson).features; final rings = features.expand((feature) => feature.rings).toList(); final points = rings.expand((ring) => ring).toList(); final center = points.isEmpty ? const LatLng(42.5, 12.5) : LatLng(points.map((point) => point.latitude).reduce((a, b) => a + b) / points.length, points.map((point) => point.longitude).reduce((a, b) => a + b) / points.length); return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 260, child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 8), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), PolygonLayer(polygons: [for (final ring in rings) Polygon(points: ring, color: color.withValues(alpha: 0.16), borderColor: color, borderStrokeWidth: 2)])]))); }
}