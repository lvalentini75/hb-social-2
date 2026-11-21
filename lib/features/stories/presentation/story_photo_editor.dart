import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/comments/domain/post_comment.dart';
import 'package:hb_social/features/comments/providers/comments_providers.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';
import 'package:hb_social/features/dogs/providers/dog_providers.dart';
import 'package:hb_social/features/hunting/domain/hunting_unit.dart';
import 'package:hb_social/features/hunting/domain/species.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/hunting_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

enum StoryOverlayKind { text, sticker, emoji }

class StoryEditorOverlay {
  final String id;
  final StoryOverlayKind kind;
  final String value;
  final IconData? icon;
  final Color color;
  final Offset position;

  const StoryEditorOverlay({required this.id, required this.kind, required this.value, required this.color, required this.position, this.icon});

  StoryEditorOverlay copyWith({String? value, Color? color, Offset? position}) => StoryEditorOverlay(id: id, kind: kind, value: value ?? this.value, color: color ?? this.color, position: position ?? this.position, icon: icon);
}

class StoryPhotoEditorController {
  Future<Uint8List> Function()? _export;

  Future<Uint8List> exportImage() async {
    final export = _export;
    if (export == null) throw const AppException('errors.image_processing_failed');
    return export();
  }
}

/// Edits a photo in memory and flattens all overlays into the uploaded image.
class StoryPhotoEditor extends ConsumerStatefulWidget {
  final Uint8List imageBytes;
  final StoryPhotoEditorController controller;
  final bool enabled;

  const StoryPhotoEditor({super.key, required this.imageBytes, required this.controller, this.enabled = true});

  @override
  ConsumerState<StoryPhotoEditor> createState() => _StoryPhotoEditorState();
}

class _StoryPhotoEditorState extends ConsumerState<StoryPhotoEditor> {
  static const _colors = [Colors.white, LightModeColors.lightOnSurface, LightModeColors.lightPrimary, LightModeColors.lightWarning, LightModeColors.lightError, LightModeColors.lightInfo];
  final _boundaryKey = GlobalKey();
  final _overlays = <StoryEditorOverlay>[];
  String? _selectedId;
  Color _activeColor = Colors.white;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    widget.controller._export = _exportImage;
  }

  @override
  void didUpdateWidget(covariant StoryPhotoEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.controller._export = _exportImage;
  }

  @override
  void dispose() {
    if (widget.controller._export == _exportImage) widget.controller._export = null;
    super.dispose();
  }

  Future<Uint8List> _exportImage() async {
    setState(() { _exporting = true; _selectedId = null; });
    await WidgetsBinding.instance.endOfFrame;
    try {
      final boundary = _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) throw const AppException('errors.image_processing_failed');
      final pixelRatio = (1080 / boundary.size.width).clamp(1.0, 3.0).toDouble();
      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) throw const AppException('errors.image_processing_failed');
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  void _addText() => _addOverlay(StoryOverlayKind.text, '');

  Future<void> _pickSticker() async {
    final value = await showDialog<StoryStickerChoice>(context: context, builder: (_) => const StoryStickerPicker());
    if (value == null || !mounted) return;
    _addOverlay(StoryOverlayKind.sticker, value.label, icon: value.icon);
  }

  Future<void> _pickEmoji() async {
    final value = await showDialog<String>(context: context, builder: (_) => const StoryEmojiPicker());
    if (value == null || !mounted) return;
    _addOverlay(StoryOverlayKind.emoji, value);
  }

  void _addOverlay(StoryOverlayKind kind, String value, {IconData? icon}) {
    final id = DateTime.now().microsecondsSinceEpoch.toString();
    setState(() {
      _overlays.add(StoryEditorOverlay(id: id, kind: kind, value: value, color: _activeColor, position: const Offset(0.5, 0.5), icon: icon));
      _selectedId = id;
    });
  }

  void _moveOverlay(String id, Offset delta, Size size) {
    final index = _overlays.indexWhere((overlay) => overlay.id == id);
    if (index < 0) return;
    final current = _overlays[index];
    final next = Offset((current.position.dx + delta.dx / size.width).clamp(0.08, 0.92), (current.position.dy + delta.dy / size.height).clamp(0.05, 0.95));
    setState(() => _overlays[index] = current.copyWith(position: next));
  }

  void _setColor(Color color) {
    setState(() {
      _activeColor = color;
      final index = _overlays.indexWhere((overlay) => overlay.id == _selectedId);
      if (index >= 0 && _overlays[index].kind == StoryOverlayKind.text) _overlays[index] = _overlays[index].copyWith(color: color);
    });
  }

  void _setText(String id, String value) {
    final index = _overlays.indexWhere((overlay) => overlay.id == id);
    if (index >= 0) _overlays[index] = _overlays[index].copyWith(value: value);
  }

  void _deleteSelected() => setState(() => _overlays.removeWhere((overlay) => overlay.id == _selectedId));

  @override
  Widget build(BuildContext context) => Stack(children: [
    Positioned.fill(child: LayoutBuilder(builder: (context, constraints) => GestureDetector(
      onTap: () => setState(() => _selectedId = null),
      child: RepaintBoundary(key: _boundaryKey, child: ColoredBox(color: Colors.black, child: Stack(fit: StackFit.expand, children: [
        Image.memory(widget.imageBytes, fit: BoxFit.contain),
        for (final overlay in _overlays)
          Align(alignment: Alignment(overlay.position.dx * 2 - 1, overlay.position.dy * 2 - 1), child: GestureDetector(
            onTap: () => setState(() => _selectedId = overlay.id),
            onPanUpdate: widget.enabled ? (details) => _moveOverlay(overlay.id, details.delta, constraints.biggest) : null,
            child: StoryOverlayView(overlay: overlay, selected: !_exporting && _selectedId == overlay.id, onTextChanged: (value) => _setText(overlay.id, value)),
          )),
      ]))),
    ))),
    if (!_exporting) Positioned(left: 0, right: 0, bottom: 0, child: StoryPhotoEditorToolbar(
        colors: _colors,
        activeColor: _activeColor,
        hasSelection: _selectedId != null,
        enabled: widget.enabled,
        onAddText: _addText,
        onAddSticker: _pickSticker,
        onAddEmoji: _pickEmoji,
        onColor: _setColor,
        onDelete: _deleteSelected,
      )),
  ]);
}

class StoryOverlayView extends StatelessWidget {
  final StoryEditorOverlay overlay;
  final bool selected;
  final ValueChanged<String> onTextChanged;

  const StoryOverlayView({super.key, required this.overlay, required this.selected, required this.onTextChanged});

  @override
  Widget build(BuildContext context) {
    final content = switch (overlay.kind) {
      StoryOverlayKind.text when selected => SizedBox(width: 220, child: TextFormField(key: ValueKey(overlay.id), initialValue: overlay.value, autofocus: true, maxLength: 80, textAlign: TextAlign.center, onChanged: onTextChanged, style: context.textStyles.titleLarge?.copyWith(color: overlay.color, fontWeight: FontWeight.w800, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)]), decoration: InputDecoration(counterText: '', hintText: 'story_editor.text_hint'.tr(), hintStyle: context.textStyles.titleLarge?.copyWith(color: Colors.white70), border: InputBorder.none))),
      StoryOverlayKind.text => Text(overlay.value, textAlign: TextAlign.center, style: context.textStyles.titleLarge?.copyWith(color: overlay.color, fontWeight: FontWeight.w800, shadows: const [Shadow(color: Colors.black54, blurRadius: 4)])),
      StoryOverlayKind.sticker => Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: LightModeColors.lightForest, borderRadius: BorderRadius.circular(AppRadius.sm), boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(overlay.icon, color: Colors.white, size: 18), const SizedBox(width: 6), Text(overlay.value, style: context.textStyles.labelLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w800))])),
      StoryOverlayKind.emoji => Text(overlay.value, style: const TextStyle(fontSize: 48)),
    };
    return Container(padding: const EdgeInsets.all(3), decoration: BoxDecoration(border: selected ? Border.all(color: Colors.white, width: 2) : null, borderRadius: BorderRadius.circular(AppRadius.sm)), child: content);
  }
}

class StoryPhotoEditorToolbar extends StatelessWidget {
  final List<Color> colors;
  final Color activeColor;
  final bool hasSelection;
  final bool enabled;
  final VoidCallback onAddText;
  final VoidCallback onAddSticker;
  final VoidCallback onAddEmoji;
  final ValueChanged<Color> onColor;
  final VoidCallback onDelete;

  const StoryPhotoEditorToolbar({super.key, required this.colors, required this.activeColor, required this.hasSelection, required this.enabled, required this.onAddText, required this.onAddSticker, required this.onAddEmoji, required this.onColor, required this.onDelete});

  @override
  Widget build(BuildContext context) => ColoredBox(color: LightModeColors.lightOnSurface, child: Padding(padding: const EdgeInsets.all(AppSpacing.sm), child: Column(mainAxisSize: MainAxisSize.min, children: [
    Row(children: [
      Expanded(child: HBButton.soft(label: 'story_editor.text'.tr(), icon: Icons.text_fields_rounded, onPressed: enabled ? onAddText : null, size: HBButtonSize.sm)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: HBButton.soft(label: 'story_editor.stickers'.tr(), icon: Icons.sell_outlined, onPressed: enabled ? onAddSticker : null, size: HBButtonSize.sm)),
      const SizedBox(width: AppSpacing.xs),
      Expanded(child: HBButton.soft(label: 'story_editor.emoji'.tr(), icon: Icons.emoji_emotions_outlined, onPressed: enabled ? onAddEmoji : null, size: HBButtonSize.sm)),
      if (hasSelection) ...[const SizedBox(width: AppSpacing.xs), HBButton.icon(icon: Icons.delete_outline_rounded, onPressed: enabled ? onDelete : null, size: HBButtonSize.sm, backgroundColor: Colors.white12, foregroundColor: Colors.white)],
    ]),
    const SizedBox(height: AppSpacing.sm),
    Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (final color in colors) Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: InkWell(onTap: enabled ? () => onColor(color) : null, customBorder: const CircleBorder(), child: Container(width: 24, height: 24, decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: Border.all(color: color == activeColor ? LightModeColors.lightPrimaryOutline : Colors.white38, width: color == activeColor ? 3 : 1)))))]),
  ])));
}

class StoryStickerChoice {
  final String label;
  final IconData icon;

  const StoryStickerChoice(this.label, this.icon);
}

enum StoryStickerCategory { location, weather, prey, milestones }

class StoryStickerPicker extends ConsumerStatefulWidget {
  const StoryStickerPicker({super.key});

  @override
  ConsumerState<StoryStickerPicker> createState() => _StoryStickerPickerState();
}

class _StoryStickerPickerState extends ConsumerState<StoryStickerPicker> {
  StoryStickerCategory _category = StoryStickerCategory.location;
  final _mentionController = TextEditingController();
  Timer? _mentionDebounce;
  List<PostAuthor> _mentions = const [];
  bool _searchingMentions = false;

  @override
  void dispose() {
    _mentionDebounce?.cancel();
    _mentionController.dispose();
    super.dispose();
  }

  void _searchMentions(String term) {
    _mentionDebounce?.cancel();
    if (term.trim().length < 2) {
      setState(() { _mentions = const []; _searchingMentions = false; });
      return;
    }
    setState(() => _searchingMentions = true);
    _mentionDebounce = Timer(const Duration(milliseconds: 300), () async {
      try {
        final results = await ref.read(commentsRepositoryProvider).searchMentions(term.trim());
        if (mounted) setState(() { _mentions = results; _searchingMentions = false; });
      } catch (_) {
        if (mounted) setState(() { _mentions = const []; _searchingMentions = false; });
      }
    });
  }

  void _choose(String label, IconData icon) => context.pop(StoryStickerChoice(label, icon));

  List<StoryStickerChoice> get _weatherChoices => [
    StoryStickerChoice('story_editor.weather_sunny'.tr(), Icons.wb_sunny_outlined),
    StoryStickerChoice('story_editor.weather_cloudy'.tr(), Icons.cloud_outlined),
    StoryStickerChoice('story_editor.weather_rain'.tr(), Icons.water_drop_outlined),
    StoryStickerChoice('story_editor.weather_snow'.tr(), Icons.ac_unit_rounded),
    StoryStickerChoice('story_editor.weather_wind'.tr(), Icons.air_rounded),
    StoryStickerChoice('story_editor.weather_fog'.tr(), Icons.foggy),
  ];

  List<StoryStickerChoice> get _milestoneChoices => [
    StoryStickerChoice('story_editor.milestone_first_outing'.tr(), Icons.flag_outlined),
    StoryStickerChoice('story_editor.milestone_goal'.tr(), Icons.gps_fixed_rounded),
    StoryStickerChoice('story_editor.milestone_personal_best'.tr(), Icons.emoji_events_outlined),
    StoryStickerChoice('story_editor.milestone_memorable_day'.tr(), Icons.auto_awesome_outlined),
    StoryStickerChoice('story_editor.sticker_hunting'.tr(), Icons.forest_outlined),
    StoryStickerChoice('story_editor.sticker_driven_hunt'.tr(), Icons.groups_outlined),
    StoryStickerChoice('story_editor.sticker_stand'.tr(), Icons.visibility_outlined),
    StoryStickerChoice('story_editor.sticker_tracking'.tr(), Icons.pets_outlined),
  ];

  Widget _choices(List<StoryStickerChoice> choices) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final choice in choices) HBButton.soft(label: choice.label, icon: choice.icon, onPressed: () => _choose(choice.label, choice.icon))]);

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentProfileProvider).value;
    final regions = profile == null ? const <ReferenceRegion>[] : ref.watch(regionsProvider(profile.countryCode)).value ?? const <ReferenceRegion>[];
    String? regionName;
    for (final region in regions) {
      if (region.id == profile?.homeRegionId) regionName = region.name;
    }
    final units = profile?.homeRegionId == null ? const <HuntingUnit>[] : ref.watch(huntingUnitsByRegionProvider(profile!.homeRegionId!)).value ?? const [];
    final species = ref.watch(speciesProvider).value ?? const <Species>[];
    final dogs = (ref.watch(myDogsProvider).value ?? const <Dog>[]).where((dog) => dog.status == DogStatus.active).toList();
    final locationChoices = [if (regionName != null) StoryStickerChoice(regionName, Icons.map_outlined), for (final unit in units) StoryStickerChoice(unit.name, Icons.place_outlined)];
    return AlertDialog(
      title: Text('story_editor.choose_sticker'.tr()),
      content: SizedBox(width: 520, height: 420, child: Column(children: [
        Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [
          for (final category in StoryStickerCategory.values) HBChip(label: 'story_editor.category_${category.name}'.tr(), selected: _category == category, onTap: () => setState(() => _category = category)),
        ]),
        const SizedBox(height: AppSpacing.md),
        Expanded(child: SingleChildScrollView(child: switch (_category) {
          StoryStickerCategory.location => locationChoices.isEmpty ? Text('story_editor.no_location'.tr()) : _choices(locationChoices),
          StoryStickerCategory.weather => _choices(_weatherChoices),
          StoryStickerCategory.prey => species.isEmpty ? Text('story_editor.no_species'.tr()) : _choices([for (final item in species) StoryStickerChoice(item.localizedName, Icons.cruelty_free_outlined)]),
          StoryStickerCategory.milestones => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _choices(_milestoneChoices),
            if (dogs.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), Text('story_editor.my_dogs'.tr(), style: context.textStyles.titleSmall), const SizedBox(height: AppSpacing.sm), _choices([for (final dog in dogs) StoryStickerChoice(dog.name, Icons.pets_outlined)])],
            const SizedBox(height: AppSpacing.md),
            HBInput(controller: _mentionController, label: 'story_editor.mention'.tr(), hint: 'story_editor.mention_hint'.tr(), prefixIcon: const Icon(Icons.alternate_email_rounded), onChanged: _searchMentions),
            if (_searchingMentions) const Padding(padding: EdgeInsets.all(AppSpacing.sm), child: LinearProgressIndicator()),
            if (_mentions.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), _choices([for (final author in _mentions) StoryStickerChoice('@${author.username}', Icons.person_outline_rounded)])],
          ]),
        })),
      ])),
      actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop())],
    );
  }
}

class StoryEmojiPicker extends StatelessWidget {
  static const choices = ['😀','😃','😄','😁','😆','😅','😂','🤣','😊','😇','🙂','🙃','😉','😍','🥰','😘','😎','🤩','🥳','😏','😮','😱','🤔','🤫','🤭','😴','🤠','👍','👎','👏','🙌','🤝','🙏','💪','👀','❤️','🧡','💛','💚','💙','💜','🖤','🤍','💯','🔥','✨','⭐','🎉','🎯','🏆','🥇','📍','⏱️','☀️','🌤️','☁️','🌧️','⛈️','❄️','🌫️','💨','🌙','🌲','🌳','🍂','🍁','⛰️','🏕️','🐕','🐶','🦌','🐗','🦆','🦅','🐇','🦊','🐺','🐻','🐾','🪶','🔭','🧭','🎒','🥾','🚙','📷','🎥'];

  const StoryEmojiPicker({super.key});

  @override
  Widget build(BuildContext context) => AlertDialog(title: Text('story_editor.choose_emoji'.tr()), content: SizedBox(width: 460, height: 420, child: GridView.count(crossAxisCount: 7, children: [for (final emoji in choices) InkWell(onTap: () => context.pop(emoji), borderRadius: BorderRadius.circular(AppRadius.sm), child: Center(child: Text(emoji, style: const TextStyle(fontSize: 30))))])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop())]);
}