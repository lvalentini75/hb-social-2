import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/chat/domain/conversation.dart';
import 'package:hb_social/features/chat/providers/chat_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/social_graph/domain/social_connection.dart';
import 'package:hb_social/features/social_graph/providers/social_graph_providers.dart';
import 'package:hb_social/core/providers/platform_providers.dart';

class MessagesPage extends ConsumerWidget {
  const MessagesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authSessionProvider).value;
    if (session == null) {
      return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.login_rounded, title: 'chat.guest_title'.tr(), message: 'chat.guest_message'.tr(), action: HBButton.primary(label: 'chat.sign_in'.tr(), onPressed: () => context.push(AppRoutes.login)))));
    }
    return PageColumns(center: ConversationInbox(selectedId: null, onNewConversation: () => showNewConversationSheet(context)));
  }
}

class ConversationInbox extends ConsumerStatefulWidget {
  final String? selectedId;
  final VoidCallback onNewConversation;
  final bool compact;
  final ValueChanged<String>? onConversationTap;

  const ConversationInbox({super.key, required this.selectedId, required this.onNewConversation, this.compact = false, this.onConversationTap});

  @override
  ConsumerState<ConversationInbox> createState() => _ConversationInboxState();
}

class _ConversationInboxState extends ConsumerState<ConversationInbox> {
  ConversationFilter _filter = ConversationFilter.all;
  String _search = '';

  void _setSearch(String value) {
    final normalized = value.trim().toLowerCase();
    if (_search == normalized) return;
    setState(() => _search = normalized);
  }

  @override
  Widget build(BuildContext context) {
    final value = ref.watch(conversationsProvider);
    final me = ref.watch(authSessionProvider).value?.user.id;
    final isPhone = !widget.compact && MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final callsEnabled = ref.watch(featureFlagsProvider).value?['calls'] == true;
    return Column(children: [
      Padding(
        padding: EdgeInsets.all(widget.compact ? AppSpacing.md : AppSpacing.lg),
        child: Column(children: [
          if (isPhone)
            MobileMessagesHeader(callsEnabled: callsEnabled, onCalls: () => context.push(AppRoutes.calls), onNewConversation: widget.onNewConversation)
          else
            HBPageHeader(title: 'nav.messages'.tr(), action: Row(mainAxisSize: MainAxisSize.min, children: [if (callsEnabled) ...[HBButton.secondary(label: widget.compact ? '' : 'calls.title'.tr(), icon: Icons.phone_outlined, onPressed: () => context.push(AppRoutes.calls)), const SizedBox(width: AppSpacing.sm)], HBButton.primary(label: widget.compact ? '' : 'chat.new'.tr(), icon: Icons.edit_outlined, onPressed: widget.onNewConversation)])),
          const SizedBox(height: AppSpacing.md),
          HBInput(search: isPhone, hint: 'chat.search_conversations'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: _setSearch),
          if (!isPhone) ...[
            const SizedBox(height: AppSpacing.sm),
            HBSegmentedTabs(labels: ['chat.filters.all'.tr(), 'chat.filters.unread'.tr(), 'chat.filters.groups'.tr()], selectedIndex: _filter.index, onChanged: (index) => setState(() => _filter = ConversationFilter.values[index])),
          ],
        ]),
      ),
      if (!isPhone) const Divider(height: 1),
      Expanded(child: RefreshIndicator(
        onRefresh: () async => ref.refresh(conversationsProvider.future),
        child: value.when(
          loading: () => ListView(physics: AlwaysScrollableScrollPhysics(), padding: EdgeInsets.all(AppSpacing.md), children: [HBListSkeleton(showTrailing: true)]),
          error: (_, __) => ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(AppSpacing.md), children: [HBEmptyState(icon: Icons.error_outline_rounded, title: 'chat.error_title'.tr(), message: 'chat.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(conversationsProvider)))]),
          data: (state) {
            final items = state.items.where((conversation) {
              if (!isPhone && _filter == ConversationFilter.unread && conversation.unreadCount == 0) return false;
              if (!isPhone && _filter == ConversationFilter.groups && !conversation.isGroup) return false;
              return _search.isEmpty || conversation.displayName(me).toLowerCase().contains(_search);
            }).toList();
            if (items.isEmpty) return ListView(physics: const AlwaysScrollableScrollPhysics(), padding: const EdgeInsets.all(AppSpacing.lg), children: [HBEmptyState(icon: Icons.chat_bubble_outline_rounded, title: 'chat.empty_title'.tr(), message: _search.isEmpty ? 'chat.empty_message'.tr() : 'chat.search_empty'.tr(), action: _search.isEmpty ? HBButton.primary(label: 'chat.new'.tr(), onPressed: widget.onNewConversation) : null)]);
            final list = ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(), padding: EdgeInsets.only(top: isPhone ? AppSpacing.xs : 0, bottom: AppSpacing.xs), itemCount: items.length + (state.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == items.length) return Padding(padding: const EdgeInsets.all(AppSpacing.md), child: HBButton.soft(label: 'chat.load_more'.tr(), isLoading: state.loadingMore, onPressed: state.loadingMore ? null : () => ref.read(conversationsProvider.notifier).loadMore()));
                  return ConversationListTile(conversation: items[index], selected: items[index].id == widget.selectedId, currentUserId: me, onTap: widget.onConversationTap);
                });
            if (!isPhone || _search.isNotEmpty) return list;
            final online = items.where((conversation) {
              final other = conversation.other(me);
              return !conversation.isGroup && other?.lastSeenAt != null && DateTime.now().toUtc().difference(other!.lastSeenAt!).inMinutes < 5;
            }).toList();
            return Column(children: [if (online.isNotEmpty) MobileOnlineConversations(conversations: online, currentUserId: me, onConversationTap: widget.onConversationTap), Expanded(child: list)]);
          },
        ),
      )),
    ]);
  }
}

/// Compact, icon-led header used only by the smartphone inbox.
class MobileMessagesHeader extends StatelessWidget {
  final bool callsEnabled;
  final VoidCallback onCalls;
  final VoidCallback onNewConversation;

  const MobileMessagesHeader({super.key, required this.callsEnabled, required this.onCalls, required this.onNewConversation});

  @override
  Widget build(BuildContext context) => Row(children: [
    Expanded(child: Text('nav.messages'.tr(), style: context.textStyles.headlineLarge?.copyWith(fontWeight: FontWeight.w800))),
    if (callsEnabled) ...[
      HBButton.icon(icon: Icons.phone_outlined, tooltip: 'calls.title'.tr(), backgroundColor: Colors.transparent, foregroundColor: LightModeColors.lightOnSurface, onPressed: onCalls),
      const SizedBox(width: AppSpacing.xs),
    ],
    HBButton.icon(icon: Icons.edit_square, tooltip: 'chat.new'.tr(), backgroundColor: Colors.transparent, foregroundColor: LightModeColors.lightOnSurface, onPressed: onNewConversation),
  ]);
}

/// Horizontally scrollable shortcuts for currently online direct chats.
class MobileOnlineConversations extends StatelessWidget {
  final List<Conversation> conversations;
  final String? currentUserId;
  final ValueChanged<String>? onConversationTap;

  const MobileOnlineConversations({super.key, required this.conversations, required this.currentUserId, this.onConversationTap});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 104,
    child: ListView.separated(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xs),
      itemCount: conversations.length,
      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
      itemBuilder: (context, index) {
        final conversation = conversations[index];
        final name = conversation.displayName(currentUserId);
        void open() {
          if (onConversationTap != null) { onConversationTap!(conversation.id); } else { context.go(AppRoutes.conversationDetailPath(conversation.id)); }
        }
        return SizedBox(width: 68, child: Column(children: [
          HBAvatar(name: name, imageUrl: conversation.avatarUrl(currentUserId), size: 64, showPresence: true, onTap: open),
          const SizedBox(height: 5),
          Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: context.textStyles.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
        ]));
      },
    ),
  );
}

class ConversationListTile extends ConsumerWidget {
  final Conversation conversation;
  final bool selected;
  final String? currentUserId;
  final ValueChanged<String>? onTap;

  const ConversationListTile({super.key, required this.conversation, required this.selected, required this.currentUserId, this.onTap});

  String _preview() {
    final message = conversation.lastMessage;
    if (message == null) return 'chat.no_messages'.tr();
    if (message.status == 'deleted') return 'chat.deleted'.tr();
    if (message.kind == 'image') return message.body.isEmpty ? 'chat.photo'.tr() : 'chat_b.photo_caption'.tr(namedArgs: {'caption': message.body});
    if (message.kind == 'voice') return 'chat.voice'.tr();
    if (message.kind == 'system') return localizedSystemMessage(message.body, message.meta);
    final prefix = message.senderId == currentUserId ? 'chat.you_prefix'.tr() : '';
    return '$prefix${message.body}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final other = conversation.other(currentUserId);
    final isOnline = !conversation.isGroup && other?.lastSeenAt != null && DateTime.now().toUtc().difference(other!.lastSeenAt!).inMinutes < 5;
    final isPhone = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final tile = Material(
      color: selected ? LightModeColors.lightPrimarySoft : Colors.transparent,
      child: InkWell(
        onTap: () { if (onTap != null) { onTap!(conversation.id); } else { context.go(AppRoutes.conversationDetailPath(conversation.id)); } },
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isPhone ? AppSpacing.lg : AppSpacing.md, vertical: isPhone ? 10 : AppSpacing.sm),
          child: Row(children: [
            if (isPhone && conversation.unreadCount > 0) ...[
              const DecoratedBox(decoration: BoxDecoration(color: LightModeColors.lightPrimary, shape: BoxShape.circle), child: SizedBox(width: 8, height: 8)),
              const SizedBox(width: AppSpacing.sm),
            ],
            HBAvatar(name: conversation.displayName(currentUserId), imageUrl: conversation.avatarUrl(currentUserId), size: isPhone ? 64 : 48, showPresence: isOnline),
            SizedBox(width: isPhone ? AppSpacing.md : AppSpacing.sm),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(conversation.displayName(currentUserId), maxLines: 1, overflow: TextOverflow.ellipsis, style: (isPhone ? context.textStyles.bodyLarge : context.textStyles.bodyMedium)?.copyWith(fontWeight: conversation.unreadCount > 0 ? FontWeight.w700 : FontWeight.w600)),
              const SizedBox(height: 2),
              Text(_preview(), maxLines: 1, overflow: TextOverflow.ellipsis, style: (isPhone ? context.textStyles.bodyMedium : context.textStyles.bodySmall)?.copyWith(color: conversation.unreadCount > 0 ? LightModeColors.lightOnSurface : LightModeColors.lightOnSurfaceVariant, fontWeight: conversation.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400, fontStyle: conversation.lastMessage?.status == 'deleted' ? FontStyle.italic : null)),
            ])),
            const SizedBox(width: AppSpacing.sm),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(relativeTime(context, conversation.lastMessageAt ?? conversation.createdAt), style: context.textStyles.labelSmall?.withColor(conversation.unreadCount > 0 && isPhone ? LightModeColors.lightPrimary : LightModeColors.lightTextTertiary)),
              const SizedBox(height: 4),
              Row(mainAxisSize: MainAxisSize.min, children: [if (conversation.isMuted) const Icon(Icons.notifications_off_outlined, size: 15, color: LightModeColors.lightTextTertiary), if (!isPhone && conversation.isMuted && conversation.unreadCount > 0) const SizedBox(width: 4), if (!isPhone && conversation.unreadCount > 0) HBBadge.count(count: conversation.unreadCount)]),
            ]),
          ]),
        ),
      ),
    );
    if (MediaQuery.sizeOf(context).width >= 900) return tile;
    return Dismissible(key: ValueKey('conversation-${conversation.id}'), direction: DismissDirection.startToEnd, confirmDismiss: (_) async {
      final action = await showModalBottomSheet<String>(context: context, builder: (_) => SafeArea(child: Column(mainAxisSize: MainAxisSize.min, children: [ListTile(leading: Icon(conversation.isMuted ? Icons.notifications_active_outlined : Icons.notifications_off_outlined), title: Text(conversation.isMuted ? 'chat_b.unmute'.tr() : 'chat_b.mute'.tr()), onTap: () => context.pop('mute')), ListTile(leading: Icon(conversation.isGroup ? Icons.logout_rounded : Icons.delete_outline_rounded), title: Text(conversation.isGroup ? 'chat_b.leave_group'.tr() : 'chat_b.delete_conversation'.tr()), onTap: () => context.pop('leave'))])));
      if (action == 'mute') await ref.read(chatRepositoryProvider).setMuted(conversation.id, conversation.isMuted ? null : DateTime.now().toUtc().add(const Duration(days: 36500)));
      if (action == 'leave') await ref.read(chatRepositoryProvider).leaveConversation(conversation.id);
      if (action != null) ref.invalidate(conversationsProvider);
      return false;
    }, background: Container(color: LightModeColors.lightPrimarySoft, padding: const EdgeInsets.only(left: AppSpacing.lg), alignment: Alignment.centerLeft, child: const Icon(Icons.more_horiz_rounded, color: LightModeColors.lightPrimary)), child: tile);
  }
}

Future<void> showNewConversationSheet(BuildContext context) => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const NewConversationSheet());

class NewConversationSheet extends ConsumerStatefulWidget {
  const NewConversationSheet({super.key});

  @override
  ConsumerState<NewConversationSheet> createState() => _NewConversationSheetState();
}

class _NewConversationSheetState extends ConsumerState<NewConversationSheet> {
  final _searchController = TextEditingController();
  final _titleController = TextEditingController();
  final Map<String, UserProfile> _selected = {};
  Timer? _debounce;
  String _query = '';
  bool _group = false;
  bool _working = false;

  @override
  void dispose() { _debounce?.cancel(); _searchController.dispose(); _titleController.dispose(); super.dispose(); }

  void _search(String text) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () { if (mounted) setState(() => _query = text.trim()); });
  }

  Future<void> _open(UserProfile profile) async {
    if (_group) { setState(() => _selected[profile.id] = profile); return; }
    setState(() => _working = true);
    try {
      final id = await ref.read(chatRepositoryProvider).startDirect(profile.id);
      ref.invalidate(conversationsProvider);
      if (mounted) { context.pop(); context.go(AppRoutes.conversationDetailPath(id)); }
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => _working = false); }
  }

  Future<void> _createGroup() async {
    if (_selected.isEmpty) return;
    setState(() => _working = true);
    try {
      final id = await ref.read(chatRepositoryProvider).createGroup(_titleController.text, _selected.keys.toList());
      ref.invalidate(conversationsProvider);
      if (mounted) { context.pop(); context.go(AppRoutes.conversationDetailPath(id)); }
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
    finally { if (mounted) setState(() => _working = false); }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(authSessionProvider).value?.user.id;
    final results = _query.isEmpty ? null : ref.watch(peopleSearchProvider(_query));
    final friends = _query.isEmpty && me != null ? ref.watch(friendsProvider(me)) : null;
    return FractionallySizedBox(heightFactor: .9, child: Padding(
      padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('chat.new'.tr(), style: context.textStyles.headlineSmall)), Switch(value: _group, onChanged: (value) => setState(() { _group = value; _selected.clear(); }), activeColor: LightModeColors.lightPrimary), Text('chat.create_group_toggle'.tr())]),
        const SizedBox(height: AppSpacing.md),
        if (_group) ...[
          HBInput(controller: _titleController, label: 'chat.group_title'.tr(), hint: 'chat.group_title_hint'.tr(), maxLength: 80),
          if (_selected.isNotEmpty) ...[const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: _selected.values.map((profile) => InputChip(label: Text(profile.displayName), onDeleted: () => setState(() => _selected.remove(profile.id)))).toList())],
          const SizedBox(height: AppSpacing.md),
        ],
        HBInput(controller: _searchController, hint: 'chat.search_people'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: _search),
        const SizedBox(height: AppSpacing.md),
        if (_query.isEmpty) Text('chat.friends'.tr(), style: context.textStyles.titleSmall),
        const SizedBox(height: AppSpacing.sm),
        Expanded(child: _PeopleResults(results: results, friends: friends, selected: _selected.keys.toSet(), onTap: _working ? null : _open)),
        if (_group) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: SizedBox(width: double.infinity, child: HBButton.primary(label: 'chat.create_group'.tr(namedArgs: {'n': '${_selected.length}'}), isLoading: _working, onPressed: _selected.isEmpty ? null : _createGroup))),
      ]),
    ));
  }
}

class _PeopleResults extends StatelessWidget {
  final AsyncValue<List<UserProfile>>? results;
  final AsyncValue<dynamic>? friends;
  final Set<String> selected;
  final ValueChanged<UserProfile>? onTap;

  const _PeopleResults({required this.results, required this.friends, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (results != null) return results!.when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'chat.people_error'.tr(), message: 'chat.error_message'.tr()), data: (items) => _list(items));
    if (friends != null) return friends!.when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'chat.people_error'.tr(), message: 'chat.error_message'.tr()), data: (state) => _list((state.items as List<FriendProfile>).map((item) => item.profile).map((profile) => UserProfile(id: profile.id, username: profile.username, displayName: profile.displayName, avatarUrl: profile.avatarUrl, countryCode: '', locale: 'it', currencyCode: 'EUR', unitSystem: 'metric', status: 'active', verificationLevel: profile.verificationLevel, createdAt: DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), lastSeenAt: profile.lastSeenAt)).toList()));
    return const SizedBox.shrink();
  }

  Widget _list(List<UserProfile> items) => items.isEmpty
      ? HBEmptyState(icon: Icons.person_search_outlined, title: 'chat.people_empty'.tr(), message: 'chat.people_empty_message'.tr())
      : ListView.builder(itemCount: items.length, itemBuilder: (context, index) { final profile = items[index]; return ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 42), title: Text(profile.displayName), subtitle: Text('@${profile.username}'), trailing: selected.contains(profile.id) ? const Icon(Icons.check_circle, color: LightModeColors.lightPrimary) : null, onTap: onTap == null ? null : () => onTap!(profile)); });
}

String localizedSystemMessage(String code, Map<String, dynamic> meta) {
  final actor = meta['actor_name']?.toString() ?? '';
  final names = (meta['target_names'] as List?)?.map((item) => item.toString()).toList() ?? const [];
  final joined = _joinNames(names);
  final key = switch (code) { 'created' => names.isEmpty ? 'chat.system.created' : 'chat.system.created_with', 'member_added' => 'chat.system.member_added', 'member_removed' => 'chat.system.member_removed', 'member_left' => 'chat.system.member_left', 'renamed' => 'chat.system.renamed', _ => 'chat.system.generic' };
  return key.tr(namedArgs: {'actor': actor, 'names': joined, 'title': meta['title']?.toString() ?? ''});
}

String _joinNames(List<String> names) {
  if (names.length < 2) return names.join();
  return '${names.take(names.length - 1).join(', ')} ${'chat.names_and'.tr()} ${names.last}';
}