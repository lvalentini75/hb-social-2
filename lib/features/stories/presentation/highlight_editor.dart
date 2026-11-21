import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/stories/domain/story.dart';
import 'package:hb_social/features/stories/providers/story_providers.dart';

Future<bool> showHighlightEditor(BuildContext context, {StoryHighlight? highlight}) async => await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true, builder: (_) => HighlightEditor(highlight: highlight)) ?? false;

/// Creates a highlight or replaces the selected stories of an existing one.
class HighlightEditor extends ConsumerStatefulWidget {
  final StoryHighlight? highlight;

  const HighlightEditor({super.key, this.highlight});

  @override
  ConsumerState<HighlightEditor> createState() => _HighlightEditorState();
}

class _HighlightEditorState extends ConsumerState<HighlightEditor> {
  late final TextEditingController _title = TextEditingController(text: widget.highlight?.title ?? '');
  late final Set<String> _selected = widget.highlight?.stories.map((story) => story.id).toSet() ?? {};
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty || _title.text.trim().length > 40) return setState(() => _error = 'story_highlights.title_error'.tr());
    if (_selected.isEmpty) return setState(() => _error = 'story_highlights.selection_error'.tr());
    setState(() { _saving = true; _error = null; });
    try {
      final repository = ref.read(storyRepositoryProvider);
      if (widget.highlight == null) {
        await repository.createHighlight(_title.text, _selected.toList());
      } else {
        if (_title.text.trim() != widget.highlight!.title) await repository.renameHighlight(widget.highlight!.id, _title.text);
        await repository.updateHighlightStories(widget.highlight!.id, _selected.toList());
      }
      ref.invalidate(storyHighlightsProvider);
      if (mounted) context.pop(true);
    } catch (error) {
      final exception = AppException.from(error);
      if (mounted) setState(() { _saving = false; _error = exception.messageKey.tr(namedArgs: exception.namedArgs); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final stories = ref.watch(myHighlightStoriesProvider);
    return FractionallySizedBox(heightFactor: .9, child: Padding(padding: EdgeInsets.only(left: AppSpacing.md, right: AppSpacing.md, bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.md), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.highlight == null ? 'story_highlights.create_title'.tr() : 'story_highlights.edit_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBInput(label: 'story_highlights.title_label'.tr(), controller: _title, maxLength: 40, errorText: _error),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: stories.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'story_highlights.error_title'.tr(), message: 'story_highlights.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myHighlightStoriesProvider))),
        data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.auto_awesome_outlined, title: 'story_highlights.no_stories_title'.tr(), message: 'story_highlights.no_stories_message'.tr()) : GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 9 / 16, crossAxisSpacing: AppSpacing.sm, mainAxisSpacing: AppSpacing.sm), itemCount: items.length, itemBuilder: (context, index) {
          final story = items[index];
          final selected = _selected.contains(story.id);
          return HighlightStoryTile(story: story, selected: selected, onTap: () => setState(() => selected ? _selected.remove(story.id) : _selected.add(story.id)));
        }),
      )),
      const SizedBox(height: AppSpacing.md),
      SizedBox(width: double.infinity, child: HBButton.primary(label: widget.highlight == null ? 'story_highlights.create'.tr() : 'story_highlights.save'.tr(), onPressed: _saving ? null : _save)),
    ])));
  }
}

class HighlightStoryTile extends StatelessWidget {
  final HighlightStory story;
  final bool selected;
  final VoidCallback onTap;

  const HighlightStoryTile({super.key, required this.story, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.sm), child: Stack(fit: StackFit.expand, children: [
    ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: story.kind == 'image' ? Image.network(story.mediaUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft)) : story.thumbnailUrl?.isNotEmpty == true ? Image.network(story.thumbnailUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft)) : const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.videocam_outlined))),
    if (story.kind == 'video') const Positioned(top: AppSpacing.xs, right: AppSpacing.xs, child: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20)),
    DecoratedBox(decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: selected ? LightModeColors.lightPrimary : Colors.transparent, width: 3))),
    Positioned(bottom: AppSpacing.xs, right: AppSpacing.xs, child: Icon(selected ? Icons.check_circle : Icons.circle_outlined, color: selected ? LightModeColors.lightPrimary : Colors.white)),
    if (story.expiresAt.isBefore(DateTime.now().toUtc())) Positioned(top: AppSpacing.xs, left: AppSpacing.xs, child: DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightWarning, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), child: Text('story_highlights.expired'.tr(), style: context.textStyles.labelSmall?.copyWith(color: Colors.white))))),
    if (story.caption?.isNotEmpty == true) Positioned(left: AppSpacing.xs, right: AppSpacing.xs, bottom: AppSpacing.xs, child: Text(story.caption!, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall?.copyWith(color: Colors.white, shadows: const [Shadow(blurRadius: 4, color: Colors.black)]))),
  ]));
}

Future<bool> showAddStoryToHighlight(BuildContext context, WidgetRef ref, Story story) async => await showModalBottomSheet<bool>(context: context, useSafeArea: true, showDragHandle: true, builder: (_) => AddStoryToHighlightSheet(story: story)) ?? false;

class AddStoryToHighlightSheet extends ConsumerWidget {
  final Story story;

  const AddStoryToHighlightSheet({super.key, required this.story});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final highlights = ref.watch(storyHighlightsProvider(story.authorId));
    return SizedBox(height: MediaQuery.sizeOf(context).height * .55, child: Column(children: [
      Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('story_highlights.add_to_title'.tr(), style: context.textStyles.titleLarge)),
      ListTile(leading: const Icon(Icons.add_circle_outline), title: Text('story_highlights.new'.tr()), onTap: () async { final created = await showHighlightEditor(context); if (created && context.mounted) context.pop(true); }),
      Expanded(child: highlights.when(loading: () => const Center(child: CircularProgressIndicator()), error: (_, __) => Center(child: Text('story_highlights.error_message'.tr())), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.auto_awesome_outlined, title: 'story_highlights.empty_title'.tr(), message: 'story_highlights.empty_owner_message'.tr()) : ListView.builder(itemCount: items.length, itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(title: Text(item.title), trailing: Text('${item.storyCount}'), onTap: () async { try { await ref.read(storyRepositoryProvider).addStoryToHighlight(item.id, story.id); ref.invalidate(storyHighlightsProvider(story.authorId)); if (context.mounted) context.pop(true); } catch (_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('story_highlights.error_message'.tr()))); } });
      }))),
    ]));
  }
}