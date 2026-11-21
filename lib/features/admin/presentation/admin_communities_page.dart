import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/data/admin_list_repository.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/presentation/admin_content_page.dart';
import 'package:hb_social/features/admin/presentation/admin_users_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';

class AdminCommunitiesPage extends ConsumerStatefulWidget {
  final String? initialId;
  const AdminCommunitiesPage({super.key, this.initialId});
  @override ConsumerState<AdminCommunitiesPage> createState() => _AdminCommunitiesPageState();
}

class _AdminCommunitiesPageState extends ConsumerState<AdminCommunitiesPage> {
  int tab = 0;
  String? status;
  String? visibility;
  String? joinPolicy;
  String? category;
  String? verification;
  String? country;
  String? region;
  String period = 'all';
  String search = '';
  Object? selected;
  Timer? debounce;

  String get kind => const ['groups','pages','forums','events'][tab];
  @override void dispose() { debounce?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final filters = AdminCommunityFilters(id: widget.initialId, kind: kind, status: status, visibility: visibility, joinPolicy: joinPolicy, category: category, verificationStatus: verification, countryCode: country, regionId: region, period: period, search: search);
    final communityProvider = adminCommunitiesProvider(filters);
    final eventProvider = adminEventsProvider(filters);
    final value = tab == 3 ? ref.watch(eventProvider) : ref.watch(communityProvider);
    final state = value.value;
    final count = tab == 3 ? ref.read(eventProvider.notifier).count : ref.read(communityProvider.notifier).count;
    if (selected == null && widget.initialId != null && state?.items.isNotEmpty == true) WidgetsBinding.instance.addPostFrameCallback((_) { if (mounted && selected == null) setState(() => selected = state!.items.first); });
    return Stack(children: [
      AdminListPage(
        title: 'admin.modules.communities.title'.tr(),
        description: 'admin.p05d.results'.tr(namedArgs: {'count': '$count'}),
        filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 520, child: HBSegmentedTabs(labels: [for (final key in ['groups','pages','forums','events']) 'admin.p05d.communityTabs.$key'.tr()], selectedIndex: tab, onChanged: (value) => setState(() { tab = value; status = null; visibility = null; joinPolicy = null; category = null; verification = null; selected = null; }))),
          const SizedBox(height: AppSpacing.sm),
          CommunityFilters(tab: tab, status: status, visibility: visibility, joinPolicy: joinPolicy, category: category, verification: verification, country: country, region: region, period: period, onSearch: _search, onStatus: (value) => setState(() => status = value), onVisibility: (value) => setState(() => visibility = value), onJoinPolicy: (value) => setState(() => joinPolicy = value), onCategory: (value) => setState(() => category = value), onVerification: (value) => setState(() => verification = value), onCountry: (value) => setState(() => country = value), onRegion: (value) => setState(() => region = value), onPeriod: (value) => setState(() => period = value)),
          if (tab == 1) ...[const SizedBox(height: AppSpacing.sm), HBChip(label: 'admin.p05d.pendingVerifications'.tr(), selected: verification == 'pending', onTap: () => setState(() => verification = verification == 'pending' ? null : 'pending'))],
        ]),
        kpis: [AdminKpiValue(label: 'admin.p05d.total'.tr(), value: '$count')],
        emptyMessage: 'admin.p05d.communitiesEmpty'.tr(),
        content: AdminCommunitiesTable(tab: tab, items: state?.items ?? const [], isLoading: value.isLoading, onSelected: (item) => setState(() => selected = item)),
        hasMore: state?.hasMore ?? false,
        isLoadingMore: state?.isLoadingMore ?? false,
        onLoadMore: () => tab == 3 ? ref.read(eventProvider.notifier).loadMore() : ref.read(communityProvider.notifier).loadMore(),
        onRetry: value.hasError && state == null ? () => tab == 3 ? ref.invalidate(eventProvider) : ref.invalidate(communityProvider) : null,
      ),
      if (selected != null) AdminDetailOverlay(onClose: _close, panel: AdminCommunityDetailPanel(record: selected!, onClose: _close)),
    ]);
  }

  void _search(String value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 250), () { if (mounted) setState(() => search = value); }); }
  void _close() { setState(() => selected = null); if (widget.initialId != null) context.go('/admin/communities'); }
}

class CommunityFilters extends StatelessWidget {
  final int tab;
  final String? status;
  final String? visibility;
  final String? joinPolicy;
  final String? category;
  final String? verification;
  final String? country;
  final String? region;
  final String period;
  final ValueChanged<String> onSearch;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String?> onVisibility;
  final ValueChanged<String?> onJoinPolicy;
  final ValueChanged<String?> onCategory;
  final ValueChanged<String?> onVerification;
  final ValueChanged<String?> onCountry;
  final ValueChanged<String?> onRegion;
  final ValueChanged<String> onPeriod;
  const CommunityFilters({super.key, required this.tab, required this.status, required this.visibility, required this.joinPolicy, required this.category, required this.verification, required this.country, required this.region, required this.period, required this.onSearch, required this.onStatus, required this.onVisibility, required this.onJoinPolicy, required this.onCategory, required this.onVerification, required this.onCountry, required this.onRegion, required this.onPeriod});

  @override Widget build(BuildContext context) {
    final pageCategories = const ['company','association','breeder','gun_shop','guide','manufacturer','media'];
    final eventCategories = const ['meetup','shooting','drive','fair','course'];
    return Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [
      SizedBox(width: 230, child: HBInput(hint: (tab == 3 ? 'admin.p05d.searchTitle' : 'admin.p05d.searchName').tr(), prefixIcon: const Icon(Icons.search), onChanged: onSearch)),
      AdminValueFilter(label: status == null ? 'admin.p05d.status'.tr() : 'admin.p05d.statuses.$status'.tr(), values: tab == 3 ? const ['draft','published','cancelled'] : const ['active','archived','removed'], scope: 'admin.p05d.statuses', onChanged: onStatus),
      if (tab == 0 || tab == 2) AdminValueFilter(label: visibility == null ? 'admin.p05d.visibility'.tr() : 'admin.p05d.visibilities.$visibility'.tr(), values: tab == 0 ? const ['public','private','secret'] : const ['public','private'], scope: 'admin.p05d.visibilities', onChanged: onVisibility),
      if (tab == 0) AdminValueFilter(label: joinPolicy == null ? 'admin.p05d.joinPolicy'.tr() : 'admin.p05d.joinPolicies.$joinPolicy'.tr(), values: const ['open','approval'], scope: 'admin.p05d.joinPolicies', onChanged: onJoinPolicy),
      if (tab == 1 || tab == 3) AdminValueFilter(label: category == null ? 'admin.p05d.category'.tr() : 'admin.p05d.categories.$category'.tr(), values: tab == 1 ? pageCategories : eventCategories, scope: 'admin.p05d.categories', onChanged: onCategory),
      if (tab == 1) AdminValueFilter(label: verification == null ? 'admin.p05d.verification'.tr() : 'admin.p05d.verifications.$verification'.tr(), values: const ['none','pending','verified','rejected'], scope: 'admin.p05d.verifications', onChanged: onVerification),
      AdminValueFilter(label: country ?? 'admin.p05d.country'.tr(), values: const ['IT','FR','ES','DE','AT','GB'], onChanged: onCountry),
      if (tab == 0 || tab == 1 || tab == 3) SizedBox(width: 170, child: HBInput(hint: 'admin.p05d.regionId'.tr(), onChanged: (value) => onRegion(value.trim().isEmpty ? null : value.trim()))),
      if (tab == 3) AdminValueFilter(label: 'admin.p05d.periods.$period'.tr(), values: const ['future','past'], scope: 'admin.p05d.periods', onChanged: (value) => onPeriod(value ?? 'all')),
    ]);
  }
}

class AdminCommunitiesTable extends StatelessWidget {
  final int tab;
  final List<Object> items;
  final bool isLoading;
  final ValueChanged<Object> onSelected;
  const AdminCommunitiesTable({super.key, required this.tab, required this.items, required this.isLoading, required this.onSelected});
  @override Widget build(BuildContext context) {
    if (tab == 3) return AdminDataTable(headers: [for (final key in ['title','category','organizer','date','place','participants','price','status']) 'admin.p05d.eventColumns.$key'.tr()], columnWidths: const [220,120,190,160,180,130,120,110], rows: [for (final raw in items) _eventCells(context, raw as AdminEventRecord)], rowCallbacks: [for (final item in items) () => onSelected(item)], emptyMessage: 'admin.p05d.communitiesEmpty'.tr(), isLoading: isLoading);
    final headers = tab == 0 ? ['name','owner','visibility','join','members','posts','region','status','created'] : tab == 1 ? ['name','category','owner','verification','followers','region','status'] : ['name','category','owner','visibility','threads','members','status'];
    return AdminDataTable(headers: [for (final key in headers) 'admin.p05d.communityColumns.$key'.tr()], columnWidths: [for (var i = 0; i < headers.length; i++) i == 0 ? 210 : i == 2 ? 180 : 120], rows: [for (final raw in items) _communityCells(context, raw as AdminCommunityRecord)], rowCallbacks: [for (final item in items) () => onSelected(item)], emptyMessage: 'admin.p05d.communitiesEmpty'.tr(), isLoading: isLoading);
  }

  List<Widget> _communityCells(BuildContext context, AdminCommunityRecord item) {
    final name = Row(children: [HBAvatar(size: 24, imageUrl: item.avatarUrl, name: item.name), const SizedBox(width: AppSpacing.xs), Expanded(child: Text(item.name, overflow: TextOverflow.ellipsis))]);
    final owner = AdminPersonCell(person: item.owner, avatarSize: 24, showUsername: false);
    final status = AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status);
    if (tab == 0) return [name, owner, Text('admin.p05d.visibilities.${item.visibility}'.tr()), Text('admin.p05d.joinPolicies.${item.joinPolicy}'.tr()), Text('${item.memberCount}'), Text('${item.contentCount}'), Text(item.regionName ?? 'common.unavailable'.tr()), status, Text(relativeTime(context, item.createdAt))];
    if (tab == 1) return [name, Text('admin.p05d.categories.${item.category}'.tr()), owner, Column(crossAxisAlignment: CrossAxisAlignment.start, children: [VerificationChip(value: item.verificationStatus ?? 'none'), if (item.verifiedAt != null) Text(DateFormat.yMd(context.locale.toString()).format(item.verifiedAt!.toLocal()), style: context.textStyles.labelSmall)]), Text('${item.followerCount}'), Text(item.regionName ?? 'common.unavailable'.tr()), status];
    return [name, Text(item.category ?? 'common.unavailable'.tr()), owner, Text('admin.p05d.visibilities.${item.visibility}'.tr()), Text('${item.contentCount}'), Text('${item.memberCount}'), status];
  }

  List<Widget> _eventCells(BuildContext context, AdminEventRecord item) {
    final event = item.event;
    return [Text(event.title), Text('admin.p05d.categories.${event.category}'.tr()), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(event.organizer.name), Text('admin.p05d.organizerKinds.${event.organizer.kind}'.tr(), style: context.textStyles.labelSmall)]), Text(DateFormat.yMd(context.locale.toString()).add_Hm().format(event.startsAt.toLocal())), Text(event.location ?? event.address ?? 'common.unavailable'.tr()), Text('${event.participantCount}/${event.capacity?.toString() ?? '—'}'), Text(MoneyFormatter.format(amountMinor: event.priceMinor, currencyCode: event.currencyCode, locale: context.locale)), AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status)];
  }
}

class VerificationChip extends StatelessWidget {
  final String value;
  const VerificationChip({super.key, required this.value});
  @override Widget build(BuildContext context) => HBStatusChip(kind: switch (value) { 'pending' => HBStatusKind.pending, 'verified' => HBStatusKind.approved, 'rejected' => HBStatusKind.rejected, _ => HBStatusKind.neutral }, label: 'admin.p05d.verifications.$value'.tr());
}

class AdminCommunityDetailPanel extends ConsumerWidget {
  final Object record;
  final VoidCallback onClose;
  const AdminCommunityDetailPanel({super.key, required this.record, required this.onClose});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final canWrite = ref.watch(adminAccessProvider).valueOrNull?.canWrite('communities') ?? false;
    if (record is AdminEventRecord) return AdminEventDetailPanel(record: record as AdminEventRecord, canWrite: canWrite, onClose: onClose);
    final item = record as AdminCommunityRecord;
    final detail = ref.watch(adminCommunityDetailProvider(item));
    final path = item.kind == 'groups' ? '/groups/${item.slug}' : item.kind == 'pages' ? '/pages/${item.slug}' : '/forum/${item.slug}';
    final actionKeys = item.kind == 'pages' ? ['verify','rejectVerification','archive'] : item.kind == 'groups' ? ['archive','remove','changeOwner'] : ['archive','remove'];
    return AdminDetailPanel(title: item.name, status: AdminStatusValueChip(scope: 'admin.p05d.statuses', value: item.status), onClose: onClose, actions: canWrite ? [for (final key in actionKeys) P41Action(labelKey: 'admin.p05d.actions.$key')] : const [], body: Column(children: [
      AdminDetailCard(title: 'admin.p05d.description'.tr(), child: Text(item.description ?? 'common.unavailable'.tr())),
      AdminDetailCard(title: 'admin.p05d.counters'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.p05d.members'.tr(), value: '${item.memberCount}'), AdminLabelValueRow(label: item.kind == 'forums' ? 'admin.p05d.threads'.tr() : 'admin.p05d.posts'.tr(), value: '${item.contentCount}'), if (item.kind == 'pages') AdminLabelValueRow(label: 'admin.p05d.followers'.tr(), value: '${item.followerCount}')])),
      if (item.kind == 'pages') AdminDetailCard(title: 'admin.approvals.pages.verification'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.approvals.pages.status'.tr(), value: 'admin.p05d.verifications.${item.verificationStatus ?? 'none'}'.tr()), AdminLabelValueRow(label: 'admin.approvals.pages.verified_at'.tr(), value: item.verifiedAt == null ? 'common.unavailable'.tr() : DateFormat.yMd(context.locale.toString()).format(item.verifiedAt!.toLocal()))])),
      if (item.kind == 'pages') AdminDetailCard(title: 'admin.p05d.contacts'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.p05d.website'.tr(), value: item.website ?? 'common.unavailable'.tr()), AdminLabelValueRow(label: 'admin.p05d.phone'.tr(), value: item.phone ?? 'common.unavailable'.tr()), AdminLabelValueRow(label: 'admin.p05d.email'.tr(), value: item.email ?? 'common.unavailable'.tr()), AdminLabelValueRow(label: 'admin.p05d.address'.tr(), value: item.address ?? 'common.unavailable'.tr())])),
      detail.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('admin.p05b.detailError'.tr()), data: (value) => CommunityRelatedData(kind: item.kind, detail: value)),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.go(path), icon: const Icon(Icons.open_in_new), label: Text('admin.p05d.openInApp'.tr()))),
    ]));
  }
}

class CommunityRelatedData extends StatelessWidget {
  final String kind;
  final AdminCommunityDetail detail;
  const CommunityRelatedData({super.key, required this.kind, required this.detail});
  @override Widget build(BuildContext context) => Column(children: [
    AdminDetailCard(title: kind == 'pages' ? 'admin.p05d.roles'.tr() : 'admin.p05d.members'.tr(), child: detail.members.isEmpty ? Text('admin.p05d.noMembers'.tr()) : Column(children: [for (final item in detail.members) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(size: 28, imageUrl: item.person.avatarUrl, name: item.person.displayName), title: Text(item.person.displayName), subtitle: Text(item.role), trailing: item.status == 'pending' ? HBStatusChip(kind: HBStatusKind.pending, label: 'admin.p05d.statuses.pending'.tr()) : item.status == null ? null : Text('admin.p05d.statuses.${item.status}'.tr()))])),
    if (kind != 'forums') AdminDetailCard(title: 'admin.p05d.latestPosts'.tr(), child: detail.posts.isEmpty ? Text('admin.p05d.noPosts'.tr()) : Column(children: [for (final item in detail.posts) ListTile(contentPadding: EdgeInsets.zero, title: Text(excerpt(item.post.content, 80)), subtitle: Text(item.post.author.displayName), onTap: () => context.go('/admin/content?id=${item.post.id}'))])),
    if (kind == 'forums') AdminDetailCard(title: 'admin.p05d.latestThreads'.tr(), child: detail.threads.isEmpty ? Text('admin.p05d.noThreads'.tr()) : Column(children: [for (final item in detail.threads) ListTile(contentPadding: EdgeInsets.zero, title: Text(item.title), subtitle: Text('${item.author.displayName} · ${'forum.reply_count'.plural(item.replyCount)}'), trailing: Wrap(spacing: 4, children: [if (item.isPinned) const Icon(Icons.push_pin_outlined, size: 16), if (item.isLocked) const Icon(Icons.lock_outline, size: 16), if (item.isSolved) const Icon(Icons.check_circle_outline, size: 16)]))])),
  ]);
}

class AdminEventDetailPanel extends ConsumerWidget {
  final AdminEventRecord record;
  final bool canWrite;
  final VoidCallback onClose;
  const AdminEventDetailPanel({super.key, required this.record, required this.canWrite, required this.onClose});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(adminEventDetailProvider(record.event.id));
    return AdminDetailPanel(title: record.event.title, status: AdminStatusValueChip(scope: 'admin.p05d.statuses', value: record.status), onClose: onClose, actions: canWrite ? const [P41Action(labelKey: 'admin.p05d.actions.cancel'), P41Action(labelKey: 'admin.p05d.actions.remove')] : const [], body: Column(children: [
      AdminDetailCard(title: 'admin.p05d.description'.tr(), child: Text(record.event.description ?? 'common.unavailable'.tr())),
      detail.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('admin.p05b.detailError'.tr()), data: (value) => AdminDetailCard(title: 'admin.p05d.participants'.tr(), child: value.participants.isEmpty ? Text('admin.p05d.noParticipants'.tr()) : Column(children: [for (final item in value.participants) ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(size: 28, imageUrl: item.profile.avatarUrl, name: item.profile.displayName), title: Text(item.profile.displayName), trailing: Text('admin.p05d.participantStatuses.${item.status}'.tr()))]))),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(onPressed: () => context.go('/events/${record.event.id}'), icon: const Icon(Icons.open_in_new), label: Text('admin.p05d.openInApp'.tr()))),
    ]));
  }
}