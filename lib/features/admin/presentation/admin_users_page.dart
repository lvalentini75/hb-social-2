import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_access.dart';
import 'package:hb_social/features/admin/domain/admin_p41_models.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';
import 'package:hb_social/features/admin/providers/admin_p41_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminUsersPage extends ConsumerStatefulWidget {
  final String? initialId;
  const AdminUsersPage({super.key, this.initialId});
  @override ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  String query = '';
  String? status;
  String? country;
  String? verification;
  String? flag;
  String sort = 'created';
  DateTime? from;
  DateTime? to;
  int offset = 0;
  Timer? debounce;
  late Future<List<AdminP41User>> future;

  @override void initState() { super.initState(); future = _load(); if (widget.initialId != null) WidgetsBinding.instance.addPostFrameCallback((_) => context.go('${AppRoutes.adminUsers}/${widget.initialId}')); }
  @override void dispose() { debounce?.cancel(); super.dispose(); }
  Future<List<AdminP41User>> _load() => ref.read(adminP41RepositoryProvider).users(query: query, status: status, country: country, verification: verification, flag: flag, from: from, to: to, sort: sort, offset: offset);
  void _reload({bool reset = true}) => setState(() { if (reset) offset = 0; future = _load(); });

  @override Widget build(BuildContext context) {
    final stats = ref.watch(adminModerationStatsProvider).value;
    final countries = ref.watch(adminPlatformConfigurationProvider).value?.countries.where((item) => item.isActive).toList() ?? const [];
    return FutureBuilder<List<AdminP41User>>(
      future: future,
      builder: (context, snapshot) {
        final users = snapshot.data ?? const <AdminP41User>[];
        final total = users.isEmpty ? 0 : users.first.total;
        final start = total == 0 ? 0 : offset + 1;
        final end = (offset + users.length).clamp(0, total);
        return AdminListPage(
          title: 'admin.users.title'.tr(), description: 'admin.users.p41_range'.tr(namedArgs: {'from': '$start', 'to': '$end', 'total': '$total'}),
          filters: AdminUsersP41Filters(queryChanged: (value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 350), () { query = value; _reload(); }); }, status: status, onStatus: (value) { status = value; _reload(); }, country: country, countries: countries.map((item) => item.code).toList(), onCountry: (value) { country = value; _reload(); }, verification: verification, onVerification: (value) { verification = value; _reload(); }, flag: flag, onFlag: (value) { flag = value; _reload(); }, sort: sort, onSort: (value) { sort = value; _reload(); }, from: from, to: to, onDates: _dates),
          kpis: [AdminKpiValue(label: 'admin.users.kpi.suspended'.tr(), value: '${stats?.suspendedUsers ?? 0}'), AdminKpiValue(label: 'admin.users.kpi.banned'.tr(), value: '${stats?.bannedUsers ?? 0}'), AdminKpiValue(label: 'admin.users.kpi.deleting'.tr(), value: '${stats?.pendingDeletions ?? 0}')],
          emptyMessage: 'admin.users.emptyFiltered'.tr(),
          content: snapshot.hasError ? HBEmptyState(icon: Icons.error_outline, title: 'admin.users.load_error'.tr(), message: 'errors.network'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: _reload)) : Column(children: [AdminDataTable(headers: [for (final key in ['user','status','countryRegion','verification','registered','lastActivity','posts','followers','strikes','reports','role']) 'admin.users.table.$key'.tr()], columnWidths: const [210,150,150,120,110,120,70,80,75,80,120], rows: [for (final user in users) _row(user)], rowCallbacks: [for (final user in users) () => context.go('${AppRoutes.adminUsers}/${user.id}')], emptyMessage: 'admin.users.emptyFiltered'.tr(), isLoading: snapshot.connectionState == ConnectionState.waiting), const SizedBox(height: AppSpacing.md), Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('admin.users.p41_range'.tr(namedArgs: {'from': '$start', 'to': '$end', 'total': '$total'})), const SizedBox(width: AppSpacing.md), HBButton.icon(icon: Icons.chevron_left, onPressed: offset > 0 ? () { offset = (offset - 50).clamp(0, total); _reload(reset: false); } : null), const SizedBox(width: AppSpacing.xs), HBButton.icon(icon: Icons.chevron_right, onPressed: offset + users.length < total ? () { offset += 50; _reload(reset: false); } : null)])]),
        );
      },
    );
  }

  List<Widget> _row(AdminP41User user) => [Row(children: [HBAvatar(size: 34, name: user.displayName, imageUrl: user.avatarUrl), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(user.displayName, overflow: TextOverflow.ellipsis), Text('@${user.username}', overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall)]))]), AdminUserStatusChip(user: user), Text([user.countryCode, user.regionName].whereType<String>().where((v) => v.isNotEmpty).join(' · ')), HBStatusChip(kind: user.verificationLevel == 'none' ? HBStatusKind.neutral : HBStatusKind.approved, label: 'admin.badges.type.${user.verificationLevel}'.tr()), Text(relativeTime(context, user.createdAt)), Text(user.lastSeenAt == null ? 'common.unavailable'.tr() : relativeTime(context, user.lastSeenAt!)), Text('${user.postCount}'), Text('${user.followerCount}'), user.activeStrikes == 0 ? const Text('0') : HBStatusChip(kind: HBStatusKind.rejected, label: '${user.activeStrikes}'), Text('${user.openReports}'), Text(user.adminRole == null ? 'common.unavailable'.tr() : 'admin.roles.${_roleKey(user.adminRole!)}'.tr())];

  Future<void> _dates() async {
    final range = await showDateRangePicker(context: context, firstDate: DateTime(2020), lastDate: DateTime.now());
    if (range != null) { from = range.start; to = range.end.add(const Duration(days: 1)); _reload(); }
  }
}

class AdminUsersP41Filters extends StatelessWidget {
  final ValueChanged<String> queryChanged;
  final String? status, country, verification, flag;
  final List<String> countries;
  final ValueChanged<String?> onStatus, onCountry, onVerification, onFlag;
  final String sort;
  final ValueChanged<String> onSort;
  final DateTime? from, to;
  final VoidCallback onDates;
  const AdminUsersP41Filters({super.key, required this.queryChanged, required this.status, required this.onStatus, required this.country, required this.countries, required this.onCountry, required this.verification, required this.onVerification, required this.flag, required this.onFlag, required this.sort, required this.onSort, required this.from, required this.to, required this.onDates});
  @override Widget build(BuildContext context) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, crossAxisAlignment: WrapCrossAlignment.center, children: [
    SizedBox(width: 260, child: HBInput(hint: 'admin.users.searchHint'.tr(), prefixIcon: const Icon(Icons.search, size: 18), onChanged: queryChanged)),
    for (final value in [null, 'active','suspended','banned','deleted']) HBChip(label: (value == null ? 'admin.p05b.all' : 'admin.users.status.$value').tr(), selected: status == value, onTap: () => onStatus(value)),
    AdminCompactDropdown(label: country ?? 'admin.users.country'.tr(), items: ['admin.p05b.all'.tr(), ...countries], onSelected: (i) => onCountry(i == 0 ? null : countries[i - 1])),
    AdminCompactDropdown(label: verification == null ? 'admin.users.verification'.tr() : 'admin.badges.type.$verification'.tr(), items: [for (final value in ['none','hunter','gun_shop','guide','association']) 'admin.badges.type.$value'.tr()], onSelected: (i) => onVerification(['none','hunter','gun_shop','guide','association'][i])),
    AdminCompactDropdown(label: flag == null ? 'admin.users.flag'.tr() : 'admin.users.flags.$flag'.tr(), items: [for (final value in ['strikes','reported','admins','deleting']) 'admin.users.flags.$value'.tr()], onSelected: (i) => onFlag(['strikes','reported','admins','deleting'][i])),
    AdminCompactDropdown(label: 'admin.users.sort.$sort'.tr(), items: [for (final value in ['created','last_seen','name','posts']) 'admin.users.sort.$value'.tr()], onSelected: (i) => onSort(['created','last_seen','name','posts'][i])),
    HBButton.soft(label: from == null ? 'admin.users.date_range'.tr() : '${DateFormat.yMd().format(from!)} - ${DateFormat.yMd().format(to!.subtract(const Duration(days: 1)))}', icon: Icons.date_range, size: HBButtonSize.sm, onPressed: onDates),
  ]);
}

class AdminUserStatusChip extends StatelessWidget {
  final AdminP41User user;
  const AdminUserStatusChip({super.key, required this.user});
  @override Widget build(BuildContext context) {
    final kind = switch (user.status) { 'active' => HBStatusKind.approved, 'suspended' => HBStatusKind.pending, 'banned' => HBStatusKind.rejected, _ => HBStatusKind.neutral };
    final suffix = user.status == 'suspended' ? user.suspendedUntil == null ? 'admin.users.indefinite'.tr() : 'admin.users.until'.tr(namedArgs: {'date': DateFormat.yMd(context.locale.toString()).format(user.suspendedUntil!.toLocal())}) : '';
    return HBStatusChip(kind: kind, label: '${'admin.users.status.${user.status}'.tr()}${suffix.isEmpty ? '' : ' · $suffix'}');
  }
}

class AdminVerificationChip extends StatelessWidget {
  final String value;
  const AdminVerificationChip({super.key, required this.value});
  @override Widget build(BuildContext context) => HBStatusChip(kind: value == 'none' ? HBStatusKind.neutral : value == 'hunter' ? HBStatusKind.approved : HBStatusKind.info, label: 'admin.badges.type.$value'.tr());
}

class AdminStatusValueChip extends StatelessWidget {
  final String scope;
  final String value;
  const AdminStatusValueChip({super.key, required this.scope, required this.value});
  @override Widget build(BuildContext context) => HBStatusChip(kind: switch (value) { 'active' || 'approved' || 'resolved' || 'sold' => HBStatusKind.approved, 'suspended' || 'pending' || 'reserved' || 'medium' => HBStatusKind.pending, 'banned' || 'rejected' || 'removed' || 'high' => HBStatusKind.rejected, 'in_progress' || 'gun_shop' || 'guide' || 'association' => HBStatusKind.info, _ => HBStatusKind.neutral }, label: '$scope.$value'.tr());
}

class AdminUserDetailPage extends ConsumerStatefulWidget {
  final String userId;
  const AdminUserDetailPage({super.key, required this.userId});
  @override ConsumerState<AdminUserDetailPage> createState() => _AdminUserDetailPageState();
}

class _AdminUserDetailPageState extends ConsumerState<AdminUserDetailPage> {
  int tab = 0;
  @override Widget build(BuildContext context) {
    final detail = ref.watch(adminP41UserDetailProvider(widget.userId));
    final access = ref.watch(adminAccessProvider).value;
    return CustomScrollView(slivers: [SliverToBoxAdapter(child: Padding(padding: const EdgeInsets.only(bottom: AppSpacing.xl), child: detail.when(loading: () => const LinearProgressIndicator(), error: (_, __) => HBEmptyState(icon: Icons.error_outline, title: 'admin.users.load_error'.tr(), message: 'errors.network'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(adminP41UserDetailProvider(widget.userId)))), data: (value) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [AdminUserDetailHeader(detail: value, access: access, onAction: (action) => _action(action, value, access)), const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: [for (final key in ['overview','strikes','reports','notes','history','exports']) 'admin.users.tabs.$key'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value), variant: HBSegmentedTabsVariant.underlined), const SizedBox(height: AppSpacing.md), AdminUserDetailTab(detail: value, tab: tab, canWrite: access?.canWrite('users') == true, onRefresh: () => ref.invalidate(adminP41UserDetailProvider(widget.userId)), onDownload: _download)]))))]);
  }

  Future<void> _action(String action, AdminUserP41Detail detail, AdminAccess? access) async {
    final profile = detail.profile;
    final id = '${profile['id']}';
    try {
      if (action == 'export') await ref.read(adminP41RepositoryProvider).requestExport(id);
      if (action == 'reactivate') await ref.read(adminP41RepositoryProvider).unsuspend(id, await _textDialog('admin.users.actions.reactivate'.tr(), required: false));
      if (action == 'suspend') { final value = await showDialog<AdminActionInput>(context: context, builder: (_) => AdminActionDialog(kind: 'suspend', username: '${profile['username']}')); if (value != null) await ref.read(adminP41RepositoryProvider).suspend(id, value.days, value.reason, value.note); }
      if (action == 'ban') { final value = await showDialog<AdminActionInput>(context: context, builder: (_) => AdminActionDialog(kind: 'ban', username: '${profile['username']}')); if (value != null) await ref.read(adminP41RepositoryProvider).ban(id, value.reason, value.note); }
      if (action == 'strike') { final value = await showDialog<AdminActionInput>(context: context, builder: (_) => AdminActionDialog(kind: 'strike', username: '${profile['username']}')); if (value != null) await ref.read(adminP41RepositoryProvider).issueStrike(id, value.strikeReason ?? 'other', value.reason, value.days); }
      if (action == 'delete') { final value = await showDialog<AdminActionInput>(context: context, builder: (_) => AdminActionDialog(kind: 'delete', username: '${profile['username']}')); if (value != null) { await ref.read(adminP41RepositoryProvider).deleteUser(id, value.reason); if (mounted) { context.go(AppRoutes.adminUsers); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.users.deleted_success'.tr()))); } return; } }
      ref.invalidate(adminP41UserDetailProvider(widget.userId));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.users.action_success'.tr())));
    } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  Future<String?> _textDialog(String title, {required bool required}) async { final controller = TextEditingController(); return showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text(title), content: HBInput(controller: controller, hint: 'admin.users.note_optional'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.confirm'.tr(), onPressed: () => context.pop(controller.text.trim().isEmpty && required ? null : controller.text.trim()))])); }
  Future<void> _download(String id) async { try { final url = await ref.read(adminP41RepositoryProvider).exportUrl(id); await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
}

class AdminUserDetailHeader extends StatelessWidget {
  final AdminUserP41Detail detail;
  final AdminAccess? access;
  final ValueChanged<String> onAction;
  const AdminUserDetailHeader({super.key, required this.detail, required this.access, required this.onAction});
  @override Widget build(BuildContext context) {
    final p = detail.profile;
    final protected = detail.adminRole != null;
    final elevated = access?.roleName == 'admin' || access?.roleName == 'superadmin';
    final status = '${p['status'] ?? 'active'}';
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [HBButton.icon(icon: Icons.arrow_back, onPressed: () => context.go(AppRoutes.adminUsers)), const SizedBox(width: AppSpacing.md), HBAvatar(size: 72, name: '${p['display_name'] ?? ''}', imageUrl: p['avatar_url']?.toString()), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('${p['display_name'] ?? ''}', style: context.textStyles.headlineSmall?.bold), Text('@${p['username'] ?? ''}'), Text(['${p['country_code'] ?? ''}', p['region_name'], p['locale'], p['currency_code']].where((v) => v != null && '$v'.isNotEmpty).join(' · '), style: context.textStyles.bodySmall)])), HBStatusChip(kind: status == 'active' ? HBStatusKind.approved : status == 'banned' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'admin.users.status.$status'.tr())]), if (access?.canWrite('users') == true) ...[const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [ProtectedAction(label: 'admin.users.actions.suspend'.tr(), protected: protected, onPressed: () => onAction('suspend')), if (status == 'suspended' || status == 'banned') ProtectedAction(label: 'admin.users.actions.reactivate'.tr(), protected: protected || status == 'banned' && !elevated, onPressed: () => onAction('reactivate')), ProtectedAction(label: 'admin.users.actions.ban'.tr(), protected: protected || !elevated, destructive: true, onPressed: () => onAction('ban')), ProtectedAction(label: 'admin.users.actions.strike'.tr(), protected: protected, onPressed: () => onAction('strike')), HBButton.soft(label: 'admin.users.actions.export'.tr(), icon: Icons.archive_outlined, onPressed: () => onAction('export')), ProtectedAction(label: 'admin.users.actions.delete'.tr(), protected: protected || !elevated, destructive: true, onPressed: () => onAction('delete'))])]]));
  }
}

class ProtectedAction extends StatelessWidget {
  final String label;
  final bool protected;
  final bool destructive;
  final VoidCallback onPressed;
  const ProtectedAction({super.key, required this.label, required this.protected, this.destructive = false, required this.onPressed});
  @override Widget build(BuildContext context) => Tooltip(message: protected ? 'admin.users.protected'.tr() : '', child: HBButton.soft(label: label, icon: destructive ? Icons.warning_amber : null, onPressed: protected ? null : onPressed));
}

class AdminUserDetailTab extends ConsumerStatefulWidget {
  final AdminUserP41Detail detail;
  final int tab;
  final bool canWrite;
  final VoidCallback onRefresh;
  final ValueChanged<String> onDownload;
  const AdminUserDetailTab({super.key, required this.detail, required this.tab, required this.canWrite, required this.onRefresh, required this.onDownload});
  @override ConsumerState<AdminUserDetailTab> createState() => _AdminUserDetailTabState();
}

class _AdminUserDetailTabState extends ConsumerState<AdminUserDetailTab> {
  final noteController = TextEditingController();
  @override void dispose() { noteController.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final detail = widget.detail;
    if (widget.tab == 0) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final entry in detail.counts.entries) SizedBox(width: 180, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.users.counts.${entry.key}'.tr(), style: context.textStyles.bodySmall), Text('${entry.value}', style: context.textStyles.headlineSmall?.bold)]))), if (detail.pendingVerification != null) SizedBox(width: 260, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.users.verification'.tr(), style: context.textStyles.titleMedium?.bold), HBButton.ghost(label: 'admin.approvals.users.open_request'.tr(), onPressed: () => context.go('${AppRoutes.adminApprovals}?id=${detail.pendingVerification!['id']}'))])))]), const SizedBox(height: AppSpacing.md), AdminUserAccessCard(userId: '${detail.profile['id']}')]);
    if (widget.tab == 1) return _mapsTable(detail.strikes, ['reason','created_at','expires_at','status'], action: widget.canWrite ? (row) => HBButton.ghost(label: 'admin.users.revoke'.tr(), onPressed: () => _revoke('${row['id']}')) : null);
    if (widget.tab == 2) return _mapsTable(detail.recentReports, ['reason','status','created_at'], action: (row) => HBButton.ghost(label: 'common.open'.tr(), onPressed: () => context.go('${AppRoutes.adminReports}?id=${row['id']}')));
    if (widget.tab == 3) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [if (widget.canWrite) Row(children: [Expanded(child: HBInput(controller: noteController, hint: 'admin.users.add_note'.tr(), maxLines: 3, maxLength: 2000)), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'common.add'.tr(), onPressed: _addNote)]), const SizedBox(height: AppSpacing.md), _mapsTable(detail.notes, ['note','author_name','created_at'], action: widget.canWrite ? (row) => HBButton.icon(icon: Icons.delete_outline, onPressed: () => _deleteNote('${row['id']}')) : null)]);
    if (widget.tab == 4) return _mapsTable(detail.history, ['action','admin_name','created_at','details']);
    return _mapsTable([for (final e in detail.exports) {'id': e.id, 'status': e.status, 'requested_at': e.requestedAt.toIso8601String(), 'file_size': e.fileSize, 'expires_at': e.expiresAt?.toIso8601String()}], ['status','requested_at','file_size','expires_at'], action: (row) => row['status'] == 'ready' ? HBButton.ghost(label: 'admin.users.download'.tr(), onPressed: () => widget.onDownload('${row['id']}')) : const SizedBox.shrink());
  }

  Widget _mapsTable(List<Map<String, dynamic>> rows, List<String> fields, {Widget Function(Map<String, dynamic>)? action}) => HBCard(child: rows.isEmpty ? HBEmptyState(icon: Icons.inbox_outlined, title: 'admin.users.tab_empty'.tr(), message: 'admin.users.tab_empty_help'.tr()) : AdminDataTable(headers: [...fields.map((f) => 'admin.users.fields.$f'.tr()), if (action != null) ''], rows: [for (final row in rows) [...fields.map((field) => Text(_format(row[field]))), if (action != null) action(row)]], emptyMessage: 'admin.users.tab_empty'.tr()));
  String _format(Object? value) { if (value == null) return 'common.unavailable'.tr(); final date = DateTime.tryParse('$value'); return date == null ? '$value' : DateFormat.yMd(context.locale.toString()).add_Hm().format(date.toLocal()); }
  Future<void> _addNote() async { if (noteController.text.trim().isEmpty) return; await ref.read(adminP41RepositoryProvider).addNote('${widget.detail.profile['id']}', noteController.text); noteController.clear(); widget.onRefresh(); }
  Future<void> _deleteNote(String id) async { await ref.read(adminP41RepositoryProvider).deleteNote(id); widget.onRefresh(); }
  Future<void> _revoke(String id) async { final controller = TextEditingController(); final note = await showDialog<String>(context: context, builder: (context) => AlertDialog(title: Text('admin.users.revoke'.tr()), content: HBInput(controller: controller, hint: 'admin.users.reason'.tr()), actions: [HBButton.primary(label: 'common.confirm'.tr(), onPressed: () => context.pop(controller.text.trim()))])); if (note?.isNotEmpty == true) { await ref.read(adminP41RepositoryProvider).revokeStrike(id, note!); widget.onRefresh(); } }
}

class AdminUserAccessCard extends ConsumerWidget {
  final String userId;
  const AdminUserAccessCard({super.key, required this.userId});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(adminUserIdentitiesProvider(userId)).when(
    loading: () => const HBCard(child: LinearProgressIndicator()),
    error: (_, __) => HBCard(child: Text('admin.auth.user_error'.tr())),
    data: (value) {
      final identities = [for (final item in value['identities'] as List? ?? const []) Map<String, dynamic>.from(item as Map)];
      return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.auth.user_card'.tr(), style: context.textStyles.titleMedium?.bold), const SizedBox(height: AppSpacing.sm), Text('admin.auth.user_email'.tr(namedArgs: {'email': value['email']?.toString() ?? 'common.unavailable'.tr()})), Text('admin.auth.user_confirmed'.tr(namedArgs: {'value': value['email_confirmed_at'] == null ? 'admin.p05c.no'.tr() : 'admin.p05c.yes'.tr()})), Text('admin.auth.user_password'.tr(namedArgs: {'value': value['has_password'] == true ? 'admin.p05c.yes'.tr() : 'admin.p05c.no'.tr()})), Text('admin.auth.user_last_sign_in'.tr(namedArgs: {'time': value['last_sign_in_at'] == null ? 'common.unavailable'.tr() : relativeTime(context, DateTime.parse(value['last_sign_in_at'].toString()))})), const Divider(), for (final identity in identities) Padding(padding: const EdgeInsets.symmetric(vertical: 4), child: Text('${'auth.social.provider.${identity['provider']}'.tr()} · ${identity['email'] ?? 'common.unavailable'.tr()} · ${identity['last_sign_in_at'] == null ? 'common.unavailable'.tr() : relativeTime(context, DateTime.parse(identity['last_sign_in_at'].toString()))}'))]));
    },
  );
}

class AdminActionInput {
  final String reason;
  final String? note;
  final int? days;
  final String? strikeReason;
  const AdminActionInput({required this.reason, this.note, this.days, this.strikeReason});
}

class AdminActionDialog extends StatefulWidget {
  final String kind;
  final String username;
  const AdminActionDialog({super.key, required this.kind, required this.username});
  @override State<AdminActionDialog> createState() => _AdminActionDialogState();
}

class _AdminActionDialogState extends State<AdminActionDialog> {
  final reason = TextEditingController();
  final note = TextEditingController();
  final confirmation = TextEditingController();
  int? days = 3;
  String strikeReason = 'spam';
  @override void dispose() { reason.dispose(); note.dispose(); confirmation.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) {
    final dangerous = widget.kind == 'ban' || widget.kind == 'delete';
    final expected = widget.kind == 'ban' ? 'BAN' : widget.username;
    return AlertDialog(title: Text('admin.users.dialog.${widget.kind}'.tr(), style: dangerous ? const TextStyle(color: LightModeColors.lightError) : null), content: SizedBox(width: 520, child: Column(mainAxisSize: MainAxisSize.min, children: [if (widget.kind == 'suspend') Wrap(spacing: AppSpacing.xs, children: [for (final value in [1,3,7,30,null]) HBChip(label: value == null ? 'admin.users.indefinite'.tr() : 'admin.users.days'.tr(namedArgs: {'days': '$value'}), selected: days == value, onTap: () => setState(() => days = value))]), if (widget.kind == 'strike') AdminCompactDropdown(label: 'safety.reasons.$strikeReason'.tr(), items: [for (final value in ['spam','harassment','hate','violence','animal_abuse','illegal','sensitive','scam','other']) 'safety.reasons.$value'.tr()], onSelected: (i) => setState(() => strikeReason = ['spam','harassment','hate','violence','animal_abuse','illegal','sensitive','scam','other'][i])), const SizedBox(height: AppSpacing.sm), HBInput(controller: reason, hint: 'admin.users.reason'.tr(), maxLength: widget.kind == 'strike' ? 1000 : 300, maxLines: 3), if (widget.kind != 'delete') ...[const SizedBox(height: AppSpacing.sm), HBInput(controller: note, hint: 'admin.users.note_optional'.tr(), maxLines: 2)], if (dangerous) ...[const SizedBox(height: AppSpacing.sm), if (widget.kind == 'delete') Text('admin.users.delete_effects'.tr()), HBInput(controller: confirmation, hint: 'admin.users.confirm_text'.tr(namedArgs: {'value': expected}))]])), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => context.pop()), HBButton.primary(label: 'common.confirm'.tr(), onPressed: () { if (reason.text.trim().isEmpty || dangerous && confirmation.text.trim() != expected) return; context.pop(AdminActionInput(reason: reason.text.trim(), note: note.text.trim(), days: days, strikeReason: strikeReason)); })]);
  }
}

String _roleKey(String role) => switch (role) { 'ads_reviewer' => 'adsReviewer', 'hunting_data_editor' => 'huntingDataEditor', _ => role };