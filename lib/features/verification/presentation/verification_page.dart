import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/verification/domain/verification_request.dart';
import 'package:hb_social/features/verification/presentation/verification_wizard.dart';
import 'package:hb_social/features/verification/providers/verification_providers.dart';

class VerificationPage extends ConsumerStatefulWidget {
  const VerificationPage({super.key});
  @override
  ConsumerState<VerificationPage> createState() => _VerificationPageState();
}

class _VerificationPageState extends ConsumerState<VerificationPage> {
  @override
  void initState() { super.initState(); Future.microtask(() => ref.invalidate(myVerificationProvider)); }

  Future<void> _openWizard() async {
    final sent = await showModalBottomSheet<bool>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => const VerificationWizard());
    if (sent == true) ref.invalidate(myVerificationProvider);
  }

  Future<void> _cancel(VerificationRequest request) async {
    final confirmed = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text('verification.cancel_title'.tr()), content: Text('verification.cancel_message'.tr()), actions: [HBButton.ghost(label: 'common.back'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'verification.withdraw'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
    if (!confirmed || !mounted) return;
    try { await ref.read(verificationRepositoryProvider).cancel(request.id); ref.invalidate(myVerificationProvider); } on AppException catch (error) { if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override
  Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
    Text('verification.title'.tr(), style: context.textStyles.headlineSmall),
    const SizedBox(height: AppSpacing.xs),
    Text('verification.subtitle'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightOnSurfaceVariant)),
    const SizedBox(height: AppSpacing.lg),
    ref.watch(myVerificationProvider).when(loading: () => const HBListSkeleton(count: 3), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.shield_outlined, title: 'verification.errors.load_title'.tr(), message: 'verification.errors.load'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myVerificationProvider)))), data: (status) => VerificationStatusContent(status: status, onRequest: _openWizard, onCancel: _cancel)),
  ]))]));
}

class VerificationStatusContent extends StatelessWidget {
  final VerificationStatus status;
  final VoidCallback onRequest;
  final ValueChanged<VerificationRequest> onCancel;
  const VerificationStatusContent({super.key, required this.status, required this.onRequest, required this.onCancel});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
    HBCard(child: status.level == null ? _UnverifiedHeader(onRequest: onRequest, disabled: status.pending != null) : _VerifiedHeader(status: status, onRequest: onRequest)),
    if (status.pending != null) ...[const SizedBox(height: AppSpacing.md), PendingVerificationCard(request: status.pending!, onCancel: () => onCancel(status.pending!))],
    const SizedBox(height: AppSpacing.lg),
    Text('verification.history'.tr(), style: context.textStyles.titleLarge),
    const SizedBox(height: AppSpacing.sm),
    if (status.history.isEmpty) HBCard(child: HBEmptyState(icon: Icons.history_rounded, title: 'verification.history_empty'.tr(), message: 'verification.history_empty_message'.tr())) else Column(children: [for (final request in status.history) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: VerificationHistoryTile(request: request))]),
    const SizedBox(height: AppSpacing.sm),
    Text('verification.retention_note'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
  ]);
}

class _UnverifiedHeader extends StatelessWidget {
  final VoidCallback onRequest;
  final bool disabled;
  const _UnverifiedHeader({required this.onRequest, required this.disabled});
  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.shield_outlined, size: 30, color: LightModeColors.lightTextTertiary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('verification.not_verified'.tr(), style: context.textStyles.titleLarge))]), const SizedBox(height: AppSpacing.sm), Text('verification.not_verified_help'.tr()), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'verification.request'.tr(), onPressed: disabled ? null : onRequest)]);
}

class _VerifiedHeader extends StatelessWidget {
  final VerificationStatus status;
  final VoidCallback onRequest;
  const _VerifiedHeader({required this.status, required this.onRequest});
  @override
  Widget build(BuildContext context) {
    final days = status.daysLeft;
    final kind = days != null && days <= 15 ? HBStatusKind.rejected : days != null && days <= 60 ? HBStatusKind.pending : HBStatusKind.approved;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [HBBadge.verification(level: status.level!.code, verifiedAt: status.verifiedAt), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(status.level!.translationKey.tr(), style: context.textStyles.titleLarge))]), if (status.verifiedAt != null) ...[const SizedBox(height: AppSpacing.sm), Text('verification.verified_from'.tr(namedArgs: {'date': _format(context, status.verifiedAt!)}))], if (status.expiresAt != null) ...[const SizedBox(height: AppSpacing.xs), HBStatusChip(kind: kind, label: 'verification.expires'.tr(namedArgs: {'date': _format(context, status.expiresAt!), 'days': '${days ?? 0}'}))], const SizedBox(height: AppSpacing.md), if (status.renewable) HBButton.primary(label: 'verification.renew'.tr(), onPressed: onRequest) else Text('verification.badge_valid'.tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]);
  }
}

class PendingVerificationCard extends StatelessWidget {
  final VerificationRequest request;
  final VoidCallback onCancel;
  const PendingVerificationCard({super.key, required this.request, required this.onCancel});
  @override
  Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text('verification.pending_title'.tr(), style: context.textStyles.titleMedium)), HBStatusChip(kind: HBStatusKind.pending, label: 'verification.status.pending'.tr())]), const SizedBox(height: AppSpacing.sm), Text('verification.pending_summary'.tr(namedArgs: {'date': _format(context, request.createdAt), 'count': '${request.documents.length}'})), const SizedBox(height: AppSpacing.md), HBButton.soft(label: 'verification.withdraw'.tr(), onPressed: onCancel)]));
}

class VerificationHistoryTile extends StatelessWidget {
  final VerificationRequest request;
  const VerificationHistoryTile({super.key, required this.request});
  @override
  Widget build(BuildContext context) => HBTile(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(request.badgeType.translationKey.tr(), style: context.textStyles.titleSmall), Text(_format(context, request.createdAt), style: context.textStyles.bodySmall), if (request.status == VerificationRequestStatus.rejected && request.rejectionReason?.isNotEmpty == true) Text('verification.rejection_reason'.tr(namedArgs: {'reason': request.rejectionReason!}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError)), if (request.documentsPurgedAt != null) Text('verification.documents_purged'.tr(namedArgs: {'date': _format(context, request.documentsPurgedAt!)}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), const SizedBox(width: AppSpacing.sm), HBStatusChip(kind: _kind(request.status), label: 'verification.status.${request.status.code}'.tr())]));
}

HBStatusKind _kind(VerificationRequestStatus status) => switch (status) {VerificationRequestStatus.approved => HBStatusKind.approved, VerificationRequestStatus.rejected => HBStatusKind.rejected, VerificationRequestStatus.pending => HBStatusKind.pending, _ => HBStatusKind.neutral};
String _format(BuildContext context, DateTime value) => DateFormat.yMMMd(context.locale.languageCode).format(value.toLocal());