import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/storage_url.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/chat/presentation/messages_page.dart';
import 'package:hb_social/features/chat/presentation/chat_media_widgets.dart';
import 'package:hb_social/features/chat/presentation/chat_composer_media.dart';
import 'package:hb_social/features/chat/presentation/chat_info_sheet.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/features/calls/providers/calls_providers.dart';
import 'package:uuid/uuid.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/features/gifs/presentation/gif_picker.dart';
import 'package:hb_social/core/widgets/translatable_text.dart';
import 'package:hb_social/features/gifs/providers/gifs_providers.dart';

class ConversationPage extends ConsumerWidget {
  final String conversationId;
  const ConversationPage({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversation = ref.watch(conversationProvider(conversationId));
    final chat = conversation.when(
      loading: () => const Center(child: HBListSkeleton(count: 6, showTrailing: false)),
      error: (_, __) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'chat.error_title'.tr(), message: 'chat.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(conversationProvider(conversationId)))),
      data: (item) => item == null ? HBEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'chat.unavailable_title'.tr(), message: 'chat.unavailable_message'.tr()) : ConversationThread(conversation: item),
    );
    return PageColumns(center: LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth <= 820) return HBCard.media(child: chat);
      return SizedBox(height: constraints.maxHeight, child: HBCard.media(child: Row(children: [SizedBox(width: 360, child: ConversationInbox(selectedId: conversationId, compact: true, onNewConversation: () => showNewConversationSheet(context))), const VerticalDivider(width: 1), Expanded(child: chat)])));
    }));
  }
}

class ConversationThread extends ConsumerStatefulWidget {
  final Conversation conversation;
  const ConversationThread({super.key, required this.conversation});

  @override
  ConsumerState<ConversationThread> createState() => _ConversationThreadState();
}

class _ConversationThreadState extends ConsumerState<ConversationThread> with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  Timer? _typingThrottle;
  ChatMessage? _replyingTo;
  ChatMessage? _editing;
  bool _visible = true;
  bool _nearBottom = true;
  int _pendingBelow = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scrollController.addListener(() { final near = !_scrollController.hasClients || _scrollController.position.maxScrollExtent - _scrollController.offset < 100; if (near != _nearBottom && mounted) setState(() { _nearBottom = near; if (near) _pendingBelow = 0; }); });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopTyping();
    _typingThrottle?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) => _visible = state == AppLifecycleState.resumed;

  void _onTextChanged(String value) {
    setState(() {});
    if (value.isEmpty) { _stopTyping(); return; }
    if (_typingThrottle?.isActive ?? false) return;
    _sendTyping(false);
    _typingThrottle = Timer(const Duration(seconds: 2), () {});
  }

  Future<void> _sendTyping(bool stopped) async {
    final user = ref.read(currentProfileProvider).value;
    if (user == null) return;
    await ref.read(chatRealtimeProvider(widget.conversation.id)).sendTyping(userId: user.id, displayName: user.displayName, stopped: stopped);
  }

  void _stopTyping() => _sendTyping(true);

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _stopTyping();
    if (_editing != null) {
      try { await ref.read(messagesProvider(widget.conversation.id).notifier).edit(_editing!, text); _controller.clear(); setState(() => _editing = null); }
      on AppException catch (error) { _showError(error); }
      return;
    }
    final reply = _replyingTo;
    _controller.clear();
    setState(() => _replyingTo = null);
    try {
      await ref.read(messagesProvider(widget.conversation.id).notifier).send(text, replyToId: reply?.id, clientId: const Uuid().v4());
      _scrollToBottom();
    } on AppException catch (error) { _showError(error); }
  }

  Future<void> _sendGif() async {
    final gif = await showGifPicker(context);
    if (gif == null || !mounted) return;
    try {
      await ref.read(gifsRepositoryProvider).share(gif.onsent);
      await ref.read(messagesProvider(widget.conversation.id).notifier).sendGif(gif, replyToId: _replyingTo?.id, clientId: const Uuid().v4());
      setState(() => _replyingTo = null);
      _scrollToBottom();
    } on AppException catch (error) { _showError(error); }
  }

  void _showError(AppException error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs)))); }
  void _scrollToBottom() { WidgetsBinding.instance.addPostFrameCallback((_) { if (_scrollController.hasClients) _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut); }); }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authSessionProvider).value?.user.id;
    final messages = ref.watch(messagesProvider(widget.conversation.id));
    final typing = ref.watch(typingProvider(widget.conversation.id)).values.where((name) => name.isNotEmpty).toList();
    ref.listen(messagesProvider(widget.conversation.id), (previous, next) {
      final oldLength = previous?.value?.items.length ?? 0;
      final newLength = next.value?.items.length ?? 0;
      if (newLength <= oldLength) return;
      if (_visible) ref.read(messagesProvider(widget.conversation.id).notifier).markRead();
      if (_nearBottom) _scrollToBottom(); else if (mounted) setState(() => _pendingBelow += newLength - oldLength);
    });
    return VisibilityDetector(
      key: ValueKey('conversation-${widget.conversation.id}'),
      onVisibilityChanged: (info) { _visible = info.visibleFraction > .5; if (_visible) ref.read(messagesProvider(widget.conversation.id).notifier).markRead(); },
      child: Column(children: [
        ConversationHeader(conversation: widget.conversation, currentUserId: me, typingNames: typing),
        const Divider(height: 1),
        Expanded(child: Stack(children: [
          messages.when(
            loading: () => const Padding(padding: EdgeInsets.all(AppSpacing.md), child: HBListSkeleton(count: 7, showTrailing: false)),
            error: (_, __) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'chat.error_title'.tr(), message: 'chat.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(messagesProvider(widget.conversation.id)))),
            data: (state) => ChatMessagesList(state: state, conversation: widget.conversation, currentUserId: me, controller: _scrollController, onReply: (message) => setState(() { _replyingTo = message; _editing = null; }), onEdit: (message) { _controller.text = message.body; setState(() { _editing = message; _replyingTo = null; }); }),
          ),
          if (_pendingBelow > 0) Positioned(right: AppSpacing.md, bottom: AppSpacing.md, child: HBButton.soft(label: 'chat.new_messages'.tr(), icon: Icons.arrow_downward_rounded, onPressed: () { setState(() => _pendingBelow = 0); _scrollToBottom(); })),
        ])),
        const Divider(height: 1),
        if (widget.conversation.isBlocked)
          Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('chat.blocked_footer'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)))
        else ChatComposer(conversationId: widget.conversation.id, controller: _controller, replyingTo: _replyingTo, editing: _editing, gifEnabled: ref.watch(gifsAvailableProvider).value == true, onChanged: _onTextChanged, onCancelMode: () => setState(() { _replyingTo = null; _editing = null; _controller.clear(); }), onSend: _submit, onGif: _sendGif, onMediaSend: (media, kind, body, clientId) => ref.read(messagesProvider(widget.conversation.id).notifier).sendMedia(media, kind: kind, body: body, clientId: clientId)),
      ]),
    );
  }
}

class ConversationHeader extends ConsumerWidget {
  final Conversation conversation;
  final String? currentUserId;
  final List<String> typingNames;
  const ConversationHeader({super.key, required this.conversation, required this.currentUserId, required this.typingNames});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = conversation.other(currentUserId);
    final online = other?.lastSeenAt != null && DateTime.now().toUtc().difference(other!.lastSeenAt!).inMinutes < 5;
    final subtitle = typingNames.isNotEmpty ? _typingText(typingNames) : conversation.isGroup ? 'chat.participant_count'.tr(namedArgs: {'n': '${conversation.participants.length}'}) : online ? 'chat.online'.tr() : other?.lastSeenAt == null ? '' : 'chat.last_seen'.tr(namedArgs: {'time': relativeTime(context, other!.lastSeenAt!)});
    return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Row(children: [
      if (MediaQuery.sizeOf(context).width < 1200) ...[HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.go(AppRoutes.messages)), const SizedBox(width: AppSpacing.sm)],
      HBAvatar(name: conversation.displayName(currentUserId), imageUrl: conversation.avatarUrl(currentUserId), size: 42, showPresence: !conversation.isGroup && online),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: InkWell(
        onTap: () => showConversationInfo(context, conversation),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(conversation.displayName(currentUserId), maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)), if (subtitle.isNotEmpty) Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.copyWith(color: typingNames.isNotEmpty ? LightModeColors.lightPrimary : LightModeColors.lightOnSurfaceVariant))]),
      )),
      if (conversation.isMuted) const Padding(padding: EdgeInsets.only(right: AppSpacing.xs), child: Icon(Icons.notifications_off_outlined, size: 18)),
      if (!conversation.isGroup && !conversation.isBlocked && ref.watch(featureFlagsProvider).value?['calls'] == true) ...[
        HBButton.icon(icon: Icons.phone_outlined, tooltip: 'calls.start_audio'.tr(), onPressed: other == null ? null : () => _startCall(context, ref, other.userId, 'audio')),
        const SizedBox(width: AppSpacing.xs),
        HBButton.icon(icon: Icons.videocam_outlined, tooltip: 'calls.start_video'.tr(), onPressed: other == null ? null : () => _startCall(context, ref, other.userId, 'video')),
      ],
      PopupMenuButton<String>(onSelected: (value) async { if (value == 'read') { await ref.read(chatRepositoryProvider).markRead(conversation.id); ref.invalidate(unreadConversationsCountProvider); ref.invalidate(conversationsProvider); } if (value == 'profile' && other != null && context.mounted) context.push(AppRoutes.publicProfilePath(other.username)); if (value == 'info' && context.mounted) showConversationInfo(context, conversation); }, itemBuilder: (_) => [PopupMenuItem(value: 'read', child: Text('chat.mark_read'.tr())), if (!conversation.isGroup) PopupMenuItem(value: 'profile', child: Text('chat.profile'.tr())), PopupMenuItem(value: 'info', child: Text('chat_b.info'.tr()))]),
    ]));
  }

  String _typingText(List<String> names) => names.length == 1 ? 'chat.typing_one'.tr(namedArgs: {'name': names.first}) : 'chat.typing_many'.tr(namedArgs: {'a': names[0], 'b': names[1]});

  Future<void> _startCall(BuildContext context, WidgetRef ref, String userId, String kind) async {
    try {
      final call = await ref.read(callsRepositoryProvider).start(userId, kind);
      if (!context.mounted) return;
      if (call.status == 'busy') { ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('calls.busy'.tr()))); return; }
      context.push(AppRoutes.callPath(call.id));
    } on AppException catch (error) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }
}

class ChatMessagesList extends ConsumerWidget {
  final MessagesState state;
  final Conversation conversation;
  final String? currentUserId;
  final ScrollController controller;
  final ValueChanged<ChatMessage> onReply;
  final ValueChanged<ChatMessage> onEdit;

  const ChatMessagesList({super.key, required this.state, required this.conversation, required this.currentUserId, required this.controller, required this.onReply, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.items.isEmpty) return HBEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'chat.thread_empty_title'.tr(), message: 'chat.thread_empty_message'.tr());
    return ListView.builder(
      controller: controller, padding: const EdgeInsets.all(AppSpacing.md), itemCount: state.items.length + (state.hasOlder ? 1 : 0),
      itemBuilder: (context, index) {
        if (state.hasOlder && index == 0) return Center(child: HBButton.soft(label: 'chat.load_older'.tr(), isLoading: state.loadingOlder, onPressed: state.loadingOlder ? null : () => ref.read(messagesProvider(conversation.id).notifier).loadOlder()));
        final itemIndex = index - (state.hasOlder ? 1 : 0);
        final message = state.items[itemIndex];
        final previous = itemIndex > 0 ? state.items[itemIndex - 1] : null;
        final next = itemIndex + 1 < state.items.length ? state.items[itemIndex + 1] : null;
        final dayChanged = previous == null || !_sameDay(previous.createdAt.toLocal(), message.createdAt.toLocal());
        final firstInGroup = previous == null || previous.senderId != message.senderId || previous.kind == 'system' || message.createdAt.difference(previous.createdAt).inMinutes > 5;
        final lastInGroup = next == null || next.senderId != message.senderId || next.kind == 'system' || next.createdAt.difference(message.createdAt).inMinutes > 5;
        final readBy = conversation.participants.where((participant) => participant.userId != currentUserId && participant.lastReadAt != null && !participant.lastReadAt!.isBefore(message.createdAt)).toList();
        return Column(children: [
          if (dayChanged) DaySeparator(date: message.createdAt),
          ChatMessageBubble(message: message, reply: message.replyToId == null ? null : state.items.where((item) => item.id == message.replyToId).firstOrNull, isMine: message.senderId == currentUserId, showSender: conversation.isGroup && firstInGroup, showReceipt: message.senderId == currentUserId && lastInGroup, readBy: readBy, direct: !conversation.isGroup, canDeleteOthers: conversation.isGroup && conversation.myRole == 'owner', onReply: () => onReply(message), onEdit: () => onEdit(message)),
          const SizedBox(height: 4),
        ]);
      },
    );
  }
}

class DaySeparator extends StatelessWidget {
  final DateTime date;
  const DaySeparator({super.key, required this.date});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), child: Row(children: [const Expanded(child: Divider()), Padding(padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm), child: Text(DateFormat.yMMMd(context.locale.toString()).format(date.toLocal()), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary))), const Expanded(child: Divider())]));
}

class ChatMessageBubble extends ConsumerWidget {
  final ChatMessage message;
  final ChatMessage? reply;
  final bool isMine;
  final bool showSender;
  final bool showReceipt;
  final List<ConversationParticipant> readBy;
  final bool direct;
  final bool canDeleteOthers;
  final VoidCallback onReply;
  final VoidCallback onEdit;

  const ChatMessageBubble({super.key, required this.message, this.reply, required this.isMine, required this.showSender, required this.showReceipt, required this.readBy, required this.direct, required this.canDeleteOthers, required this.onReply, required this.onEdit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (message.kind == 'system') return Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Text(localizedSystemMessage(message.body, message.meta), textAlign: TextAlign.center, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)));
    return GestureDetector(
      onLongPress: () => _showActions(context, ref), onSecondaryTap: () => _showActions(context, ref), onHorizontalDragEnd: (details) { if ((details.primaryVelocity ?? 0) > 250) onReply(); },
      child: Align(alignment: isMine ? Alignment.centerRight : Alignment.centerLeft, child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 460), child: Column(crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
        if (showSender) Padding(padding: const EdgeInsets.only(left: AppSpacing.sm, bottom: 2), child: Text(message.sender.displayName, style: context.textStyles.labelSmall?.copyWith(color: LightModeColors.messageSenderColor(message.senderId), fontWeight: FontWeight.w700))),
        Container(
          padding: message.kind == 'image' ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: isMine ? LightModeColors.lightPrimarySoft : LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.md)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (message.status != 'deleted' && message.meta['listing'] is Map) ...[ChatListingCard(data: Map<String, dynamic>.from(message.meta['listing'] as Map)), const SizedBox(height: AppSpacing.xs)],
            if (reply != null) Container(width: double.infinity, padding: const EdgeInsets.all(AppSpacing.sm), margin: const EdgeInsets.only(bottom: AppSpacing.xs), decoration: BoxDecoration(color: LightModeColors.lightSurface.withValues(alpha: .7), borderRadius: BorderRadius.circular(AppRadius.xs)), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(reply!.sender.displayName, style: context.textStyles.labelSmall?.copyWith(fontWeight: FontWeight.w700)), Text(reply!.status == 'deleted' ? 'chat.deleted'.tr() : reply!.body, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall)])),
            if (message.status == 'deleted') Text('chat.deleted'.tr(), style: context.textStyles.bodyMedium?.copyWith(fontStyle: FontStyle.italic))
             else if (message.kind == 'image') ChatImageBubble(message: message)
             else if (message.kind == 'gif' && message.mediaPath != null) GifImage(url: message.mediaPath!, width: message.mediaWidth?.toDouble().clamp(120, 320), height: message.mediaHeight?.toDouble().clamp(100, 280))
            else if (message.kind == 'voice') ChatVoiceBubble(message: message, isMine: isMine)
            else if (!isMine) TranslatableText(type: 'message', id: message.id, field: 'body', text: message.body, style: context.textStyles.bodyMedium)
            else Text(message.body, style: context.textStyles.bodyMedium?.copyWith(color: message.localState == LocalMessageState.sending ? LightModeColors.lightTextTertiary : null)),
            const SizedBox(height: 2),
            Padding(padding: message.kind == 'image' ? const EdgeInsets.fromLTRB(AppSpacing.sm, 0, AppSpacing.sm, AppSpacing.sm) : EdgeInsets.zero, child: Row(mainAxisSize: MainAxisSize.min, children: [Text(DateFormat.Hm(context.locale.toString()).format(message.createdAt.toLocal()), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)), if (message.status == 'edited') Text(' · ${'chat.edited'.tr()}', style: context.textStyles.labelSmall?.withColor(LightModeColors.lightTextTertiary)), if (isMine) ...[const SizedBox(width: 4), MessageDeliveryIcon(message: message)]])),
          ]),
        ),
        if (showReceipt && message.localState == LocalMessageState.sent) InkWell(onTap: readBy.isEmpty ? null : () => showReadersSheet(context, readBy), child: Padding(padding: const EdgeInsets.only(top: 2, right: 4), child: Text(direct ? (readBy.isEmpty ? 'chat.sent'.tr() : 'chat.read'.tr()) : 'chat.read_by'.tr(namedArgs: {'n': '${readBy.length}'}), style: context.textStyles.labelSmall?.copyWith(color: readBy.isEmpty ? LightModeColors.lightTextTertiary : LightModeColors.lightPrimary)))),
      ]))),
    );
  }

  Future<void> _showActions(BuildContext context, WidgetRef ref) async {
    final canEdit = isMine && message.kind == 'text' && message.status != 'deleted' && message.localState == LocalMessageState.sent;
    final canDelete = (isMine || canDeleteOthers) && message.status != 'deleted';
    final action = await showModalBottomSheet<String>(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: const Icon(Icons.reply_rounded), title: Text('chat.reply'.tr()), onTap: () => context.pop('reply')), if (message.body.isNotEmpty && message.status != 'deleted') ListTile(leading: const Icon(Icons.copy_rounded), title: Text('chat.copy'.tr()), onTap: () => context.pop('copy')), if (message.mediaPath != null && message.status != 'deleted') ListTile(leading: const Icon(Icons.download_outlined), title: Text('chat_b.save_media'.tr()), onTap: () => context.pop('save')), if (canEdit) ListTile(leading: const Icon(Icons.edit_outlined), title: Text('chat.edit'.tr()), onTap: () => context.pop('edit')), if (canDelete) ListTile(leading: const Icon(Icons.delete_outline_rounded), title: Text(message.localState == LocalMessageState.failed ? 'chat.remove'.tr() : 'chat.delete'.tr()), onTap: () => context.pop('delete')), if (message.localState == LocalMessageState.failed) ListTile(leading: const Icon(Icons.refresh_rounded), title: Text('chat.retry'.tr()), onTap: () => context.pop('retry'))])));
    if (action == 'reply') onReply();
    if (action == 'copy') await Clipboard.setData(ClipboardData(text: message.body));
    if (action == 'save' && message.mediaPath != null) { final url = message.kind == 'gif' ? message.mediaPath! : await ref.read(chatRepositoryProvider).signedMediaUrl(message.mediaPath!); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); }
    if (action == 'edit') onEdit();
    if (action == 'retry') { try { await ref.read(messagesProvider(message.conversationId).notifier).retry(message); } catch (_) {} }
    if (action == 'delete' && context.mounted) {
      final confirmed = message.localState == LocalMessageState.failed || await showDialog<bool>(context: context, builder: (_) => AlertDialog(title: Text('chat.delete_title'.tr()), content: Text('chat.delete_message'.tr()), actions: [TextButton(onPressed: () => context.pop(false), child: Text('common.cancel'.tr())), TextButton(onPressed: () => context.pop(true), child: Text('chat.delete'.tr()))])) == true;
      if (confirmed) { try { await ref.read(messagesProvider(message.conversationId).notifier).delete(message); } catch (_) {} }
    }
  }
}

class ChatListingCard extends ConsumerWidget {
  final Map<String, dynamic> data;
  const ChatListingCard({super.key, required this.data});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final id = data['id']?.toString() ?? '';
    final path = data['media_path'] as String?;
    final image = storagePublicUrl(ref.watch(supabaseClientProvider), 'listing-media', path);
    final amount = (data['price_minor'] as num?)?.toInt();
    final currency = (data['currency_code'] as String? ?? 'EUR').trim();
    return InkWell(onTap: id.isEmpty ? null : () => context.push(AppRoutes.marketplaceDetailPath(id)), borderRadius: BorderRadius.circular(AppRadius.xs), child: Container(width: 300, padding: const EdgeInsets.all(AppSpacing.xs), decoration: BoxDecoration(color: LightModeColors.lightSurface.withValues(alpha: .8), borderRadius: BorderRadius.circular(AppRadius.xs)), child: Row(children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xs), child: SizedBox.square(dimension: 52, child: image == null ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.storefront_outlined)) : Image.network(image, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.broken_image_outlined))))), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['title'] as String? ?? '', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.labelLarge), if (amount != null) Text(MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale), style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w700))]))])));
  }
}

class MessageDeliveryIcon extends StatelessWidget {
  final ChatMessage message;
  const MessageDeliveryIcon({super.key, required this.message});
  @override
  Widget build(BuildContext context) => Icon(message.localState == LocalMessageState.sending ? Icons.schedule_rounded : message.localState == LocalMessageState.failed ? Icons.error_rounded : Icons.check_rounded, size: 15, color: message.localState == LocalMessageState.failed ? LightModeColors.lightError : LightModeColors.lightTextTertiary);
}

class ChatComposer extends StatelessWidget {
  final String conversationId;
  final TextEditingController controller;
  final ChatMessage? replyingTo;
  final ChatMessage? editing;
  final ValueChanged<String> onChanged;
  final VoidCallback onCancelMode;
  final VoidCallback onSend;
  final VoidCallback onGif;
  final bool gifEnabled;
  final SendChatMedia onMediaSend;

  const ChatComposer({super.key, required this.conversationId, required this.controller, this.replyingTo, this.editing, required this.gifEnabled, required this.onChanged, required this.onCancelMode, required this.onSend, required this.onGif, required this.onMediaSend});

  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Column(children: [
    if (replyingTo != null || editing != null) Container(margin: const EdgeInsets.only(bottom: AppSpacing.sm), padding: const EdgeInsets.all(AppSpacing.sm), decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)), child: Row(children: [const Icon(Icons.reply_rounded, size: 18), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(editing != null ? 'chat.edit_banner'.tr() : replyingTo!.sender.displayName, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w700)), if (replyingTo != null) Text(replyingTo!.body, maxLines: 1, overflow: TextOverflow.ellipsis)])), IconButton(onPressed: onCancelMode, icon: const Icon(Icons.close_rounded))])),
    Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      if (gifEnabled) ...[HBButton.ghost(label: 'gifs.button'.tr(), onPressed: editing == null ? onGif : null, size: HBButtonSize.sm), const SizedBox(width: AppSpacing.xs)],
      Expanded(child: CallbackShortcuts(bindings: kIsWeb ? {const SingleActivator(LogicalKeyboardKey.enter): onSend} : const {}, child: HBInput(controller: controller, hint: 'chat.input_hint'.tr(), maxLength: 4000, maxLines: 5, minLines: 1, onChanged: onChanged))),
      const SizedBox(width: AppSpacing.sm),
      ChatMediaComposerControls(textEmpty: controller.text.trim().isEmpty, onTextSend: onSend, onMediaSend: onMediaSend),
    ]),
    if (controller.text.length > 3800) Align(alignment: Alignment.centerRight, child: Text('${controller.text.length}/4000', style: context.textStyles.labelSmall?.withColor(controller.text.length >= 4000 ? LightModeColors.lightError : LightModeColors.lightTextTertiary))),
  ]));
}

Future<void> showParticipantsSheet(BuildContext context, Conversation conversation) => showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('chat.participants'.tr(), style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: AppSpacing.md), Flexible(child: ListView(shrinkWrap: true, children: conversation.participants.map((participant) => ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: participant.displayName, imageUrl: participant.avatarUrl, size: 40), title: Text(participant.displayName), subtitle: Text('@${participant.username}'))).toList()))]))));

Future<void> showReadersSheet(BuildContext context, List<ConversationParticipant> readers) => showModalBottomSheet<void>(context: context, builder: (_) => SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('chat.readers'.tr(), style: Theme.of(context).textTheme.titleLarge), const SizedBox(height: AppSpacing.md), Flexible(child: ListView(shrinkWrap: true, children: readers.map((participant) => ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: participant.displayName, imageUrl: participant.avatarUrl, size: 40), title: Text(participant.displayName), subtitle: Text(participant.lastReadAt == null ? '' : relativeTime(context, participant.lastReadAt!)))).toList()))]))));

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;