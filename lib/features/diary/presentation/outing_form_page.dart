import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/features/diary/data/diary_repository.dart';
import 'package:hb_social/features/diary/domain/outing.dart';
import 'package:hb_social/features/diary/presentation/outing_media_panel.dart';
import 'package:hb_social/features/diary/providers/diary_providers.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/events/presentation/event_map.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/map/domain/map_models.dart';
import 'package:hb_social/features/map/providers/map_providers.dart';
import 'package:hb_social/features/weather/data/weather_repository.dart';
import 'package:hb_social/features/weather/domain/weather_forecast.dart';
import 'package:hb_social/features/weather/presentation/weather_widgets.dart';
import 'package:hb_social/features/weather/providers/weather_providers.dart';
import 'package:hb_social/features/sightings/providers/sightings_providers.dart';
import 'package:latlong2/latlong.dart';

class OutingFormPage extends ConsumerStatefulWidget {
  final String? outingId;
  const OutingFormPage({super.key, this.outingId});
  @override
  ConsumerState<OutingFormPage> createState() => _OutingFormPageState();
}

class _OutingFormPageState extends ConsumerState<OutingFormPage> {
  final _title = TextEditingController();
  final _zone = TextEditingController();
  final _municipality = TextEditingController();
  final _distance = TextEditingController();
  final _notes = TextEditingController();
  DateTime _startedAt = DateTime.now();
  DateTime? _endedAt;
  Municipality? _selectedMunicipality;
  String? _regionId;
  String? _unitId;
  String? _unitType;
  UnitAtPoint? _detectedUnit;
  HuntingMethod _method = HuntingMethod.vagante;
  OutingVisibility _visibility = OutingVisibility.private;
  OutingPoint? _point;
  OutingWeather? _weather;
  List<OutingSpecies> _species = [];
  Set<String> _dogIds = {};
  String? _savedId;
  bool _loading = true;
  bool _saving = false;
  bool _weatherLoading = false;
  bool _weatherUnavailable = false;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startedAt = DateTime(now.year, now.month, now.day, now.hour, (now.minute / 15).round() * 15);
    Future.microtask(_initialize);
  }

  Future<void> _initialize() async {
    Outing? outing;
    final draft = ref.read(outingFormProvider);
    if (draft.source != null) outing = draft.source;
    if (outing == null && widget.outingId != null) outing = await ref.read(diaryRepositoryProvider).getOuting(widget.outingId!, locale: context.locale.languageCode);
    if (outing != null) {
      final duplicate = draft.duplicate;
      _title.text = outing.title ?? '';
      _zone.text = outing.zoneName ?? '';
      _municipality.text = outing.municipalityName ?? '';
      _distance.text = outing.distanceM == null ? '' : (outing.distanceM! / 1000).toStringAsFixed(1);
      _notes.text = outing.notes ?? '';
      _startedAt = duplicate ? DateTime.now() : outing.startedAt.toLocal();
      _endedAt = duplicate || outing.endedAt == null ? null : outing.endedAt!.toLocal();
      _regionId = outing.regionId;
      _unitId = outing.unitId;
      _unitType = outing.unitType;
      _method = outing.method;
      _visibility = outing.visibility;
      _point = outing.point;
      _weather = duplicate ? null : outing.weather;
      _species = [...outing.species];
      _dogIds = outing.dogs.map((dog) => dog.id).toSet();
      _savedId = duplicate ? null : outing.id;
      if (outing.municipalityId != null) _selectedMunicipality = await ref.read(referenceRepositoryProvider).getMunicipality(outing.municipalityId!);
    } else {
      final settings = ref.read(userSettingsProvider);
      if (draft.startedAt != null) _startedAt = draft.startedAt!;
      _regionId = settings.regionId;
      _unitId = settings.unitId;
      final municipalityId = draft.municipalityId ?? settings.municipalityId;
      if (municipalityId != null) {
        _selectedMunicipality = await ref.read(referenceRepositoryProvider).getMunicipality(municipalityId);
        _municipality.text = _selectedMunicipality?.compactName ?? '';
      }
    }
    ref.read(outingFormProvider.notifier).clear();
    if (mounted) { setState(() => _loading = false); if (_weather == null) _refreshWeather(); }
  }

  @override
  void dispose() { _title.dispose(); _zone.dispose(); _municipality.dispose(); _distance.dispose(); _notes.dispose(); super.dispose(); }

  Future<void> _pickDateTime(bool end) async {
    final initial = end ? _endedAt ?? _startedAt.add(const Duration(hours: 3)) : _startedAt;
    final date = await showDatePicker(context: context, initialDate: initial, firstDate: DateTime.now().subtract(const Duration(days: 3650)), lastDate: DateTime.now().add(const Duration(days: 365)));
    if (date == null || !mounted) return;
    final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(initial));
    if (time == null) return;
    setState(() { final value = DateTime(date.year, date.month, date.day, time.hour, time.minute); if (end) _endedAt = value; else _startedAt = value; });
    if (!end) _refreshWeather();
  }

  Future<void> _locate() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) throw const AppException('diary.errors.location_denied');
      final value = await Geolocator.getCurrentPosition();
      setState(() => _point = OutingPoint(lat: value.latitude, lng: value.longitude, accuracyM: value.accuracy));
      await _detectUnit(value.latitude, value.longitude);
      _refreshWeather();
    } on AppException catch (error) { if (mounted) _message(error.messageKey); }
  }

  Future<void> _detectUnit(double? lat, double? lng) async {
    if (lat == null || lng == null) return;
    try {
      final unit = await ref.read(mapRepositoryProvider).unitAt(lat, lng);
      if (!mounted || unit == null) return;
      setState(() { _detectedUnit = unit; if (_unitId == null) { _unitId = unit.id; _unitType = unit.unitType; _regionId = unit.regionId ?? _regionId; } });
    } on AppException catch (error) { if (mounted) _message(error.messageKey); }
  }

  Future<void> _refreshWeather() async {
    if (_selectedMunicipality == null && _point == null) return;
    final oldest = DateTime.now().subtract(const Duration(days: 92));
    final newest = DateTime.now().add(const Duration(days: 7));
    if (_startedAt.isBefore(DateTime(oldest.year, oldest.month, oldest.day)) || _startedAt.isAfter(newest)) { setState(() { _weatherUnavailable = true; _weather = null; }); return; }
    setState(() { _weatherLoading = true; _weatherUnavailable = false; });
    try {
      final forecast = await ref.read(weatherRepositoryProvider).fetch(municipalityId: _point == null ? _selectedMunicipality?.id : null, lat: _point?.lat, lng: _point?.lng, date: _startedAt, forceRefresh: true);
      if (forecast.hourly.isEmpty) throw const AppException('weather.unavailable');
      final hour = forecast.hourly.reduce((a, b) => (a.time.difference(_startedAt).abs() <= b.time.difference(_startedAt).abs()) ? a : b);
      setState(() => _weather = _snapshot(forecast, hour));
    } catch (_) { if (mounted) setState(() { _weather = null; _weatherUnavailable = true; }); }
    finally { if (mounted) setState(() => _weatherLoading = false); }
  }

  OutingWeather _snapshot(WeatherForecast forecast, WeatherHour hour) => OutingWeather(temperature: hour.temperature, apparentTemperature: hour.apparentTemperature, weatherCode: hour.weatherCode, windSpeed: hour.windSpeed, windDirection: hour.windDirection, precipitation: hour.precipitation, humidity: hour.humidity, moonPhaseName: forecast.moon.phaseName, moonIllumination: forecast.moon.illumination, hour: DateFormat.Hm().format(hour.time), source: 'open-meteo', fetchedAt: forecast.fetchedAt);

  Future<void> _addDog() async {
    final dog = await showDialog<({String name, String? breedId, String? sex})>(context: context, builder: (_) => const QuickDogDialog());
    if (dog == null) return;
    try { final repository = ref.read(dogsRepositoryProvider); final id = await repository.upsert(DogInput(name: dog.name, breedId: dog.breedId, sex: dog.sex)); ref.invalidate(myDogsProvider); ref.invalidate(dogsOfProvider(repository.currentUserId)); setState(() => _dogIds.add(id)); }
    on AppException catch (error) { if (mounted) _message(error.messageKey); }
  }

  Future<void> _addSpecies() async {
    final all = await ref.read(speciesProvider.future);
    if (!mounted) return;
    final available = all.where((item) => !_species.any((row) => row.speciesId == item.id)).toList();
    final species = await showDialog<Species>(context: context, builder: (_) => SpeciesPickerDialog(items: available));
    if (species != null) setState(() => _species.add(OutingSpecies(speciesId: species.id, scientificName: species.scientificName, name: species.localizedName, category: species.category, harvestCount: 0, seenCount: 0, shots: 0)));
  }

  Future<void> _save() async {
    if (_endedAt != null && !_endedAt!.isAfter(_startedAt)) return _message('diary.errors.dates_invalid');
    setState(() => _saving = true);
    try {
      final id = await ref.read(diaryRepositoryProvider).upsertOuting(OutingInput(id: _savedId, startedAt: _startedAt, endedAt: _endedAt, title: _title.text.trim().isEmpty ? null : _title.text.trim(), zoneName: _zone.text.trim().isEmpty ? null : _zone.text.trim(), regionId: _regionId, huntingUnitId: _unitId, municipalityId: _selectedMunicipality?.id, method: _method, notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(), visibility: _visibility, distanceM: _distance.text.trim().isEmpty ? null : (double.parse(_distance.text.replaceAll(',', '.')) * 1000).round(), weather: _weather, point: _point, species: _species, dogIds: _dogIds.toList()));
      _savedId = id;
      ref.invalidate(diarySeasonsProvider(null));
      ref.invalidate(diaryStatsProvider);
      ref.invalidate(todayOutingProvider);
      ref.invalidate(outingsProvider((userId: null, season: null)));
      ref.invalidate(outingProvider(id));
      if (mounted) context.go(AppRoutes.diaryDetailPath(id));
    } on AppException catch (error) { if (mounted) _message(error.messageKey); }
    catch (_) { if (mounted) _message('diary.errors.generic'); }
    finally { if (mounted) setState(() => _saving = false); }
  }

  void _message(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final settings = ref.watch(userSettingsProvider);
    final regions = settings.countryCode == null ? const <ReferenceRegion>[] : ref.watch(regionsProvider(settings.countryCode!)).value ?? const [];
    final units = _regionId == null ? const <HuntingUnit>[] : ref.watch(huntingUnitsByRegionProvider(_regionId!)).value ?? const [];
    final types = settings.countryCode == null ? const <HuntingUnitTypeInfo>[] : ref.watch(unitTypesProvider(settings.countryCode!)).value ?? const [];
    final dogs = (ref.watch(myDogsProvider).value ?? const <Dog>[]).where((dog) => dog.status != DogStatus.deceased).toList();
    final duration = _endedAt?.difference(_startedAt);
    return CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverToBoxAdapter(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text((_savedId == null ? 'diary.form.new_title' : 'diary.form.edit_title').tr(), style: context.textStyles.headlineSmall)), HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.canPop() ? context.pop() : context.go(AppRoutes.diary))]),
      const SizedBox(height: AppSpacing.lg),
      HBCard(child: Column(children: [
        HBFormSection(title: 'diary.form.when'.tr(), children: [HBFormField(label: 'diary.form.started_at'.tr(), required: true, child: DateTimeButton(value: _startedAt, onTap: () => _pickDateTime(false))), HBFormField(label: 'diary.form.ended_at'.tr(), child: DateTimeButton(value: _endedAt, onTap: () => _pickDateTime(true), onClear: _endedAt == null ? null : () => setState(() => _endedAt = null))), if (duration != null) Align(alignment: Alignment.centerLeft, child: Text('diary.duration_minutes'.tr(namedArgs: {'n': duration.inMinutes.toString()})))]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'diary.form.where'.tr(), children: [
          HBFormField(label: 'diary.form.municipality'.tr(), child: HBPlaceField<Municipality>(controller: _municipality, hint: 'diary.form.search_municipality'.tr(), search: (query) async => [for (final item in await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: settings.countryCode ?? 'IT')) HBPlaceSuggestion(value: item, title: item.compactName, subtitle: item.regionName)], onSelected: (value) { setState(() { _selectedMunicipality = value; _regionId = value.regionId; _unitId = null; _detectedUnit = null; }); _detectUnit(value.lat, value.lng); _refreshWeather(); })),
          HBFormField(label: 'diary.form.zone'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBInput(controller: _zone, hint: 'diary.form.zone_hint'.tr()), FutureBuilder<List<String>>(future: ref.read(diaryRepositoryProvider).zoneSuggestions(), builder: (_, snapshot) { final values = snapshot.data ?? const []; if (values.isEmpty) return const SizedBox.shrink(); return Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final value in values.take(8)) HBChip(label: value, selected: _zone.text == value, onTap: () => setState(() => _zone.text = value))])); })])),
          HBFormField(label: 'diary.form.region'.tr(), child: HBSelect<String>(value: _regionId, options: [for (final item in regions) HBSelectOption(value: item.id, label: item.name)], onChanged: (value) => setState(() { _regionId = value; _unitId = null; }))),
          HBFormField(label: 'diary.form.unit_type'.tr(), child: HBSelect<String>(value: _unitType, options: [for (final item in types) HBSelectOption(value: item.code, label: item.nameKey.tr())], allowClear: true, onChanged: (value) => setState(() { _unitType = value; _unitId = null; }))),
          HBFormField(label: 'diary.form.unit'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBSelect<String>(value: _unitId, options: [for (final item in units.where((item) => _unitType == null || item.unitType == _unitType)) HBSelectOption(value: item.id, label: item.name)], allowClear: true, onChanged: (value) => setState(() => _unitId = value)), if (_detectedUnit != null && _unitId == _detectedUnit!.id) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: HBChip(label: 'map.unit_from_position'.tr(namedArgs: {'name': _detectedUnit!.name}), selected: true, icon: Icons.my_location_rounded))])),
          HBFormField(label: 'diary.form.private_position'.tr(), helper: 'diary.form.private_position_help'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (_point == null) HBButton.secondary(label: 'diary.form.save_position'.tr(), icon: Icons.my_location_rounded, onPressed: _locate) else ...[EventMap(latitude: _point!.lat, longitude: _point!.lng, editable: true, onChanged: (LatLng value) { setState(() => _point = OutingPoint(lat: value.latitude, lng: value.longitude, accuracyM: _point?.accuracyM)); if (_unitId == null) _detectUnit(value.latitude, value.longitude); }), const SizedBox(height: AppSpacing.sm), HBButton.ghost(label: 'diary.form.remove_position'.tr(), onPressed: () => setState(() { _point = null; _detectedUnit = null; }))]])),
        ]),
        const HBFormSectionDivider(),
          HBFormSection(title: 'diary.form.how'.tr(), children: [HBChoice<HuntingMethod>(options: HuntingMethod.values, value: _method, onChanged: (value) => setState(() => _method = value), labelBuilder: (value) => value.labelKey.tr()), HBFormField(label: 'diary.form.distance'.tr(), child: HBInput(controller: _distance, keyboardType: const TextInputType.numberWithOptions(decimal: true), suffixIcon: Padding(padding: const EdgeInsets.all(14), child: Text('diary.units.km'.tr())))), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final dog in dogs) Row(mainAxisSize: MainAxisSize.min, children: [HBAvatar(name: dog.name, imageUrl: dog.avatarUrl, size: 28), const SizedBox(width: AppSpacing.xs), HBChip(label: dog.status == DogStatus.retired ? '${dog.name} · ${dog.status.labelKey.tr()}' : dog.name, selected: _dogIds.contains(dog.id), onTap: () => setState(() => _dogIds.contains(dog.id) ? _dogIds.remove(dog.id) : _dogIds.add(dog.id)))]), HBChip(label: 'diary.form.add_dog'.tr(), selected: false, icon: Icons.add_rounded, onTap: _addDog)])]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'diary.form.species'.tr(), children: [for (var index = 0; index < _species.length; index++) SpeciesFormRow(value: _species[index], onChanged: (value) => setState(() => _species[index] = value), onRemove: () => setState(() => _species.removeAt(index)), onSighting: () { ref.read(sightingFormPrefillProvider.notifier).state = SightingFormPrefill(logId: _savedId, sightedAt: _startedAt, lat: _point?.lat, lng: _point?.lng, accuracyM: _point?.accuracyM, municipalityId: _selectedMunicipality?.id, speciesId: _species[index].speciesId); context.push(AppRoutes.sightingsNew); }), HBButton.secondary(label: 'diary.form.add_species'.tr(), icon: Icons.add_rounded, onPressed: _addSpecies)]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'diary.form.weather'.tr(), children: [WeatherSnapshotPreview(weather: _weather, loading: _weatherLoading, unavailable: _weatherUnavailable), HBButton.soft(label: 'diary.form.refresh_weather'.tr(), icon: Icons.refresh_rounded, onPressed: _weatherLoading ? null : _refreshWeather)]),
        const HBFormSectionDivider(),
        HBFormSection(title: 'diary.form.details'.tr(), children: [HBFormField(label: 'diary.form.title'.tr(), child: HBInput(controller: _title, maxLength: 80)), HBFormField(label: 'diary.form.notes'.tr(), child: HBInput(controller: _notes, maxLines: 6, maxLength: 5000)), HBFormField(label: 'diary.form.visibility'.tr(), child: HBChoice<OutingVisibility>(options: OutingVisibility.values, value: _visibility, onChanged: (value) => setState(() => _visibility = value), labelBuilder: (value) => value.labelKey.tr(), descriptions: {for (final value in OutingVisibility.values) value: 'diary.visibility_description.${value.code}'.tr()}))]),
        HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _save, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.canPop() ? context.pop() : context.go(AppRoutes.diary), loading: _saving),
      ])),
      if (_savedId != null) ...[const SizedBox(height: AppSpacing.lg), OutingMediaPanel(outingId: _savedId!, editable: true)],
      const SizedBox(height: AppSpacing.xxl),
    ])))))]);
  }
}

class DateTimeButton extends StatelessWidget {
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;
  const DateTimeButton({super.key, required this.value, required this.onTap, this.onClear});
  @override
  Widget build(BuildContext context) => Row(children: [Expanded(child: HBButton.secondary(label: value == null ? 'diary.form.select_date'.tr() : DateFormat.yMMMd(context.locale.languageCode).add_Hm().format(value!), icon: Icons.schedule_rounded, onPressed: onTap)), if (onClear != null) HBButton.icon(icon: Icons.close_rounded, onPressed: onClear)]);
}

class SpeciesFormRow extends StatelessWidget {
  final OutingSpecies value;
  final ValueChanged<OutingSpecies> onChanged;
  final VoidCallback onRemove;
  final VoidCallback? onSighting;
  const SpeciesFormRow({super.key, required this.value, required this.onChanged, required this.onRemove, this.onSighting});
  OutingSpecies _copy({int? seen, int? shots, int? harvest}) => OutingSpecies(speciesId: value.speciesId, scientificName: value.scientificName, name: value.name, category: value.category, seenCount: seen ?? value.seenCount, shots: shots ?? value.shots, harvestCount: harvest ?? value.harvestCount, notes: value.notes);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Column(children: [Row(children: [Expanded(child: Text(value.name, style: context.textStyles.titleSmall)), HBButton.icon(icon: Icons.close_rounded, onPressed: onRemove)]), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.md, runSpacing: AppSpacing.sm, children: [CountStepper(label: 'diary.form.seen'.tr(), value: value.seenCount, onChanged: (n) => onChanged(_copy(seen: n))), CountStepper(label: 'diary.form.shots'.tr(), value: value.shots, onChanged: (n) => onChanged(_copy(shots: n))), CountStepper(label: 'diary.form.harvested'.tr(), value: value.harvestCount, onChanged: (n) => onChanged(_copy(harvest: n)))]), if (onSighting != null) Align(alignment: Alignment.centerLeft, child: HBButton.ghost(label: 'sightings.outing_section.register'.tr(), icon: Icons.visibility_outlined, onPressed: onSighting)) ]));
}

class CountStepper extends StatelessWidget {
  final String label; final int value; final ValueChanged<int> onChanged;
  const CountStepper({super.key, required this.label, required this.value, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(children: [Text(label, style: context.textStyles.labelSmall), Row(mainAxisSize: MainAxisSize.min, children: [IconButton(onPressed: value == 0 ? null : () => onChanged(value - 1), icon: const Icon(Icons.remove_circle_outline)), Text('$value', style: context.textStyles.titleMedium), IconButton(onPressed: () => onChanged(value + 1), icon: const Icon(Icons.add_circle_outline))])]);
}

class WeatherSnapshotPreview extends StatelessWidget {
  final OutingWeather? weather; final bool loading; final bool unavailable;
  const WeatherSnapshotPreview({super.key, required this.weather, required this.loading, required this.unavailable});
  @override
  Widget build(BuildContext context) {
    if (loading) return const LinearProgressIndicator();
    if (weather == null) return Text((unavailable ? 'diary.form.weather_unavailable' : 'diary.form.weather_waiting').tr());
    return Row(children: [WeatherConditionIcon(code: weather!.weatherCode ?? 0, isDay: weather!.isDay, size: 32), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('${weather!.temperature?.round()}° · ${'diary.weather.wind'.tr()} ${weather!.windSpeed?.round()} km/h · ${'diary.weather.rain'.tr()} ${weather!.precipitation?.toStringAsFixed(1)} mm · ${weather!.moonPhaseName ?? ''}'))]);
  }
}

class SpeciesPickerDialog extends StatefulWidget {
  final List<Species> items;
  const SpeciesPickerDialog({super.key, required this.items});
  @override
  State<SpeciesPickerDialog> createState() => _SpeciesPickerDialogState();
}
class _SpeciesPickerDialogState extends State<SpeciesPickerDialog> {
  String query = '';
  @override
  Widget build(BuildContext context) { final items = widget.items.where((item) => item.localizedName.toLowerCase().contains(query.toLowerCase())).toList(); return AlertDialog(title: Text('diary.form.add_species'.tr()), content: SizedBox(width: 420, height: 420, child: Column(children: [HBInput(hint: 'common.search'.tr(), onChanged: (value) => setState(() => query = value)), const SizedBox(height: AppSpacing.sm), Expanded(child: ListView.builder(itemCount: items.length, itemBuilder: (_, i) => ListTile(title: Text(items[i].localizedName), subtitle: Text(items[i].scientificName), onTap: () => context.pop(items[i]))))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop())]); }
}

class QuickDogDialog extends ConsumerStatefulWidget {
  const QuickDogDialog({super.key});
  @override
  ConsumerState<QuickDogDialog> createState() => _QuickDogDialogState();
}
class _QuickDogDialogState extends ConsumerState<QuickDogDialog> {
  final name = TextEditingController(); String? breedId; String? sex;
  @override
  void dispose() { name.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) { final breeds = ref.watch(dogBreedsProvider).value ?? const <DogBreed>[]; return AlertDialog(title: Text('diary.form.add_dog'.tr()), content: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(controller: name, hint: 'diary.form.dog_name'.tr()), const SizedBox(height: AppSpacing.md), HBSelect<String>(value: breedId, placeholder: 'diary.form.dog_breed'.tr(), options: [for (final breed in breeds) HBSelectOption(value: breed.id, label: breed.localizedName(context.locale.languageCode), groupLabel: 'dogs.fci_group_short'.tr(namedArgs: {'group': '${breed.fciGroup}'}))], onChanged: (value) => setState(() => breedId = value)), const SizedBox(height: AppSpacing.md), HBSelect<String>(value: sex, options: [HBSelectOption(value: 'male', label: 'dogs.sex.male'.tr()), HBSelectOption(value: 'female', label: 'dogs.sex.female'.tr())], onChanged: (value) => setState(() => sex = value))]), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'diary.actions.add'.tr(), onPressed: () { if (name.text.trim().isNotEmpty) context.pop((name: name.text.trim(), breedId: breedId, sex: sex)); })]); }
}