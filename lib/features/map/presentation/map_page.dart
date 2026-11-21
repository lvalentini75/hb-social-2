import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart' hide MapEvent;
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/events/data/photon_place_service.dart';
import 'package:hb_social/features/events/presentation/event_map.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/map/domain/map_models.dart';
import 'package:hb_social/features/map/domain/map_geometry.dart';
import 'package:hb_social/features/map/providers/map_providers.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:hb_social/features/sightings/domain/sighting_alert.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeago/timeago.dart' as timeago;

class MapPage extends ConsumerStatefulWidget {
  final double? initialLat; final double? initialLng;
  const MapPage({super.key, this.initialLat, this.initialLng});
  @override
  ConsumerState<MapPage> createState() => _MapPageState();
}

class _MapPageState extends ConsumerState<MapPage> {
  final MapController _controller = MapController();
  final TextEditingController _search = TextEditingController();
  final PhotonPlaceService _places = PhotonPlaceService();
  Timer? _viewportTimer;
  late final LatLng _initialCenter;
  late final double _initialZoom;
  bool _mapInitialized = false;
  LatLng? _myLocation;
  LatLng? _editingAt;
  MapPoint? _editingPoint;
  List<LatLng>? _drawingVertices;
  MapZone? _editingZone;

  bool get _wide => MediaQuery.sizeOf(context).width >= 900;

  @override
  void initState() {
    super.initState();
    final hunting = ref.read(huntingContextProvider);
    _initialCenter = widget.initialLat != null && widget.initialLng != null ? LatLng(widget.initialLat!, widget.initialLng!) : hunting.lat != null && hunting.lng != null ? LatLng(hunting.lat!, hunting.lng!) : const LatLng(42.5, 12.5);
    _initialZoom = _initialCenter.latitude == 42.5 && _initialCenter.longitude == 12.5 ? 6 : 13;
  }

  @override
  void dispose() { _viewportTimer?.cancel(); _search.dispose(); super.dispose(); }

  void _positionChanged(MapCamera camera, bool hasGesture) {
    _viewportTimer?.cancel();
    _viewportTimer = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      final bounds = camera.visibleBounds;
      final distance = const Distance().as(LengthUnit.Kilometer, bounds.northWest, bounds.southEast) / 2;
      ref.read(mapViewportProvider.notifier).state = MapViewport(center: camera.center, zoom: camera.zoom, radiusKm: distance.clamp(2, 300));
    });
  }

  Future<void> _initializeMap() async {
    if (_mapInitialized) return;
    _mapInitialized = true;
    ref.read(mapViewportProvider.notifier).state = MapViewport(center: _initialCenter, zoom: _initialZoom, radiusKm: _initialZoom <= 6 ? 300 : 25);
    // A delayed no-op move makes flutter_map recalculate tiles after an
    // IndexedStack branch becomes visible on desktop.
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;
    _controller.move(_initialCenter, _initialZoom);
    if (widget.initialLat == null && widget.initialLng == null) await _findMe(showErrors: false, redirectToLogin: false);
  }

  Future<void> _findMe({bool showErrors = true, bool redirectToLogin = true}) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { if (mounted && redirectToLogin) context.push(AppRoutes.login); return; }
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('map.location_denied');
      final position = await Geolocator.getCurrentPosition();
      final point = LatLng(position.latitude, position.longitude);
      if (mounted) setState(() => _myLocation = point);
      _controller.move(point, 14);
    } on AppException catch (error) { if (showErrors) _message(error.messageKey); } catch (_) { if (showErrors) _message('map.location_denied'); }
  }

  void _message(String key, {Map<String, String> args = const {}}) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr(namedArgs: args)))); }

  Future<void> _longPress(LatLng point) async {
    final action = await showModalBottomSheet<String>(context: context, showDragHandle: true, builder: (sheet) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ListTile(leading: const Icon(Icons.add_location_alt_outlined), title: Text('map.actions.add_here'.tr()), onTap: () => sheet.pop('add')),
      ListTile(leading: const Icon(Icons.visibility_outlined), title: Text('p30b.map.report_here'.tr()), onTap: () => sheet.pop('sighting')),
      ListTile(leading: const Icon(Icons.notifications_active_outlined), title: Text('sighting_alerts.create_here'.tr()), onTap: () => sheet.pop('alert')),
      ListTile(leading: const Icon(Icons.polyline_outlined), title: Text('map.actions.draw_zone'.tr()), onTap: () => sheet.pop('zone')),
      ListTile(leading: const Icon(Icons.travel_explore_outlined), title: Text('map.actions.which_unit'.tr()), onTap: () => sheet.pop('unit')),
      ListTile(leading: const Icon(Icons.directions_outlined), title: Text('map.actions.directions'.tr()), onTap: () => sheet.pop('directions')),
      ListTile(leading: const Icon(Icons.copy_rounded), title: Text('map.actions.copy_coordinates'.tr()), onTap: () => sheet.pop('copy')),
    ])));
    if (!mounted || action == null) return;
    if (action == 'add') { if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; } _openForm(point); }
    if (action == 'sighting') { if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; } ref.read(sightingFormPrefillProvider.notifier).state = SightingFormPrefill(lat: point.latitude, lng: point.longitude); context.push(AppRoutes.sightingsNew); }
    if (action == 'alert') { if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; } ref.read(sightingAlertPrefillProvider.notifier).state = SightingAlertPrefill(lat: point.latitude, lng: point.longitude); context.push('${AppRoutes.sightingAlerts}?create=1'); }
    if (action == 'zone') _startDrawing([point]);
    if (action == 'unit') { try { final unit = await ref.read(mapRepositoryProvider).unitAt(point.latitude, point.longitude); _message(unit == null ? 'map.no_unit' : 'map.unit_found', args: {'name': unit?.name ?? ''}); } on AppException catch (error) { _message(error.messageKey); } }
    if (action == 'directions') await _directions(point);
    if (action == 'copy') { await Clipboard.setData(ClipboardData(text: '${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}')); _message('map.coordinates_copied'); }
  }

  void _startDrawing([List<LatLng> vertices = const [], MapZone? zone]) {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    setState(() { _drawingVertices = [...vertices]; _editingZone = zone; _editingAt = null; _editingPoint = null; });
    if (vertices.isNotEmpty) _controller.move(vertices.first, _controller.camera.zoom < 13 ? 13 : _controller.camera.zoom);
  }

  void _moveVertex(int index, DragUpdateDetails details) {
    final points = _drawingVertices;
    if (points == null) return;
    final scale = 360 / (256 * (1 << _controller.camera.zoom.round()));
    final current = points[index];
    setState(() => points[index] = LatLng((current.latitude - details.delta.dy * scale).clamp(-90, 90), (current.longitude + details.delta.dx * scale).clamp(-180, 180)));
  }

  Future<void> _saveDrawing() async {
    final points = _drawingVertices;
    if (points == null || points.length < 3) return;
    final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: 0.88, child: MapZoneForm(vertices: points, existing: _editingZone)));
    if (saved == true && mounted) { setState(() { _drawingVertices = null; _editingZone = null; }); forceMapRefresh(ref); _message('map.zone_saved'); }
  }

  Future<void> _directions(LatLng point) => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}'), mode: LaunchMode.externalApplication);

  void _openForm(LatLng point, [MapPoint? existing]) {
    if (_wide) { setState(() { _editingAt = point; _editingPoint = existing; }); return; }
    showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: 0.92, child: MapPointForm(point: point, existing: existing, onSaved: _pointSaved, onDeleted: _pointDeleted)));
  }

  void _pointSaved(String id) { setState(() { _editingAt = null; _editingPoint = null; }); forceMapRefresh(ref); if (!_wide && context.canPop()) context.pop(); _message('map.point_saved'); }
  void _pointDeleted() { setState(() { _editingAt = null; _editingPoint = null; }); ref.read(selectedMapItemProvider.notifier).state = null; forceMapRefresh(ref); if (!_wide && context.canPop()) context.pop(); _message('map.point_deleted'); }

  void _select(Object item, LatLng position) {
    ref.read(selectedMapItemProvider.notifier).state = item;
    _controller.move(position, _controller.camera.zoom < 13 ? 13 : _controller.camera.zoom);
    if (!_wide) showModalBottomSheet<void>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => MapItemDetail(item: item, overview: ref.read(mapOverviewProvider).value, onEdit: item is MapPoint && item is! SharedPoint ? () { context.pop(); _openForm(item.position, item); } : item is MapZone ? () { context.pop(); _openZoneData(item); } : null, onEditVertices: item is MapZone && item is! SharedZone ? () { context.pop(); _startDrawing(item.rings.firstOrNull ?? const [], item); } : null, onDelete: item is MapPoint && item is! SharedPoint ? () => _delete(item) : item is MapZone && item is! SharedZone ? () => _deleteZone(item) : null, onCenter: item is MapZone ? () { context.pop(); _controller.move(item.center, 13); } : null));
  }

  Future<void> _openZoneData(MapZone zone) async { final saved = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: 0.88, child: MapZoneForm(vertices: zone.rings.firstOrNull ?? const [], existing: zone))); if (saved == true && mounted) { forceMapRefresh(ref); _message('map.zone_saved'); } }

  Future<void> _deleteZone(MapZone zone) async {
    final confirm = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('map.zone_delete_title'.tr()), content: Text('map.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.secondary(label: 'diary.actions.delete'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirm) return;
    try { await ref.read(mapRepositoryProvider).deleteZone(zone.id); ref.read(selectedMapItemProvider.notifier).state = null; forceMapRefresh(ref); if (!_wide && mounted && context.canPop()) context.pop(); _message('map.zone_deleted'); } on AppException catch (error) { _message(error.messageKey); }
  }

  Future<void> _delete(MapPoint point) async {
    final confirm = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('map.delete_title'.tr()), content: Text('map.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.secondary(label: 'diary.actions.delete'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirm) return;
    try { await ref.read(mapRepositoryProvider).deletePoint(point.id); _pointDeleted(); } on AppException catch (error) { _message(error.messageKey); }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(mapOverviewProvider);
    final layers = ref.watch(mapLayersProvider);
    final selected = ref.watch(selectedMapItemProvider);
    final zoom = ref.watch(mapViewportProvider.select((value) => value.zoom));
    final sightingMarkers = ref.watch(mapSightingsProvider).value ?? const <NearbySighting>[];
    final heatCells = ref.watch(mapSightingsHeatProvider).value ?? const <SightingHeatCell>[];
    final officialIds = ref.watch(officialMapLayerIdsProvider);
    final officialLayers = (overview.value?.layers ?? const <OfficialMapLayer>[]).where((layer) => officialIds.contains(layer.id)).toList();
    final maxHeat = heatCells.fold<int>(1, (value, cell) => cell.sightings > value ? cell.sightings : value);
    final map = Stack(children: [
      FlutterMap(mapController: _controller, options: MapOptions(initialCenter: _initialCenter, initialZoom: _initialZoom, onMapReady: _initializeMap, onPositionChanged: _positionChanged, onTap: _drawingVertices == null ? null : (_, point) => setState(() => _drawingVertices!.add(point)), onLongPress: _drawingVertices == null ? (_, point) => _longPress(point) : null), children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'),
        for (final layer in officialLayers) ref.watch(officialMapLayerGeometryProvider(layer)).maybeWhen(data: (geometry) => PolygonLayer(polygons: [for (final feature in geometry.features) for (final ring in feature.rings) Polygon(points: ring, color: mapStoredColor(layer.color).withValues(alpha: 0.16), borderColor: mapStoredColor(layer.color), borderStrokeWidth: 2, label: zoom >= 12 ? feature.name : null, labelStyle: context.textStyles.labelSmall ?? const TextStyle())]), orElse: () => const SizedBox.shrink()),
        for (final layer in officialLayers) ref.watch(officialMapLayerGeometryProvider(layer)).maybeWhen(data: (geometry) => MarkerLayer(markers: [for (final feature in geometry.features) if (feature.rings.expand((ring) => ring).firstOrNull != null) Marker(point: feature.rings.expand((ring) => ring).first, width: 80, height: 80, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _select(OfficialFeatureSelection(layer, feature), feature.rings.expand((ring) => ring).first), child: const SizedBox.expand()))]), orElse: () => const SizedBox.shrink()),
        if (layers.units) PolygonLayer(polygons: [for (final unit in overview.value?.units ?? const <UnitArea>[]) for (final ring in unit.rings) Polygon(points: ring, color: LightModeColors.lightPrimary.withValues(alpha: 0.10), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 1.5, label: zoom >= 11 ? unit.name : null, labelStyle: context.textStyles.labelSmall?.copyWith(color: LightModeColors.lightForest) ?? const TextStyle())]),
        if (layers.sharedZones) PolygonLayer(polygons: [for (final zone in overview.value?.sharedZones ?? const <SharedZone>[]) for (final ring in zone.rings.take(1)) Polygon(points: ring, color: mapStoredColor(zone.color).withValues(alpha: 0.08), borderColor: mapStoredColor(zone.color), borderStrokeWidth: 2)]),
        if (layers.myZones) PolygonLayer(polygons: [for (final zone in overview.value?.myZones ?? const <MapZone>[]) for (final ring in zone.rings.take(1)) Polygon(points: ring, color: mapStoredColor(zone.color).withValues(alpha: 0.18), borderColor: mapStoredColor(zone.color), borderStrokeWidth: 2)]),
        if (_drawingVertices != null && _drawingVertices!.length >= 2) PolygonLayer(polygons: [Polygon(points: _drawingVertices!, color: LightModeColors.lightPrimary.withValues(alpha: 0.18), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 2)]),
        if (_drawingVertices != null) MarkerLayer(markers: [for (var index = 0; index < _drawingVertices!.length; index++) Marker(point: _drawingVertices![index], width: 30, height: 30, child: GestureDetector(onPanUpdate: (details) => _moveVertex(index, details), onTap: () async { final remove = await showModalBottomSheet<bool>(context: context, builder: (sheet) => SafeArea(child: ListTile(leading: const Icon(Icons.remove_circle_outline), title: Text('map.drawing.remove_vertex'.tr()), onTap: () => sheet.pop(true)))); if (remove == true && mounted) setState(() => _drawingVertices!.removeAt(index)); }, child: Container(decoration: const BoxDecoration(color: LightModeColors.lightSurface, shape: BoxShape.circle, boxShadow: AppShadows.level1), child: const Icon(Icons.circle, size: 14, color: LightModeColors.lightPrimary))))]),
        if (layers.sightings && layers.sightingsHeat) CircleLayer(circles: [for (final cell in heatCells) CircleMarker(point: LatLng(cell.lat, cell.lng), radius: 600, useRadiusInMeter: true, color: LightModeColors.lightPrimary.withValues(alpha: _heatOpacity(cell.sightings, maxHeat)), borderStrokeWidth: 0)]),
        if (layers.sightings && layers.sightingsHeat) MarkerLayer(markers: [for (final cell in heatCells) Marker(point: LatLng(cell.lat, cell.lng), width: 80, height: 80, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => _select(cell, LatLng(cell.lat, cell.lng)), child: const SizedBox.expand()))]),
        if (layers.myPoints) MarkerLayer(markers: [for (final point in overview.value?.myPoints ?? const <MapPoint>[]) MapMarkerFactory.point(point, zoom: zoom, onTap: () => _select(point, point.position))]),
        if (layers.units) MarkerLayer(markers: [for (final unit in overview.value?.units ?? const <UnitArea>[]) if (unit.center != null) Marker(point: unit.center!, width: 120, height: 34, child: GestureDetector(onTap: () => _select(unit, unit.center!), child: zoom >= 11 ? DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightSurface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(AppRadius.sm)), child: Center(child: Text(unit.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall))) : const SizedBox.shrink()))]),
        if (layers.outings) MarkerLayer(markers: [for (final outing in overview.value?.outings ?? const <MapOuting>[]) MapMarkerFactory.outing(context, outing, () => _select(outing, outing.position))]),
        if (layers.events) MarkerLayer(markers: [for (final event in overview.value?.events ?? const <MapEvent>[]) MapMarkerFactory.event(context, event, () => _select(event, event.position))]),
        if (layers.sharedPoints) MarkerClusterLayerWidget(options: MarkerClusterLayerOptions(maxClusterRadius: 50, size: const Size(44, 44), markers: [for (final point in overview.value?.sharedPoints ?? const <SharedPoint>[]) MapMarkerFactory.shared(point, () => _select(point, point.position))], builder: (_, markers) => MapClusterBadge(count: markers.length))),
        if (layers.posts) MarkerClusterLayerWidget(options: MarkerClusterLayerOptions(maxClusterRadius: 50, size: const Size(44, 44), markers: [for (final post in overview.value?.posts ?? const <MapPost>[]) MapMarkerFactory.post(post, () => _select(post, post.position))], builder: (_, markers) => MapClusterBadge(count: markers.length))),
        if (layers.sightings && layers.sightingsMarkers && zoom >= 9) MarkerClusterLayerWidget(options: MarkerClusterLayerOptions(maxClusterRadius: sightingMarkers.length > 40 ? 50 : 1, size: const Size(44, 44), markers: [for (final sighting in sightingMarkers) MapMarkerFactory.sighting(sighting, () => _select(sighting, LatLng(sighting.lat!, sighting.lng!)))], builder: (_, markers) => MapClusterBadge(count: markers.length))),
        MarkerLayer(markers: [if (layers.myZones) for (final zone in overview.value?.myZones ?? const <MapZone>[]) Marker(point: zone.center, width: 120, height: 34, child: GestureDetector(onTap: () => _select(zone, zone.center), child: MapZoneLabel(name: zone.name))), if (layers.sharedZones) for (final zone in overview.value?.sharedZones ?? const <SharedZone>[]) Marker(point: zone.center, width: 120, height: 34, child: GestureDetector(onTap: () => _select(zone, zone.center), child: MapZoneLabel(name: zone.name)))]),
        if (_myLocation != null) MarkerLayer(markers: [Marker(point: _myLocation!, width: 28, height: 28, child: const Icon(Icons.my_location_rounded, color: LightModeColors.lightInfo, size: 26))]),
        RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () => launchUrl(Uri.parse('https://www.openstreetmap.org/copyright')))]),
      ]),
      Positioned(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.md,
        child: Align(
          alignment: Alignment.topLeft,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: HBCard(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: HBPlaceField<PhotonPlace>(
                controller: _search,
                hint: 'map.search_hint'.tr(),
                search: (query) async => [for (final place in await _places.search(query, language: context.locale.languageCode)) HBPlaceSuggestion(value: place, title: place.name, subtitle: place.address)],
                onSelected: (place) => _controller.move(LatLng(place.latitude, place.longitude), 13),
              ),
            ),
          ),
        ),
      ),
      if (overview.isLoading) Positioned(top: 86, left: AppSpacing.md, child: HBStatusChip(kind: HBStatusKind.info, label: 'map.loading'.tr())),
      if (_drawingVertices != null) Positioned(left: AppSpacing.md, right: AppSpacing.md, top: AppSpacing.md, child: Align(alignment: Alignment.topCenter, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 700), child: MapDrawingBar(vertices: _drawingVertices!, onCancel: () => setState(() { _drawingVertices = null; _editingZone = null; }), onUndo: _drawingVertices!.isEmpty ? null : () => setState(() => _drawingVertices!.removeLast()), onSave: _drawingVertices!.length < 3 ? null : _saveDrawing)))),
      if (_drawingVertices == null) Positioned(right: AppSpacing.md, bottom: AppSpacing.xxl, child: Column(children: [HBButton.icon(icon: Icons.polyline_outlined, backgroundColor: LightModeColors.lightSurface, onPressed: _startDrawing), const SizedBox(height: AppSpacing.sm), HBButton.icon(icon: Icons.add_rounded, backgroundColor: LightModeColors.lightSurface, onPressed: () => _controller.move(_controller.camera.center, (_controller.camera.zoom + 1).clamp(3, 18))), const SizedBox(height: 6), HBButton.icon(icon: Icons.remove_rounded, backgroundColor: LightModeColors.lightSurface, onPressed: () => _controller.move(_controller.camera.center, (_controller.camera.zoom - 1).clamp(3, 18))), const SizedBox(height: AppSpacing.sm), HBButton.icon(icon: Icons.my_location_rounded, backgroundColor: LightModeColors.lightSurface, onPressed: () => _findMe()), const SizedBox(height: AppSpacing.sm), HBButton.icon(icon: Icons.layers_outlined, backgroundColor: LightModeColors.lightSurface, onPressed: () => showModalBottomSheet<void>(context: context, showDragHandle: true, builder: (_) => MapLayersSheet(overview: overview.value)))])),
      if (overview.hasError) Positioned(left: AppSpacing.md, bottom: AppSpacing.md, child: HBButton.secondary(label: 'common.retry'.tr(), icon: Icons.refresh_rounded, onPressed: () => forceMapRefresh(ref))),
      if (layers.sightings && layers.sightingsHeat && heatCells.isNotEmpty) Positioned(left: AppSpacing.md, bottom: AppSpacing.md, child: MapHeatLegend()),
    ]);
    if (_wide) {
      final panel = _editingAt != null
          ? MapPointForm(point: _editingAt!, existing: _editingPoint, onSaved: _pointSaved, onDeleted: _pointDeleted, onCancel: () => setState(() => _editingAt = null))
          : selected != null
              ? MapItemDetail(item: selected, overview: overview.value, onEdit: selected is MapPoint && selected is! SharedPoint ? () => _openForm(selected.position, selected) : selected is MapZone && selected is! SharedZone ? () => _openZoneData(selected) : null, onEditVertices: selected is MapZone && selected is! SharedZone ? () => _startDrawing(selected.rings.firstOrNull ?? const [], selected) : null, onDelete: selected is MapPoint && selected is! SharedPoint ? () => _delete(selected) : selected is MapZone && selected is! SharedZone ? () => _deleteZone(selected) : null, onCenter: selected is MapZone ? () => _controller.move(selected.center, 13) : null)
              : MapAssetsPanel(overview: overview.value, onAddPoint: () => _openForm(_controller.camera.center), onAddZone: _startDrawing, onPointSelected: (point) => _select(point, point.position), onZoneSelected: (zone) => _select(zone, zone.center));
      return Row(children: [Expanded(child: map), SizedBox(width: 360, child: ColoredBox(color: LightModeColors.lightSurface, child: panel))]);
    }
    return Stack(children: [map, if (_drawingVertices == null) Positioned(left: AppSpacing.md, bottom: AppSpacing.md, child: HBButton.primary(label: 'map.saved_items'.tr(namedArgs: {'n': '${(overview.value?.myPoints.length ?? 0) + (overview.value?.myZones.length ?? 0)}'}), icon: Icons.bookmarks_outlined, onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => FractionallySizedBox(heightFactor: 0.75, child: MapAssetsPanel(overview: overview.value, onAddPoint: () { context.pop(); _openForm(_controller.camera.center); }, onAddZone: () { context.pop(); _startDrawing(); }, onPointSelected: (point) { context.pop(); _select(point, point.position); }, onZoneSelected: (zone) { context.pop(); _select(zone, zone.center); }))))) ]);
  }
}

double _heatOpacity(int value, int maximum) { final level = (value / maximum * 5).ceil().clamp(1, 5); return 0.05 + level * 0.12; }

class MapMarkerFactory {
  static Marker point(MapPoint point, {required double zoom, required VoidCallback onTap}) => Marker(point: point.position, width: zoom >= 14 ? 150 : 48, height: 52, child: GestureDetector(onTap: onTap, child: Row(mainAxisSize: MainAxisSize.min, children: [MapPin(icon: point.kind.icon, color: mapStoredColor(point.color)), if (zoom >= 14) Flexible(child: DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightSurface, borderRadius: BorderRadius.circular(AppRadius.sm), boxShadow: AppShadows.level1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3), child: Text(point.name, overflow: TextOverflow.ellipsis))))])));
  static Marker shared(SharedPoint point, VoidCallback onTap) => Marker(point: point.position, width: 52, height: 52, child: GestureDetector(onTap: onTap, child: Stack(children: [MapPin(icon: point.kind.icon, color: mapStoredColor(point.color)), Positioned(right: 0, bottom: 0, child: HBAvatar(name: point.owner.displayName, imageUrl: point.owner.avatarUrl, size: 20))])));
  static Marker outing(BuildContext context, MapOuting outing, VoidCallback onTap) => Marker(point: outing.position, width: 54, height: 54, child: GestureDetector(onTap: onTap, child: Transform.rotate(angle: 0.785, child: DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightWarning, borderRadius: BorderRadius.circular(8), boxShadow: AppShadows.level1), child: Center(child: Transform.rotate(angle: -0.785, child: Text(DateFormat.Md(context.locale.languageCode).format(outing.startedAt.toLocal()), style: const TextStyle(fontSize: 12, color: LightModeColors.lightOnPrimary, fontWeight: FontWeight.w700))))))));
  static Marker event(BuildContext context, MapEvent event, VoidCallback onTap) => Marker(point: event.position, width: 52, height: 52, child: GestureDetector(onTap: onTap, child: MapPin(icon: Icons.calendar_month_outlined, color: LightModeColors.lightError, label: '${event.startsAt.toLocal().day}')));
  static Marker post(MapPost post, VoidCallback onTap) => Marker(point: post.position, width: 48, height: 48, child: GestureDetector(onTap: onTap, child: HBAvatar(name: post.author.displayName, imageUrl: post.author.avatarUrl, size: 42)));
  static Marker sighting(NearbySighting item, VoidCallback onTap) => Marker(point: LatLng(item.lat!, item.lng!), width: 48, height: 48, child: GestureDetector(onTap: onTap, child: Container(decoration: BoxDecoration(color: LightModeColors.lightSurface, shape: BoxShape.circle, border: Border.all(color: item.isMine ? LightModeColors.lightPrimary : LightModeColors.lightOnSurfaceVariant, width: 2), boxShadow: AppShadows.level1), child: Stack(alignment: Alignment.center, children: [Icon(item.kind.icon, color: LightModeColors.lightPrimary), Positioned(right: 2, bottom: 1, child: Text('${item.animalsCount}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))) ]))));
}

class MapHeatLegend extends StatelessWidget { const MapHeatLegend({super.key}); @override Widget build(BuildContext context) => HBCard(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Row(mainAxisSize: MainAxisSize.min, children: [Text('p30b.map.less'.tr()), for (final alpha in const [0.15, 0.27, 0.39, 0.51, 0.65]) Padding(padding: const EdgeInsets.symmetric(horizontal: 2), child: Icon(Icons.circle, size: 12, color: LightModeColors.lightPrimary.withValues(alpha: alpha))), Text('p30b.map.more'.tr())])); }

class MapPin extends StatelessWidget {
  final IconData icon; final Color color; final String? label;
  const MapPin({super.key, required this.icon, required this.color, this.label});
  @override
  Widget build(BuildContext context) => Container(width: 42, height: 42, decoration: BoxDecoration(color: color, shape: BoxShape.circle, boxShadow: AppShadows.level2), child: Center(child: label == null ? Icon(icon, color: LightModeColors.lightOnPrimary, size: 22) : Text(label!, style: const TextStyle(color: LightModeColors.lightOnPrimary, fontWeight: FontWeight.w700))));
}

class MapClusterBadge extends StatelessWidget {
  final int count; const MapClusterBadge({super.key, required this.count});
  @override
  Widget build(BuildContext context) => Container(decoration: const BoxDecoration(color: LightModeColors.lightForest, shape: BoxShape.circle, boxShadow: AppShadows.level2), alignment: Alignment.center, child: Text('$count', style: const TextStyle(color: LightModeColors.lightOnPrimary, fontWeight: FontWeight.w700)));
}

class MapZoneLabel extends StatelessWidget {
  final String name;
  const MapZoneLabel({super.key, required this.name});
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightSurface.withValues(alpha: 0.92), borderRadius: BorderRadius.circular(AppRadius.sm), boxShadow: AppShadows.level1), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), child: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.labelSmall)));
}

class MapDrawingBar extends StatelessWidget {
  final List<LatLng> vertices; final VoidCallback onCancel; final VoidCallback? onUndo; final VoidCallback? onSave;
  const MapDrawingBar({super.key, required this.vertices, required this.onCancel, this.onUndo, this.onSave});
  @override
  Widget build(BuildContext context) => HBCard(padding: const EdgeInsets.all(AppSpacing.sm), child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [Text('map.drawing.hint'.tr(namedArgs: {'n': '${vertices.length}'}), style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w700)), if (vertices.length >= 2) Text('map.drawing.measure'.tr(namedArgs: {'area': formatMapArea(MapGeometry.areaM2(vertices)), 'perimeter': formatMapDistance(MapGeometry.perimeterM(vertices))}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: onCancel, size: HBButtonSize.sm), HBButton.secondary(label: 'map.drawing.undo'.tr(), onPressed: onUndo, size: HBButtonSize.sm), HBButton.primary(label: 'common.save'.tr(), onPressed: onSave, size: HBButtonSize.sm)]));
}

class MapAssetsPanel extends StatefulWidget {
  final MapOverview? overview; final VoidCallback onAddPoint; final VoidCallback onAddZone; final ValueChanged<MapPoint> onPointSelected; final ValueChanged<MapZone> onZoneSelected;
  const MapAssetsPanel({super.key, required this.overview, required this.onAddPoint, required this.onAddZone, required this.onPointSelected, required this.onZoneSelected});
  @override State<MapAssetsPanel> createState() => _MapAssetsPanelState();
}
class _MapAssetsPanelState extends State<MapAssetsPanel> {
  int tab = 0;
  @override Widget build(BuildContext context) { final points = widget.overview?.myPoints ?? const <MapPoint>[]; final zones = widget.overview?.myZones ?? const <MapZone>[]; return Column(children: [Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.md, AppSpacing.md, 0), child: HBSegmentedTabs(labels: ['map.my_points'.tr(), 'map.my_zones'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value))), Expanded(child: tab == 0 ? MapMyPointsPanel(points: points, onAdd: widget.onAddPoint, onSelected: widget.onPointSelected) : MapMyZonesPanel(zones: zones, onAdd: widget.onAddZone, onSelected: widget.onZoneSelected))]); }
}

class MapMyZonesPanel extends StatelessWidget {
  final List<MapZone> zones; final VoidCallback onAdd; final ValueChanged<MapZone> onSelected;
  const MapMyZonesPanel({super.key, required this.zones, required this.onAdd, required this.onSelected});
  @override Widget build(BuildContext context) { final total = zones.fold<double>(0, (sum, zone) => sum + zone.areaM2); return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Row(children: [Expanded(child: Text('map.my_zones'.tr(), style: context.textStyles.titleLarge)), Text('${zones.length}/50')]), const SizedBox(height: AppSpacing.xs), Text('map.zones_total_area'.tr(namedArgs: {'area': formatMapArea(total)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'map.draw_zone'.tr(), icon: Icons.polyline_outlined, onPressed: onAdd), const SizedBox(height: AppSpacing.md), if (zones.isEmpty) HBEmptyState(icon: Icons.polyline_outlined, title: 'map.empty_zones'.tr(), message: 'map.empty_zones_message'.tr()) else for (final zone in zones) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(Icons.hexagon_outlined, color: mapStoredColor(zone.color)), title: Text(zone.name), subtitle: Text('${formatMapArea(zone.areaM2)} · ${zone.visibility.labelKey.tr()}'), onTap: () => onSelected(zone))]); }
}

class MapZoneForm extends ConsumerStatefulWidget {
  final List<LatLng> vertices; final MapZone? existing;
  const MapZoneForm({super.key, required this.vertices, this.existing});
  @override ConsumerState<MapZoneForm> createState() => _MapZoneFormState();
}
class _MapZoneFormState extends ConsumerState<MapZoneForm> {
  late final TextEditingController name = TextEditingController(text: widget.existing?.name);
  late final TextEditingController notes = TextEditingController(text: widget.existing?.notes);
  late MapPointVisibility visibility = widget.existing?.visibility ?? MapPointVisibility.private;
  late Color color = mapStoredColor(widget.existing?.color); bool saving = false;
  static const colors = [LightModeColors.lightPrimary, LightModeColors.lightInfo, LightModeColors.lightWarning, LightModeColors.lightError, LightModeColors.lightSecondary, LightModeColors.lightSuccess];
  @override void dispose() { name.dispose(); notes.dispose(); super.dispose(); }
  Future<void> save() async { setState(() => saving = true); try { await ref.read(mapRepositoryProvider).upsertZone(id: widget.existing?.id, name: name.text, ring: [for (final point in widget.vertices) [point.longitude, point.latitude]], notes: notes.text, color: mapColorHex(color), visibility: visibility); if (mounted) context.pop(true); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } finally { if (mounted) setState(() => saving = false); } }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [Text(widget.existing == null ? 'map.zone_form.create_title'.tr() : 'map.zone_form.edit_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.name'.tr(), required: true, child: HBInput(controller: name, maxLength: 60, onChanged: (_) => setState(() {}))), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.notes'.tr(), child: HBInput(controller: notes, maxLines: 4, maxLength: 500)), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.color'.tr(), child: Wrap(spacing: AppSpacing.sm, children: [for (final item in colors) GestureDetector(onTap: () => setState(() => color = item), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: item, shape: BoxShape.circle, border: color == item ? Border.all(color: LightModeColors.lightOnSurface, width: 2) : null)))])), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.visibility'.tr(), child: HBChoice<MapPointVisibility>(options: MapPointVisibility.values, value: visibility, onChanged: (value) => setState(() => visibility = value), labelBuilder: (value) => value.labelKey.tr(), descriptions: {for (final value in MapPointVisibility.values) value: value.descriptionKey.tr()})), HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: name.text.trim().isEmpty ? null : save, secondaryLabel: 'common.cancel'.tr(), onSecondary: context.pop, loading: saving)]);
}

class MapLayersSheet extends ConsumerWidget {
  final MapOverview? overview; const MapLayersSheet({super.key, this.overview});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(mapLayersProvider);
    void set(MapLayers next) => ref.read(mapLayersProvider.notifier).state = next;
    final rows = <(String, bool, int, ValueChanged<bool>)>[
      ('map.layers.my_points', value.myPoints, overview?.myPoints.length ?? 0, (v) => set(value.copyWith(myPoints: v))),
      ('map.layers.shared_points', value.sharedPoints, overview?.sharedPoints.length ?? 0, (v) => set(value.copyWith(sharedPoints: v))),
      ('map.layers.my_zones', value.myZones, overview?.myZones.length ?? 0, (v) => set(value.copyWith(myZones: v))),
      ('map.layers.shared_zones', value.sharedZones, overview?.sharedZones.length ?? 0, (v) => set(value.copyWith(sharedZones: v))),
      ('map.layers.outings', value.outings, overview?.outings.length ?? 0, (v) => set(value.copyWith(outings: v))),
      ('map.layers.units', value.units, overview?.units.length ?? 0, (v) => set(value.copyWith(units: v))),
      ('map.layers.posts', value.posts, overview?.posts.length ?? 0, (v) => set(value.copyWith(posts: v))),
      ('map.layers.events', value.events, overview?.events.length ?? 0, (v) => set(value.copyWith(events: v))),
      ('p30b.map.layer', value.sightings, 0, (v) => set(value.copyWith(sightings: v))),
    ];
    final species = ref.watch(speciesProvider).value ?? const <Species>[];
    final official = overview?.layers ?? const <OfficialMapLayer>[];
    final selectedOfficial = ref.watch(officialMapLayerIdsProvider);
    return SafeArea(child: SingleChildScrollView(child: Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('map.layers.title'.tr(), style: context.textStyles.titleLarge), if (official.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), Text('map.layers.official'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final layer in official) HBChip(label: '${layer.name} · ${'map.layers.kind.${layer.kind}'.tr()} · ${'map.layers.areas'.tr(namedArgs: {'n': '${layer.featureCount}'})}', selected: selectedOfficial.contains(layer.id), colorDot: mapStoredColor(layer.color), onTap: () { final next = {...selectedOfficial}; next.contains(layer.id) ? next.remove(layer.id) : next.add(layer.id); ref.read(officialMapLayerIdsProvider.notifier).state = next; })]), const Divider(height: AppSpacing.xl)], for (final row in rows) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text(row.$1.tr()), subtitle: row.$3 == 0 ? null : Text('${row.$3}'), value: row.$2, onChanged: row.$4), if (value.sightings) ...[SwitchListTile(contentPadding: const EdgeInsets.only(left: AppSpacing.md), title: Text('p30b.map.heat'.tr()), value: value.sightingsHeat, onChanged: (enabled) => set(value.copyWith(sightingsHeat: enabled))), SwitchListTile(contentPadding: const EdgeInsets.only(left: AppSpacing.md), title: Text('p30b.map.markers'.tr()), value: value.sightingsMarkers, onChanged: (enabled) => set(value.copyWith(sightingsMarkers: enabled))), HBSelect<String>(value: value.sightingsSpeciesId, allowClear: true, placeholder: 'sightings.filters.species'.tr(), options: [for (final item in species) HBSelectOption(value: item.id, label: item.localizedName)], onChanged: (speciesId) => set(value.copyWith(sightingsSpeciesId: speciesId, clearSightingsSpecies: speciesId == null))), const SizedBox(height: AppSpacing.sm), HBChoice<int>(options: const [7, 30, 90, 365], value: value.sightingsDays, onChanged: (days) => set(value.copyWith(sightingsDays: days)), labelBuilder: (days) => '$days')]]))));
  }
}

class MapMyPointsPanel extends StatefulWidget {
  final List<MapPoint> points; final VoidCallback onAdd; final ValueChanged<MapPoint> onSelected;
  const MapMyPointsPanel({super.key, required this.points, required this.onAdd, required this.onSelected});
  @override State<MapMyPointsPanel> createState() => _MapMyPointsPanelState();
}
class _MapMyPointsPanelState extends State<MapMyPointsPanel> {
  final _search = TextEditingController(); String _query = '';
  @override void dispose() { _search.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final points = widget.points.where((item) => item.name.toLowerCase().contains(_query.toLowerCase())).toList();
    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Row(children: [Expanded(child: Text('map.my_points'.tr(), style: context.textStyles.titleLarge)), Text('${widget.points.length}/200')]), const SizedBox(height: AppSpacing.md), HBInput(controller: _search, hint: 'map.search_points'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: (value) => setState(() => _query = value)), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'map.add_point'.tr(), icon: Icons.add_location_alt_outlined, onPressed: widget.onAdd), const SizedBox(height: AppSpacing.md), if (points.isEmpty) HBEmptyState(icon: Icons.bookmark_border_rounded, title: 'map.empty_points'.tr(), message: 'map.empty_points_message'.tr()) else for (final kind in MapPointKind.values) if (points.any((point) => point.kind == kind)) ...[Padding(padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs), child: Text(kind.labelKey.tr(), style: context.textStyles.labelMedium?.copyWith(color: LightModeColors.lightOnSurfaceVariant))), for (final point in points.where((point) => point.kind == kind)) ListTile(contentPadding: EdgeInsets.zero, leading: Icon(point.kind.icon, color: mapStoredColor(point.color)), title: Text(point.name), subtitle: Text(point.visibility.labelKey.tr()), onTap: () => widget.onSelected(point))]]);
  }
}

class MapPointForm extends ConsumerStatefulWidget {
  final LatLng point; final MapPoint? existing; final ValueChanged<String> onSaved; final VoidCallback onDeleted; final VoidCallback? onCancel;
  const MapPointForm({super.key, required this.point, this.existing, required this.onSaved, required this.onDeleted, this.onCancel});
  @override ConsumerState<MapPointForm> createState() => _MapPointFormState();
}
class _MapPointFormState extends ConsumerState<MapPointForm> {
  late final TextEditingController _name = TextEditingController(text: widget.existing?.name);
  late final TextEditingController _notes = TextEditingController(text: widget.existing?.notes);
  late LatLng _point = widget.point;
  late MapPointKind _kind = widget.existing?.kind ?? MapPointKind.altro;
  late MapPointVisibility _visibility = widget.existing?.visibility ?? MapPointVisibility.private;
  late Color _color = mapStoredColor(widget.existing?.color);
  bool _saving = false;
  static const colors = [LightModeColors.lightPrimary, LightModeColors.lightInfo, LightModeColors.lightWarning, LightModeColors.lightError, LightModeColors.lightSecondary, LightModeColors.lightSuccess];
  @override void dispose() { _name.dispose(); _notes.dispose(); super.dispose(); }
  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = await ref.read(mapRepositoryProvider).upsertPoint(id: widget.existing?.id, name: _name.text, kind: _kind, lat: _point.latitude, lng: _point.longitude, notes: _notes.text, color: mapColorHex(_color), visibility: _visibility);
      ref.read(selectedMapItemProvider.notifier).state = MapPoint(id: id, name: _name.text.trim(), kind: _kind, lat: _point.latitude, lng: _point.longitude, notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(), color: mapColorHex(_color), visibility: _visibility, huntingUnitId: widget.existing?.huntingUnitId);
      widget.onSaved(id);
    }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => _saving = false); }
  }
  Future<void> _delete() async {
    if (widget.existing == null) return;
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('map.delete_title'.tr()), content: Text('map.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.secondary(label: 'diary.actions.delete'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(mapRepositoryProvider).deletePoint(widget.existing!.id); widget.onDeleted(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  @override Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Text(widget.existing == null ? 'map.form.create_title'.tr() : 'map.form.edit_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.name'.tr(), required: true, child: HBInput(controller: _name, maxLength: 60, onChanged: (_) => setState(() {}))), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.kind'.tr(), child: Wrap(spacing: 6, runSpacing: 6, children: [for (final kind in MapPointKind.values) ChoiceChip(avatar: Icon(kind.icon, size: 18), label: Text(kind.labelKey.tr()), selected: _kind == kind, onSelected: (_) => setState(() => _kind = kind))])), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.position'.tr(), child: Column(children: [EventMap(latitude: _point.latitude, longitude: _point.longitude, editable: true, height: 180, onChanged: (value) => setState(() => _point = value)), const SizedBox(height: 6), Text('${_point.latitude.toStringAsFixed(6)}, ${_point.longitude.toStringAsFixed(6)}')])) , const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.notes'.tr(), child: HBInput(controller: _notes, maxLines: 4, maxLength: 500)), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.color'.tr(), child: Wrap(spacing: AppSpacing.sm, children: [for (final color in colors) GestureDetector(onTap: () => setState(() => _color = color), child: Container(width: 34, height: 34, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: _color == color ? Border.all(color: LightModeColors.lightOnSurface, width: 2) : null)))])), const SizedBox(height: AppSpacing.md), HBFormField(label: 'map.form.visibility'.tr(), child: HBChoice<MapPointVisibility>(options: MapPointVisibility.values, value: _visibility, onChanged: (value) => setState(() => _visibility = value), labelBuilder: (value) => value.labelKey.tr(), descriptions: {for (final value in MapPointVisibility.values) value: value.descriptionKey.tr()})), HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _name.text.trim().isEmpty ? null : _save, secondaryLabel: widget.onCancel == null ? null : 'common.cancel'.tr(), onSecondary: widget.onCancel, loading: _saving), if (widget.existing != null) ...[const SizedBox(height: AppSpacing.md), HBButton.ghost(label: 'diary.actions.delete'.tr(), icon: Icons.delete_outline_rounded, onPressed: _delete)]]);
}

class MapItemDetail extends ConsumerWidget {
  final Object item; final MapOverview? overview; final VoidCallback? onEdit; final VoidCallback? onEditVertices; final VoidCallback? onDelete; final VoidCallback? onCenter;
  const MapItemDetail({super.key, required this.item, this.overview, this.onEdit, this.onEditVertices, this.onDelete, this.onCenter});
  @override Widget build(BuildContext context, WidgetRef ref) {
    String title; IconData icon; List<Widget> rows = []; List<Widget> actions = [];
    if (item is SharedZone) { final zone = item as SharedZone; title = zone.name; icon = Icons.hexagon_outlined; rows = [ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: zone.owner.displayName, size: 42), title: Text(zone.owner.displayName), subtitle: Text('@${zone.owner.username}'), onTap: () => context.push(AppRoutes.publicProfilePath(zone.owner.username))), MapDetailRow(label: 'map.area_label'.tr(), value: formatMapArea(zone.areaM2)), Align(alignment: Alignment.centerLeft, child: HBStatusChip(kind: zone.visibility == MapPointVisibility.public ? HBStatusKind.approved : HBStatusKind.info, label: zone.visibility.labelKey.tr()))]; actions = [HBButton.secondary(label: 'map.center'.tr(), icon: Icons.center_focus_strong, onPressed: onCenter)]; }
    else if (item is MapZone) { final zone = item as MapZone; title = zone.name; icon = Icons.hexagon_outlined; final ring = zone.rings.firstOrNull ?? const <LatLng>[]; final pointCount = overview?.myPoints.where((point) => MapGeometry.contains(ring, point.position)).length ?? 0; final outingCount = overview?.outings.where((outing) => MapGeometry.contains(ring, outing.position)).length ?? 0; rows = [MapDetailRow(label: 'map.area_label'.tr(), value: formatMapArea(zone.areaM2)), Align(alignment: Alignment.centerLeft, child: HBStatusChip(kind: zone.visibility == MapPointVisibility.private ? HBStatusKind.neutral : zone.visibility == MapPointVisibility.friends ? HBStatusKind.info : HBStatusKind.approved, label: zone.visibility.labelKey.tr())), if (zone.notes?.isNotEmpty == true) MapDetailRow(label: 'map.form.notes'.tr(), value: zone.notes!), Text('map.zone_contents'.tr(namedArgs: {'points': '$pointCount', 'outings': '$outingCount'}), style: context.textStyles.bodyMedium)]; actions = [HBButton.secondary(label: 'map.edit_vertices'.tr(), icon: Icons.polyline_outlined, onPressed: onEditVertices), HBButton.secondary(label: 'map.edit_data'.tr(), icon: Icons.edit_outlined, onPressed: onEdit), HBButton.secondary(label: 'map.center'.tr(), icon: Icons.center_focus_strong, onPressed: onCenter), HBButton.ghost(label: 'diary.actions.delete'.tr(), icon: Icons.delete_outline, onPressed: onDelete)]; }
    else if (item is SharedPoint) { final point = item as SharedPoint; title = point.name; icon = point.kind.icon; rows = [ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: point.owner.displayName, imageUrl: point.owner.avatarUrl, size: 42), title: Text(point.owner.displayName), subtitle: Text('@${point.owner.username}'), onTap: () => context.push(AppRoutes.publicProfilePath(point.owner.username))), Align(alignment: Alignment.centerLeft, child: HBStatusChip(kind: point.visibility == MapPointVisibility.public ? HBStatusKind.approved : HBStatusKind.info, label: point.visibility.labelKey.tr())), MapDetailRow(label: 'map.form.kind'.tr(), value: point.kind.labelKey.tr()), MapCoordinatesRow(point: point.position)]; }
    else if (item is MapPoint) { final point = item as MapPoint; title = point.name; icon = point.kind.icon; rows = [MapDetailRow(label: 'map.form.kind'.tr(), value: point.kind.labelKey.tr()), Align(alignment: Alignment.centerLeft, child: HBStatusChip(kind: point.visibility == MapPointVisibility.private ? HBStatusKind.neutral : point.visibility == MapPointVisibility.friends ? HBStatusKind.info : HBStatusKind.approved, label: point.visibility.labelKey.tr())), if (point.huntingUnitId != null) MapDetailRow(label: 'map.unit_type'.tr(), value: point.huntingUnitId!), if (point.notes?.isNotEmpty == true) MapDetailRow(label: 'map.form.notes'.tr(), value: point.notes!), MapCoordinatesRow(point: point.position)]; actions = [HBButton.secondary(label: 'diary.actions.edit'.tr(), icon: Icons.edit_outlined, onPressed: onEdit), HBButton.ghost(label: 'diary.actions.delete'.tr(), icon: Icons.delete_outline, onPressed: onDelete)]; }
    else if (item is MapOuting) { final outing = item as MapOuting; title = outing.title ?? outing.zoneName ?? 'map.outing'.tr(); icon = Icons.menu_book_outlined; rows = [MapDetailRow(label: 'map.date'.tr(), value: DateFormat.yMMMd(context.locale.languageCode).format(outing.startedAt.toLocal())), MapDetailRow(label: 'map.harvest'.tr(), value: '${outing.harvestTotal}')]; actions = [HBButton.primary(label: 'map.open_diary'.tr(), onPressed: () => context.push(AppRoutes.diaryDetailPath(outing.id)))]; }
    else if (item is UnitArea) { final unit = item as UnitArea; title = unit.name; icon = Icons.map_outlined; rows = [MapDetailRow(label: 'map.unit_type'.tr(), value: unit.unitType), if (unit.code != null) MapDetailRow(label: 'map.code'.tr(), value: unit.code!), if (unit.regionName != null) MapDetailRow(label: 'map.region'.tr(), value: unit.regionName!), if (unit.areaM2 != null) MapDetailRow(label: 'map.area'.tr(), value: (unit.areaM2! / 1000000).toStringAsFixed(1))]; actions = [HBButton.primary(label: 'map.calendar'.tr(), onPressed: () { ref.read(huntingContextProvider.notifier).setAppliesTo(unit.unitType.toLowerCase()); context.go(AppRoutes.hunting); }), HBButton.secondary(label: 'map.filter_diary'.tr(), onPressed: () => context.go('${AppRoutes.diary}?unit=${unit.id}'))]; }
    else if (item is OfficialFeatureSelection) { final selection = item as OfficialFeatureSelection; title = selection.feature.name ?? selection.layer.name; icon = Icons.layers_outlined; rows = [if (selection.feature.code != null) MapDetailRow(label: 'map.code'.tr(), value: selection.feature.code!), MapDetailRow(label: 'map.layers.type'.tr(), value: 'map.layers.kind.${selection.layer.kind}'.tr()), if (selection.layer.description?.isNotEmpty == true) MapDetailRow(label: 'map.layers.description'.tr(), value: selection.layer.description!), if (selection.layer.sourceName?.isNotEmpty == true) MapDetailRow(label: 'map.layers.source'.tr(), value: selection.layer.sourceName!), MapDetailRow(label: 'map.area_label'.tr(), value: formatMapArea(selection.layer.areaM2)), Text('map.layers.disclaimer'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]; actions = [if (selection.layer.sourceUrl != null) HBButton.secondary(label: 'map.layers.official_text'.tr(), icon: Icons.open_in_new, onPressed: () => launchUrl(Uri.parse(selection.layer.sourceUrl!), mode: LaunchMode.externalApplication))]; }
    else if (item is MapPost) { final post = item as MapPost; title = post.locationName ?? 'map.post'.tr(); icon = Icons.photo_camera_outlined; final image = post.mediaPath == null ? null : storagePublicUrl(ref.read(supabaseClientProvider), 'post-media', post.mediaPath); rows = [ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: post.author.displayName, imageUrl: post.author.avatarUrl, size: 42), title: Text(post.author.displayName), subtitle: Text('@${post.author.username}')), if (post.content?.isNotEmpty == true) Text(post.content!, maxLines: 4, overflow: TextOverflow.ellipsis), if (image?.isNotEmpty == true) Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(image!, height: 150, width: double.infinity, fit: BoxFit.cover)))]; actions = [HBButton.primary(label: 'map.open_post'.tr(), onPressed: () => context.push(AppRoutes.postPath(post.id)))]; }
    else if (item is SightingHeatCell) { final cell = item as SightingHeatCell; title = 'p30b.map.cell_title'.tr(namedArgs: {'count': '${cell.sightings}'}); icon = Icons.blur_on_rounded; rows = [MapDetailRow(label: 'p30b.map.animals'.tr(), value: '${cell.animals}'), MapDetailRow(label: 'p30b.map.species'.tr(), value: '${cell.speciesCount}'), if (cell.topSpeciesName != null) MapDetailRow(label: 'p30b.map.top_species'.tr(), value: cell.topSpeciesName!), MapDetailRow(label: 'p30b.map.last'.tr(), value: timeago.format(cell.lastAt.toLocal(), locale: context.locale.languageCode))]; actions = [HBButton.primary(label: 'p30b.map.open_list'.tr(), onPressed: () => context.push('${AppRoutes.sightings}?tab=nearby&lat=${cell.lat}&lng=${cell.lng}&radius=2'))]; }
    else if (item is NearbySighting) { final sighting = item as NearbySighting; title = 'sightings.animals'.plural(sighting.animalsCount, namedArgs: {'count': '${sighting.animalsCount}', 'species': sighting.species.name}); icon = sighting.kind.icon; rows = [MapDetailRow(label: 'map.date'.tr(), value: DateFormat.yMMMd(context.locale.languageCode).add_Hm().format(sighting.sightedAt.toLocal())), MapDetailRow(label: 'p30b.nearby.author'.tr(), value: sighting.isMine ? 'p30b.you'.tr() : sighting.author.displayName), if (sighting.municipality != null) MapDetailRow(label: 'map.place'.tr(), value: sighting.municipality!.name)]; actions = [HBButton.primary(label: 'p30b.open'.tr(), onPressed: () => context.push(AppRoutes.sightingDetailPath(sighting.id)))]; }
    else { final event = item as MapEvent; title = event.title; icon = Icons.event_outlined; rows = [MapDetailRow(label: 'map.date'.tr(), value: DateFormat.yMMMd(context.locale.languageCode).add_Hm().format(event.startsAt.toLocal())), if (event.locationName != null) MapDetailRow(label: 'map.place'.tr(), value: event.locationName!), MapDetailRow(label: 'map.attendees'.tr(), value: '${event.attendeeCount}'), if (event.distanceM != null) MapDetailRow(label: 'map.distance'.tr(), value: (event.distanceM! / 1000).toStringAsFixed(1))]; actions = [HBButton.primary(label: 'map.open_event'.tr(), onPressed: () => context.push(AppRoutes.eventDetailPath(event.id)))]; }
    return ListView(padding: const EdgeInsets.all(AppSpacing.md), children: [Icon(icon, size: 36, color: LightModeColors.lightPrimary), const SizedBox(height: AppSpacing.sm), Text(title, style: context.textStyles.titleLarge, textAlign: TextAlign.center), const SizedBox(height: AppSpacing.md), ...rows, const SizedBox(height: AppSpacing.md), for (final action in actions) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: action)]);
  }
}

class MapDetailRow extends StatelessWidget { final String label; final String value; const MapDetailRow({super.key, required this.label, required this.value}); @override Widget build(BuildContext context) => HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(label, style: context.textStyles.bodySmall?.copyWith(color: LightModeColors.lightOnSurfaceVariant))), Flexible(child: Text(value, textAlign: TextAlign.end))])); }
class MapCoordinatesRow extends StatelessWidget { final LatLng point; const MapCoordinatesRow({super.key, required this.point}); @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [Expanded(child: Text('${point.latitude.toStringAsFixed(6)}, ${point.longitude.toStringAsFixed(6)}')), HBButton.icon(icon: Icons.copy_rounded, onPressed: () => Clipboard.setData(ClipboardData(text: '${point.latitude}, ${point.longitude}'))), HBButton.icon(icon: Icons.directions_outlined, onPressed: () => launchUrl(Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${point.latitude},${point.longitude}'), mode: LaunchMode.externalApplication))])); }

Color mapStoredColor(String? value) { if (value == null || !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(value)) return LightModeColors.lightPrimary; return Color(int.parse(value.substring(1), radix: 16) + 0xFF000000); }
String mapColorHex(Color color) => '#${(color.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
String formatMapArea(double areaM2) => areaM2 >= 1000000 ? '${(areaM2 / 1000000).toStringAsFixed(1)} km²' : '${(areaM2 / 10000).toStringAsFixed(areaM2 >= 100000 ? 0 : 1)} ha';
String formatMapDistance(double distanceM) => distanceM >= 1000 ? '${(distanceM / 1000).toStringAsFixed(1)} km' : '${distanceM.round()} m';