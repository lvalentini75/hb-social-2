import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/ads/domain/ad_reports.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdminAdsReviewPage extends ConsumerStatefulWidget {
  final String? accountFilter;
  final String? creativeFilter;
  const AdminAdsReviewPage({super.key, this.accountFilter, this.creativeFilter});
  @override ConsumerState<AdminAdsReviewPage> createState() => _AdminAdsReviewPageState();
}

class _AdminAdsReviewPageState extends ConsumerState<AdminAdsReviewPage> {
  int tab = 0;
  AdReviewItem? selected;
  bool onlyBoost = false;
  String get status => const ['pending', 'approved', 'rejected'][tab];
  @override
  Widget build(BuildContext context) {
    final queue = ref.watch(adReviewQueueProvider(status));
    return Column(children: [
      HBSegmentedTabs(labels: ['admin.ads.tabs.pending'.tr(), 'admin.ads.tabs.approved'.tr(), 'admin.ads.tabs.rejected'.tr()], selectedIndex: tab, onChanged: (value) => setState(() { tab = value; selected = null; })),
      const SizedBox(height: AppSpacing.sm), Row(children: [HBChip(label: 'boost.admin.only'.tr(), selected: onlyBoost, onTap: () => setState(() => onlyBoost = !onlyBoost)), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('boost.admin.help'.tr(), style: context.textStyles.bodySmall))]),
      const SizedBox(height: AppSpacing.md),
      Expanded(child: queue.when(
        loading: () => const HBListSkeleton(),
        error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'admin.ads.error_title'.tr(), message: 'admin.ads.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(adReviewQueueProvider(status))))),
        data: (items) {
          final visible = items.where((item) => (!onlyBoost || item.isBoost) && (widget.accountFilter == null || item.accountId == widget.accountFilter) && (widget.creativeFilter == null || item.creativeId == widget.creativeFilter)).toList();
          if (visible.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.fact_check_outlined, title: 'admin.ads.empty'.tr(), message: 'admin.ads.empty_message'.tr()));
          return Row(children: [
            Expanded(child: ListView.separated(itemCount: visible.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm), itemBuilder: (_, index) => AdminAdReviewRow(item: visible[index], selected: selected?.creativeId == visible[index].creativeId, onTap: () => setState(() => selected = visible[index])))),
            if (selected != null) ...[const SizedBox(width: AppSpacing.md), SizedBox(width: 430, child: AdminAdReviewDetail(item: selected!, readOnly: status != 'pending', onDone: () { ref.invalidate(adReviewQueueProvider(status)); setState(() => selected = null); }))],
          ]);
        },
      )),
    ]);
  }
}

class AdminAdReviewRow extends StatelessWidget {
  final AdReviewItem item;
  final bool selected;
  final VoidCallback onTap;
  const AdminAdReviewRow({super.key, required this.item, required this.selected, required this.onTap});
  @override Widget build(BuildContext context) { final old = DateTime.now().toUtc().difference(item.creative.createdAt).inHours >= 24; return HBCard(child: InkWell(onTap: onTap, child: Row(children: [Icon(Icons.image_outlined, color: old ? LightModeColors.lightWarning : LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.creative.headline, style: context.textStyles.titleSmall), Text('${item.accountName} · @${item.ownerUsername}'), Text('admin.ads.waiting'.tr(namedArgs: {'time': relativeTime(context, item.creative.createdAt)}), style: context.textStyles.bodySmall?.withColor(old ? LightModeColors.lightWarning : LightModeColors.lightOnSurfaceVariant)), Wrap(spacing: AppSpacing.xs, children: [for (final campaign in item.campaigns) HBChip(label: campaign['name']?.toString() ?? '')])])), HBStatusChip(kind: selected ? HBStatusKind.info : HBStatusKind.pending, label: item.creative.kind.labelKey.tr())]))); }
}

class AdminAdReviewDetail extends ConsumerWidget {
  final AdReviewItem item;
  final bool readOnly;
  final VoidCallback onDone;
  const AdminAdReviewDetail({super.key, required this.item, required this.readOnly, required this.onDone});
  Future<void> decide(BuildContext context, WidgetRef ref, String decision) async { String? note; if (decision == 'reject') { note = await showModalBottomSheet<String>(context: context, isScrollControlled: true, builder: (_) => const AdRejectionSheet()); if (note == null) return; } else { final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('admin.ads.approve_title'.tr()), content: Text('admin.ads.approve_message'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'admin.ads.approve'.tr(), onPressed: () => dialog.pop(true))])) ?? false; if (!confirmed) return; } try { await ref.read(adsRepositoryProvider).reviewCreative(item.creativeId, decision, note: note); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('admin.ads.${decision}_success'.tr()))); onDone(); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  @override Widget build(BuildContext context, WidgetRef ref) => HBCard(child: ListView(children: [Text('admin.ads.detail'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), AdPreviewCard(client: ref.watch(supabaseClientProvider), advertiserName: item.accountName, headline: item.creative.headline, body: item.creative.body, cta: item.creative.callToAction, media: item.creative.media), const SizedBox(height: AppSpacing.md), AdPreviewCard(client: ref.watch(supabaseClientProvider), advertiserName: item.accountName, headline: item.creative.headline, body: item.creative.body, cta: item.creative.callToAction, media: item.creative.media, variant: AdPreviewVariant.rightRail), const Divider(), Text('${item.creative.destinationType} · ${item.creative.destinationUrl ?? item.creative.destinationId ?? '—'}'), Text('${item.accountName} · @${item.ownerUsername}'), for (final campaign in item.campaigns) ListTile(contentPadding: EdgeInsets.zero, title: Text(campaign['name']?.toString() ?? ''), trailing: Text('ads.campaign_status.${campaign['status']}'.tr())), if (item.creative.rejectionReason?.isNotEmpty == true) Text(item.creative.rejectionReason!, style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightError)), if (!readOnly) ...[const SizedBox(height: AppSpacing.md), Row(children: [Expanded(child: HBButton.secondary(label: 'admin.ads.reject'.tr(), onPressed: () => decide(context, ref, 'reject'))), const SizedBox(width: AppSpacing.sm), Expanded(child: HBButton.primary(label: 'admin.ads.approve'.tr(), onPressed: () => decide(context, ref, 'approve')))])]]));
}

class AdRejectionSheet extends StatefulWidget {
  const AdRejectionSheet({super.key});
  @override State<AdRejectionSheet> createState() => _AdRejectionSheetState();
}

class _AdRejectionSheetState extends State<AdRejectionSheet> {
  final controller = TextEditingController();
  @override void dispose() { controller.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => SafeArea(child: Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.ads.reject_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (var index = 1; index <= 4; index++) GestureDetector(onTap: () => setState(() => controller.text = 'admin.ads.quick_reason.$index'.tr()), child: HBChip(label: 'admin.ads.quick_reason.$index'.tr()))]), const SizedBox(height: AppSpacing.md), HBInput(controller: controller, maxLines: 4, hint: 'admin.ads.reason_hint'.tr(), onChanged: (_) => setState(() {})), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'admin.ads.reject'.tr(), onPressed: controller.text.trim().length < 3 ? null : () => context.pop(controller.text.trim()))])));
}