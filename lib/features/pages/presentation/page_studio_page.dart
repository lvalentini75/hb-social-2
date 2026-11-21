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
import 'package:hb_social/features/home/domain/feed_post.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/pages/domain/community_page.dart';
import 'package:hb_social/features/pages/presentation/page_create_page.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/verification/domain/verification_request.dart';
import 'package:hb_social/features/verification/presentation/verification_wizard.dart';
import 'package:hb_social/features/verification/providers/verification_providers.dart';
import 'package:hb_social/features/pages/articles/presentation/page_articles.dart';

class PageStudioPage extends ConsumerStatefulWidget {
  final String slug;
  const PageStudioPage({super.key, required this.slug});
  @override
  ConsumerState<PageStudioPage> createState() => _PageStudioPageState();
}

class _PageStudioPageState extends ConsumerState<PageStudioPage> {
  int _tab = 0;

  void _invalidate(CommunityPage page) {
    ref.invalidate(pageStudioSummaryProvider(page.id));
    ref.invalidate(pageTeamProvider(page.id));
    ref.invalidate(pageBySlugProvider(page.slug));
    ref.invalidate(pagePostsProvider(page.id));
    for (final days in const [7, 30, 90]) { ref.invalidate(pageStudioStatsProvider((pageId: page.id, days: days))); }
    ref.invalidate(myPagesProvider);
  }

  @override
  Widget build(BuildContext context) => ref.watch(pageBySlugProvider(widget.slug)).when(
    loading: () => const PageColumns(center: HBListSkeleton(count: 4)),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'page_studio.load_error_title'.tr(), message: 'page_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pageBySlugProvider(widget.slug)))))),
    data: (page) => page == null ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.article_outlined, title: 'pages.unavailable_title'.tr(), message: 'pages.unavailable_message'.tr()))) : ref.watch(pageStudioSummaryProvider(page.id)).when(
      loading: () => const PageColumns(center: HBListSkeleton(count: 4)),
      error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'page_studio.load_error_title'.tr(), message: 'page_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pageStudioSummaryProvider(page.id)))))),
      data: (summary) {
        if (summary?.myRole == null) return PageColumns(center: PageStudioDenied(slug: page.slug));
        final labels = ['page_studio.tabs.overview'.tr(), 'articles.tab'.tr(), 'page_studio.tabs.team'.tr(), 'page_studio.tabs.settings'.tr()];
        return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
          if (summary!.status == 'archived') ...[PageStudioArchivedBanner(page: page, owner: summary.myRole == 'owner', onChanged: () => _invalidate(page)), const SizedBox(height: AppSpacing.md)],
          HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: PageStudioHeader(page: page, summary: summary)),
          const SizedBox(height: AppSpacing.md),
          HBSegmentedTabs(labels: labels, badges: [null, null, summary.teamCount, null], selectedIndex: _tab, scrollable: true, onChanged: (value) => setState(() => _tab = value)),
          const SizedBox(height: AppSpacing.md),
          PageStudioPanel(child: switch (_tab) {
            0 => PageStudioOverview(page: page, summary: summary),
            1 => PageArticlesManager(pageId: page.id, pageSlug: page.slug),
            2 => PageStudioTeam(page: page, myRole: summary.myRole!, onChanged: () => _invalidate(page)),
            _ => PageStudioSettings(page: page, myRole: summary.myRole!, onChanged: () => _invalidate(page)),
          }),
        ]))]));
      },
    ),
  );
}

class PageStudioDenied extends StatelessWidget {
  final String slug;
  const PageStudioDenied({super.key, required this.slug});
  @override
  Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.admin_panel_settings_outlined, title: 'page_studio.denied_title'.tr(), message: 'page_studio.denied_message'.tr(), action: HBButton.primary(label: 'page_studio.back_to_page'.tr(), onPressed: () => context.go(AppRoutes.pageDetailPath(slug)))));
}

class PageStudioPanel extends StatelessWidget {
  final Widget child;
  const PageStudioPanel({super.key, required this.child});
  @override
  Widget build(BuildContext context) => MediaQuery.sizeOf(context).width < 700 ? child : HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: child);
}

class PageStudioHeader extends StatelessWidget {
  final CommunityPage page;
  final PageStudioSummary summary;
  const PageStudioHeader({super.key, required this.page, required this.summary});
  @override
  Widget build(BuildContext context) => Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center, spacing: AppSpacing.md, runSpacing: AppSpacing.md, children: [
    Row(mainAxisSize: MainAxisSize.min, children: [HBAvatar(name: page.name, imageUrl: page.avatarUrl, size: 48), const SizedBox(width: AppSpacing.md), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(page.name, style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.xs), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.xs, children: [HBChip(label: 'pages.category.${page.category}'.tr(), selected: false), PageVerificationStatus(status: summary.verificationStatus)])])]),
    HBButton.ghost(label: 'page_studio.view_page'.tr(), onPressed: () => context.go(AppRoutes.pageDetailPath(page.slug))),
  ]);
}

class PageVerificationStatus extends StatelessWidget {
  final String status;
  const PageVerificationStatus({super.key, required this.status});
  @override
  Widget build(BuildContext context) => HBStatusChip(kind: switch (status) {'pending' => HBStatusKind.pending, 'verified' => HBStatusKind.approved, 'rejected' => HBStatusKind.rejected, _ => HBStatusKind.neutral}, label: 'page_studio.verification.$status'.tr());
}

class PageStudioOverview extends ConsumerStatefulWidget {
  final CommunityPage page;
  final PageStudioSummary summary;
  const PageStudioOverview({super.key, required this.page, required this.summary});
  @override
  ConsumerState<PageStudioOverview> createState() => _PageStudioOverviewState();
}

class _PageStudioOverviewState extends ConsumerState<PageStudioOverview> {
  int _days = 30;
  String _series = 'posts';

  @override
  Widget build(BuildContext context) {
    final posts = ref.watch(pagePostsProvider(widget.page.id));
    final request = (pageId: widget.page.id, days: _days);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      ref.watch(pageStudioStatsProvider(request)).when(
        loading: () => const HBListSkeleton(count: 4),
        error: (_, __) => HBEmptyState(icon: Icons.query_stats_outlined, title: 'page_analytics.error_title'.tr(), message: 'page_analytics.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pageStudioStatsProvider(request)))),
        data: (stats) => StudioOverview(
          stats: stats.overview,
          labels: {for (final key in const ['followers', 'posts', 'reactions', 'comments']) key: 'page_analytics.metrics.$key'.tr()},
          series: const ['posts', 'followers', 'reactions', 'comments'],
          selectedSeries: _series,
          onPeriodChanged: (value) => setState(() => _days = value),
          onSeriesChanged: (value) => setState(() => _series = value),
          lists: [
            StudioOverviewList(title: 'page_analytics.latest_followers'.tr(), children: [for (final item in stats.latestFollowers.take(10)) ListTile(contentPadding: EdgeInsets.zero, dense: true, leading: HBAvatar(name: item.profile.displayName, imageUrl: item.profile.avatarUrl, size: 34), title: Text(item.profile.displayName, overflow: TextOverflow.ellipsis), subtitle: Text('page_analytics.followed'.tr(namedArgs: {'time': relativeTime(context, item.joinedAt)})), trailing: DateTime.now().difference(item.joinedAt).inHours < 24 ? HBStatusChip(kind: HBStatusKind.approved, label: 'studio_overview.new'.tr()) : null, onTap: () => context.push(AppRoutes.publicProfilePath(item.profile.username)))]),
            StudioOverviewList(title: 'page_analytics.top_posts'.tr(), children: [for (final item in stats.topPosts.take(5)) ListTile(contentPadding: EdgeInsets.zero, dense: true, title: Text(item.preview.isNotEmpty ? item.preview : 'admin.p05d.kinds.${item.kind}'.tr(), maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text('page_studio.post_stats'.tr(namedArgs: {'reactions': '${item.reactionCount}', 'comments': '${item.commentCount}'})), onTap: () => context.push(AppRoutes.postPath(item.id)))]),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      Row(children: [Expanded(child: Text('page_studio.latest_posts'.tr(), style: context.textStyles.titleLarge)), HBButton.ghost(label: 'common.see_all'.tr(), onPressed: () => context.go(AppRoutes.pageDetailPath(widget.page.slug)))]),
      const SizedBox(height: AppSpacing.sm),
      posts.when(loading: () => const HBListSkeleton(count: 3), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'pages.error_title'.tr(), message: 'pages.error_message'.tr()), data: (value) => value.items.isEmpty ? HBEmptyState(icon: Icons.article_outlined, title: 'page_studio.posts_empty'.tr(), message: 'pages.posts_empty_message'.tr()) : Column(children: value.items.take(5).map((post) => PageStudioPostRow(post: post)).toList())),
    ]);
  }
}

class PageStudioPostRow extends StatelessWidget {
  final FeedPost post;
  const PageStudioPostRow({super.key, required this.post});
  @override
  Widget build(BuildContext context) { final text = post.content?.trim().isNotEmpty == true ? post.content!.trim() : 'post_composer.${post.kind}'.tr(); final title = text.length > 80 ? '${text.substring(0, 80)}...' : text; return ListTile(contentPadding: EdgeInsets.zero, onTap: () => context.push(AppRoutes.postPath(post.id)), title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis), subtitle: Text(relativeTime(context, post.createdAt)), trailing: Text('page_studio.post_stats'.tr(namedArgs: {'reactions': '${post.reactionCount}', 'comments': '${post.commentCount}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))); }
}

class PageStudioTeam extends ConsumerWidget {
  final CommunityPage page;
  final String myRole;
  final VoidCallback onChanged;
  const PageStudioTeam({super.key, required this.page, required this.myRole, required this.onChanged});

  Future<void> _add(BuildContext context, WidgetRef ref) async {
    final added = await showModalBottomSheet<PageTeamMember>(context: context, isScrollControlled: true, builder: (_) => PageAddMemberSheet(pageId: page.id));
    if (added != null && context.mounted) { onChanged(); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('page_studio.member_added'.tr(namedArgs: {'name': added.profile.displayName})))); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    if (myRole == 'owner') Align(alignment: Alignment.centerRight, child: HBButton.primary(label: 'page_studio.add_member'.tr(), icon: Icons.person_add_alt_1_rounded, onPressed: () => _add(context, ref))),
    if (myRole == 'owner') const SizedBox(height: AppSpacing.md),
    ref.watch(pageTeamProvider(page.id)).when(loading: () => const HBListSkeleton(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'page_studio.team_error'.tr(), message: 'page_studio.load_error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(pageTeamProvider(page.id)))), data: (members) => members.isEmpty ? HBEmptyState(icon: Icons.group_outlined, title: 'page_studio.team_empty'.tr(), message: 'page_studio.team_empty_message'.tr()) : Column(children: members.map((member) => PageTeamMemberRow(page: page, member: member, myRole: myRole, onChanged: onChanged)).toList())),
  ]);
}

class PageTeamMemberRow extends ConsumerWidget {
  final CommunityPage page;
  final PageTeamMember member;
  final String myRole;
  final VoidCallback onChanged;
  const PageTeamMemberRow({super.key, required this.page, required this.member, required this.myRole, required this.onChanged});

  Future<void> _remove(BuildContext context, WidgetRef ref, {required bool leaving}) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text((leaving ? 'page_studio.leave_title' : 'page_studio.remove_title').tr()), content: Text((leaving ? 'page_studio.leave_message' : 'page_studio.remove_message').tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: (leaving ? 'page_studio.leave' : 'page_studio.remove').tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed || !context.mounted) return;
    try { await ref.read(pageRepositoryProvider).removeMember(member.id); onChanged(); if (leaving && context.mounted) context.go(AppRoutes.pageDetailPath(page.slug)); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<void> _role(BuildContext context, WidgetRef ref, String role) async {
    try { await ref.read(pageRepositoryProvider).setMemberRole(member.id, role); onChanged(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('page_studio.role_updated'.tr()))); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authSessionProvider).value?.user.id == member.profile.id;
    final actions = <PopupMenuEntry<String>>[];
    if (member.role != 'owner' && myRole == 'owner') actions.addAll([PopupMenuItem(value: member.role == 'editor' ? 'moderator' : 'editor', child: Text((member.role == 'editor' ? 'page_studio.make_moderator' : 'page_studio.make_editor').tr())), PopupMenuItem(value: 'remove', child: Text('page_studio.remove'.tr()))]);
    if (member.role != 'owner' && myRole != 'owner' && me) actions.add(PopupMenuItem(value: 'leave', child: Text('page_studio.leave'.tr())));
    return ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: member.profile.displayName, imageUrl: member.profile.avatarUrl, size: 40), title: Wrap(spacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [Text(member.profile.displayName), PageRoleStatus(role: member.role), if (me) HBChip(label: 'page_studio.you'.tr(), selected: false)]), subtitle: Text('@${member.profile.username} · ${'page_studio.member_since'.tr(namedArgs: {'time': relativeTime(context, member.createdAt)})}'), trailing: actions.isEmpty ? null : PopupMenuButton<String>(onSelected: (value) => value == 'remove' ? _remove(context, ref, leaving: false) : value == 'leave' ? _remove(context, ref, leaving: true) : _role(context, ref, value), itemBuilder: (_) => actions));
  }
}

class PageRoleStatus extends StatelessWidget {
  final String role;
  const PageRoleStatus({super.key, required this.role});
  @override
  Widget build(BuildContext context) => HBStatusChip(kind: role == 'owner' ? HBStatusKind.admin : role == 'moderator' ? HBStatusKind.moderator : HBStatusKind.neutral, label: 'page_studio.roles.$role'.tr());
}

class PageAddMemberSheet extends ConsumerStatefulWidget {
  final String pageId;
  const PageAddMemberSheet({super.key, required this.pageId});
  @override
  ConsumerState<PageAddMemberSheet> createState() => _PageAddMemberSheetState();
}

class _PageAddMemberSheetState extends ConsumerState<PageAddMemberSheet> {
  final _username = TextEditingController();
  Timer? _timer;
  List<UserProfile> _results = const [];
  UserProfile? _selected;
  String _role = 'editor';
  bool _saving = false;
  String? _error;

  @override
  void dispose() { _timer?.cancel(); _username.dispose(); super.dispose(); }
  void _search(String value) { _selected = null; _timer?.cancel(); _timer = Timer(const Duration(milliseconds: 300), () async { try { final result = await ref.read(pageRepositoryProvider).searchProfiles(value); if (mounted) setState(() => _results = result); } catch (_) { if (mounted) setState(() => _results = const []); } }); setState(() {}); }
  Future<void> _add() async { if (_selected == null || _saving) return; setState(() { _saving = true; _error = null; }); try { final member = await ref.read(pageRepositoryProvider).addMember(widget.pageId, _selected!.username, _role); if (mounted) context.pop(member); } on AppException catch (error) { if (mounted) setState(() { _saving = false; _error = error.messageKey; }); } }

  @override
  Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    Text('page_studio.add_member'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.lg),
    HBInput(controller: _username, label: 'page_studio.username'.tr(), hint: 'page_studio.username_hint'.tr(), prefixIcon: const Icon(Icons.alternate_email_rounded), onChanged: _search),
    if (_results.isNotEmpty && _selected == null) ...[const SizedBox(height: AppSpacing.sm), HBCard(child: Column(children: _results.map((profile) => ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 36), title: Text(profile.displayName), subtitle: Text('@${profile.username}'), onTap: () => setState(() { _selected = profile; _username.text = profile.username; _results = const []; }))).toList()))],
    const SizedBox(height: AppSpacing.lg), Text('page_studio.choose_role'.tr(), style: context.textStyles.titleSmall), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, children: ['editor', 'moderator'].map((role) => HBChip(label: 'page_studio.roles.$role'.tr(), selected: _role == role, onTap: () => setState(() => _role = role))).toList()), const SizedBox(height: AppSpacing.sm), Text('page_studio.role_help.$_role'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
    if (_error != null) ...[const SizedBox(height: AppSpacing.md), Text(_error!.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))],
    const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'page_studio.add'.tr(), onPressed: _selected == null || _saving ? null : _add, isLoading: _saving),
  ]))));
}

class PageStudioSettings extends ConsumerStatefulWidget {
  final CommunityPage page;
  final String myRole;
  final VoidCallback onChanged;
  const PageStudioSettings({super.key, required this.page, required this.myRole, required this.onChanged});
  @override
  ConsumerState<PageStudioSettings> createState() => _PageStudioSettingsState();
}

class _PageStudioSettingsState extends ConsumerState<PageStudioSettings> {
  late final TextEditingController _name = TextEditingController(text: widget.page.name);
  late final TextEditingController _description = TextEditingController(text: widget.page.description ?? '');
  late final TextEditingController _website = TextEditingController(text: widget.page.website ?? '');
  late final TextEditingController _phone = TextEditingController(text: widget.page.phone ?? '');
  late final TextEditingController _email = TextEditingController(text: widget.page.email ?? '');
  late final TextEditingController _address = TextEditingController(text: widget.page.address ?? '');
  late String _category = widget.page.category;
  ReferenceRegion? _region;
  bool _regionReady = false;
  PreparedUpload? _avatar;
  PreparedUpload? _cover;
  bool _saving = false;
  bool _publishing = false;
  double _progress = 0;
  String? _error;

  @override
  void dispose() { for (final value in [_name, _description, _website, _phone, _email, _address]) { value.dispose(); } super.dispose(); }
  String? _optional(TextEditingController value) => value.text.trim().isEmpty ? null : value.text.trim();
  Future<void> _pick(bool avatar) async { try { final service = ref.read(mediaUploadServiceProvider); final source = await MediaSourcePicker.imageBytes(context, service); if (source == null || !mounted) return; final cropped = await HBImageCropper.show(context, bytes: source, aspectRatio: avatar ? 1 : 3, outputWidth: avatar ? 512 : 1800, outputHeight: avatar ? 512 : 600, circularMask: avatar); if (cropped != null && mounted) setState(() => avatar ? _avatar = service.prepareJpeg(cropped) : _cover = service.prepareJpeg(cropped)); } on AppException catch (error) { if (mounted) setState(() => _error = error.messageKey); } }
  Future<UploadedMedia?> _upload(PreparedUpload? value, String userId, int index, int count) async { if (value == null) return null; final progress = UploadProgress(); final subscription = progress.stream.listen((value) { if (mounted) setState(() => _progress = (index + value) / count); }); try { return await ref.read(mediaUploadServiceProvider).uploadToBucket(bucket: 'page-media', userId: userId, upload: value, isPublic: true, progress: progress); } finally { await subscription.cancel(); await progress.close(); } }

  Future<void> _save() async {
    final website = _optional(_website); final email = _optional(_email);
    if (website != null && !website.startsWith('https://')) { setState(() => _error = 'pages.errors.website_invalid'); return; }
    if (email != null && !email.contains('@')) { setState(() => _error = 'pages.errors.email_invalid'); return; }
    final userId = ref.read(authSessionProvider).value?.user.id; if (_saving || userId == null) return;
    setState(() { _saving = true; _publishing = false; _progress = 0; _error = null; });
    UploadedMedia? avatar; UploadedMedia? cover; final count = [_avatar, _cover].whereType<PreparedUpload>().length;
    try {
      avatar = await _upload(_avatar, userId, 0, count); cover = await _upload(_cover, userId, _avatar == null ? 0 : 1, count); if (mounted) setState(() { _progress = count == 0 ? 0 : 1; _publishing = true; });
      final changes = <String, dynamic>{};
      void changed(String key, Object? value, Object? old) { if (value != old) changes[key] = value; }
      changed('name', _name.text.trim(), widget.page.name); changed('description', _optional(_description), widget.page.description); changed('category', _category, widget.page.category); changed('website', website, widget.page.website); changed('phone', _optional(_phone), widget.page.phone); changed('email', email, widget.page.email); changed('address', _optional(_address), widget.page.address); changed('region_id', _region?.id, widget.page.regionId); if (avatar != null) changes['avatar_url'] = avatar.path; if (cover != null) changes['cover_url'] = cover.path;
      await ref.read(pageRepositoryProvider).updatePage(widget.page.id, changes);
      final media = ref.read(mediaUploadServiceProvider); if (avatar != null) { try { await media.delete('page-media', media.pathFromPublicUrl('page-media', widget.page.avatarUrl)); } catch (_) {} } if (cover != null) { try { await media.delete('page-media', media.pathFromPublicUrl('page-media', widget.page.coverUrl)); } catch (_) {} }
      widget.onChanged(); if (mounted) { setState(() { _saving = false; _publishing = false; _avatar = null; _cover = null; }); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('page_studio.settings_saved'.tr()))); }
    } on AppException catch (error) { if (avatar != null) { try { await ref.read(mediaUploadServiceProvider).delete('page-media', avatar.path); } catch (_) {} } if (cover != null) { try { await ref.read(mediaUploadServiceProvider).delete('page-media', cover.path); } catch (_) {} } if (mounted) setState(() { _saving = false; _publishing = false; _error = error.messageKey; }); }
  }

  Future<void> _archive() async { final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('page_studio.archive_title'.tr()), content: Text('page_studio.archive_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'page_studio.archive'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false; if (!confirmed || !mounted) return; try { await ref.read(pageRepositoryProvider).setStatus(widget.page.id, 'archived'); widget.onChanged(); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(pageCategoriesProvider); final regions = ref.watch(regionsProvider(widget.page.countryCode));
    if (!_regionReady && regions.hasValue) { _regionReady = true; for (final item in regions.value ?? const <ReferenceRegion>[]) { if (item.id == widget.page.regionId) _region = item; } }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      PageVerificationSection(page: widget.page, onChanged: widget.onChanged),
      const HBFormSectionDivider(),
      HBFormSection(title: 'pages.form.identity'.tr(), children: [
        LayoutBuilder(builder: (context, constraints) { final avatar = HBFormField(label: 'pages.form.avatar'.tr(), child: HBImageField(kind: HBImageFieldKind.avatar, imageUrl: widget.page.avatarUrl, imageBytes: _avatar?.bytes, onPick: _saving ? null : () => _pick(true), onRemove: _avatar == null ? null : () => setState(() => _avatar = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr())); final cover = HBFormField(label: 'pages.form.cover'.tr(), child: HBImageField(kind: HBImageFieldKind.cover, imageUrl: widget.page.coverUrl, imageBytes: _cover?.bytes, onPick: _saving ? null : () => _pick(false), onRemove: _cover == null ? null : () => setState(() => _cover = null), changeLabel: 'form.change_image'.tr(), removeLabel: 'form.remove_image'.tr())); return constraints.maxWidth < 560 ? Column(children: [avatar, const SizedBox(height: AppSpacing.lg), cover]) : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [SizedBox(width: 150, child: avatar), const SizedBox(width: AppSpacing.lg), Expanded(child: cover)]); }),
        HBFormField(label: 'pages.form.name'.tr(), required: true, child: HBInput(controller: _name, maxLength: 80, enabled: !_saving)),
        HBFormField(label: 'pages.form.category_label'.tr(), child: categories.isLoading ? const LinearProgressIndicator() : Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: (categories.value ?? const <PageCategory>[]).map((item) => HBChip(label: item.nameKey.tr(), selected: _category == item.slug, onTap: () => setState(() => _category = item.slug))).toList())),
        HBFormField(label: 'pages.form.description'.tr(), child: HBInput(controller: _description, maxLength: 2000, minLines: 3, maxLines: 8, enabled: !_saving)),
      ]),
      const HBFormSectionDivider(),
      HBFormSection(title: 'pages.form.contacts'.tr(), children: [HBFormField(label: 'pages.form.website'.tr(), child: HBInput(controller: _website, keyboardType: TextInputType.url, enabled: !_saving)), HBFormField(label: 'pages.form.phone'.tr(), child: HBInput(controller: _phone, keyboardType: TextInputType.phone, enabled: !_saving)), HBFormField(label: 'pages.form.email'.tr(), child: HBInput(controller: _email, keyboardType: TextInputType.emailAddress, enabled: !_saving)), HBFormField(label: 'pages.form.address'.tr(), child: HBInput(controller: _address, maxLength: 200, enabled: !_saving)), HBFormField(label: 'pages.form.region'.tr(), child: PageRegionPicker(regions: regions.value ?? const [], selected: _region, enabled: !_saving, onSelected: (value) => setState(() { _regionReady = true; _region = value; })))]),
      if (_saving || _error != null) ...[const SizedBox(height: AppSpacing.md), HBUploadProgress(progress: _progress, publishing: _publishing, errorKey: _saving ? null : _error)],
      HBFormActions(primaryLabel: 'common.save'.tr(), onPrimary: !_saving && _name.text.trim().length >= 2 ? _save : null, secondaryLabel: 'common.cancel'.tr(), onSecondary: () => context.go(AppRoutes.pageDetailPath(widget.page.slug)), loading: _saving),
      const SizedBox(height: AppSpacing.sm), Text('page_studio.slug_note'.tr(namedArgs: {'slug': widget.page.slug}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      if (widget.myRole == 'owner' && widget.page.status == 'active') ...[const SizedBox(height: AppSpacing.xl), HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('page_studio.danger_zone'.tr(), style: context.textStyles.titleMedium?.withColor(LightModeColors.lightError)), const SizedBox(height: AppSpacing.sm), HBButton.soft(label: 'page_studio.archive'.tr(), icon: Icons.archive_outlined, onPressed: _archive)]))],
    ]);
  }
}

class PageVerificationSection extends ConsumerWidget {
  final CommunityPage page;
  final VoidCallback onChanged;
  const PageVerificationSection({super.key, required this.page, required this.onChanged});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final sent = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => VerificationWizard(fixedType: BadgeType.page, pageId: page.id));
    if (sent == true) { ref.invalidate(myVerificationProvider); onChanged(); }
  }

  Future<void> _cancel(BuildContext context, WidgetRef ref, VerificationRequest pending) async {
    try { await ref.read(verificationRepositoryProvider).cancel(pending.id); ref.invalidate(myVerificationProvider); onChanged(); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(myVerificationProvider).when(
    loading: () => const LinearProgressIndicator(),
    error: (_, __) => HBTile(child: Text('verification.errors.load'.tr())),
    data: (status) {
      final pending = status.pending?.pageId == page.id ? status.pending : null;
      final rejected = status.history.where((item) => item.pageId == page.id && item.status == VerificationRequestStatus.rejected).firstOrNull;
      final label = page.verificationStatus == 'verified' && page.verifiedAt != null ? 'verification.page.verified'.tr(namedArgs: {'date': DateFormat.yMMMd(context.locale.languageCode).format(page.verifiedAt!.toLocal())}) : 'verification.page.${page.verificationStatus}'.tr();
      return HBFormSection(title: 'verification.page.title'.tr(), children: [HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: context.textStyles.titleSmall), if (page.verificationStatus == 'rejected' && rejected?.rejectionReason != null) ...[const SizedBox(height: AppSpacing.xs), Text('verification.rejection_reason'.tr(namedArgs: {'reason': rejected!.rejectionReason!}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError))], const SizedBox(height: AppSpacing.sm), if (pending != null) HBButton.soft(label: 'verification.withdraw'.tr(), onPressed: () => _cancel(context, ref, pending)) else if (page.verificationStatus != 'verified') HBButton.primary(label: page.verificationStatus == 'rejected' ? 'verification.request_again'.tr() : 'verification.request'.tr(), onPressed: () => _open(context, ref))]))]);
    },
  );
}

class PageStudioArchivedBanner extends ConsumerWidget {
  final CommunityPage page;
  final bool owner;
  final VoidCallback onChanged;
  const PageStudioArchivedBanner({super.key, required this.page, required this.owner, required this.onChanged});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(padding: const EdgeInsets.all(AppSpacing.md), decoration: BoxDecoration(color: LightModeColors.lightWarning.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(AppRadius.md)), child: Row(children: [const Icon(Icons.archive_outlined, color: LightModeColors.lightWarning), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('page_studio.archived'.tr(), style: context.textStyles.titleSmall)), if (owner) HBButton.soft(label: 'page_studio.reactivate'.tr(), size: HBButtonSize.sm, onPressed: () async { try { await ref.read(pageRepositoryProvider).setStatus(page.id, 'active'); onChanged(); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } })]));
}