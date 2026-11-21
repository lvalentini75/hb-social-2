import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/chat/presentation/chat_media_widgets.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/safety/presentation/safety_confirmations.dart';
import 'package:hb_social/features/safety/providers/safety_providers.dart';
import 'package:hb_social/features/settings/providers/settings_providers.dart';

Future<void> showConversationInfo(BuildContext context, Conversation conversation) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ConversationInfoSheet(conversation: conversation));

class ConversationInfoSheet extends ConsumerStatefulWidget {
  final Conversation conversation;
  const ConversationInfoSheet({super.key, required this.conversation});
  @override
  ConsumerState<ConversationInfoSheet> createState() => _ConversationInfoSheetState();
}

class _ConversationInfoSheetState extends ConsumerState<ConversationInfoSheet> {
  late final TextEditingController _title = TextEditingController(text: widget.conversation.title);
  bool _working = false;
  @override
  void dispose() { _title.dispose(); super.dispose(); }

  Future<void> _run(Future<void> Function() action, {bool close = false}) async {
    setState(() => _working = true);
    try { await action(); ref.invalidate(conversationsProvider); ref.invalidate(conversationProvider(widget.conversation.id)); if (close && mounted) { context.pop(); context.go(AppRoutes.messages); } }
    on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _mute() async {
    if (widget.conversation.isMuted) { await _run(() => ref.read(chatRepositoryProvider).setMuted(widget.conversation.id, null)); return; }
    final choice = await showModalBottomSheet<Duration?>(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(title: Text('chat_b.mute_1h'.tr()), onTap: () => context.pop(const Duration(hours: 1))), ListTile(title: Text('chat_b.mute_8h'.tr()), onTap: () => context.pop(const Duration(hours: 8))), ListTile(title: Text('chat_b.mute_week'.tr()), onTap: () => context.pop(const Duration(days: 7))), ListTile(title: Text('chat_b.mute_forever'.tr()), onTap: () => context.pop(const Duration(days: 36500)))])));
    if (choice != null) await _run(() => ref.read(chatRepositoryProvider).setMuted(widget.conversation.id, DateTime.now().toUtc().add(choice)));
  }

  Future<void> _leave() async {
    final message = widget.conversation.isGroup && widget.conversation.myRole == 'owner' ? 'chat_b.leave_owner_message'.tr() : widget.conversation.isGroup ? 'chat_b.leave_group_message'.tr() : 'chat_b.delete_conversation_message'.tr();
    final confirmed = await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text(widget.conversation.isGroup ? 'chat_b.leave_group'.tr() : 'chat_b.delete_conversation'.tr()), content: Text(message), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop(false)), HBButton.primary(label: widget.conversation.isGroup ? 'chat_b.leave'.tr() : 'chat.delete'.tr(), onPressed: () => context.pop(true))])) == true;
    if (confirmed) await _run(() => ref.read(chatRepositoryProvider).leaveConversation(widget.conversation.id), close: true);
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authSessionProvider).value?.user.id;
    final other = widget.conversation.other(me);
    return FractionallySizedBox(heightFactor: .92, child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(children: [
      Row(children: [Expanded(child: Text('chat_b.info'.tr(), style: context.textStyles.headlineSmall)), HBButton.icon(icon: Icons.close_rounded, onPressed: context.pop)]),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: ListView(children: [
        Center(child: HBAvatar(name: widget.conversation.displayName(me), imageUrl: widget.conversation.avatarUrl(me), size: 88)), const SizedBox(height: AppSpacing.sm),
        if (widget.conversation.isGroup) Row(children: [Expanded(child: HBInput(controller: _title, label: 'chat.group_title'.tr(), maxLength: 80)), const SizedBox(width: AppSpacing.sm), HBButton.icon(icon: Icons.edit_outlined, onPressed: _working ? null : () => _run(() => ref.read(chatRepositoryProvider).renameConversation(widget.conversation.id, _title.text)))])
        else ...[Center(child: Text(other?.displayName ?? '', style: context.textStyles.titleLarge)), Center(child: Text('@${other?.username ?? ''}', style: context.textStyles.bodySmall)), const SizedBox(height: AppSpacing.sm), Center(child: HBButton.soft(label: 'chat_b.view_profile'.tr(), onPressed: other == null ? null : () => context.push(AppRoutes.publicProfilePath(other.username))))],
        const SizedBox(height: AppSpacing.lg),
        ListTile(leading: Icon(widget.conversation.isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined), title: Text(widget.conversation.isMuted ? 'chat_b.unmute'.tr() : 'chat_b.mute'.tr()), onTap: _working ? null : _mute),
        if (!widget.conversation.isGroup) ListTile(leading: const Icon(Icons.photo_library_outlined), title: Text('chat_b.shared_media'.tr()), onTap: () => showSharedMedia(context, widget.conversation.id)),
        if (widget.conversation.isGroup) ...[
          ListTile(title: Text('chat.participant_count'.tr(namedArgs: {'n': '${widget.conversation.participants.length}'}), style: context.textStyles.titleMedium), trailing: HBButton.soft(label: 'chat_b.add_participants'.tr(), icon: Icons.person_add_alt_1, onPressed: widget.conversation.participants.length >= 50 ? null : () => showAddParticipants(context, widget.conversation))),
          ...widget.conversation.participants.map((participant) => ConversationParticipantRow(conversation: widget.conversation, participant: participant, currentUserId: me)),
        ],
        if (!widget.conversation.isGroup && other != null) ListTile(leading: Icon(widget.conversation.isBlocked ? Icons.lock_open_rounded : Icons.block_rounded), title: Text(widget.conversation.isBlocked ? 'safety.unblock'.tr() : 'safety.block'.tr()), onTap: () async { if (widget.conversation.isBlocked) { await ref.read(userSettingsRepositoryProvider).unblockUser(other.userId); } else if (await showBlockConfirmation(context, other.displayName)) { await ref.read(safetyRepositoryProvider).blockUser(other.userId); } ref.invalidate(conversationsProvider); if (mounted) context.pop(); }),
        ListTile(leading: Icon(widget.conversation.isGroup ? Icons.logout_rounded : Icons.delete_outline_rounded, color: LightModeColors.lightError), title: Text(widget.conversation.isGroup ? 'chat_b.leave_group'.tr() : 'chat_b.delete_conversation'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightError)), onTap: _working ? null : _leave),
      ])),
    ])));
  }
}

class ConversationParticipantRow extends ConsumerWidget {
  final Conversation conversation;
  final ConversationParticipant participant;
  final String? currentUserId;
  const ConversationParticipantRow({super.key, required this.conversation, required this.participant, required this.currentUserId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ListTile(leading: HBAvatar(name: participant.displayName, imageUrl: participant.avatarUrl, size: 42), title: Row(children: [Flexible(child: Text(participant.displayName, overflow: TextOverflow.ellipsis)), if (participant.role == 'owner') ...[const SizedBox(width: AppSpacing.xs), HBStatusChip(kind: HBStatusKind.info, label: 'chat_b.owner'.tr())], if (participant.userId == currentUserId) ...[const SizedBox(width: AppSpacing.xs), Text('chat_b.you'.tr(), style: context.textStyles.labelSmall)]]), subtitle: Text('@${participant.username}'), trailing: participant.userId == currentUserId ? null : PopupMenuButton<String>(onSelected: (value) async { if (value == 'profile') context.push(AppRoutes.publicProfilePath(participant.username)); if (value == 'message') { final id = await ref.read(chatRepositoryProvider).startDirect(participant.userId); if (context.mounted) { context.pop(); context.go(AppRoutes.conversationDetailPath(id)); } } if (value == 'remove') { await ref.read(chatRepositoryProvider).removeParticipant(conversation.id, participant.userId); ref.invalidate(conversationsProvider); ref.invalidate(conversationProvider(conversation.id)); } }, itemBuilder: (_) => [PopupMenuItem(value: 'profile', child: Text('chat.profile'.tr())), PopupMenuItem(value: 'message', child: Text('chat_b.message'.tr())), if (conversation.myRole == 'owner') PopupMenuItem(value: 'remove', child: Text('chat_b.remove_participant'.tr()))]));
}

Future<void> showAddParticipants(BuildContext context, Conversation conversation) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => AddParticipantsSheet(conversation: conversation));

class AddParticipantsSheet extends ConsumerStatefulWidget {
  final Conversation conversation;
  const AddParticipantsSheet({super.key, required this.conversation});
  @override
  ConsumerState<AddParticipantsSheet> createState() => _AddParticipantsSheetState();
}

class _AddParticipantsSheetState extends ConsumerState<AddParticipantsSheet> {
  final _search = TextEditingController();
  final Map<String, UserProfile> _selected = {};
  Timer? _debounce;
  String _query = '';
  @override
  void dispose() { _debounce?.cancel(); _search.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final present = widget.conversation.participants.map((item) => item.userId).toSet();
    final results = _query.length < 2 ? null : ref.watch(peopleSearchProvider(_query));
    return FractionallySizedBox(heightFactor: .85, child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(children: [
      Text('chat_b.add_participants'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.md),
      HBInput(controller: _search, hint: 'chat.search_people'.tr(), onChanged: (value) { _debounce?.cancel(); _debounce = Timer(const Duration(milliseconds: 300), () { if (mounted) setState(() => _query = value.trim()); }); }),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: results == null ? const SizedBox.shrink() : results.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'chat.people_error'.tr(), message: 'chat.error_message'.tr()),
        data: (items) {
          final available = items.where((item) => !present.contains(item.id)).toList();
          return ListView(children: available.map((profile) => CheckboxListTile(
            value: _selected.containsKey(profile.id), secondary: HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 40), title: Text(profile.displayName), subtitle: Text('@${profile.username}'),
            onChanged: (_) => setState(() { _selected.containsKey(profile.id) ? _selected.remove(profile.id) : _selected[profile.id] = profile; }),
          )).toList());
        },
      )),
      SizedBox(width: double.infinity, child: HBButton.primary(label: 'chat_b.add_selected'.tr(namedArgs: {'n': '${_selected.length}'}), onPressed: _selected.isEmpty || present.length + _selected.length > 50 ? null : () async { await ref.read(chatRepositoryProvider).addParticipants(widget.conversation.id, _selected.keys.toList()); ref.invalidate(conversationsProvider); ref.invalidate(conversationProvider(widget.conversation.id)); if (context.mounted) context.pop(); })),
    ])));
  }
}

Future<void> showSharedMedia(BuildContext context, String conversationId) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => SharedChatMedia(conversationId: conversationId));

class SharedChatMedia extends ConsumerWidget {
  final String conversationId;
  const SharedChatMedia({super.key, required this.conversationId});
  @override
  Widget build(BuildContext context, WidgetRef ref) => FractionallySizedBox(heightFactor: .8, child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: FutureBuilder<List<ChatMessage>>(future: ref.read(chatRepositoryProvider).sharedImages(conversationId), builder: (context, snapshot) { final images = snapshot.data; if (images == null) return const Center(child: CircularProgressIndicator()); if (images.isEmpty) return HBEmptyState(icon: Icons.photo_library_outlined, title: 'chat_b.no_shared_media'.tr(), message: 'chat_b.no_shared_media_message'.tr()); return GridView.builder(gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: AppSpacing.xs, mainAxisSpacing: AppSpacing.xs), itemCount: images.length, itemBuilder: (context, index) => ChatImageBubble(message: images[index])); })));
}