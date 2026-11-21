import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/events/data/photon_place_service.dart';
import 'package:hb_social/features/events/presentation/event_map.dart';
import 'package:hb_social/features/events/providers/event_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:latlong2/latlong.dart';

class EventFormPage extends ConsumerStatefulWidget {
  final String? eventId;
  final String? initialPageId;
  final String? initialGroupId;
  const EventFormPage({super.key, this.eventId, this.initialPageId, this.initialGroupId});
  @override
  ConsumerState<EventFormPage> createState() => _EventFormPageState();
}

class _EventFormPageState extends ConsumerState<EventFormPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController();
  final _address = TextEditingController();
  final _latitude = TextEditingController();
  final _longitude = TextEditingController();
  final _capacity = TextEditingController();
  final _price = TextEditingController(text: '0');
  String? _category;
  String? _regionId;
  String? _unitId;
  DateTime? _startsAt;
  DateTime? _endsAt;
  PreparedUpload? _cover;
  String? _existingCover;
  String _organizerKind = 'user';
  String? _organizerId;
  bool _publish = true;
  bool _saving = false;
  bool _loaded = false;
  double? _progress;
  String? _errorKey;

  bool get _editing => widget.eventId != null;

  @override
  void dispose() {
    for (final controller in [_title, _description, _location, _address, _latitude, _longitude, _capacity, _price]) { controller.dispose(); }
    super.dispose();
  }

  void _load(HuntingEvent event) {
    if (_loaded) return;
    _loaded = true;
    _title.text = event.title; _description.text = event.description ?? ''; _location.text = event.location ?? ''; _address.text = event.address ?? '';
    _latitude.text = event.latitude?.toStringAsFixed(6) ?? ''; _longitude.text = event.longitude?.toStringAsFixed(6) ?? '';
    _capacity.text = event.capacity?.toString() ?? ''; _price.text = (event.priceMinor / 100).toStringAsFixed(2);
    _category = event.category; _regionId = event.regionId; _unitId = event.huntingUnitId; _startsAt = event.startsAt.toLocal(); _endsAt = event.endsAt?.toLocal();
    _existingCover = event.coverUrl; _organizerKind = event.organizer.kind; _organizerId = event.organizer.kind == 'user' ? null : event.organizer.id; _publish = event.status == 'published';
  }

  Future<void> _pickCover() async {
    try { final service = ref.read(mediaUploadServiceProvider); final source = await MediaSourcePicker.imageBytes(context, service); if (source == null || !mounted) return; final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: 16 / 9, outputWidth: 1600, outputHeight: 900); if (cropped != null && mounted) setState(() => _cover = service.prepareJpeg(cropped)); }
    on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); }
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime.now().subtract(const Duration(days: 1)), lastDate: DateTime.now().add(const Duration(days: 3650)));
    if (date == null || !mounted) return null;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    return time == null ? null : DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _usePosition() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('events.location_denied');
      final position = await Geolocator.getCurrentPosition();
      if (mounted) await _setCoordinates(LatLng(position.latitude, position.longitude));
    } on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); }
    catch (_) { if (mounted) setState(() => _errorKey = 'events.location_error'); }
  }

  void _setPlace(PhotonPlace place) => setState(() { _location.text = place.name; _address.text = place.address; _latitude.text = place.latitude.toStringAsFixed(6); _longitude.text = place.longitude.toStringAsFixed(6); });

  Future<void> _setCoordinates(LatLng value) async {
    setState(() { _latitude.text = value.latitude.toStringAsFixed(6); _longitude.text = value.longitude.toStringAsFixed(6); });
    try {
      final place = await ref.read(photonPlaceServiceProvider).reverse(value.latitude, value.longitude, language: context.locale.languageCode);
      if (place != null && mounted) setState(() { _location.text = place.name; _address.text = place.address; });
    } on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); }
  }

  int? _priceMinor() {
    final normalized = _price.text.trim().replaceAll(',', '.');
    final value = double.tryParse(normalized);
    return value == null || value < 0 ? null : (value * 100).round();
  }

  Future<void> _save() async {
    final session = ref.read(authSessionProvider).value;
    if (session == null) { context.go(AppRoutes.login); return; }
    if (_saving) return;
    if (_title.text.trim().length < 3 || _category == null || _startsAt == null || _priceMinor() == null) { setState(() => _errorKey = 'events.form.required_error'); return; }
    setState(() { _saving = true; _errorKey = null; _progress = _cover == null ? null : 0; });
    UploadedMedia? uploaded;
    try {
      if (_cover != null) {
        final progress = UploadProgress();
        final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = value); });
        try { uploaded = await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'event-media', userId: session.user.id, upload: _cover!, isPublic: true, progress: progress); }
        finally { await subscription.cancel(); await progress.close(); }
      }
      final values = <String, dynamic>{
        'title': _title.text.trim(), 'category': _category, 'starts_at': _startsAt!.toUtc().toIso8601String(), 'ends_at': _endsAt?.toUtc().toIso8601String(),
        'description': _description.text.trim().isEmpty ? null : _description.text.trim(), 'location_name': _location.text.trim().isEmpty ? null : _location.text.trim(), 'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'lat': double.tryParse(_latitude.text), 'lng': double.tryParse(_longitude.text), 'region_id': _regionId, 'hunting_unit_id': _unitId, 'capacity': int.tryParse(_capacity.text),
        'price_minor': _priceMinor(), 'currency_code': ref.read(userSettingsProvider).currencyCode,
      };
      if (uploaded != null || !_editing) values['cover_url'] = uploaded?.path;
      String id;
      if (_editing) {
        await ref.read(eventRepositoryProvider).updateEvent(widget.eventId!, values); id = widget.eventId!;
      } else {
        final params = {for (final entry in values.entries) 'p_${entry.key}': entry.value, 'p_organizer_page_id': _organizerKind == 'page' ? _organizerId : null, 'p_organizer_group_id': _organizerKind == 'group' ? _organizerId : null, 'p_publish': _publish};
        id = await ref.read(eventRepositoryProvider).createEvent(params);
      }
      ref.invalidate(eventsProvider); ref.invalidate(eventByIdProvider(id));
      if (mounted) context.go(AppRoutes.eventDetailPath(id));
    } on AppException catch (error) {
      if (uploaded != null) await ref.read(mediaUploadServiceProvider).delete('event-media', uploaded.path);
      if (mounted) setState(() { _saving = false; _errorKey = error.messageKey; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'events.sign_in_title'.tr(), message: 'events.sign_in_message'.tr(), action: HBFormActions(primaryLabel: 'events.sign_in'.tr(), onPrimary: () => context.go(AppRoutes.login)))));
    final existing = _editing ? ref.watch(eventByIdProvider(widget.eventId!)) : null;
    if (existing?.isLoading == true) return const PageColumns(center: Center(child: CircularProgressIndicator()));
    if (existing?.hasError == true || existing?.value == null && _editing) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'events.error_title'.tr(), message: 'events.error_message'.tr())));
    if (existing?.value != null) _load(existing!.value!);
    final settings = ref.watch(userSettingsProvider);
    final categories = ref.watch(eventCategoriesProvider).value ?? const <EventCategory>[];
    final regions = settings.countryCode == null ? null : ref.watch(regionsProvider(settings.countryCode!));
    final units = _regionId == null ? null : ref.watch(huntingUnitsByRegionProvider(_regionId!));
    final pages = ref.watch(myPagesProvider).value ?? const [];
    final groups = ref.watch(managedGroupsForEventsProvider).value ?? const <EventOrganizerChoice>[];
    if (!_editing && !_loaded) { _loaded = true; _regionId = settings.regionId; if (widget.initialPageId != null) { _organizerKind = 'page'; _organizerId = widget.initialPageId; } if (widget.initialGroupId != null) { _organizerKind = 'group'; _organizerId = widget.initialGroupId; } }
    final lat = double.tryParse(_latitude.text); final lng = double.tryParse(_longitude.text);
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Text((_editing ? 'events.form.edit_title' : 'events.form.create_title').tr(), style: context.textStyles.headlineSmall))),
      const SizedBox(height: AppSpacing.lg),
      Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: HBCard(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 700 ? AppSpacing.lg : AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        HBFormSection(title: 'events.form.event'.tr(), children: [
          HBFormField(label: 'events.form.cover'.tr(), child: HBCard.media(child: HBImageField(kind: HBImageFieldKind.cover, coverAspectRatio: 16 / 9, imageUrl: _existingCover, imageBytes: _cover?.bytes, onPick: _saving ? null : _pickCover, progress: _progress, onRemove: _cover == null && _existingCover == null ? null : () => setState(() { _cover = null; _existingCover = null; }), changeLabel: 'events.form.cover_change'.tr(), removeLabel: 'common.remove'.tr()))),
          HBFormField(label: 'events.form.title'.tr(), required: true, child: HBInput(controller: _title, maxLength: 120, enabled: !_saving)),
          HBFormField(label: 'events.form.category_label'.tr(), required: true, child: Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: categories.map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: _saving ? null : () => setState(() => _category = item.slug))).toList())),
          HBFormField(label: 'events.form.description'.tr(), child: HBInput(controller: _description, maxLength: 5000, minLines: 3, maxLines: 8, enabled: !_saving)),
        ]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'events.form.when'.tr(), children: [
          LayoutBuilder(builder: (context, constraints) { final start = HBFormField(label: 'events.form.starts_at'.tr(), required: true, child: HBFormDateButton(value: _startsAt, onPressed: _saving ? null : () async { final value = await _pickDateTime(_startsAt ?? DateTime.now().add(const Duration(hours: 1))); if (value != null && mounted) setState(() => _startsAt = value); })); final end = HBFormField(label: 'events.form.ends_at'.tr(), child: HBFormDateButton(value: _endsAt, onPressed: _saving ? null : () async { final value = await _pickDateTime(_endsAt ?? (_startsAt ?? DateTime.now()).add(const Duration(hours: 2))); if (value != null && mounted) setState(() => _endsAt = value); }, onClear: _endsAt == null ? null : () => setState(() => _endsAt = null))); return constraints.maxWidth >= 560 ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: start), const SizedBox(width: AppSpacing.md), Expanded(child: end)]) : Column(children: [start, const SizedBox(height: AppSpacing.md), end]); }),
          Text('events.form.timezone_help'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
        ]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'events.form.where'.tr(), children: [
          HBFormField(label: 'events.form.location_name'.tr(), helper: 'event_location.search_help'.tr(), child: HBPlaceField<PhotonPlace>(controller: _location, enabled: !_saving, minimumCharacters: 3, debounce: const Duration(milliseconds: 350), hint: 'event_location.search_hint'.tr(), search: (query) async => [for (final place in await ref.read(photonPlaceServiceProvider).search(query, language: context.locale.languageCode)) HBPlaceSuggestion(value: place, title: place.name, subtitle: place.address.isEmpty ? null : place.address)], onSelected: _setPlace)), HBFormField(label: 'events.form.address'.tr(), child: HBInput(controller: _address, enabled: !_saving)),
          HBFormField(label: 'events.form.region'.tr(), child: HBSelect<String>(value: _regionId, placeholder: 'events.form.region'.tr(), options: [for (final item in regions?.value ?? const []) HBSelectOption(value: item.id, label: item.name)], onChanged: _saving ? null : (value) => setState(() { _regionId = value; _unitId = null; }))),
          HBFormField(label: 'events.form.hunting_unit'.tr(), child: (units?.value ?? const []).isEmpty && _regionId != null ? HBEmptyState(icon: Icons.location_on_outlined, title: 'hunting.units_empty'.tr(namedArgs: {'region': (regions?.value ?? const []).where((item) => item.id == _regionId).firstOrNull?.name ?? ''}), message: 'hunting.units_empty_forum'.tr()) : HBSelect<String>(value: _unitId, placeholder: 'events.form.hunting_unit'.tr(), options: [for (final item in units?.value ?? const []) HBSelectOption(value: item.id, label: item.name, groupLabel: 'hunting.unit_type.${item.unitType}'.tr())], onChanged: _saving ? null : (value) => setState(() => _unitId = value))),
          HBFormField(label: 'events.form.coordinates'.tr(), child: Row(children: [Expanded(child: HBInput(controller: _latitude, hint: 'events.form.latitude'.tr(), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))], onChanged: (_) => setState(() {}))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBInput(controller: _longitude, hint: 'events.form.longitude'.tr(), keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[-0-9.,]'))], onChanged: (_) => setState(() {})))])),
          HBFormActions(primaryLabel: 'events.form.use_location'.tr(), onPrimary: _saving ? null : _usePosition),
          if (lat != null && lng != null) HBCard.media(child: EventMap(latitude: lat, longitude: lng, editable: true, onChanged: _setCoordinates)),
        ]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'events.form.participation'.tr(), children: [
          HBFormField(label: 'events.form.capacity'.tr(), child: HBInput(controller: _capacity, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], enabled: !_saving)),
          HBFormField(label: 'events.form.price'.tr(namedArgs: {'currency': settings.currencyCode}), child: HBInput(controller: _price, prefixIcon: Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), child: Center(widthFactor: 1, child: Text(settings.currencyCode))), keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))], enabled: !_saving)),
          if (!_editing) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('events.form.publish_now'.tr()), subtitle: Text((_publish ? 'events.form.publish_help' : 'events.form.draft_help').tr()), value: _publish, onChanged: _saving ? null : (value) => setState(() => _publish = value), activeColor: LightModeColors.lightPrimary),
        ]),
        if (!_editing) ...[const HBFormSectionDivider(), HBFormSection(title: 'events.form.organizer'.tr(), children: [
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBChip(label: 'events.form.organizer_me'.tr(), selected: _organizerKind == 'user', onTap: () => setState(() { _organizerKind = 'user'; _organizerId = null; })), ...pages.where((page) => page.myRole != null).map((page) => HBChip(label: page.name, selected: _organizerKind == 'page' && _organizerId == page.id, onTap: () => setState(() { _organizerKind = 'page'; _organizerId = page.id; }))), ...groups.map((group) => HBChip(label: group.name, selected: _organizerKind == 'group' && _organizerId == group.id, onTap: () => setState(() { _organizerKind = 'group'; _organizerId = group.id; })))])
        ])],
        if (_errorKey != null) ...[const SizedBox(height: AppSpacing.md), Text(_errorKey!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
        HBFormActions(primaryLabel: (_editing ? 'events.form.save' : 'events.form.create').tr(), onPrimary: _save, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.pop(), loading: _saving),
      ])))),
    ]))]));
  }
}

class HBFormDateButton extends StatelessWidget {
  final DateTime? value;
  final VoidCallback? onPressed;
  final VoidCallback? onClear;
  const HBFormDateButton({super.key, required this.value, required this.onPressed, this.onClear});
  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [Expanded(child: InkWell(onTap: onPressed, child: Container(height: 48, alignment: Alignment.centerLeft, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Text(value == null ? 'events.form.choose_date'.tr() : DateFormat.yMMMMd(context.locale.toLanguageTag()).add_jm().format(value!), maxLines: 1, overflow: TextOverflow.ellipsis)))), if (onClear != null) ...[const SizedBox(width: AppSpacing.xs), SizedBox(width: 48, height: 48, child: IconButton(onPressed: onClear, icon: const Icon(Icons.close_rounded)))]]);
}
