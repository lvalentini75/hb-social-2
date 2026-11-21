import 'dart:math';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/events/data/photon_place_service.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/sightings/data/sightings_repository.dart';
import 'package:hb_social/features/sightings/domain/sighting.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:image/image.dart' as img;
import 'package:latlong2/latlong.dart';

enum SightingPositionMode { current, map, municipality }

class SightingFormPage extends ConsumerStatefulWidget {
  final String? sightingId;
  const SightingFormPage({super.key, this.sightingId});
  @override
  ConsumerState<SightingFormPage> createState() => _SightingFormPageState();
}

class _SightingFormPageState extends ConsumerState<SightingFormPage> {
  final _notes = TextEditingController();
  final _municipalityText = TextEditingController();
  final _placeText = TextEditingController();
  DateTime _sightedAt = DateTime.now();
  Species? _species;
  SightingKind _kind = SightingKind.sighting;
  SightingVisibility _visibility = SightingVisibility.public;
  SightingPositionMode _positionMode = SightingPositionMode.current;
  int _count = 1;
  double? _lat;
  double? _lng;
  double? _accuracy;
  Municipality? _municipality;
  String? _regionId;
  String? _logId;
  String? _mediaPath;
  String? _thumbnailPath;
  Uint8List? _photo;
  double? _uploadProgress;
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() { super.initState(); Future.microtask(_initialize); }

  Future<void> _initialize() async {
    final allSpecies = await ref.read(speciesProvider.future);
    final prefill = ref.read(sightingFormPrefillProvider);
    ref.read(sightingFormPrefillProvider.notifier).state = null;
    if (widget.sightingId != null) {
      final detail = await ref.read(sightingsRepositoryProvider).detail(widget.sightingId!);
      if (!detail.isMine) { if (mounted) context.go(AppRoutes.sightingDetailPath(detail.id)); return; }
      _species = allSpecies.where((item) => item.id == detail.species.id).firstOrNull;
      _sightedAt = detail.sightedAt.toLocal(); _kind = detail.kind; _visibility = detail.visibility; _count = detail.animalsCount; _lat = detail.lat; _lng = detail.lng; _accuracy = detail.accuracyM; _notes.text = detail.notes ?? ''; _logId = detail.logId; _mediaPath = detail.mediaPath; _thumbnailPath = detail.thumbnailPath;
      if (detail.municipality != null) { _municipalityText.text = detail.municipality!.name; _municipality = await ref.read(referenceRepositoryProvider).getMunicipality(detail.municipality!.id); }
      _positionMode = detail.hasPosition ? SightingPositionMode.map : SightingPositionMode.municipality;
    } else if (prefill != null) {
      _sightedAt = prefill.sightedAt?.toLocal() ?? _sightedAt; _lat = prefill.lat; _lng = prefill.lng; _accuracy = prefill.accuracyM; _logId = prefill.logId;
      _species = allSpecies.where((item) => item.id == prefill.speciesId).firstOrNull;
      if (prefill.municipalityId != null) { _municipality = await ref.read(referenceRepositoryProvider).getMunicipality(prefill.municipalityId!); _municipalityText.text = _municipality?.compactName ?? ''; _regionId = _municipality?.regionId; }
      _positionMode = _lat == null ? SightingPositionMode.municipality : SightingPositionMode.map;
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() { _notes.dispose(); _municipalityText.dispose(); _placeText.dispose(); super.dispose(); }

  Future<void> _pickSpecies() async {
    final all = await ref.read(speciesProvider.future);
    final recent = (await ref.read(sightingsRepositoryProvider).mySightings(limit: 20)).map((item) => item.species.id).toList();
    final selected = await showDialog<Species>(context: context, builder: (_) => SightingSpeciesPicker(items: all, recentIds: recent.take(5).toList()));
    if (selected != null) setState(() => _species = selected);
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(context: context, initialDate: _sightedAt, firstDate: DateTime.now().subtract(const Duration(days: 730)), lastDate: DateTime.now().add(const Duration(days: 1)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_sightedAt));
    if (time != null) setState(() => _sightedAt = DateTime(date.year, date.month, date.day, time.hour, time.minute));
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('sightings.errors.location_denied');
      final value = await Geolocator.getCurrentPosition();
      if (mounted) setState(() { _lat = value.latitude; _lng = value.longitude; _accuracy = value.accuracy; });
    } on AppException catch (error) { _message(error.messageKey); }
  }

  Future<void> _pickPhoto() async {
    try {
      final bytes = await MediaSourcePicker.imageBytes(context, ref.read(mediaUploadServiceProvider));
      if (bytes == null) return;
      Uint8List selected = bytes;
      if (mounted && await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('sightings.form.crop_title'.tr()), content: Text('sightings.form.crop_help'.tr()), actions: [HBButton.ghost(label: 'sightings.form.keep_original'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'sightings.form.crop'.tr(), onPressed: () => dialog.pop(true))])) == true) {
        final image = img.decodeImage(bytes)!;
        final longest = max(image.width, image.height);
        final scale = min(1.0, 1600 / longest);
        final cropped = await HBImageCropper.show(context, bytes: bytes, aspectRatio: image.width / image.height, outputWidth: (image.width * scale).round(), outputHeight: (image.height * scale).round());
        if (cropped != null) selected = cropped;
      }
      if (mounted) setState(() => _photo = selected);
    } on AppException catch (error) { _message(error.messageKey); }
  }

  Future<void> _save() async {
    if (_species == null) return _message('sightings.errors.species_required');
    if (_positionMode == SightingPositionMode.municipality && _municipality == null || _positionMode != SightingPositionMode.municipality && (_lat == null || _lng == null)) return _message('sightings.errors.place_required');
    setState(() => _saving = true);
    try {
      var mediaPath = _mediaPath; var thumbnailPath = _thumbnailPath;
      if (_photo != null) { final upload = await ref.read(sightingsRepositoryProvider).uploadPhoto(_photo!, (value) { if (mounted) setState(() => _uploadProgress = value); }); mediaPath = upload.path; thumbnailPath = upload.thumbnailPath; }
      final includeCoordinates = _positionMode != SightingPositionMode.municipality;
      final id = await ref.read(sightingsRepositoryProvider).upsert(SightingInput(id: widget.sightingId, speciesId: _species!.id, sightedAt: _sightedAt, animalsCount: _count, kind: _kind, lat: includeCoordinates ? _lat : null, lng: includeCoordinates ? _lng : null, accuracyM: _positionMode == SightingPositionMode.current ? _accuracy : null, municipalityId: _positionMode == SightingPositionMode.municipality ? _municipality?.id : null, regionId: _positionMode == SightingPositionMode.municipality ? _regionId : null, notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(), visibility: _visibility, mediaPath: mediaPath, thumbnailPath: thumbnailPath, logId: _logId));
      ref.invalidate(mySightingsProvider); ref.invalidate(sightingsOfProvider); ref.invalidate(sightingDetailProvider(id));
      if (mounted) { context.go(AppRoutes.sightingDetailPath(id)); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('sightings.saved'.tr()))); }
    } on AppException catch (error) { _message(error.messageKey); }
    finally { if (mounted) setState(() { _saving = false; _uploadProgress = null; }); }
  }

  void _message(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final settings = ref.watch(userSettingsProvider);
    final outings = ref.watch(outingsProvider((userId: null, season: null))).value?.items.where((item) => item.startedAt.isAfter(DateTime.now().subtract(const Duration(days: 30)))).toList() ?? const <Outing>[];
    final imageUrl = ref.watch(sightingsRepositoryProvider).publicUrl(_mediaPath);
    return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text((widget.sightingId == null ? 'sightings.form.new_title' : 'sightings.form.edit_title').tr(), style: context.textStyles.headlineSmall)), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.sightings))]),
      const SizedBox(height: AppSpacing.lg),
      HBCard(child: Column(children: [
        HBFormSection(title: 'sightings.form.what'.tr(), children: [HBFormField(label: 'sightings.form.species'.tr(), required: true, child: HBButton.secondary(label: _species?.localizedName ?? 'sightings.form.choose_species'.tr(), icon: Icons.search_rounded, onPressed: _pickSpecies)), HBFormField(label: 'sightings.form.kind'.tr(), child: HBChoice<SightingKind>(options: SightingKind.values, value: _kind, onChanged: (value) => setState(() => _kind = value), labelBuilder: (value) => value.labelKey.tr())), HBFormField(label: 'sightings.form.count'.tr(), child: SightingCountStepper(value: _count, onChanged: (value) => setState(() => _count = value))), HBFormField(label: 'sightings.form.when'.tr(), required: true, child: HBButton.secondary(label: DateFormat.yMMMd(context.locale.languageCode).add_Hm().format(_sightedAt), icon: Icons.schedule_rounded, onPressed: _pickDate))]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'sightings.form.where'.tr(), subtitle: 'sightings.form.privacy_note'.tr(), children: [HBSegmentedTabs(labels: ['sightings.position.current'.tr(), 'sightings.position.map'.tr(), 'sightings.position.municipality'.tr()], selectedIndex: _positionMode.index, onChanged: (index) => setState(() => _positionMode = SightingPositionMode.values[index])), if (_positionMode == SightingPositionMode.current) HBButton.secondary(label: _lat == null ? 'sightings.position.locate'.tr() : 'sightings.position.located'.tr(), icon: Icons.my_location_rounded, onPressed: _locate), if (_positionMode == SightingPositionMode.map) ...[HBPlaceField<PhotonPlace>(controller: _placeText, hint: 'sightings.position.search_place'.tr(), search: (query) async => [for (final place in await PhotonPlaceService().search(query, language: context.locale.languageCode)) HBPlaceSuggestion(value: place, title: place.name, subtitle: place.address)], onSelected: (place) => setState(() { _lat = place.latitude; _lng = place.longitude; })), SightingLocationMap(latitude: _lat, longitude: _lng, onChanged: (point) => setState(() { _lat = point.latitude; _lng = point.longitude; }))], if (_positionMode == SightingPositionMode.municipality) HBPlaceField<Municipality>(controller: _municipalityText, hint: 'sightings.position.search_municipality'.tr(), search: (query) async => [for (final place in await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: settings.countryCode ?? 'IT')) HBPlaceSuggestion(value: place, title: place.compactName, subtitle: place.regionName)], onSelected: (place) => setState(() { _municipality = place; _regionId = place.regionId; }))]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'sightings.form.details'.tr(), children: [HBFormField(label: 'sightings.form.photo'.tr(), child: HBImageField(kind: HBImageFieldKind.cover, imageUrl: imageUrl, imageBytes: _photo, onPick: _pickPhoto, progress: _uploadProgress, onRemove: _photo != null || _mediaPath != null ? () => setState(() { _photo = null; _mediaPath = null; _thumbnailPath = null; }) : null, changeLabel: 'sightings.form.choose_photo'.tr(), removeLabel: 'common.remove'.tr(), coverAspectRatio: 16 / 9)), HBFormField(label: 'sightings.form.notes'.tr(), child: HBInput(controller: _notes, maxLines: 5, maxLength: 500)), HBFormField(label: 'sightings.form.visibility'.tr(), child: HBChoice<SightingVisibility>(options: SightingVisibility.values, value: _visibility, onChanged: (value) => setState(() => _visibility = value), labelBuilder: (value) => value.labelKey.tr(), descriptions: {for (final value in SightingVisibility.values) value: 'sightings.visibility_description.${value.code}'.tr()})), HBFormField(label: 'sightings.form.outing'.tr(), child: HBSelect<String>(value: _logId, allowClear: true, placeholder: 'sightings.form.no_outing'.tr(), options: [for (final outing in outings) HBSelectOption(value: outing.id, label: outing.title ?? DateFormat.yMMMd(context.locale.languageCode).format(outing.startedAt.toLocal()))], onChanged: (value) => setState(() => _logId = value)))]),
        HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _save, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.canPop() ? context.pop() : context.go(AppRoutes.sightings), loading: _saving),
      ])),
      const SizedBox(height: AppSpacing.xxl),
    ])))))]);
  }
}

class SightingCountStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  const SightingCountStepper({super.key, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Row(children: [HBButton.icon(icon: Icons.remove_rounded, onPressed: value <= 1 ? null : () => onChanged(value - 1)), Expanded(child: Text('$value', textAlign: TextAlign.center, style: context.textStyles.titleLarge)), HBButton.icon(icon: Icons.add_rounded, onPressed: value >= 500 ? null : () => onChanged(value + 1))]);
}

class SightingSpeciesPicker extends StatefulWidget {
  final List<Species> items;
  final List<String> recentIds;
  const SightingSpeciesPicker({super.key, required this.items, required this.recentIds});
  @override
  State<SightingSpeciesPicker> createState() => _SightingSpeciesPickerState();
}

class _SightingSpeciesPickerState extends State<SightingSpeciesPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final normalized = query.toLowerCase();
    final filtered = widget.items.where((item) => item.localizedName.toLowerCase().contains(normalized) || item.scientificName.toLowerCase().contains(normalized) || item.category.toLowerCase().contains(normalized)).toList()..sort((a, b) { final ai = widget.recentIds.indexOf(a.id); final bi = widget.recentIds.indexOf(b.id); if (ai >= 0 || bi >= 0) return (ai < 0 ? 99 : ai).compareTo(bi < 0 ? 99 : bi); return a.localizedName.compareTo(b.localizedName); });
    return AlertDialog(title: Text('sightings.form.choose_species'.tr()), content: SizedBox(width: 460, height: 460, child: Column(children: [HBInput(hint: 'common.search'.tr(), onChanged: (value) => setState(() => query = value)), const SizedBox(height: AppSpacing.sm), Expanded(child: ListView.builder(itemCount: filtered.length, itemBuilder: (_, index) { final item = filtered[index]; return ListTile(leading: widget.recentIds.contains(item.id) ? const Icon(Icons.history_rounded) : null, title: Text(item.localizedName), subtitle: Text('${item.scientificName} · ${item.category}'), onTap: () => context.pop(item)); }))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop())]);
  }
}

class SightingLocationMap extends StatefulWidget {
  final double? latitude;
  final double? longitude;
  final ValueChanged<LatLng> onChanged;
  const SightingLocationMap({super.key, this.latitude, this.longitude, required this.onChanged});
  @override
  State<SightingLocationMap> createState() => _SightingLocationMapState();
}

class _SightingLocationMapState extends State<SightingLocationMap> {
  final _mapKey = GlobalKey();
  final _controller = MapController();
  @override
  Widget build(BuildContext context) {
    final point = LatLng(widget.latitude ?? 45.46, widget.longitude ?? 9.19);
    final marker = Marker(
      point: point,
      width: 48,
      height: 48,
      child: Draggable<LatLng>(
        data: point,
        feedback: const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError),
        childWhenDragging: const SizedBox.shrink(),
        onDragEnd: (details) {
          final box = _mapKey.currentContext?.findRenderObject() as RenderBox?;
          if (box != null) widget.onChanged(_controller.camera.screenOffsetToLatLng(box.globalToLocal(details.offset + const Offset(24, 44))));
        },
        child: const Icon(Icons.location_pin, size: 44, color: LightModeColors.lightError),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        height: 260,
        child: FlutterMap(
          key: _mapKey,
          mapController: _controller,
          options: MapOptions(initialCenter: point, initialZoom: widget.latitude == null ? 6 : 13, onTap: (_, value) => widget.onChanged(value), onLongPress: (_, value) => widget.onChanged(value)),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'),
            if (widget.latitude != null) MarkerLayer(markers: [marker]),
            RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors', onTap: () {})]),
          ],
        ),
      ),
    );
  }
}