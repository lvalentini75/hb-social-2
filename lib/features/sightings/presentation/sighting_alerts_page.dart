import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/events/data/photon_place_service.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/domain/sighting_alert.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:latlong2/latlong.dart';
import 'package:timeago/timeago.dart' as timeago;

class SightingAlertsPage extends ConsumerStatefulWidget {
  final bool openForm;
  const SightingAlertsPage({super.key, this.openForm = false});
  @override ConsumerState<SightingAlertsPage> createState() => _SightingAlertsPageState();
}

class _SightingAlertsPageState extends ConsumerState<SightingAlertsPage> {
  bool opened = false;
  @override void didChangeDependencies() { super.didChangeDependencies(); if (widget.openForm && !opened) { opened = true; WidgetsBinding.instance.addPostFrameCallback((_) => _open()); } }
  Future<void> _open([SightingAlert? alert]) async {
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => FractionallySizedBox(heightFactor: 0.94, child: SightingAlertForm(alert: alert)));
    ref.read(sightingAlertPrefillProvider.notifier).state = null;
  }
  Future<void> _delete(SightingAlert alert) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('sighting_alerts.delete_title'.tr()), content: Text('sighting_alerts.delete_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.secondary(label: 'sighting_alerts.delete'.tr(), onPressed: () => dialog.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(sightingsRepositoryProvider).deleteAlert(alert.id); ref.invalidate(mySightingAlertsProvider); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  @override Widget build(BuildContext context) {
    final value = ref.watch(mySightingAlertsProvider);
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('sighting_alerts.title'.tr(), style: context.textStyles.headlineSmall), Text('sighting_alerts.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBButton.primary(label: 'sighting_alerts.create'.tr(), icon: Icons.add_alert_outlined, onPressed: _open)]),
      const SizedBox(height: AppSpacing.lg),
      value.when(loading: () => const HBListSkeleton(count: 4), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'sighting_alerts.errors.title'.tr(), message: 'sighting_alerts.errors.generic'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(mySightingAlertsProvider)))), data: (alerts) {
        if (alerts.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.notifications_active_outlined, title: 'sighting_alerts.empty_title'.tr(), message: 'sighting_alerts.empty_message'.tr(), action: HBButton.primary(label: 'sighting_alerts.create'.tr(), onPressed: _open)));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('sighting_alerts.count'.tr(namedArgs: {'count': '${alerts.length}'}), style: context.textStyles.labelLarge), const SizedBox(height: AppSpacing.sm), for (final alert in alerts) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: SightingAlertTile(alert: alert, onEdit: () => _open(alert), onDelete: () => _delete(alert)))]);
      }),
      const SizedBox(height: AppSpacing.xxl),
    ]))]));
  }
}

class SightingAlertTile extends ConsumerWidget {
  final SightingAlert alert;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const SightingAlertTile({super.key, required this.alert, required this.onEdit, required this.onDelete});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final allKinds = alert.kinds.length == SightingKind.values.length;
    final place = alert.area == SightingAlertArea.point ? 'sighting_alerts.point_radius'.tr(namedArgs: {'radius': alert.radiusKm.toStringAsFixed(0)}) : alert.placeLabel;
    final last = alert.lastFiredAt == null ? 'sighting_alerts.never'.tr() : timeago.format(alert.lastFiredAt!.toLocal(), locale: context.locale.languageCode);
    Future<void> toggle(bool active) async { try { await ref.read(sightingsRepositoryProvider).setAlertActive(alert.id, active); ref.invalidate(mySightingAlertsProvider); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
    return HBCard(child: HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.visibility_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.md),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text(alert.name, style: context.textStyles.titleMedium)), HBStatusChip(kind: alert.isActive ? HBStatusKind.approved : HBStatusKind.neutral, label: (alert.isActive ? 'sighting_alerts.active' : 'sighting_alerts.inactive').tr())]),
        Text(alert.speciesName ?? 'sighting_alerts.any_species'.tr(), style: context.textStyles.bodyMedium), Text(place, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        if (alert.minAnimals > 1) Text('sighting_alerts.min_animals'.tr(namedArgs: {'count': '${alert.minAnimals}'})),
        if (!allKinds) Wrap(spacing: AppSpacing.xs, children: [for (final kind in alert.kinds) HBChip(label: kind.labelKey.tr(), selected: false)]),
        const SizedBox(height: AppSpacing.xs), Text('sighting_alerts.fired'.tr(namedArgs: {'count': '${alert.fireCount}', 'last': last}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      ])),
      Switch(value: alert.isActive, onChanged: toggle, activeColor: LightModeColors.lightPrimary),
      PopupMenuButton<String>(onSelected: (value) => value == 'edit' ? onEdit() : onDelete(), itemBuilder: (_) => [PopupMenuItem(value: 'edit', child: Text('sighting_alerts.edit'.tr())), PopupMenuItem(value: 'delete', child: Text('sighting_alerts.delete'.tr()))]),
    ])));
  }
}

class SightingAlertForm extends ConsumerStatefulWidget {
  final SightingAlert? alert;
  const SightingAlertForm({super.key, this.alert});
  @override ConsumerState<SightingAlertForm> createState() => _SightingAlertFormState();
}

class _SightingAlertFormState extends ConsumerState<SightingAlertForm> {
  late final TextEditingController name;
  final placeSearch = TextEditingController();
  final municipalitySearch = TextEditingController();
  late String? speciesId;
  String? speciesName;
  late SightingAlertArea area;
  LatLng? point;
  late double radius;
  Municipality? municipality;
  String? regionId;
  late Set<SightingKind> kinds;
  late int minAnimals;
  late int cooldown;
  bool saving = false;
  bool nameTouched = false;
  @override void initState() {
    super.initState();
    final existing = widget.alert; final prefill = ref.read(sightingAlertPrefillProvider);
    name = TextEditingController(text: existing?.name ?? ''); speciesId = existing?.speciesId ?? prefill?.speciesId; speciesName = existing?.speciesName ?? prefill?.speciesName;
    area = existing?.area ?? SightingAlertArea.point; point = existing?.lat != null && existing?.lng != null ? LatLng(existing!.lat!, existing.lng!) : prefill?.lat != null && prefill?.lng != null ? LatLng(prefill!.lat!, prefill.lng!) : null;
    radius = existing?.radiusKm ?? 10; regionId = existing?.regionId; kinds = {...(existing?.kinds ?? SightingKind.values)}; minAnimals = existing?.minAnimals ?? 1; cooldown = existing?.cooldownMin ?? 60;
  }
  @override void dispose() { name.dispose(); placeSearch.dispose(); municipalitySearch.dispose(); super.dispose(); }
  void suggest() { if (nameTouched) return; final species = speciesName ?? 'sighting_alerts.any_species'.tr(); final place = area == SightingAlertArea.municipality ? municipality?.name : area == SightingAlertArea.region ? null : 'sighting_alerts.within'.tr(namedArgs: {'radius': radius.toStringAsFixed(0)}); name.text = [species, if (place != null) place].join(' '); }
  Future<void> locate() async {
    try { var permission = await Geolocator.checkPermission(); if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission(); if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('sightings.errors.location_denied'); final value = await Geolocator.getCurrentPosition(); if (mounted) setState(() => point = LatLng(value.latitude, value.longitude)); }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }
  Future<void> save() async {
    setState(() => saving = true);
    try {
      await ref.read(sightingsRepositoryProvider).upsertAlert(SightingAlertInput(id: widget.alert?.id, name: name.text.trim(), speciesId: speciesId, kinds: kinds.toList(), lat: area == SightingAlertArea.point ? point?.latitude : null, lng: area == SightingAlertArea.point ? point?.longitude : null, radiusKm: radius, municipalityId: area == SightingAlertArea.municipality ? municipality?.id ?? widget.alert?.municipalityId : null, regionId: area == SightingAlertArea.region ? regionId : null, minAnimals: minAnimals, cooldownMin: cooldown, isActive: widget.alert?.isActive ?? true));
      ref.invalidate(mySightingAlertsProvider); if (mounted) context.pop();
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => saving = false); }
  }
  @override Widget build(BuildContext context) {
    final species = ref.watch(speciesProvider).value ?? const <Species>[];
    final settings = ref.watch(userSettingsProvider); final regions = ref.watch(regionsProvider(settings.countryCode ?? 'IT')).value ?? const <ReferenceRegion>[];
    if (speciesId != null && speciesName == null) { for (final item in species) { if (item.id == speciesId) speciesName = item.localizedName; } }
    return ListView(padding: const EdgeInsets.all(AppSpacing.lg), children: [
      Text(widget.alert == null ? 'sighting_alerts.form.create_title'.tr() : 'sighting_alerts.form.edit_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.lg),
      HBFormSection(title: 'sighting_alerts.form.what'.tr(), children: [
        HBFormField(label: 'sighting_alerts.form.name'.tr(), required: true, child: HBInput(controller: name, maxLength: 60, onChanged: (_) => nameTouched = true)),
        HBFormField(label: 'sighting_alerts.form.species'.tr(), child: HBSelect<String>(value: speciesId, allowClear: true, placeholder: 'sighting_alerts.any_species'.tr(), options: [for (final item in species) HBSelectOption(value: item.id, label: item.localizedName)], onChanged: (value) => setState(() { speciesId = value; speciesName = value == null ? null : species.firstWhere((item) => item.id == value).localizedName; suggest(); }))),
      ]), const HBFormSectionDivider(),
      HBFormSection(title: 'sighting_alerts.form.area'.tr(), children: [
        HBSegmentedTabs(labels: ['sighting_alerts.form.point'.tr(), 'sighting_alerts.form.municipality'.tr(), 'sighting_alerts.form.region'.tr()], selectedIndex: SightingAlertArea.values.indexOf(area), onChanged: (index) => setState(() { area = SightingAlertArea.values[index]; suggest(); })),
        if (area == SightingAlertArea.point) ...[
          HBPlaceField<PhotonPlace>(controller: placeSearch, hint: 'sighting_alerts.form.search_point'.tr(), search: (query) async => [for (final place in await PhotonPlaceService().search(query, language: context.locale.languageCode)) HBPlaceSuggestion(value: place, title: place.name, subtitle: place.address)], onSelected: (place) => setState(() => point = LatLng(place.latitude, place.longitude))),
          HBButton.soft(label: 'sighting_alerts.form.use_location'.tr(), icon: Icons.my_location_outlined, onPressed: locate),
          if (point != null) SightingAlertPointMap(point: point!, radiusKm: radius, onChanged: (value) => setState(() => point = value)),
          HBFormField(label: 'sighting_alerts.form.radius'.tr(), child: HBChoice<double>(options: const [2, 5, 10, 25, 50], value: radius, onChanged: (value) => setState(() { radius = value; suggest(); }), labelBuilder: (value) => '${value.toInt()} km')),
        ],
        if (area == SightingAlertArea.municipality) HBPlaceField<Municipality>(controller: municipalitySearch, hint: widget.alert?.municipalityName ?? 'sighting_alerts.form.search_municipality'.tr(), search: (query) async => [for (final item in await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: settings.countryCode ?? 'IT')) HBPlaceSuggestion(value: item, title: item.compactName, subtitle: item.regionName)], onSelected: (value) => setState(() { municipality = value; suggest(); })),
        if (area == SightingAlertArea.region) HBSelect<String>(value: regionId, placeholder: 'sighting_alerts.form.choose_region'.tr(), options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() { regionId = value; suggest(); })),
      ]), const HBFormSectionDivider(),
      HBFormSection(title: 'sighting_alerts.form.filters'.tr(), children: [
        HBFormField(label: 'sighting_alerts.form.kinds'.tr(), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final kind in SightingKind.values) HBChip(label: kind.labelKey.tr(), selected: kinds.contains(kind), onTap: () => setState(() => kinds.contains(kind) ? kinds.remove(kind) : kinds.add(kind)))])),
        HBFormField(label: 'sighting_alerts.form.minimum'.tr(), child: AlertCountStepper(value: minAnimals, onChanged: (value) => setState(() => minAnimals = value))),
        HBFormField(label: 'sighting_alerts.form.cooldown'.tr(), child: HBChoice<int>(options: const [0, 60, 360, 1440], value: cooldown, onChanged: (value) => setState(() => cooldown = value), labelBuilder: (value) => 'sighting_alerts.cooldown.$value'.tr())),
      ]),
      HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.lock_outline, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('sighting_alerts.form.privacy_note'.tr()))])),
      HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: name.text.trim().isEmpty || kinds.isEmpty ? null : save, secondaryLabel: 'common.cancel'.tr(), onSecondary: context.pop, loading: saving),
    ]);
  }
}

class AlertCountStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const AlertCountStepper({super.key, required this.value, required this.onChanged});
  @override Widget build(BuildContext context) => Row(children: [HBButton.icon(icon: Icons.remove, onPressed: value <= 1 ? null : () => onChanged(value - 1)), Expanded(child: Text('$value', textAlign: TextAlign.center, style: context.textStyles.titleMedium)), HBButton.icon(icon: Icons.add, onPressed: value >= 500 ? null : () => onChanged(value + 1))]);
}

class SightingAlertPointMap extends StatefulWidget {
  final LatLng point;
  final double radiusKm;
  final ValueChanged<LatLng> onChanged;
  const SightingAlertPointMap({super.key, required this.point, required this.radiusKm, required this.onChanged});
  @override State<SightingAlertPointMap> createState() => _SightingAlertPointMapState();
}

class _SightingAlertPointMapState extends State<SightingAlertPointMap> {
  final mapKey = GlobalKey(); final controller = MapController();
  @override void didUpdateWidget(covariant SightingAlertPointMap oldWidget) { super.didUpdateWidget(oldWidget); if (oldWidget.point != widget.point) WidgetsBinding.instance.addPostFrameCallback((_) => controller.move(widget.point, controller.camera.zoom)); }
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 230, child: FlutterMap(key: mapKey, mapController: controller, options: MapOptions(initialCenter: widget.point, initialZoom: 12, onTap: (_, value) => widget.onChanged(value)), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), CircleLayer(circles: [CircleMarker(point: widget.point, radius: widget.radiusKm * 1000, useRadiusInMeter: true, color: LightModeColors.lightPrimary.withValues(alpha: 0.14), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 2)]), MarkerLayer(markers: [Marker(point: widget.point, width: 48, height: 48, child: Draggable<LatLng>(data: widget.point, feedback: const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError), childWhenDragging: const SizedBox.shrink(), onDragEnd: (details) { final box = mapKey.currentContext?.findRenderObject() as RenderBox?; if (box != null) widget.onChanged(controller.camera.screenOffsetToLatLng(box.globalToLocal(details.offset + const Offset(24, 44)))); }, child: const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError))) ]), RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})])] )));
}