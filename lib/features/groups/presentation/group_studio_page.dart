import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/media_source_picker.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/media_upload_service.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_image_cropper.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/studio_overview.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/groups/data/group_repository.dart';
import 'package:hb_social/features/groups/domain/group.dart';
import 'package:hb_social/features/groups/presentation/group_create_page.dart';
import 'package:hb_social/features/groups/providers/group_providers.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/profile/providers/profile_providers.dart';

class GroupStudioPage extends ConsumerStatefulWidget {
  final String slug;

  const GroupStudioPage({super.key, required this.slug});

  @override
  ConsumerState<GroupStudioPage> createState() => _GroupStudioPageState();
}

class _GroupStudioPageState extends ConsumerState<GroupStudioPage> {
  String _tab = 'overview';

  void _invalidate(String groupId) {
    ref.invalidate(groupStudioSummaryProvider(groupId));
    ref.invalidate(groupStudioPendingProvider(groupId));
    ref.invalidate(groupStudioMembersProvider(groupId));
    ref.invalidate(groupStudioBannedProvider(groupId));
    for (final days in const [7, 30, 90]) { ref.invalidate(groupStudioStatsProvider((groupId: groupId, days: days))); }
    ref.invalidate(groupBySlugProvider(widget.slug));
    ref.invalidate(groupsListProvider);
  }

  void _message(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  Future<void> _run(String groupId, Future<void> Function() action, String successKey, {bool requestAction = false}) async {
    try {
      await action();
      _invalidate(groupId);
      if (mounted) _message(successKey);
    } on AppException catch (error) {
      _invalidate(groupId);
      if (!mounted) return;
      _message(requestAction && error.messageKey == 'group_studio.errors.request_not_pending' ? 'group_studio.request_already_handled' : error.messageKey);
    }
  }

  @override
  Widget build(BuildContext context) => ref.watch(groupBySlugProvider(widget.slug)).when(
    loading: () => const PageColumns(center: HBListSkeleton(count: 4)),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'group_studio.load_error_title'.tr(), message: 'group_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupBySlugProvider(widget.slug)))))),
    data: (group) => group == null
        ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.groups_2_outlined, title: 'groups.not_found_title'.tr(), message: 'groups.not_found_message'.tr())))
        : ref.watch(groupStudioSummaryProvider(group.id)).when(
            loading: () => const PageColumns(center: HBListSkeleton(count: 4)),
            error: (error, _) => PageColumns(center: error is AppException && error.messageKey == 'group_studio.errors.permission_denied' ? GroupStudioDenied(slug: widget.slug) : HBCard(child: GroupStudioListError(onRetry: () => ref.invalidate(groupStudioSummaryProvider(group.id))))),
            data: (summary) {
              if (!const {'owner', 'admin', 'moderator'}.contains(summary.role)) return PageColumns(center: GroupStudioDenied(slug: widget.slug));
              final tabs = <String>['overview'];
              if (group.joinPolicy == 'approval') tabs.add('requests');
              tabs.addAll(['members', 'banned']);
              if (summary.role == 'owner' || summary.role == 'admin') tabs.add('settings');
              if (!tabs.contains(_tab)) _tab = tabs.first;
              final selected = tabs.indexOf(_tab);
              final labels = tabs.map((tab) => tab == 'overview' ? 'studio_overview.overview'.tr() : 'group_studio.tabs.$tab'.tr()).toList();
              final badges = tabs.map<int?>((tab) => switch (tab) {'requests' => summary.pendingCount, 'members' => summary.memberCount, 'banned' => summary.bannedCount, _ => null}).toList();
              return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
                if (group.status == 'archived') ...[GroupArchivedBanner(group: group, onReactivate: () => _run(group.id, () => ref.read(groupRepositoryProvider).setGroupStatus(group.id, 'active'), 'group_studio.reactivated')), const SizedBox(height: AppSpacing.md)],
                HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: GroupStudioHeader(group: group, summary: summary)),
                const SizedBox(height: AppSpacing.md),
                HBSegmentedTabs(labels: labels, badges: badges, selectedIndex: selected, scrollable: true, onChanged: (index) => setState(() => _tab = tabs[index])),
                const SizedBox(height: AppSpacing.md),
                GroupStudioPanel(child: switch (_tab) {
                  'overview' => GroupStudioOverview(group: group),
                  'requests' => GroupRequestsList(groupId: group.id, onReview: (member, accept) => _run(group.id, () async { await ref.read(groupRepositoryProvider).reviewJoinRequest(member.id, accept: accept); }, accept ? 'group_studio.request_accepted' : 'group_studio.request_declined', requestAction: true)),
                  'members' => GroupMembersStudioList(groupId: group.id, myRole: summary.role, onChanged: () => _invalidate(group.id)),
                  'banned' => GroupBannedList(groupId: group.id, onUnban: (member) => _run(group.id, () => ref.read(groupRepositoryProvider).unbanMember(member.id), 'studio_overview.user_unbanned_active')),
                  _ => GroupSettingsForm(group: group, myRole: summary.role, onSaved: () => _invalidate(group.id)),
                }),
              ]))]));
            },
          ),
  );
}

class GroupStudioOverview extends ConsumerStatefulWidget {
  final Group group;
  const GroupStudioOverview({super.key, required this.group});
  @override
  ConsumerState<GroupStudioOverview> createState() => _GroupStudioOverviewState();
}

class _GroupStudioOverviewState extends ConsumerState<GroupStudioOverview> {
  int _days = 30;
  String _series = 'posts';

  @override
  Widget build(BuildContext context) {
    final request = (groupId: widget.group.id, days: _days);
    return ref.watch(groupStudioStatsProvider(request)).when(
      loading: () => const HBListSkeleton(count: 4),
      error: (_, __) => HBEmptyState(icon: Icons.query_stats_outlined, title: 'group_analytics.error_title'.tr(), message: 'group_analytics.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(groupStudioStatsProvider(request)))),
      data: (stats) => StudioOverview(
        stats: stats.overview,
        labels: {for (final key in const ['members', 'posts', 'reactions', 'comments']) key: 'group_analytics.metrics.$key'.tr()},
        series: const ['posts', 'members', 'reactions', 'comments'],
        selectedSeries: _series,
        onPeriodChanged: (value) => setState(() => _days = value),
        onSeriesChanged: (value) => setState(() => _series = value),
        lists: [
          StudioOverviewList(title: 'group_analytics.latest_members'.tr(), children: [for (final item in stats.latestMembers.take(10)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 34), title: Text(item.profile.displayName, overflow: TextOverflow.ellipsis), subtitle: Text('group_analytics.joined'.tr(namedArgs: {'time': relativeTime(context, item.joinedAt)})), trailing: DateTime.now().difference(item.joinedAt).inHours < 24 ? HBStatusChip(kind: HBStatusKind.approved, label: 'studio_overview.new'.tr()) : null, onTap: () => context.push(AppRoutes.publicProfilePath(item.profile.username)))]),
          StudioOverviewList(title: 'group_analytics.top_posts'.tr(), children: [for (final item in stats.topPosts.take(5)) ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(item.preview.isNotEmpty ? item.preview : 'admin.p05d.kinds.${item.kind}'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('group_analytics.post_counts'.tr(namedArgs: {'reactions': '${item.reactionCount}', 'comments': '${item.commentCount}'})), onTap: () => context.push(AppRoutes.postPath(item.id)))]),
          StudioOverviewList(title: 'group_analytics.top_contributors'.tr(), children: [for (final item in stats.topContributors.take(5)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 34), title: Text(item.profile.displayName, overflow: TextOverflow.ellipsis), subtitle: Text('group_analytics.period_posts'.plural(item.posts)), onTap: () => context.push(AppRoutes.publicProfilePath(item.profile.username)))]),
        ],
      ),
    );
  }
}

class GroupStudioPanel extends StatelessWidget {
  final Widget child;

  const GroupStudioPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) => HBCard(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 700 ? AppSpacing.lg : AppSpacing.md), child: child);
}

class GroupStudioDenied extends StatelessWidget {
  final String slug;

  const GroupStudioDenied({super.key, required this.slug});

  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.admin_panel_settings_outlined, title: 'group_studio.denied_title'.tr(), message: 'group_studio.denied_message'.tr(), action: HBButton.primary(label: 'group_studio.back_to_group'.tr(), onPressed: () => context.go(AppRoutes.groupDetailPath(slug)))));
}

class GroupStudioHeader extends StatelessWidget {
  final Group group;
  final GroupStudioSummary summary;

  const GroupStudioHeader({super.key, required this.group, required this.summary});

  @override
  Widget build(BuildContext context) => Row(children: [
    HBAvatar(name: group.name, imageUrl: group.avatarUrl, size: 48),
    const SizedBox(width: AppSpacing.md),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(group.name, style: context.textStyles.titleLarge), Text('${'groups.member_count'.plural(summary.memberCount)} · ${'groups.post_count'.plural(summary.postCount)}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])),
    HBButton.ghost(label: 'group_studio.view_group'.tr(), onPressed: () => context.go(AppRoutes.groupDetailPath(group.slug))),
  ]);
}

class GroupArchivedBanner extends StatelessWidget {
  final Group group;
  final VoidCallback? onReactivate;

  const GroupArchivedBanner({super.key, required this.group, this.onReactivate});

  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightWarning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.archive_outlined, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('group_studio.archived'.tr(), style: context.textStyles.titleSmall)), if (onReactivate != null) HBButton.soft(label: 'group_studio.reactivate'.tr(), onPressed: onReactivate, size: HBButtonSize.sm)]));
}

class GroupRequestsList extends ConsumerWidget {
  final String groupId;
  final void Function(GroupMember member, bool accept) onReview;

  const GroupRequestsList({super.key, required this.groupId, required this.onReview});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(groupStudioPendingProvider(groupId)).when(
    loading: () => const HBListSkeleton(),
    error: (_, __) => GroupStudioListError(onRetry: () => ref.invalidate(groupStudioPendingProvider(groupId))),
    data: (members) => AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: members.isEmpty
        ? HBEmptyState(key: const ValueKey('empty'), icon: Icons.how_to_reg_outlined, title: 'group_studio.requests_empty'.tr(), message: 'group_studio.requests_empty_message'.tr())
        : Column(key: ValueKey(members.length), children: [for (final member in members) GroupRequestRow(member: member, onReview: onReview)])),
  );
}

class GroupRequestRow extends StatelessWidget {
  final GroupMember member;
  final void Function(GroupMember member, bool accept) onReview;

  const GroupRequestRow({super.key, required this.member, required this.onReview});

  @override
  Widget build(BuildContext context) => SizedBox(height: 64, child: ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: InkWell(onTap: () => context.push(AppRoutes.publicProfilePath(member.profile.username)), child: Text(member.profile.displayName, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600))), subtitle: Text(relativeTime(context, member.createdAt), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), trailing: Wrap(spacing: AppSpacing.xs, children: [HBButton.ghost(label: 'group_studio.decline'.tr(), onPressed: () => onReview(member, false), size: HBButtonSize.sm), HBButton.primary(label: 'group_studio.accept'.tr(), onPressed: () => onReview(member, true), size: HBButtonSize.sm)])));
}

class GroupMembersStudioList extends ConsumerStatefulWidget {
  final String groupId;
  final String myRole;
  final VoidCallback onChanged;

  const GroupMembersStudioList({super.key, required this.groupId, required this.myRole, required this.onChanged});

  @override
  ConsumerState<GroupMembersStudioList> createState() => _GroupMembersStudioListState();
}

class _GroupMembersStudioListState extends ConsumerState<GroupMembersStudioList> {
  final _search = TextEditingController();
  final _extra = <GroupMember>[];
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<void> _loadMore(int offset) async {
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(groupRepositoryProvider).fetchStudioMembers(widget.groupId, status: 'active', offset: offset);
      if (mounted) setState(() { _extra.addAll(page.where((item) => !_extra.any((old) => old.id == item.id))); _hasMore = page.length == GroupRepository.studioPageSize; });
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  Future<bool> _confirm(String titleKey, String messageKey, String actionKey) async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(titleKey.tr()), content: Text(messageKey.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: actionKey.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;

  Future<void> _action(GroupMember member, String action) async {
    final repository = ref.read(groupRepositoryProvider);
    try {
      if (action.startsWith('role:')) {
        final role = action.substring(5);
        if (!await _confirm('group_studio.confirm_role_title', 'group_studio.confirm_role_message', 'common.continue')) return;
        await repository.setMemberRole(member.id, role);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('group_studio.role_updated'.tr())));
      } else if (action == 'remove') {
        if (!await _confirm('group_studio.remove_title', 'group_studio.remove_message', 'group_studio.remove')) return;
        await repository.removeMember(member.id);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('group_studio.member_removed'.tr())));
      } else {
        final reason = await showModalBottomSheet<String?>(context: context, isScrollControlled: true, builder: (_) => GroupBanSheet(memberName: member.profile.displayName));
        if (reason == null || !mounted) return;
        await repository.banMember(member.id, reason: reason);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('group_studio.member_banned'.tr())));
      }
      setState(() => _extra.removeWhere((item) => item.id == member.id));
      ref.invalidate(groupStudioMembersProvider(widget.groupId));
      widget.onChanged();
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) => ref.watch(groupStudioMembersProvider(widget.groupId)).when(
    loading: () => const HBListSkeleton(),
    error: (_, __) => GroupStudioListError(onRetry: () => ref.invalidate(groupStudioMembersProvider(widget.groupId))),
    data: (initial) {
      final byId = <String, GroupMember>{for (final item in [...initial, ..._extra]) item.id: item};
      final query = _search.text.trim().toLowerCase();
      final visible = byId.values.where((item) => query.isEmpty || item.profile.displayName.toLowerCase().contains(query) || item.profile.username.toLowerCase().contains(query)).toList();
      return Column(children: [
        HBInput(controller: _search, hint: 'group_studio.search_members'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: (_) => setState(() {})),
        const SizedBox(height: AppSpacing.sm),
        if (visible.isEmpty) HBEmptyState(icon: Icons.people_outline_rounded, title: 'group_studio.members_empty'.tr(), message: 'group_studio.members_empty_message'.tr()) else for (final member in visible) GroupMemberStudioRow(member: member, myRole: widget.myRole, onAction: (action) => _action(member, action)),
        if (_hasMore && query.isEmpty) Padding(padding: const EdgeInsets.only(top: AppSpacing.md), child: HBButton.soft(label: 'feed.load_more'.tr(), isLoading: _loadingMore, onPressed: _loadingMore ? null : () => _loadMore(byId.length))),
      ]);
    },
  );
}

class GroupMemberStudioRow extends ConsumerWidget {
  final GroupMember member;
  final String myRole;
  final ValueChanged<String> onAction;

  const GroupMemberStudioRow({super.key, required this.member, required this.myRole, required this.onAction});

  int _rank(String role) => const {'owner': 3, 'admin': 2, 'moderator': 1, 'member': 0}[role] ?? 0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final myId = ref.watch(authSessionProvider).value?.user.id;
    final canAct = member.role != 'owner' && member.profile.id != myId && _rank(myRole) > _rank(member.role);
    final actions = <({String value, String key})>[];
    if (canAct) {
      if (myRole == 'owner') {
        if (member.role != 'admin') actions.add((value: 'role:admin', key: 'group_studio.make_admin'));
        if (member.role != 'moderator') actions.add((value: 'role:moderator', key: 'group_studio.make_moderator'));
        if (member.role != 'member') actions.add((value: 'role:member', key: 'group_studio.make_member'));
      } else if (myRole == 'admin') {
        if (member.role != 'moderator') actions.add((value: 'role:moderator', key: 'group_studio.make_moderator'));
        if (member.role != 'member') actions.add((value: 'role:member', key: 'group_studio.make_member'));
      }
      actions.addAll([(value: 'remove', key: 'group_studio.remove'), (value: 'ban', key: 'group_studio.ban')]);
    }
    return SizedBox(height: 64, child: ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), onTap: () => context.push(AppRoutes.publicProfilePath(member.profile.username)), title: Wrap(spacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(member.profile.displayName, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)), if (member.role != 'member') GroupRoleChip(role: member.role)]), subtitle: Text('@${member.profile.username} · ${'group_studio.member_since'.tr(namedArgs: {'time': relativeTime(context, member.createdAt)})}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), trailing: actions.isEmpty ? null : PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: onAction, itemBuilder: (_) => actions.map((action) => PopupMenuItem(value: action.value, child: Text(action.key.tr()))).toList())));
  }
}

class GroupRoleChip extends StatelessWidget {
  final String role;

  const GroupRoleChip({super.key, required this.role});

  @override
  Widget build(BuildContext context) => HBStatusChip(kind: switch (role) {'owner' => HBStatusKind.superAdmin, 'admin' => HBStatusKind.admin, _ => HBStatusKind.moderator}, label: 'group_studio.roles.$role'.tr());
}

class GroupBanSheet extends StatefulWidget {
  final String memberName;

  const GroupBanSheet({super.key, required this.memberName});

  @override
  State<GroupBanSheet> createState() => _GroupBanSheetState();
}

class _GroupBanSheetState extends State<GroupBanSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() { _reason.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('group_studio.ban_title'.tr(namedArgs: {'name': widget.memberName}), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBInput(controller: _reason, label: 'group_studio.ban_reason'.tr(), hint: 'group_studio.ban_reason_hint'.tr(), maxLength: 300, maxLines: 4), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'group_studio.ban'.tr(), onPressed: () => context.pop(_reason.text.trim())))])));
}

class GroupBannedList extends ConsumerWidget {
  final String groupId;
  final ValueChanged<GroupMember> onUnban;

  const GroupBannedList({super.key, required this.groupId, required this.onUnban});

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(groupStudioBannedProvider(groupId)).when(
    loading: () => const HBListSkeleton(),
    error: (_, __) => GroupStudioListError(onRetry: () => ref.invalidate(groupStudioBannedProvider(groupId))),
    data: (members) => AnimatedSwitcher(duration: const Duration(milliseconds: 180), child: members.isEmpty ? HBEmptyState(key: const ValueKey('empty'), icon: Icons.block_outlined, title: 'group_studio.banned_empty'.tr(), message: 'group_studio.banned_empty_message'.tr()) : Column(key: ValueKey(members.length), children: [for (final member in members) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: Text(member.profile.displayName), subtitle: Text([if (member.banReason?.isNotEmpty == true) member.banReason!, 'group_studio.blocked_at'.tr(namedArgs: {'time': relativeTime(context, member.bannedAt ?? member.createdAt)})].join(' · ')), trailing: HBButton.soft(label: 'group_studio.unblock'.tr(), onPressed: () => onUnban(member), size: HBButtonSize.sm), onTap: () => context.push(AppRoutes.publicProfilePath(member.profile.username)))])),
  );
}

class GroupStudioListError extends StatelessWidget {
  final VoidCallback onRetry;

  const GroupStudioListError({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) => HBEmptyState(icon: Icons.error_outline_rounded, title: 'group_studio.load_error_title'.tr(), message: 'group_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry));
}

class GroupSettingsForm extends ConsumerStatefulWidget {
  final Group group;
  final String myRole;
  final VoidCallback onSaved;

  const GroupSettingsForm({super.key, required this.group, required this.myRole, required this.onSaved});

  @override
  ConsumerState<GroupSettingsForm> createState() => _GroupSettingsFormState();
}

class _GroupSettingsFormState extends ConsumerState<GroupSettingsForm> {
  late final TextEditingController _name;
  late final TextEditingController _description;
  late String _visibility;
  late String _joinPolicy;
  late String? _category;
  ReferenceRegion? _region;
  bool _regionInitialized = false;
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  bool _saving = false;
  bool _publishing = false;
  double _progress = 0;
  String? _errorKey;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.group.name);
    _description = TextEditingController(text: widget.group.description ?? '');
    _visibility = widget.group.visibility;
    _joinPolicy = widget.group.joinPolicy;
    _category = widget.group.category;
  }

  @override
  void dispose() { _name.dispose(); _description.dispose(); super.dispose(); }

  Future<void> _pick(bool avatar) async {
    try {
      final service = ref.read(mediaUploadServiceProvider);
      final source = await MediaSourcePicker.imageBytes(context, service);
      if (source == null || !mounted) return;
      final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: avatar ? 1 : 3, outputWidth: avatar ? 512 : 1800, outputHeight: avatar ? 512 : 600, circularMask: avatar);
      if (cropped != null && mounted) setState(() => avatar ? _avatar = service.prepareJpeg(cropped) : _cover = service.prepareJpeg(cropped));
    } on AppException catch (error) {
      if (mounted) setState(() => _errorKey = error.messageKey);
    }
  }

  Future<UploadedMedia?> _upload(PreparedUpload? source, String userId, int index, int count) async {
    if (source == null) return null;
    final progress = UploadProgress();
    final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (index + value) / count); });
    try {
      return await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'group-media', userId: userId, upload: source, isPublic: true, progress: progress);
    } finally {
      await subscription.cancel();
      await progress.close();
    }
  }

  Future<void> _save() async {
    if (_saving || _name.text.trim().length < 3 || _name.text.trim().length > 80) return;
    final userId = ref.read(currentProfileProvider).value?.id;
    if (userId == null) return;
    setState(() { _saving = true; _publishing = false; _progress = 0; _errorKey = null; });
    UploadedMedia? avatar;
    UploadedMedia? cover;
    final count = [_avatar, _cover].whereType<PreparedUpload>().length;
    try {
      var index = 0;
      avatar = await _upload(_avatar, userId, index, count);
      if (_avatar != null) index++;
      cover = await _upload(_cover, userId, index, count);
      if (mounted) setState(() { _progress = count == 0 ? 0 : 1; _publishing = true; });
      final changes = <String, dynamic>{};
      if (_name.text.trim() != widget.group.name) changes['name'] = _name.text.trim();
      final description = _description.text.trim().isEmpty ? null : _description.text.trim();
      if (description != widget.group.description) changes['description'] = description;
      if (_visibility != widget.group.visibility) changes['visibility'] = _visibility;
      if (_joinPolicy != widget.group.joinPolicy) changes['join_policy'] = _joinPolicy;
      if (_category != widget.group.category) changes['category'] = _category;
      if (_regionInitialized && _region?.id != widget.group.regionId) changes['region_id'] = _region?.id;
      if (avatar != null) changes['avatar_url'] = avatar.path;
      if (cover != null) changes['cover_url'] = cover.path;
      await ref.read(groupRepositoryProvider).updateGroup(widget.group.id, changes);
      final media = ref.read(mediaUploadServiceProvider);
      if (avatar != null) { try { await media.delete('group-media', media.pathFromPublicUrl('group-media', widget.group.avatarUrl)); } catch (_) {} }
      if (cover != null) { try { await media.delete('group-media', media.pathFromPublicUrl('group-media', widget.group.coverUrl)); } catch (_) {} }
      widget.onSaved();
      if (mounted) { setState(() { _saving = false; _publishing = false; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('group_studio.settings_saved'.tr()))); }
    } on AppException catch (error) {
      if (avatar != null) { try { await ref.read(mediaUploadServiceProvider).delete('group-media', avatar.path); } catch (_) {} }
      if (cover != null) { try { await ref.read(mediaUploadServiceProvider).delete('group-media', cover.path); } catch (_) {} }
      if (mounted) setState(() { _saving = false; _publishing = false; _errorKey = error.messageKey; });
    }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('group_studio.archive_title'.tr()), content: Text('group_studio.archive_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'group_studio.archive'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed || !mounted) return;
    try {
      await ref.read(groupRepositoryProvider).setGroupStatus(widget.group.id, 'archived');
      widget.onSaved();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('group_studio.archived'.tr())));
    } on AppException catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr())));
    }
  }

  void _reset() => setState(() {
    _name.text = widget.group.name;
    _description.text = widget.group.description ?? '';
    _visibility = widget.group.visibility;
    _joinPolicy = widget.group.joinPolicy;
    _category = widget.group.category;
    _regionInitialized = false;
    _region = null;
    _avatar = null;
    _cover = null;
    _errorKey = null;
  });

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(groupCategoriesProvider);
    final regions = ref.watch(regionsProvider(widget.group.countryCode));
    if (!_regionInitialized && regions.hasValue) {
      _regionInitialized = true;
      for (final region in regions.value ?? const <ReferenceRegion>[]) { if (region.id == widget.group.regionId) _region = region; }
    }
    final sourceCategories = categories.value ?? const <GroupCategory>[];
    final categoryItems = [...sourceCategories.where((item) => item.slug != 'altro'), ...sourceCategories.where((item) => item.slug == 'altro')];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HBFormSection(title: 'group_form.identity'.tr(), children: [
        GroupImagesFormRow(avatar: _avatar, cover: _cover, currentAvatarUrl: widget.group.avatarUrl, currentCoverUrl: widget.group.coverUrl, enabled: !_saving, onPickAvatar: () => _pick(true), onPickCover: () => _pick(false), onRemoveAvatar: () => setState(() => _avatar = null), onRemoveCover: () => setState(() => _cover = null)),
        HBFormField(label: 'groups.form.name'.tr(), required: true, child: HBInput(controller: _name, maxLength: 80, enabled: !_saving, onChanged: (_) => setState(() {}))),
        HBFormField(label: 'groups.form.description'.tr(), child: HBInput(controller: _description, maxLength: 2000, minLines: 3, maxLines: 8, enabled: !_saving)),
      ]),
      const HBFormSectionDivider(),
      HBFormSection(title: 'group_form.access'.tr(), children: [
        HBFormField(label: 'groups.form.visibility'.tr(), child: HBChoice<String>(options: const ['public', 'private', 'secret'], value: _visibility, labelBuilder: (value) => 'groups.visibility.$value'.tr(), descriptions: {for (final value in const ['public', 'private', 'secret']) value: 'groups.visibility.${value}_help'.tr()}, onChanged: (value) => setState(() => _visibility = value))),
        HBFormField(label: 'groups.form.join_policy'.tr(), child: HBChoice<String>(options: const ['open', 'approval'], value: _joinPolicy, labelBuilder: (value) => 'groups.join_policy.$value'.tr(), descriptions: {'open': 'group_form.open_help'.tr(), 'approval': 'group_form.approval_help'.tr()}, onChanged: (value) => setState(() => _joinPolicy = value))),
      ]),
      const HBFormSectionDivider(),
      HBFormSection(title: 'group_form.classification'.tr(), children: [
        HBFormField(label: 'groups.form.category'.tr(), child: categories.isLoading ? const LinearProgressIndicator() : categories.hasError ? Text('groups.errors.categories'.tr()) : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: categoryItems.map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: () => setState(() => _category = _category == item.slug ? null : item.slug))).toList())),
        HBFormField(label: 'groups.form.region'.tr(), child: GroupRegionPicker(regions: regions.value ?? const [], selected: _region, enabled: !_saving, onSelected: (value) => setState(() { _regionInitialized = true; _region = value; }))),
      ]),
      if (_saving || _errorKey != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _publishing, errorKey: _saving ? null : _errorKey)],
      HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: !_saving && _name.text.trim().length >= 3 ? _save : null, secondaryLabel: 'common.cancel'.tr(), onSecondary: _reset, loading: _saving),
      const SizedBox(height: AppSpacing.sm),
      Text('group_studio.slug_note'.tr(namedArgs: {'slug': widget.group.slug}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      if (widget.myRole == 'owner' && widget.group.status == 'active') ...[const SizedBox(height: AppSpacing.xl), HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('group_studio.danger_zone'.tr(), style: context.textStyles.titleMedium?.withColor(LightModeColors.lightError)), const SizedBox(height: AppSpacing.sm), HBButton.soft(label: 'group_studio.archive'.tr(), icon: Icons.archive_outlined, onPressed: _archive)]))],
    ]);
  }
}