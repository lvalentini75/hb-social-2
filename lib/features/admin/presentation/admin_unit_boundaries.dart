import 'dart:convert';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/features/admin/domain/admin_hunting_models.dart';
import 'package:hb_social/features/admin/providers/admin_hunting_providers.dart';
import 'package:hb_social/features/admin/providers/admin_p44_providers.dart';
import 'package:hb_social/features/map/domain/map_geometry.dart';
import 'package:hb_social/features/map/domain/map_models.dart';
import 'package:latlong2/latlong.dart';
import 'package:intl/intl.dart';

class AdminBoundaryStatus extends StatelessWidget {
  final AdminUnitBoundary? boundary;
  const AdminBoundaryStatus({super.key, this.boundary});
  @override Widget build(BuildContext context) { final value = boundary; if (value == null) return Text('common.unavailable'.tr()); return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${'map.area'.tr()}: ${(value.areaM2 / 1000000).toStringAsFixed(1)}'), Text('${'admin.hunting.calendars.source_name'.tr()}: ${value.source ?? 'common.unavailable'.tr()}', maxLines: 1, overflow: TextOverflow.ellipsis), Text(DateFormat.yMd(context.locale.languageCode).format(value.updatedAt.toLocal()))]); }
}

class UnitBoundaryEditorDialog extends ConsumerStatefulWidget {
  final AdminHuntingUnit unit; final AdminUnitBoundary? existing;
  const UnitBoundaryEditorDialog({super.key, required this.unit, this.existing});
  @override ConsumerState<UnitBoundaryEditorDialog> createState() => _UnitBoundaryEditorDialogState();
}
class _UnitBoundaryEditorDialogState extends ConsumerState<UnitBoundaryEditorDialog> {
  final raw = TextEditingController(); late final TextEditingController source = TextEditingController(text: widget.existing?.source); Map<String, dynamic>? geoJson; String? errorKey; bool saving = false;
  @override void initState() { super.initState(); geoJson = widget.existing?.geoJson; if (geoJson != null) raw.text = const JsonEncoder.withIndent('  ').convert(geoJson); }
  @override void dispose() { raw.dispose(); source.dispose(); super.dispose(); }
  Future<void> pick() async { final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['geojson','json'], withData: true); if (result == null) return; final file = result.files.single; if (file.size > 5 * 1024 * 1024) { setState(() => errorKey = 'errors.file_too_large'); return; } final bytes = file.bytes; if (bytes == null) { setState(() => errorKey = 'errors.file_unreadable'); return; } _parse(bytes); }
  void _parse(Uint8List bytes) { try { final decoded = jsonDecode(utf8.decode(bytes)); final normalized = normalizeBoundaryGeoJson(decoded); setState(() { geoJson = normalized; raw.text = const JsonEncoder.withIndent('  ').convert(normalized); errorKey = null; }); } catch (_) { setState(() { geoJson = null; errorKey = 'map.errors.polygon_invalid'; }); } }
  void parseText() => _parse(Uint8List.fromList(utf8.encode(raw.text)));
  Future<void> save() async { if (geoJson == null) return; setState(() => saving = true); try { await ref.read(adminHuntingRepositoryProvider).setUnitBoundary(unitId: widget.unit.id, geoJson: geoJson, source: source.text); ref.invalidate(adminUnitBoundariesProvider); if (mounted) context.pop(true); } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); } finally { if (mounted) setState(() => saving = false); } }
  Future<void> remove() async { final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('common.remove'.tr()), content: Text('map.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.secondary(label: 'common.remove'.tr(), onPressed: () => dialog.pop(true))])) ?? false; if (!confirmed) return; setState(() => saving = true); try { await ref.read(adminHuntingRepositoryProvider).setUnitBoundary(unitId: widget.unit.id); ref.invalidate(adminUnitBoundariesProvider); if (mounted) context.pop(true); } on AppException catch (error) { if (mounted) setState(() => errorKey = error.messageKey); } finally { if (mounted) setState(() => saving = false); } }
  @override Widget build(BuildContext context) { final rings = geoJsonRings(geoJson); final area = rings.fold<double>(0, (sum, ring) => sum + MapGeometry.areaM2(ring)); return AlertDialog(title: Text('${'map.layers.units'.tr()} · ${widget.unit.name}'), content: SizedBox(width: 760, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBButton.secondary(label: 'admin.hunting.units.import'.tr(), icon: Icons.upload_file_outlined, onPressed: pick), const SizedBox(height: AppSpacing.sm), HBFormField(label: 'admin.hunting.units.import_hint'.tr(), child: HBInput(controller: raw, maxLines: 8, onChanged: (_) => setState(() => errorKey = null))), const SizedBox(height: AppSpacing.xs), HBButton.soft(label: 'admin.hunting.preview.title'.tr(), onPressed: parseText), if (errorKey != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text(errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))), if (rings.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), AdminBoundaryMap(boundaries: [AdminUnitBoundary(unitId: widget.unit.id, unitName: widget.unit.name, unitType: widget.unit.unitType, code: widget.unit.code, regionId: widget.unit.regionId, geoJson: geoJson!, areaM2: area, source: source.text, updatedAt: DateTime.now().toUtc())]), const SizedBox(height: AppSpacing.xs), Text('${'map.area'.tr()}: ${(area / 1000000).toStringAsFixed(1)}')], const SizedBox(height: AppSpacing.md), HBFormField(label: 'admin.hunting.calendars.source_name'.tr(), child: HBInput(controller: source, maxLength: 300))]))), actions: [if (widget.existing != null) HBButton.ghost(label: 'common.remove'.tr(), icon: Icons.delete_outline, onPressed: saving ? null : remove), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: saving ? null : context.pop), HBButton.primary(label: 'common.save'.tr(), isLoading: saving, onPressed: geoJson == null ? null : save)]); }
}

class AdminBoundariesOverview extends StatelessWidget {
  final List<AdminUnitBoundary> boundaries;
  const AdminBoundariesOverview({super.key, required this.boundaries});
  @override Widget build(BuildContext context) { if (boundaries.isEmpty) return HBEmptyState(icon: Icons.map_outlined, title: 'admin.hunting.units.empty'.tr(), message: 'map.no_unit'.tr()); return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.hunting.units.import_hint'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.md), Expanded(child: AdminBoundaryMap(boundaries: boundaries))]); }
}

class AdminBoundaryMap extends StatelessWidget {
  final List<AdminUnitBoundary> boundaries;
  const AdminBoundaryMap({super.key, required this.boundaries});
  @override Widget build(BuildContext context) { final rings = boundaries.expand((item) => geoJsonRings(item.geoJson)).toList(); final points = rings.expand((ring) => ring).toList(); final center = points.isEmpty ? const LatLng(42.5, 12.5) : LatLng(points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length, points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length); return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 360, child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: boundaries.length == 1 ? 10 : 7), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), PolygonLayer(polygons: [for (final boundary in boundaries) for (final ring in geoJsonRings(boundary.geoJson)) Polygon(points: ring, color: LightModeColors.lightPrimary.withValues(alpha: 0.14), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 1.5, label: boundary.unitName, labelStyle: context.textStyles.labelSmall ?? const TextStyle())])]))); }
}

Map<String, dynamic> normalizeBoundaryGeoJson(Object? value) {
  if (value is! Map) throw const FormatException();
  var json = Map<String, dynamic>.from(value);
  if (json['type'] == 'FeatureCollection') { final features = json['features']; if (features is! List || features.length != 1 || features.single is! Map) throw const FormatException(); json = Map<String, dynamic>.from(features.single as Map); }
  if (json['type'] == 'Feature') { final geometry = json['geometry']; if (geometry is! Map) throw const FormatException(); json = Map<String, dynamic>.from(geometry); }
  if (json['type'] != 'Polygon' && json['type'] != 'MultiPolygon' || geoJsonRings(json).isEmpty) throw const FormatException();
  return json;
}

class UnitAreasImportDialog extends ConsumerStatefulWidget {
  final String regionId; final String unitType;
  const UnitAreasImportDialog({super.key, required this.regionId, required this.unitType});
  @override ConsumerState<UnitAreasImportDialog> createState() => _UnitAreasImportDialogState();
}
class _UnitAreasImportDialogState extends ConsumerState<UnitAreasImportDialog> {
  Map<String, dynamic>? collection; List<String> properties = const []; String? codeProperty, nameProperty; final source = TextEditingController(); Map<String, dynamic>? result; bool saving = false;
  Future<void> pick() async { final file = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: const ['geojson','json'], withData: true); if (file?.files.single.bytes == null) return; try { final value = jsonDecode(utf8.decode(file!.files.single.bytes!)); if (value is! Map || value['type'] != 'FeatureCollection' || value['features'] is! List) throw const FormatException(); final map = Map<String, dynamic>.from(value); final features = map['features'] as List; final first = features.firstOrNull as Map?; final props = first?['properties'] as Map? ?? const {}; setState(() { collection = map; properties = props.keys.map((key) => key.toString()).toList(); codeProperty = properties.contains('code') ? 'code' : properties.firstOrNull; nameProperty = properties.contains('name') ? 'name' : properties.firstOrNull; result = null; }); } catch (_) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('p44.errors.layer_geojson_invalid'.tr()))); } }
  @override Widget build(BuildContext context) { final features = collection?['features'] as List? ?? const []; final missing = features.where((raw) { final props = (raw as Map?)?['properties'] as Map?; return props?[codeProperty]?.toString().trim().isEmpty != false; }).length; return AlertDialog(title: Text('admin.hunting.units.import_boundaries'.tr()), content: SizedBox(width: 780, child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBButton.secondary(label: 'admin.layers.choose_geojson'.tr(), icon: Icons.upload_file, onPressed: pick), if (collection != null) ...[const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: HBSelect<String>(value: codeProperty, placeholder: 'admin.hunting.units.code_property'.tr(), options: [for (final item in properties) HBSelectOption(value: item, label: item)], onChanged: (value) => setState(() => codeProperty = value))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBSelect<String>(value: nameProperty, placeholder: 'admin.hunting.units.name_property'.tr(), options: [for (final item in properties) HBSelectOption(value: item, label: item)], onChanged: (value) => setState(() => nameProperty = value)))]), const SizedBox(height: AppSpacing.sm), HBFormField(label: 'admin.layers.source'.tr(), child: HBInput(controller: source)), const SizedBox(height: AppSpacing.sm), Text('admin.hunting.units.boundaries_preview'.tr(namedArgs: {'features': '${features.length}', 'missing': '$missing'})), LayerFeatureCollectionPreview(collection: collection!)], if (result != null) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: Text('admin.hunting.units.boundaries_result'.tr(namedArgs: {'features': '${result!['features'] ?? 0}', 'created': '${result!['created_units'] ?? 0}', 'updated': '${result!['updated_units'] ?? 0}', 'areas': '${result!['areas_set'] ?? 0}', 'errors': '${(result!['errors'] as List?)?.length ?? 0}'}))) ]))), actions: [HBButton.ghost(label: 'common.close'.tr(), onPressed: context.pop), HBButton.primary(label: 'admin.hunting.units.import_boundaries'.tr(), isLoading: saving, onPressed: collection == null || codeProperty == null || nameProperty == null ? null : _import)]); }
  Future<void> _import() async { setState(() => saving = true); try { final value = await ref.read(adminP44RepositoryProvider).importUnitAreas(regionId: widget.regionId, unitType: widget.unitType, featureCollection: collection!, codeProperty: codeProperty!, nameProperty: nameProperty!, source: source.text); if (mounted) setState(() => result = value); ref.invalidate(adminUnitBoundariesProvider); ref.invalidate(adminHuntingUnitsProvider); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
}

class LayerFeatureCollectionPreview extends StatelessWidget {
  final Map<String, dynamic> collection;
  const LayerFeatureCollectionPreview({super.key, required this.collection});
  @override Widget build(BuildContext context) { final features = OfficialLayerGeometry.fromJson(collection).features; final rings = features.expand((feature) => feature.rings).toList(); final points = rings.expand((ring) => ring).toList(); final center = points.isEmpty ? const LatLng(42.5, 12.5) : LatLng(points.map((point) => point.latitude).reduce((a, b) => a + b) / points.length, points.map((point) => point.longitude).reduce((a, b) => a + b) / points.length); return Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 260, child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 8), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), PolygonLayer(polygons: [for (final ring in rings) Polygon(points: ring, color: LightModeColors.lightPrimary.withValues(alpha: 0.16), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 2)])])))); }
}