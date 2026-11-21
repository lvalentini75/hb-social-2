import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/features/forums/domain/forum_thread.dart';

/// Shared moderation menu for forum thread lists and thread detail.
class ThreadModerationMenu extends StatelessWidget {
  final ForumThread thread;
  final ValueChanged<String> onSelected;
  final bool includeStudioActions;

  const ThreadModerationMenu({super.key, required this.thread, required this.onSelected, this.includeStudioActions = false});

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    icon: const Icon(Icons.more_horiz_rounded),
    onSelected: onSelected,
    itemBuilder: (_) => [
      PopupMenuItem(value: 'pin', child: Text((thread.isPinned ? 'forum_studio.thread.unpin' : 'forum_studio.thread.pin').tr())),
      PopupMenuItem(value: 'lock', child: Text((thread.isLocked ? 'forum_studio.thread.reopen' : 'forum_studio.thread.close').tr())),
      PopupMenuItem(value: 'status', child: Text((thread.status == 'hidden' ? 'forum_studio.thread.republish' : 'forum_studio.thread.hide').tr())),
      if (includeStudioActions) PopupMenuItem(value: 'edit_tags', child: Text('forum_studio.thread.edit_tags'.tr())),
      if (includeStudioActions) PopupMenuItem(value: 'open', child: Text('forum_studio.thread.open'.tr())),
      PopupMenuItem(value: 'delete', child: Text('forum_studio.thread.delete'.tr())),
    ],
  );
}