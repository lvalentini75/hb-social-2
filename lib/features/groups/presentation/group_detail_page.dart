import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/composer_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';
import 'package:hb_social/features/groups/presentation/group_studio_page.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';

class GroupDetailPage extends ConsumerStatefulWidget {
  final String groupId;
  final bool debugPreview;

  const GroupDetailPage({super.key, required this.groupId, this.debugPreview = false});

  @override
  ConsumerState<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends ConsumerState<GroupDetailPage> {
  int _tabIndex = 0;
  GroupMembership? _membership;
  String? _membershipGroupId;
  bool _working = false;

  void _syncMembership(Group group) {
    if (_membershipGroupId == group.id) return;
    _membershipGroupId = group.id;
    _membership = group.myMembership;
  }

  void _invalidate(Group group) {
    ref.invalidate(groupBySlugProvider(widget.groupId));
    ref.invalidate(groupsListProvider);
    ref.invalidate(groupPostsProvider(group.id));
    ref.invalidate(currentProfileProvider);
  }

  Future<bool> _confirm(String titleKey, String messageKey, String actionKey) async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
    title: Text(titleKey.tr()),
    content: Text(messageKey.tr()),
    actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: actionKey.tr(), onPressed: () => dialogContext.pop(true))],
  )) ?? false;

  Future<void> _join(Group group) async {
    if (ref.read(authSessionProvider).value == null) { context.go(AppRoutes.login); return; }
    setState(() => _working = true);
    try {
      final membership = await ref.read(groupRepositoryProvider).joinGroup(group.id);
      if (mounted) setState(() => _membership = membership);
      _invalidate(group);
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _leave(Group group, {required bool pending}) async {
    final confirmed = await _confirm(pending ? 'groups.cancel_request_title' : 'groups.leave_title', pending ? 'groups.cancel_request_message' : 'groups.leave_message', pending ? 'groups.cancel_request' : 'groups.leave');
    if (!confirmed || !mounted) return;
    setState(() => _working = true);
    try {
      await ref.read(groupRepositoryProvider).leaveGroup(group.id);
      if (mounted) setState(() => _membership = null);
      _invalidate(group);
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
    } finally {
      if (mounted) setState(() => _working = false);
    }
  }

  Future<void> _reactivate(Group group) async {
    try {
      await ref.read(groupRepositoryProvider).setGroupStatus(group.id, 'active');
      _invalidate(group);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('group_studio.reactivated'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(groupBySlugProvider(widget.groupId));
    return groupAsync.when(
      loading: () => const PageColumns(center: HBListSkeleton(count: 3)),
      error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'groups.error_title'.tr(), message: 'groups.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupBySlugProvider(widget.groupId)))))),
      data: (group) {
        if (group == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.groups_2_outlined, title: 'groups.not_found_title'.tr(), message: 'groups.not_found_message'.tr())));
        _syncMembership(group);
        return PageColumns(
          center: RefreshIndicator(
            onRefresh: () async { _membershipGroupId = null; ref.invalidate(groupBySlugProvider(widget.groupId)); ref.invalidate(groupPostsProvider(group.id)); await ref.read(groupBySlugProvider(widget.groupId).future); },
            child: NotificationListener<ScrollNotification>(
              onNotification: (notification) { if (notification.metrics.extentAfter < 500 && _tabIndex == 0) ref.read(groupPostsProvider(group.id).notifier).loadMore(); return false; },
              child: CustomScrollView(slivers: [
                SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
                  if (group.status == 'archived' && group.myMembership?.role == 'owner') ...[GroupArchivedBanner(group: group, onReactivate: () => _reactivate(group)), const SizedBox(height: AppSpacing.md)],
                  GroupHeader(group: group, membership: _membership, working: _working, onJoin: () => _join(group), onCancelRequest: () => _leave(group, pending: true), onLeave: () => _leave(group, pending: false)),
                  const SizedBox(height: AppSpacing.lg),
                  HBSegmentedTabs(variant: HBSegmentedTabsVariant.underlined, labels: ['groups.tab_posts'.tr(), 'groups.tab_members'.tr(), 'groups.tab_events'.tr(), 'groups.tab_info'.tr()], selectedIndex: _tabIndex, onChanged: (index) => setState(() => _tabIndex = index)),
                  const SizedBox(height: AppSpacing.md),
                  if (_tabIndex == 0) GroupPostsTab(group: group, membership: _membership),
                  if (_tabIndex == 1) GroupMembersTab(groupId: group.id),
                  if (_tabIndex == 2) HBCard(child: HBEmptyState(icon: Icons.event_outlined, title: 'groups.tab_events_empty_title'.tr(), message: 'groups.tab_events_empty_message'.tr())),
                  if (_tabIndex == 3) GroupInfoTab(group: group),
                ])),
              ]),
            ),
          ),
        );
      },
    );
  }
}

class GroupHeader extends StatelessWidget {
  final Group group;
  final GroupMembership? membership;
  final bool working;
  final VoidCallback onJoin;
  final VoidCallback onCancelRequest;
  final VoidCallback onLeave;

  const GroupHeader({super.key, required this.group, required this.membership, required this.working, required this.onJoin, required this.onCancelRequest, required this.onLeave});

  String get _visibilityKey => 'groups.visibility.${group.visibility}';
  String get _joinKey => 'groups.join_policy.${group.joinPolicy}';

  @override
  Widget build(BuildContext context) => HBCard.media(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Stack(clipBehavior: Clip.none, children: [
      SizedBox(height: MediaQuery.sizeOf(context).width < AppBreakpoints.mobile ? 220 : 280, width: double.infinity, child: group.coverUrl?.isNotEmpty == true ? Image.network(group.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft)) : const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.groups_2_rounded, size: 28, color: LightModeColors.bosco))),
      Positioned(left: AppSpacing.md, top: AppSpacing.md, child: GroupOverlayButton(icon: Icons.arrow_back_rounded, onTap: () => context.pop())),
      Positioned(left: AppSpacing.lg, bottom: -36, child: HBAvatar(name: group.name, imageUrl: group.avatarUrl, size: 72, ringColor: Colors.white)),
    ]),
    Padding(padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 44, AppSpacing.lg, AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(group.name, style: AppText.heading.withColor(LightModeColors.text)),
      const SizedBox(height: AppSpacing.sm),
      Text('${'groups.member_count'.plural(group.memberCount)} · ${'groups.post_count'.plural(group.postCount)} · ${_visibilityKey.tr()} · ${_joinKey.tr()}', style: AppText.label.withColor(LightModeColors.textSecondary)),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
        GroupMembershipAction(group: group, membership: membership, working: working, onJoin: onJoin, onCancelRequest: onCancelRequest, onLeave: onLeave),
        if (membership?.canManage == true) HBButton.secondary(label: 'groups.studio'.tr(), icon: Icons.tune_rounded, onPressed: () => context.push('${AppRoutes.groupDetailPath(group.slug)}/studio')),
        if (membership?.canManage == true) PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) { if (value == 'event') context.push('${AppRoutes.eventCreate}?group=${group.id}'); }, itemBuilder: (_) => [PopupMenuItem(value: 'event', child: Text('events.create'.tr()))]),
      ]),
    ])),
  ]));
}

/// 40 px white round overlay control on the group cover.
class GroupOverlayButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const GroupOverlayButton({super.key, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => Material(
    color: LightModeColors.surface,
    shape: const CircleBorder(),
    child: InkWell(customBorder: const CircleBorder(), onTap: onTap, child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 18, color: LightModeColors.text))),
  );
}

class GroupMembershipAction extends StatelessWidget {
  final Group group;
  final GroupMembership? membership;
  final bool working;
  final VoidCallback onJoin;
  final VoidCallback onCancelRequest;
  final VoidCallback onLeave;

  const GroupMembershipAction({super.key, required this.group, required this.membership, required this.working, required this.onJoin, required this.onCancelRequest, required this.onLeave});

  @override
  Widget build(BuildContext context) {
    if (membership?.status == 'banned') return HBButton.soft(label: 'groups.banned'.tr(), onPressed: null);
    if (membership?.status == 'pending') return HBButton.soft(label: 'groups.request_sent'.tr(), icon: Icons.schedule_rounded, onPressed: working ? null : onCancelRequest, isLoading: working);
    if (membership?.isActive == true) {
      final owner = membership!.role == 'owner';
      return Row(mainAxisSize: MainAxisSize.min, children: [
        HBStatusChip(kind: HBStatusKind.approved, label: 'groups.member_chip'.tr()),
        const SizedBox(width: AppSpacing.xs),
        Tooltip(message: owner ? 'groups.owner_cannot_leave'.tr() : '', child: PopupMenuButton<String>(enabled: !working, icon: const Icon(Icons.more_horiz_rounded), onSelected: (_) => onLeave(), itemBuilder: (_) => [PopupMenuItem(value: 'leave', enabled: !owner, child: Text('groups.leave'.tr()))])),
      ]);
    }
    return HBButton.primary(label: (group.joinPolicy == 'approval' ? 'groups.request_join' : 'groups.join').tr(), onPressed: working ? null : onJoin, isLoading: working);
  }
}

class GroupPostsTab extends ConsumerWidget {
  final Group group;
  final GroupMembership? membership;

  const GroupPostsTab({super.key, required this.group, required this.membership});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (group.visibility == 'private' && membership?.isActive != true) return HBCard(child: HBEmptyState(icon: Icons.lock_outline_rounded, title: 'groups.members_only_title'.tr(), message: 'groups.members_only_message'.tr()));
    final posts = ref.watch(groupPostsProvider(group.id));
    return Column(children: [
      if (membership?.isActive == true) ...[GroupComposerBar(group: group), const SizedBox(height: AppSpacing.md)],
      posts.when(
        loading: () => const HBListSkeleton(count: 3, showTrailing: false),
        error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'groups.posts_error_title'.tr(), message: 'groups.posts_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupPostsProvider(group.id))))),
        data: (page) => page.items.isEmpty
            ? HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'groups.posts_empty_title'.tr(), message: 'groups.posts_empty_message'.tr()))
            : Column(children: [for (var index = 0; index < page.items.length; index++) ...[FeedPostCard(post: page.items[index]), if (index < page.items.length - 1) const SizedBox(height: AppSpacing.md)], if (page.isLoadingMore) const Padding(padding: EdgeInsets.all(AppSpacing.md), child: LinearProgressIndicator())]),
      ),
    ]);
  }
}

class GroupComposerBar extends StatelessWidget {
  final Group group;

  const GroupComposerBar({super.key, required this.group});

  @override
  Widget build(BuildContext context) => HBCard(child: InkWell(onTap: () => showGroupComposerSheet(context, groupId: group.id, groupName: group.name, groupVisibility: group.visibility), child: Row(children: [const Icon(Icons.edit_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('groups.composer_hint'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)))])));
}

class GroupMembersTab extends ConsumerWidget {
  final String groupId;

  const GroupMembersTab({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(groupMembersProvider(groupId)).when(
    loading: () => const HBListSkeleton(),
    error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'groups.error_title'.tr(), message: 'groups.error_message'.tr())),
    data: (members) => members.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.people_outline_rounded, title: 'groups.tab_members_empty_title'.tr(), message: 'groups.tab_members_empty_message'.tr())) : HBCard(child: Column(children: members.map((member) => ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: Text(member.profile.displayName), subtitle: Text('@${member.profile.username}'), trailing: FollowButton(userId: member.profile.id, username: member.profile.username, size: HBButtonSize.sm), onTap: () => context.push(AppRoutes.publicProfilePath(member.profile.username)))).toList())),
  );
}

class GroupInfoTab extends StatelessWidget {
  final Group group;

  const GroupInfoTab({super.key, required this.group});

  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    GroupInfoRow(label: 'groups.info_description'.tr(), value: group.description ?? 'groups.info_not_set'.tr()),
    const SizedBox(height: AppSpacing.sm),
    GroupInfoRow(label: 'groups.info_country'.tr(), value: group.countryCode),
    const SizedBox(height: AppSpacing.sm),
    GroupInfoRow(label: 'groups.info_created'.tr(), value: DateFormat.yMMMd(context.locale.toString()).format(group.createdAt.toLocal())),
  ]));
}

class GroupInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const GroupInfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 140, child: Text(label, style: context.textStyles.labelMedium?.withColor(LightModeColors.lightTextTertiary))), Expanded(child: Text(value, style: context.textStyles.bodyMedium))]);
}

