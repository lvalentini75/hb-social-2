import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/profile/providers/public_profile_providers.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';

class FriendActionButton extends ConsumerStatefulWidget {
  final String userId;
  final String username;
  final bool menuOnly;

  const FriendActionButton({super.key, required this.userId, required this.username, this.menuOnly = false});

  @override
  ConsumerState<FriendActionButton> createState() => _FriendActionButtonState();
}

class _FriendActionButtonState extends ConsumerState<FriendActionButton> {
  bool _loading = false;

  void _invalidate() {
    ref.invalidate(relationshipProvider(widget.userId));
    ref.invalidate(publicProfileProvider(widget.username));
    ref.invalidate(currentProfileProvider);
    ref.invalidate(receivedRequestsProvider);
    ref.invalidate(sentRequestsProvider);
    ref.invalidate(pendingFriendRequestCountProvider);
    ref.invalidate(peopleSuggestionsProvider);
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _loading = true);
    try {
      await action();
      _invalidate();
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _send() async {
    final message = await showModalBottomSheet<String?>(context: context, isScrollControlled: true, showDragHandle: true, builder: (_) => const FriendMessageSheet());
    if (!mounted || message == null) return;
    await _run(() async { await ref.read(socialGraphRepositoryProvider).sendRequest(widget.userId, message); });
  }

  Future<bool> _confirm(String titleKey, String messageKey) async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
    title: Text(titleKey.tr()), content: Text(messageKey.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'common.continue'.tr(), onPressed: () => dialogContext.pop(true))],
  )) ?? false;

  @override
  Widget build(BuildContext context) {
    if (ref.watch(authSessionProvider).value == null) return HBButton.soft(label: 'friendship.add'.tr(), onPressed: () => context.go(AppRoutes.login));
    final value = ref.watch(relationshipProvider(widget.userId));
    return value.when(
      loading: () => HBButton.soft(label: 'common.loading'.tr(), onPressed: null, isLoading: true),
      error: (_, __) => HBButton.soft(label: 'friendship.add'.tr(), onPressed: () => ref.invalidate(relationshipProvider(widget.userId))),
      data: (relationship) {
        if (relationship.blockedByMe || relationship.blockedMe) return const SizedBox.shrink();
        if (relationship.isFriend) return Row(mainAxisSize: MainAxisSize.min, children: [
          HBChip(label: 'friendship.friend_chip'.tr(), selected: false),
          PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) async {
            if (value == 'remove' && await _confirm('friendship.remove_title', 'friendship.remove_message')) await _run(() => ref.read(socialGraphRepositoryProvider).removeFriend(widget.userId));
          }, itemBuilder: (_) => [PopupMenuItem(value: 'remove', child: Text('friendship.remove'.tr()))]),
        ]);
        if (relationship.incomingRequestId != null) return Row(mainAxisSize: MainAxisSize.min, children: [
          HBButton.primary(label: 'friendship.accept'.tr(), isLoading: _loading, onPressed: _loading ? null : () => _run(() async { await ref.read(socialGraphRepositoryProvider).respond(relationship.incomingRequestId!, true); })),
          PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) { if (value == 'decline') _run(() async { await ref.read(socialGraphRepositoryProvider).respond(relationship.incomingRequestId!, false); }); }, itemBuilder: (_) => [PopupMenuItem(value: 'decline', child: Text('friendship.decline'.tr()))]),
        ]);
        if (relationship.outgoingRequestId != null) return HBButton.soft(label: 'friendship.sent'.tr(), isLoading: _loading, onPressed: _loading ? null : () async {
          if (await _confirm('friendship.cancel_title', 'friendship.cancel_message')) await _run(() => ref.read(socialGraphRepositoryProvider).cancel(relationship.outgoingRequestId!));
        });
        return relationship.isFollowing
            ? HBButton.soft(label: 'friendship.add'.tr(), isLoading: _loading, onPressed: _loading ? null : _send)
            : HBButton.primary(label: 'friendship.add'.tr(), isLoading: _loading, onPressed: _loading ? null : _send);
      },
    );
  }
}

class FriendMessageSheet extends StatefulWidget {
  const FriendMessageSheet({super.key});

  @override
  State<FriendMessageSheet> createState() => _FriendMessageSheetState();
}

class _FriendMessageSheetState extends State<FriendMessageSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() { _controller.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
    child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('friendship.message_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBInput(controller: _controller, hint: 'friendship.message_hint'.tr(), maxLength: 200, maxLines: 3),
      const SizedBox(height: AppSpacing.md),
      Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'friendship.send'.tr(), onPressed: () => context.pop(_controller.text.trim()))]),
    ]),
  );
}