import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';

Future<bool> showMuteConfirmation(BuildContext context, String displayName) async => await showModalBottomSheet<bool>(
  context: context, useSafeArea: true, showDragHandle: true,
  builder: (_) => MuteUserSheet(displayName: displayName),
) ?? false;

Future<bool> showBlockConfirmation(BuildContext context, String displayName) async => await showDialog<bool>(
  context: context, builder: (_) => BlockUserDialog(displayName: displayName),
) ?? false;

/// Confirms hiding an author's posts from all feeds.
class MuteUserSheet extends StatelessWidget {
  final String displayName;

  const MuteUserSheet({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.lg),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('safety.mute_title'.tr(namedArgs: {'name': displayName}), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.sm),
      Text('safety.mute_message'.tr()),
      const SizedBox(height: AppSpacing.lg),
      SizedBox(width: double.infinity, child: HBButton.primary(label: 'safety.mute'.tr(), onPressed: () => context.pop(true))),
    ]),
  );
}

/// Confirms the bidirectional block and removal of social relationships.
class BlockUserDialog extends StatelessWidget {
  final String displayName;

  const BlockUserDialog({super.key, required this.displayName});

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text('safety.block_title'.tr(namedArgs: {'name': displayName})),
    content: Text('safety.block_message'.tr()),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: 'safety.block'.tr(), onPressed: () => context.pop(true))],
  );
}