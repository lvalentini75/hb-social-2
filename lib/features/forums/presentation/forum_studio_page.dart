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
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/hb_upload_progress.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/forums/data/forums_repository.dart';
import 'package:hb_social/features/forums/domain/forum.dart';
import 'package:hb_social/features/forums/presentation/forum_studio_sections.dart';
import 'package:hb_social/features/forums/providers/forums_providers.dart';

class ForumStudioPage extends ConsumerStatefulWidget {
  final String slug;
  const ForumStudioPage({super.key, required this.slug});
  @override
  ConsumerState<ForumStudioPage> createState() => _ForumStudioPageState();
}

class _ForumStudioPageState extends ConsumerState<ForumStudioPage> {
  String _tab = 'overview';

  void _invalidate(String id) {
    ref.invalidate(forumStudioSummaryProvider(id));
    ref.invalidate(forumStudioPendingProvider(id));
    ref.invalidate(forumStudioMembersProvider(id));
    ref.invalidate(forumStudioBannedProvider(id));
    ref.invalidate(forumStudioThreadsProvider(id));
    ref.invalidate(forumStudioStatsProvider((forumId: id, days: 7)));
    ref.invalidate(forumStudioStatsProvider((forumId: id, days: 30)));
    ref.invalidate(forumStudioStatsProvider((forumId: id, days: 90)));
    ref.invalidate(forumReportsProvider((forumId: id, openOnly: true)));
    ref.invalidate(forumReportsProvider((forumId: id, openOnly: false)));
    ref.invalidate(forumDetailProvider(widget.slug));
    ref.invalidate(forumsProvider);
    ref.invalidate(threadsProvider(id));
  }

  void _message(String key) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr()))); }

  Future<void> _run(String id, Future<void> Function() action, String successKey, {bool request = false}) async {
    try { await action(); _invalidate(id); _message(successKey); } on AppException catch (error) { _invalidate(id); _message(request && error.messageKey == 'forum_studio.errors.request_not_pending' ? 'forum_studio.request_already_handled' : error.messageKey); }
  }

  @override
  Widget build(BuildContext context) => ref.watch(forumDetailProvider(widget.slug)).when(
    loading: () => const PageColumns(center: HBListSkeleton(count: 4)),
    error: (_, __) => PageColumns(center: ForumStudioListError(onRetry: () => ref.invalidate(forumDetailProvider(widget.slug)))),
    data: (forum) {
      if (forum == null) return PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.forum_outlined, title: 'forums.not_found_title'.tr(), message: 'forums.not_found_message'.tr())));
      return ref.watch(forumStudioSummaryProvider(forum.id)).when(
        loading: () => const PageColumns(center: HBListSkeleton(count: 4)),
        error: (error, _) => PageColumns(center: error is AppException && error.messageKey == 'forum_studio.errors.permission_denied' ? ForumStudioDenied(slug: widget.slug) : ForumStudioListError(onRetry: () => ref.invalidate(forumStudioSummaryProvider(forum.id)))),
        data: (summary) {
          if (!const {'owner', 'moderator'}.contains(summary.myRole)) return PageColumns(center: ForumStudioDenied(slug: widget.slug));
          final tabs = <String>['overview', 'reports'];
          if (forum.isPrivate) tabs.add('requests');
          tabs.addAll(['members', 'banned', 'threads']);
          if (summary.myRole == 'owner') tabs.add('settings');
          if (!tabs.contains(_tab)) _tab = tabs.first;
          final openReports = ref.watch(forumReportsProvider((forumId: forum.id, openOnly: true))).value?.length;
          final badges = tabs.map<int?>((tab) => switch (tab) {'reports' => openReports, 'requests' => summary.pendingCount, 'members' => summary.memberCount, 'banned' => summary.bannedCount, 'threads' => summary.threadCount, _ => null}).toList();
          return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
            if (forum.status == 'archived') ...[ForumArchivedBanner(onReactivate: summary.myRole == 'owner' ? () => _run(forum.id, () => ref.read(forumsRepositoryProvider).setForumStatus(forum.id, 'active'), 'forum_studio.reactivated') : null), const SizedBox(height: AppSpacing.md)],
            HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: ForumStudioHeader(forum: forum, summary: summary)),
            const SizedBox(height: AppSpacing.md),
            HBSegmentedTabs(labels: tabs.map((tab) => 'forum_studio.tabs.$tab'.tr()).toList(), badges: badges, selectedIndex: tabs.indexOf(_tab), scrollable: true, onChanged: (index) => setState(() => _tab = tabs[index])),
            const SizedBox(height: AppSpacing.md),
            HBCard(padding: EdgeInsets.all(MediaQuery.sizeOf(context).width >= 700 ? AppSpacing.lg : AppSpacing.md), child: switch (_tab) {
              'overview' => ForumStudioOverview(forum: forum),
              'reports' => ForumReportsPanel(forum: forum, onChanged: () => _invalidate(forum.id)),
              'requests' => ForumRequestsList(forumId: forum.id, onReview: (member, accept) => _run(forum.id, () async { await ref.read(forumsRepositoryProvider).reviewForumRequest(member.id, accept: accept); }, accept ? 'forum_studio.request_accepted' : 'forum_studio.request_declined', request: true)),
              'members' => ForumMembersList(forumId: forum.id, myRole: summary.myRole!, onChanged: () => _invalidate(forum.id)),
              'banned' => ForumBannedList(forumId: forum.id, onUnban: (member) => _run(forum.id, () => ref.read(forumsRepositoryProvider).unbanForumMember(member.id), 'forum_studio.user_unbanned')),
              'threads' => ForumStudioThreadsPanel(forum: forum, onChanged: () => _invalidate(forum.id)),
              _ => ForumSettingsForm(forum: forum, onSaved: () => _invalidate(forum.id)),
            }),
          ]))]));
        },
      );
    },
  );
}

class ForumStudioDenied extends StatelessWidget {
  final String slug;
  const ForumStudioDenied({super.key, required this.slug});
  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.admin_panel_settings_outlined, title: 'forum_studio.denied_title'.tr(), message: 'forum_studio.denied_message'.tr(), action: HBButton.primary(label: 'forum_studio.back_to_forum'.tr(), onPressed: () => context.go(AppRoutes.forumDetailPath(slug)))));
}

class ForumStudioHeader extends StatelessWidget {
  final Forum forum;
  final ForumStudioSummary summary;
  const ForumStudioHeader({super.key, required this.forum, required this.summary});
  @override
  Widget build(BuildContext context) => Row(children: [HBAvatar(name: forum.name, imageUrl: forum.avatarUrl, size: 48), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(forum.name, style: context.textStyles.titleLarge), Text('${'forums.thread_count'.plural(summary.threadCount)} · ${'forums.member_count'.plural(summary.memberCount)}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBButton.ghost(label: 'forum_studio.view_forum'.tr(), onPressed: () => context.go(AppRoutes.forumDetailPath(forum.slug)))]);
}

class ForumArchivedBanner extends StatelessWidget {
  final VoidCallback? onReactivate;
  const ForumArchivedBanner({super.key, this.onReactivate});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightWarning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.archive_outlined, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('forum_studio.archived'.tr(), style: context.textStyles.titleSmall)), if (onReactivate != null) HBButton.soft(label: 'forum_studio.reactivate'.tr(), onPressed: onReactivate, size: HBButtonSize.sm)]));
}

class ForumRequestsList extends ConsumerWidget {
  final String forumId;
  final void Function(ForumMember member, bool accept) onReview;
  const ForumRequestsList({super.key, required this.forumId, required this.onReview});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(forumStudioPendingProvider(forumId)).when(loading: () => const HBListSkeleton(), error: (_, __) => ForumStudioListError(onRetry: () => ref.invalidate(forumStudioPendingProvider(forumId))), data: (members) => members.isEmpty ? HBEmptyState(icon: Icons.how_to_reg_outlined, title: 'forum_studio.requests_empty'.tr(), message: 'forum_studio.requests_empty_message'.tr()) : Column(children: [for (final member in members) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: Text(member.profile.displayName), subtitle: Text(relativeTime(context, member.createdAt)), trailing: Wrap(spacing: AppSpacing.xs, children: [HBButton.ghost(label: 'forum_studio.decline'.tr(), size: HBButtonSize.sm, onPressed: () => onReview(member, false)), HBButton.primary(label: 'forum_studio.accept'.tr(), size: HBButtonSize.sm, onPressed: () => onReview(member, true))]), onTap: () => context.push(AppRoutes.publicProfilePath(member.profile.username)))]));
}

class ForumMembersList extends ConsumerStatefulWidget {
  final String forumId;
  final String myRole;
  final VoidCallback onChanged;
  const ForumMembersList({super.key, required this.forumId, required this.myRole, required this.onChanged});
  @override
  ConsumerState<ForumMembersList> createState() => _ForumMembersListState();
}

class _ForumMembersListState extends ConsumerState<ForumMembersList> {
  final _search = TextEditingController();
  final _extra = <ForumMember>[];
  bool _loading = false;
  bool _hasMore = true;
  String _role = 'all';
  @override
  void dispose() { _search.dispose(); super.dispose(); }

  Future<bool> _confirm(String title, String message, String action) async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(title.tr()), content: Text(message.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: action.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;

  Future<void> _act(ForumMember member, String action) async {
    final repository = ref.read(forumsRepositoryProvider);
    try {
      if (action.startsWith('role:')) {
        if (!await _confirm('forum_studio.confirm_role_title', 'forum_studio.confirm_role_message', 'common.continue')) return;
        await repository.setForumMemberRole(member.id, action.substring(5));
        if (mounted) _snack('forum_studio.role_updated');
      } else if (action == 'remove') {
        if (!await _confirm('forum_studio.remove_title', 'forum_studio.remove_message', 'forum_studio.remove')) return;
        await repository.removeForumMember(member.id);
        if (mounted) _snack('forum_studio.member_removed');
      } else {
        final reason = await showModalBottomSheet<String?>(context: context, isScrollControlled: true, builder: (_) => ForumBanSheet(memberName: member.profile.displayName));
        if (reason == null || !mounted) return;
        await repository.banForumMember(member.id, reason: reason);
        if (mounted) _snack('forum_studio.member_banned');
      }
      _extra.removeWhere((item) => item.id == member.id);
      ref.invalidate(forumStudioMembersProvider(widget.forumId));
      widget.onChanged();
    } on AppException catch (error) { if (mounted) _snack(error.messageKey); widget.onChanged(); }
  }

  void _snack(String key) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(key.tr())));

  Future<void> _loadMore(int offset) async {
    setState(() => _loading = true);
    try { final page = await ref.read(forumsRepositoryProvider).fetchStudioMembers(widget.forumId, status: 'active', offset: offset); if (mounted) setState(() { _extra.addAll(page.where((item) => !_extra.any((old) => old.id == item.id))); _hasMore = page.length == ForumsRepository.studioPageSize; }); } on AppException catch (error) { if (mounted) _snack(error.messageKey); } finally { if (mounted) setState(() => _loading = false); }
  }

  @override
  Widget build(BuildContext context) => ref.watch(forumStudioMembersProvider(widget.forumId)).when(loading: () => const HBListSkeleton(), error: (_, __) => ForumStudioListError(onRetry: () => ref.invalidate(forumStudioMembersProvider(widget.forumId))), data: (initial) {
    final all = <String, ForumMember>{for (final item in [...initial, ..._extra]) item.id: item}.values.toList()..sort((a, b) { final rank = const {'owner': 2, 'moderator': 1, 'member': 0}[b.role]!.compareTo(const {'owner': 2, 'moderator': 1, 'member': 0}[a.role]!); return rank != 0 ? rank : a.profile.displayName.toLowerCase().compareTo(b.profile.displayName.toLowerCase()); });
    final query = _search.text.trim().toLowerCase();
    final visible = all.where((item) => (_role == 'all' || _role == 'moderator' && item.role == 'moderator' || _role == 'member' && item.role == 'member') && (query.isEmpty || item.profile.displayName.toLowerCase().contains(query) || item.profile.username.toLowerCase().contains(query))).toList();
    return Column(children: [HBInput(controller: _search, hint: 'forum_studio.search_members'.tr(), prefixIcon: const Icon(Icons.search_rounded), onChanged: (_) => setState(() {})), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, children: [for (final role in const ['all', 'moderator', 'member']) HBChip(label: 'forum_studio.member_filters.$role'.tr(), selected: _role == role, onTap: () => setState(() => _role = role))]), const SizedBox(height: AppSpacing.sm), if (visible.isEmpty) HBEmptyState(icon: Icons.people_outline, title: 'forum_studio.members_empty'.tr(), message: 'forum_studio.members_empty_message'.tr()) else for (final member in visible) ForumMemberRow(member: member, myRole: widget.myRole, onAction: (action) => _act(member, action)), if (_hasMore && query.isEmpty && _role == 'all') HBButton.soft(label: 'feed.load_more'.tr(), isLoading: _loading, onPressed: _loading ? null : () => _loadMore(all.length))]);
  });
}

class ForumMemberRow extends ConsumerWidget {
  final ForumMember member;
  final String myRole;
  final ValueChanged<String> onAction;
  const ForumMemberRow({super.key, required this.member, required this.myRole, required this.onAction});
  int _rank(String role) => const {'owner': 2, 'moderator': 1, 'member': 0}[role] ?? 0;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mine = ref.watch(authSessionProvider).value?.user.id == member.profile.id;
    final canAct = !mine && member.role != 'owner' && _rank(myRole) > _rank(member.role);
    final actions = <({String value, String key})>[];
    if (canAct) {
      if (myRole == 'owner') actions.add((value: member.role == 'moderator' ? 'role:member' : 'role:moderator', key: member.role == 'moderator' ? 'forum_studio.make_member' : 'forum_studio.make_moderator'));
      actions.addAll([(value: 'remove', key: 'forum_studio.remove'), (value: 'ban', key: 'forum_studio.ban')]);
    }
    final recent = member.lastSeenAt != null && DateTime.now().difference(member.lastSeenAt!).inDays <= 7;
    return ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: Wrap(spacing: AppSpacing.xs, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(member.profile.displayName), if (member.role != 'member') HBStatusChip(kind: member.role == 'owner' ? HBStatusKind.superAdmin : HBStatusKind.moderator, label: 'forum_studio.roles.${member.role}'.tr())]), subtitle: Text(['@${member.profile.username}', 'forum_studio.member_since'.tr(namedArgs: {'time': relativeTime(context, member.createdAt)}), if (recent) 'forum_studio.last_activity'.tr(namedArgs: {'time': relativeTime(context, member.lastSeenAt!)})].join(' · ')), trailing: actions.isEmpty ? null : PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: onAction, itemBuilder: (_) => actions.map((item) => PopupMenuItem(value: item.value, child: Text(item.key.tr()))).toList()), onTap: () => context.push(AppRoutes.publicProfilePath(member.profile.username)));
  }
}

class ForumBanSheet extends StatefulWidget {
  final String memberName;
  const ForumBanSheet({super.key, required this.memberName});
  @override
  State<ForumBanSheet> createState() => _ForumBanSheetState();
}

class _ForumBanSheetState extends State<ForumBanSheet> {
  final _reason = TextEditingController();
  @override
  void dispose() { _reason.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('forum_studio.ban_title'.tr(namedArgs: {'name': widget.memberName}), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBInput(controller: _reason, label: 'forum_studio.ban_reason'.tr(), maxLength: 300, maxLines: 4), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'forum_studio.ban'.tr(), onPressed: () => context.pop(_reason.text.trim())))])));
}

class ForumBannedList extends ConsumerWidget {
  final String forumId;
  final ValueChanged<ForumMember> onUnban;
  const ForumBannedList({super.key, required this.forumId, required this.onUnban});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(forumStudioBannedProvider(forumId)).when(loading: () => const HBListSkeleton(), error: (_, __) => ForumStudioListError(onRetry: () => ref.invalidate(forumStudioBannedProvider(forumId))), data: (members) => members.isEmpty ? HBEmptyState(icon: Icons.block_outlined, title: 'forum_studio.banned_empty'.tr(), message: 'forum_studio.banned_empty_message'.tr()) : Column(children: [for (final member in members) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: Text(member.profile.displayName), subtitle: Text([if (member.banReason?.isNotEmpty == true) member.banReason!, 'forum_studio.blocked_at'.tr(namedArgs: {'time': relativeTime(context, member.bannedAt ?? member.createdAt)})].join(' · ')), trailing: HBButton.soft(label: 'forum_studio.unblock'.tr(), size: HBButtonSize.sm, onPressed: () => onUnban(member)))]));
}

class ForumSettingsForm extends ConsumerStatefulWidget {
  final Forum forum;
  final VoidCallback onSaved;
  const ForumSettingsForm({super.key, required this.forum, required this.onSaved});
  @override
  ConsumerState<ForumSettingsForm> createState() => _ForumSettingsFormState();
}

class _ForumSettingsFormState extends ConsumerState<ForumSettingsForm> {
  late final TextEditingController _name = TextEditingController(text: widget.forum.name);
  late final TextEditingController _description = TextEditingController(text: widget.forum.description ?? '');
  late String _visibility = widget.forum.visibility;
  late String? _category = widget.forum.category;
  bool _saving = false;
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  double _progress = 0;
  bool _publishing = false;
  String? _errorKey;
  @override
  void dispose() { _name.dispose(); _description.dispose(); super.dispose(); }

  Future<void> _pick(bool avatar) async {
    try { final service = ref.read(mediaUploadServiceProvider); final source = await MediaSourcePicker.imageBytes(context, service); if (source == null || !mounted) return; final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: avatar ? 1 : 3, outputWidth: avatar ? 512 : 1800, outputHeight: avatar ? 512 : 600, circularMask: avatar); if (cropped != null && mounted) setState(() => avatar ? _avatar = service.prepareJpeg(cropped) : _cover = service.prepareJpeg(cropped)); }
    on AppException catch (error) { if (mounted) setState(() => _errorKey = error.messageKey); }
  }

  Future<UploadedMedia?> _upload(PreparedUpload? source, String userId, int index, int count) async {
    if (source == null) return null;
    final progress = UploadProgress();
    final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (index + value) / count); });
    try { return await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'forum-media', userId: userId, upload: source, isPublic: true, progress: progress); }
    finally { await subscription.cancel(); await progress.close(); }
  }

  Future<void> _save() async {
    if (_name.text.trim().length < 3 || _saving) return;
    final userId = ref.read(authSessionProvider).value?.user.id;
    if (userId == null) return;
    setState(() { _saving = true; _progress = 0; _publishing = false; _errorKey = null; });
    UploadedMedia? avatar;
    UploadedMedia? cover;
    try {
      final count = [_avatar, _cover].whereType<PreparedUpload>().length;
      avatar = await _upload(_avatar, userId, 0, count);
      cover = await _upload(_cover, userId, _avatar == null ? 0 : 1, count);
      if (mounted) setState(() => _publishing = true);
      await ref.read(forumsRepositoryProvider).updateForum(widget.forum.id, {'name': _name.text.trim(), 'description': _description.text.trim().isEmpty ? null : _description.text.trim(), 'visibility': _visibility, 'category': _category, if (avatar != null) 'avatar_url': avatar.publicUrl, if (cover != null) 'cover_url': cover.publicUrl});
      final service = ref.read(mediaUploadServiceProvider);
      if (avatar != null) { try { await service.delete('forum-media', service.pathFromPublicUrl('forum-media', widget.forum.avatarUrl)); } catch (_) {} }
      if (cover != null) { try { await service.delete('forum-media', service.pathFromPublicUrl('forum-media', widget.forum.coverUrl)); } catch (_) {} }
      widget.onSaved();
      if (mounted) { setState(() { _avatar = null; _cover = null; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('forum_studio.settings_saved'.tr()))); }
    } on AppException catch (error) {
      if (avatar != null) { try { await ref.read(mediaUploadServiceProvider).delete('forum-media', avatar.path); } catch (_) {} }
      if (cover != null) { try { await ref.read(mediaUploadServiceProvider).delete('forum-media', cover.path); } catch (_) {} }
      if (mounted) setState(() => _errorKey = error.messageKey);
    } finally { if (mounted) setState(() { _saving = false; _publishing = false; }); }
  }

  Future<void> _archive() async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('forum_studio.archive_title'.tr()), content: Text('forum_studio.archive_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'forum_studio.archive'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed) return;
    try { await ref.read(forumsRepositoryProvider).setForumStatus(widget.forum.id, 'archived'); widget.onSaved(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(forumCategoriesProvider);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      HBFormSection(title: 'forums.form.identity'.tr(), children: [LayoutBuilder(builder: (context, constraints) { final avatar = HBFormField(label: 'media_crop.avatar'.tr(), child: HBImageField(kind: HBImageFieldKind.avatar, imageUrl: widget.forum.avatarUrl, imageBytes: _avatar?.bytes, onPick: _saving ? null : () => _pick(true), onRemove: _avatar == null ? null : () => setState(() => _avatar = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr())); final cover = HBFormField(label: 'media_crop.cover'.tr(), child: HBImageField(kind: HBImageFieldKind.cover, imageUrl: widget.forum.coverUrl, imageBytes: _cover?.bytes, onPick: _saving ? null : () => _pick(false), onRemove: _cover == null ? null : () => setState(() => _cover = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr())); return constraints.maxWidth < 560 ? Column(children: [avatar, const SizedBox(height: AppSpacing.md), cover]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatar), const SizedBox(width: AppSpacing.lg), Expanded(child: cover)]); }), HBFormField(label: 'forums.form.name'.tr(), required: true, child: HBInput(controller: _name, maxLength: 80, onChanged: (_) => setState(() {}))), HBFormField(label: 'forums.form.description'.tr(), child: HBInput(controller: _description, maxLength: 2000, minLines: 3, maxLines: 8))]),
      const HBFormSectionDivider(),
      HBFormSection(title: 'forums.form.access'.tr(), children: [HBFormField(label: 'forums.form.visibility'.tr(), child: HBChoice<String>(options: const ['public', 'private'], value: _visibility, labelBuilder: (value) => 'forums.visibility.$value'.tr(), descriptions: {for (final value in const ['public', 'private']) value: 'forums.visibility.${value}_help'.tr()}, onChanged: (value) => setState(() => _visibility = value)))]),
      const HBFormSectionDivider(),
      HBFormSection(title: 'forums.form.classification'.tr(), children: [HBFormField(label: 'forums.form.category'.tr(), child: categories.isLoading ? const LinearProgressIndicator() : categories.hasError ? Text('forums.errors.categories'.tr()) : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: (categories.value ?? const <ForumCategory>[]).map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: () => setState(() => _category = item.slug))).toList()))]),
      if (_saving && (_avatar != null || _cover != null) || _errorKey != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _publishing, errorKey: _saving ? null : _errorKey)],
      HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: _name.text.trim().length >= 3 ? _save : null, loading: _saving),
      Text('forum_studio.slug_note'.tr(namedArgs: {'slug': widget.forum.slug}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      if (widget.forum.status == 'active') ...[const SizedBox(height: AppSpacing.xl), HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('forum_studio.danger_zone'.tr(), style: context.textStyles.titleMedium?.withColor(LightModeColors.lightError)), const SizedBox(height: AppSpacing.sm), HBButton.soft(label: 'forum_studio.archive'.tr(), icon: Icons.archive_outlined, onPressed: _archive)]))],
    ]);
  }
}

class ForumStudioListError extends StatelessWidget {
  final VoidCallback onRetry;
  const ForumStudioListError({super.key, required this.onRetry});
  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'forum_studio.load_error_title'.tr(), message: 'forum_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)));
}