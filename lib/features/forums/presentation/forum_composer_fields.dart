import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/features/comments/domain/post_comment.dart';
import 'package:hb_social/features/comments/providers/comments_providers.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';

String normalizeForumTag(String value) {
  const source = 'àáâäãåèéêëìíîïòóôöõùúûüýÿçñ';
  const target = 'aaaaaaeeeeiiiiooooouuuuyycn';
  var normalized = value.toLowerCase().replaceFirst(RegExp(r'^#'), '');
  for (var index = 0; index < source.length; index++) { normalized = normalized.replaceAll(source[index], target[index]); }
  return normalized.replaceAll(RegExp('[^a-z0-9_]'), '');
}

class ForumTagEditor extends ConsumerStatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onChanged;
  const ForumTagEditor({super.key, required this.tags, required this.onChanged});
  @override
  ConsumerState<ForumTagEditor> createState() => _ForumTagEditorState();
}

class _ForumTagEditorState extends ConsumerState<ForumTagEditor> {
  final _controller = TextEditingController();
  Timer? _timer;
  List<String> _suggestions = const [];
  @override
  void dispose() { _timer?.cancel(); _controller.dispose(); super.dispose(); }
  void _add(String raw) { final tag = normalizeForumTag(raw); if (tag.isEmpty || widget.tags.contains(tag) || widget.tags.length >= 5) return; widget.onChanged([...widget.tags, tag]); _controller.clear(); setState(() => _suggestions = const []); }
  void _search(String value) {
    if (RegExp(r'[,\s]$').hasMatch(value)) { _add(value); return; }
    _timer?.cancel(); final tag = normalizeForumTag(value);
    if (tag.length < 2) { setState(() => _suggestions = const []); return; }
    _timer = Timer(const Duration(milliseconds: 250), () async { final items = await ref.read(forumsRepositoryProvider).searchTags(tag); if (mounted && _controller.text == value) setState(() => _suggestions = items); });
  }
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('forum_advanced.tags.label'.tr(), style: context.textStyles.labelMedium),
    const SizedBox(height: AppSpacing.xs),
    Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final tag in widget.tags) InputChip(label: Text('#$tag'), onDeleted: () => widget.onChanged(widget.tags.where((item) => item != tag).toList()))]),
    if (widget.tags.length < 5) ...[const SizedBox(height: AppSpacing.xs), HBInput(controller: _controller, hint: 'forum_advanced.tags.hint'.tr(), onChanged: _search, onSubmitted: _add)],
    if (_suggestions.isNotEmpty) Wrap(spacing: AppSpacing.xs, children: [for (final tag in _suggestions) HBChip(label: '#$tag', selected: false, onTap: () => _add(tag))]),
  ]);
}

class ForumMentionInput extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final int minLines;
  final int maxLines;
  final int maxLength;
  final String hint;
  final ValueChanged<String>? onChanged;
  const ForumMentionInput({super.key, required this.controller, required this.minLines, required this.maxLines, required this.maxLength, required this.hint, this.onChanged});
  @override
  ConsumerState<ForumMentionInput> createState() => _ForumMentionInputState();
}

class _ForumMentionInputState extends ConsumerState<ForumMentionInput> {
  Timer? _timer;
  List<PostAuthor> _results = const [];
  @override
  void dispose() { _timer?.cancel(); super.dispose(); }
  void _changed(String value) {
    widget.onChanged?.call(value); _timer?.cancel();
    final match = RegExp(r'(?:^|\s)@([a-zA-Z0-9_]{2,})$').firstMatch(value);
    if (match == null) { setState(() => _results = const []); return; }
    _timer = Timer(const Duration(milliseconds: 250), () async { final results = await ref.read(commentsRepositoryProvider).searchMentions(match.group(1)!); if (mounted) setState(() => _results = results); });
  }
  void _select(PostAuthor author) {
    final text = widget.controller.text.replaceFirst(RegExp(r'@[a-zA-Z0-9_]+$'), '@${author.username} ');
    widget.controller.value = TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
    widget.onChanged?.call(text); setState(() => _results = const []);
  }
  @override
  Widget build(BuildContext context) => Column(children: [
    HBInput(controller: widget.controller, minLines: widget.minLines, maxLines: widget.maxLines, maxLength: widget.maxLength, hint: widget.hint, onChanged: _changed),
    if (_results.isNotEmpty) HBCard(padding: const EdgeInsets.all(AppSpacing.xs), child: Column(children: [for (final author in _results) ListTile(dense: true, leading: HBAvatar(name: author.displayName, imageUrl: author.avatarUrl, size: 28), title: Text(author.displayName), subtitle: Text('@${author.username}'), onTap: () => _select(author))])),
  ]);
}