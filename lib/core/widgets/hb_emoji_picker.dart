import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';

/// Reusable emoji grid that returns the selected emoji to a text editor.
class HBEmojiPicker extends StatelessWidget {
  static const choices = ['😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '🙂', '😉', '😍', '🥰', '😘', '😎', '🤩', '🥳', '🤔', '😮', '😱', '🤭', '🤠', '👍', '👏', '🙌', '🤝', '🙏', '💪', '👀', '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '💯', '🔥', '✨', '⭐', '🎉', '🎯', '🏆', '📍', '☀️', '🌤️', '🌧️', '🌙', '🌲', '🍂', '⛰️', '🏕️', '🐕', '🐶', '🦌', '🐗', '🦆', '🦅', '🐇', '🦊', '🐺', '🐻', '🐾', '🪶', '🔭', '🧭', '🎒', '🥾', '🚙', '📷', '🎥'];

  final ValueChanged<String> onSelected;

  const HBEmojiPicker({super.key, required this.onSelected});

  /// Opens the picker and returns the chosen emoji, if any.
  static Future<String?> show(BuildContext context) => showDialog<String>(context: context, builder: (_) => Dialog(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460, maxHeight: 460), child: const _HBEmojiPickerDialog())));

  @override
  Widget build(BuildContext context) => GridView.builder(
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
    itemCount: choices.length,
    itemBuilder: (context, index) => InkWell(borderRadius: BorderRadius.circular(AppRadius.sm), onTap: () => onSelected(choices[index]), child: Center(child: Text(choices[index], style: const TextStyle(fontSize: 28)))),
  );
}

class _HBEmojiPickerDialog extends StatelessWidget {
  const _HBEmojiPickerDialog();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(children: [
      Row(children: [Expanded(child: Text('post_composer.emoji_picker_title'.tr(), style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700))), HBButton.icon(icon: Icons.close_rounded, tooltip: 'common.close'.tr(), onPressed: context.pop, size: HBButtonSize.sm)]),
      const SizedBox(height: AppSpacing.sm),
      Expanded(child: HBEmojiPicker(onSelected: (emoji) => context.pop(emoji))),
    ]),
  );
}