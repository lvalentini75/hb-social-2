import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/data/admin_list_repository.dart';
import 'package:hb_social/features/admin/domain/admin_access.dart';
import 'package:hb_social/features/admin/domain/admin_list_models.dart';
import 'package:hb_social/features/admin/presentation/admin_users_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_detail_panel.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_list_page.dart';
import 'package:hb_social/features/admin/presentation/widgets/admin_read_only_widgets.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_console_providers.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminApprovalsPage extends ConsumerStatefulWidget {
  final String initialStatus;
  final String? initialId;
  const AdminApprovalsPage({super.key, this.initialStatus = 'pending', this.initialId});
  @override ConsumerState<AdminApprovalsPage> createState() => _AdminApprovalsPageState();
}

class _AdminApprovalsPageState extends ConsumerState<AdminApprovalsPage> {
  late String? status = widget.initialStatus == 'all' ? null : widget.initialStatus;
  String? badgeType;
  String search = '';
  AdminVerificationRequest? selected;
  bool maintenanceRunning = false;

  @override Widget build(BuildContext context) {
    final filters = AdminApprovalFilters(id: widget.initialId, status: status, badgeType: badgeType);
    final requests = ref.watch(adminApprovalsProvider(filters));
    final stats = ref.watch(adminVerificationStatsProvider);
    final access = ref.watch(adminAccessProvider).value;
    final state = requests.value;
    final loaded = state?.items ?? const <AdminVerificationRequest>[];
    final normalized = search.trim().toLowerCase();
    final items = normalized.length < 2 ? loaded : loaded.where((item) => item.user.username.toLowerCase().contains(normalized) || item.user.displayName.toLowerCase().contains(normalized)).toList();
    final count = requests.hasValue ? ref.read(adminApprovalsProvider(filters).notifier).count : null;
    final canMaintain = access?.roleName == 'superadmin' || access?.roleName == 'admin';
    return Stack(children: [
      AdminListPage(
        title: 'admin.approvals.title'.tr(),
        description: 'admin.approvals.results'.tr(namedArgs: {'count': count?.toString() ?? '—'}),
        actions: [if (canMaintain) HBButton.secondary(label: 'admin.approvals.maintenance.action'.tr(), icon: Icons.settings_suggest_outlined, isLoading: maintenanceRunning, onPressed: maintenanceRunning ? null : () => _runMaintenance(filters))],
        filters: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [SizedBox(width: 260, child: HBInput(hint: 'admin.approvals.search'.tr(), prefixIcon: const Icon(Icons.search, size: 18), onChanged: (value) => setState(() => search = value))), AdminCompactDropdown(label: status == null ? 'admin.approvals.status.all'.tr() : 'admin.approvals.status.$status'.tr(), items: [for (final value in const ['pending','approved','rejected','cancelled','expired','all']) 'admin.approvals.status.$value'.tr()], onSelected: (index) => setState(() => status = index == 5 ? null : const ['pending','approved','rejected','cancelled','expired'][index]))]),
          const SizedBox(height: AppSpacing.sm),
          stats.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (value) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBChip(label: 'admin.approvals.type.all'.tr(), selected: badgeType == null, onTap: () => setState(() => badgeType = null)), for (final type in const ['hunter','gun_shop','guide','association','page']) HBChip(label: 'admin.approvals.type_count'.tr(namedArgs: {'type': 'admin.approvals.type.$type'.tr(), 'count': '${value.byType[type] ?? 0}'}), selected: badgeType == type, onTap: () => setState(() => badgeType = type))])),
          const SizedBox(height: AppSpacing.sm),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.info_outline, size: 18, color: LightModeColors.lightOnSurfaceVariant), const SizedBox(width: AppSpacing.xs), Expanded(child: Text('admin.approvals.maintenance.note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)))]),
        ]),
        kpis: stats.value == null ? const [] : _kpis(stats.value!),
        headers: [for (final key in const ['user','type','page','submitted','documents','status','reviewer']) 'admin.approvals.columns.$key'.tr()],
        columnWidths: const [230,130,160,130,110,120,180],
        rows: [for (final request in items) _row(request)],
        rowCallbacks: [for (final request in items) () => setState(() => selected = request)],
        emptyMessage: 'admin.approvals.empty'.tr(),
        isLoading: requests.isLoading,
        onRetry: requests.hasError && state == null ? () => ref.invalidate(adminApprovalsProvider(filters)) : null,
        hasMore: state?.hasMore ?? false,
        isLoadingMore: state?.isLoadingMore ?? false,
        onLoadMore: () => ref.read(adminApprovalsProvider(filters).notifier).loadMore(),
      ),
      if (selected != null || (widget.initialId != null && items.isNotEmpty)) AdminDetailOverlay(onClose: () => setState(() => selected = null), panel: AdminApprovalDetailPanel(request: selected ?? items.first, access: access, onClose: () => setState(() => selected = null), onReviewed: () { setState(() => selected = null); ref.invalidate(adminApprovalsProvider(filters)); ref.invalidate(adminVerificationStatsProvider); })),
    ]);
  }

  List<AdminKpiValue> _kpis(AdminVerificationStats stats) {
    final oldestKind = stats.pendingOldestDays > 5 ? HBStatusKind.rejected : stats.pendingOldestDays > 2 ? HBStatusKind.pending : HBStatusKind.neutral;
    return [
      AdminKpiValue(label: 'admin.approvals.kpi.pending'.tr(), value: '${stats.pending}', detail: HBStatusChip(kind: oldestKind, label: 'admin.approvals.kpi.oldest'.tr(namedArgs: {'days': '${stats.pendingOldestDays}'}))),
      AdminKpiValue(label: 'admin.approvals.kpi.approved'.tr(), value: '${stats.approved30d}'),
      AdminKpiValue(label: 'admin.approvals.kpi.rejected'.tr(), value: '${stats.rejected30d}'),
      AdminKpiValue(label: 'admin.approvals.kpi.expiring'.tr(), value: '${stats.expiring30d}'),
      AdminKpiValue(label: 'admin.approvals.kpi.purge'.tr(), value: '${stats.docsAwaitingPurge}'),
    ];
  }

  List<Widget> _row(AdminVerificationRequest request) => [
    Row(children: [HBAvatar(size: 32, imageUrl: request.user.avatarUrl, name: request.user.displayName), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.user.displayName, overflow: TextOverflow.ellipsis), Text('@${request.user.username}${request.user.countryCode.isEmpty ? '' : ' · ${request.user.countryCode}'}', overflow: TextOverflow.ellipsis, style: context.textStyles.labelSmall)]))]),
    AdminVerificationChip(value: request.badgeType),
    Text(request.page?.name ?? 'common.unavailable'.tr(), overflow: TextOverflow.ellipsis),
    Text(relativeTime(context, request.createdAt)),
    Row(children: [Icon(request.documentsPurgedAt == null ? Icons.description_outlined : Icons.delete_sweep_outlined, size: 17), const SizedBox(width: 4), Text('${request.documents.length}')]),
    AdminStatusValueChip(scope: 'admin.approvals.status', value: request.status),
    request.reviewer == null ? const AdminDashText() : AdminPersonCell(person: request.reviewer!, avatarSize: 24, showUsername: false),
  ];

  Future<void> _runMaintenance(AdminApprovalFilters filters) async {
    setState(() => maintenanceRunning = true);
    try {
      final result = await ref.read(adminListRepositoryProvider).runVerificationMaintenance();
      if (!mounted) return;
      _toast('admin.approvals.maintenance.success'.tr(namedArgs: {'expired': '${result.expired}', 'reminded': '${result.reminded}'}));
      ref.invalidate(adminVerificationStatsProvider);
      ref.invalidate(adminApprovalsProvider(filters));
    } catch (error) { if (mounted) _toast(_errorText(error)); }
    if (mounted) setState(() => maintenanceRunning = false);
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  String _errorText(Object error) => error is AppException ? error.messageKey.tr(namedArgs: error.namedArgs) : 'errors.generic'.tr();
}

class AdminApprovalDetailPanel extends ConsumerStatefulWidget {
  final AdminVerificationRequest request;
  final AdminAccess? access;
  final VoidCallback onClose;
  final VoidCallback onReviewed;
  const AdminApprovalDetailPanel({super.key, required this.request, required this.access, required this.onClose, required this.onReviewed});
  @override ConsumerState<AdminApprovalDetailPanel> createState() => _AdminApprovalDetailPanelState();
}

class _AdminApprovalDetailPanelState extends ConsumerState<AdminApprovalDetailPanel> {
  String? previewUrl;
  String? previewPath;
  bool openingDocument = false;

  AdminVerificationRequest get request => widget.request;
  bool get canReview => request.status == 'pending' && request.user.id != widget.access?.userId && const {'superadmin','admin','moderator'}.contains(widget.access?.roleName);

  @override void dispose() {
    if (previewUrl != null) NetworkImage(previewUrl!).evict();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final history = ref.watch(adminVerificationHistoryProvider((userId: request.user.id, currentId: request.id)));
    final date = DateFormat.yMd(context.locale.toString());
    return AdminDetailPanel(
      title: request.user.displayName,
      status: AdminStatusValueChip(scope: 'admin.approvals.status', value: request.status),
      onClose: widget.onClose,
      actions: canReview ? [HBButton.secondary(label: 'admin.approvals.reject'.tr(), icon: Icons.close_rounded, foregroundColor: LightModeColors.lightError, onPressed: _reject), HBButton.primary(label: 'admin.approvals.approve'.tr(), icon: Icons.check_rounded, onPressed: _approve)] : const [],
      body: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(onTap: () => context.go('/admin/users?id=${request.user.id}'), child: Row(children: [HBAvatar(size: 56, imageUrl: request.user.avatarUrl, name: request.user.displayName), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.user.displayName, style: context.textStyles.titleMedium?.bold), Text('@${request.user.username} · ${request.user.countryCode}'), Text('admin.approvals.open_user'.tr(), style: context.textStyles.labelSmall?.withColor(LightModeColors.lightPrimary))]))])),
        const SizedBox(height: AppSpacing.md),
        AdminDetailCard(title: 'admin.approvals.request'.tr(), child: Column(children: [AdminLabelValueRow(label: 'admin.approvals.fields.type'.tr(), value: 'admin.approvals.type.${request.badgeType}'.tr()), if (request.page != null) AdminLabelValueRow(label: 'admin.approvals.fields.page'.tr(), value: request.page!.name), AdminLabelValueRow(label: 'admin.approvals.fields.submitted'.tr(), value: date.format(request.createdAt.toLocal())), AdminLabelValueRow(label: 'admin.approvals.fields.expires'.tr(), value: request.expiresAt == null ? 'admin.approvals.no_expiry'.tr() : date.format(request.expiresAt!.toLocal()))])),
        AdminDetailCard(title: 'admin.approvals.declared'.tr(), child: request.declaredData.isEmpty ? Text('common.unavailable'.tr()) : Column(children: [for (final entry in request.declaredData.entries) AdminLabelValueRow(label: _declaredLabel(entry.key), value: entry.value?.toString() ?? 'common.unavailable'.tr())])),
        AdminDetailCard(title: 'admin.approvals.documents'.tr(), child: request.documentsPurgedAt != null ? Text('admin.approvals.documents_purged'.tr(namedArgs: {'date': date.format(request.documentsPurgedAt!.toLocal())})) : request.documents.isEmpty ? Text('admin.approvals.no_documents'.tr()) : Column(children: [for (final document in request.documents) VerificationDocumentRow(document: document, loading: openingDocument && previewPath == document.path, onOpen: () => _openDocument(document)), if (previewUrl != null) ...[const SizedBox(height: AppSpacing.sm), SignedVerificationImage(url: previewUrl!)]])),
        AdminDetailCard(title: 'admin.approvals.history'.tr(), child: history.when(loading: () => const LinearProgressIndicator(), error: (_, __) => Text('admin.approvals.history_error'.tr()), data: (items) => items.isEmpty ? Text('admin.approvals.history_empty'.tr()) : Column(children: [for (final item in items) AdminLabelValueRow(label: '${'admin.approvals.status.${item.status}'.tr()} · ${date.format(item.createdAt.toLocal())}', value: item.rejectionReason ?? 'common.unavailable'.tr())]))),
        AdminDetailCard(title: 'admin.approvals.maintenance.title'.tr(), child: Text('admin.approvals.maintenance.note'.tr())),
      ]),
    );
  }

  String _declaredLabel(String key) => const {'licence_number','issuer','expires_on','company_name','vat_id','tax_code','association'}.contains(key) ? 'admin.approvals.declared_fields.$key'.tr() : key;

  Future<void> _openDocument(AdminVerificationDocument document) async {
    setState(() { openingDocument = true; previewPath = document.path; });
    try {
      final url = await ref.read(adminListRepositoryProvider).createVerificationDocumentUrl(document.path);
      if (!mounted) return;
      if (_isImage(document)) {
        if (previewUrl != null) await NetworkImage(previewUrl!).evict();
        setState(() => previewUrl = url);
      }
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (error) { if (mounted) _toast(_errorText(error)); }
    if (mounted) setState(() => openingDocument = false);
  }

  bool _isImage(AdminVerificationDocument document) {
    final value = '${document.name} ${document.path}'.toLowerCase();
    return value.endsWith('.jpg') || value.endsWith('.jpeg') || value.endsWith('.png') || value.endsWith('.webp');
  }

  Future<void> _approve() async {
    DateTime? initial;
    if (request.badgeType == 'hunter' || request.badgeType == 'guide') initial = DateTime.tryParse(request.declaredData['expires_on']?.toString() ?? '');
    final expiry = await showModalBottomSheet<ApproveVerificationResult>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ApproveVerificationSheet(initialDate: initial, allowExpiry: request.badgeType != 'page'));
    if (expiry == null) return;
    await _review('approve', expiresAt: expiry.expiresAt);
  }

  Future<void> _reject() async {
    final reason = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const RejectVerificationSheet());
    if (reason != null) await _review('reject', reason: reason);
  }

  Future<void> _review(String decision, {String? reason, DateTime? expiresAt}) async {
    try {
      await ref.read(adminListRepositoryProvider).reviewVerification(id: request.id, decision: decision, reason: reason, expiresAt: expiresAt);
      if (!mounted) return;
      _toast('admin.approvals.${decision}_success'.tr());
      widget.onReviewed();
    } catch (error) { if (mounted) _toast(_errorText(error)); }
  }

  void _toast(String message) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  String _errorText(Object error) => error is AppException ? error.messageKey.tr(namedArgs: error.namedArgs) : 'errors.generic'.tr();
}

class VerificationDocumentRow extends StatelessWidget {
  final AdminVerificationDocument document;
  final bool loading;
  final VoidCallback onOpen;
  const VerificationDocumentRow({super.key, required this.document, required this.loading, required this.onOpen});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs), child: Row(children: [const Icon(Icons.description_outlined, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.approvals.document_kind.${document.kind}'.tr()), Text('${document.name} · ${_fileSize(document.size)}', style: context.textStyles.labelSmall)])), HBButton.ghost(label: 'admin.approvals.open'.tr(), icon: Icons.open_in_new, size: HBButtonSize.sm, isLoading: loading, onPressed: loading ? null : onOpen)]));
  String _fileSize(int bytes) => bytes >= 1024 * 1024 ? '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB' : '${(bytes / 1024).ceil()} KB';
}

class SignedVerificationImage extends StatefulWidget {
  final String url;
  const SignedVerificationImage({super.key, required this.url});
  @override State<SignedVerificationImage> createState() => _SignedVerificationImageState();
}

class _SignedVerificationImageState extends State<SignedVerificationImage> {
  @override void dispose() { NetworkImage(widget.url).evict(); super.dispose(); }
  @override Widget build(BuildContext context) => ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(widget.url, fit: BoxFit.contain, errorBuilder: (_, __, ___) => Padding(padding: const EdgeInsets.all(AppSpacing.md), child: Text('admin.approvals.preview_error'.tr()))));
}

class ApproveVerificationResult {
  final DateTime? expiresAt;
  const ApproveVerificationResult(this.expiresAt);
}

class ApproveVerificationSheet extends StatefulWidget {
  final DateTime? initialDate;
  final bool allowExpiry;
  const ApproveVerificationSheet({super.key, this.initialDate, required this.allowExpiry});
  @override State<ApproveVerificationSheet> createState() => _ApproveVerificationSheetState();
}

class _ApproveVerificationSheetState extends State<ApproveVerificationSheet> {
  DateTime? expiry;
  @override void initState() { super.initState(); expiry = widget.initialDate; }
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.approvals.approve_title'.tr(), style: context.textStyles.titleLarge?.bold), const SizedBox(height: AppSpacing.md), if (widget.allowExpiry) HBFormField(label: 'admin.approvals.expiry'.tr(), helper: 'admin.approvals.expiry_help'.tr(), child: Row(children: [Expanded(child: HBButton.secondary(label: expiry == null ? 'admin.approvals.no_expiry'.tr() : DateFormat.yMd(context.locale.toString()).format(expiry!), icon: Icons.calendar_today_outlined, onPressed: _pickDate)), if (expiry != null) HBButton.icon(icon: Icons.close, onPressed: () => setState(() => expiry = null), size: HBButtonSize.sm)])) else Text('admin.approvals.page_no_expiry'.tr()), const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'admin.approvals.confirm_approve'.tr(), onPressed: () => context.pop(ApproveVerificationResult(widget.allowExpiry ? expiry : null)))]));
  Future<void> _pickDate() async { final now = DateTime.now(); final picked = await showDatePicker(context: context, initialDate: expiry != null && expiry!.isAfter(now) ? expiry! : now.add(const Duration(days: 1)), firstDate: now, lastDate: DateTime(now.year + 20)); if (picked != null && mounted) setState(() => expiry = picked); }
}

class RejectVerificationSheet extends StatefulWidget {
  const RejectVerificationSheet({super.key});
  @override State<RejectVerificationSheet> createState() => _RejectVerificationSheetState();
}

class _RejectVerificationSheetState extends State<RejectVerificationSheet> {
  static const reasons = ['unreadable','expired','mismatch','invalid','other'];
  String selected = 'unreadable';
  final controller = TextEditingController();
  String? error;
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.approvals.reject_title'.tr(), style: context.textStyles.titleLarge?.bold), const SizedBox(height: AppSpacing.md), HBChoice<String>(options: reasons, value: selected, onChanged: (value) => setState(() => selected = value), labelBuilder: (value) => 'admin.approvals.quick_reason.$value'.tr()), if (selected == 'other') ...[const SizedBox(height: AppSpacing.md), HBInput(controller: controller, hint: 'admin.approvals.reason_hint'.tr(), errorText: error, maxLines: 3, maxLength: 500)], const SizedBox(height: AppSpacing.lg), HBButton.primary(label: 'admin.approvals.confirm_reject'.tr(), onPressed: _submit)]));
  void _submit() { final reason = selected == 'other' ? controller.text.trim() : 'admin.approvals.quick_reason.$selected'.tr(); if (reason.length < 3) { setState(() => error = 'admin.approvals.errors.reason_required'.tr()); return; } context.pop(reason); }
}