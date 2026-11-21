import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/features/admin/domain/admin_p42_models.dart';
import 'package:hb_social/features/admin/providers/admin_access_provider.dart';
import 'package:hb_social/features/admin/providers/admin_p42_providers.dart';

class AdminListingsPage extends ConsumerStatefulWidget {
  final String? initialId;
  const AdminListingsPage({super.key, this.initialId});
  @override ConsumerState<AdminListingsPage> createState() => _AdminListingsPageState();
}

class _AdminListingsPageState extends ConsumerState<AdminListingsPage> {
  int tab = 0;
  String query = '';
  String? categoryId;
  String? status;
  int offset = 0;
  Timer? debounce;
  late Future<List<AdminListingReviewItem>> future = load();
  String get review => const ['pending', 'rejected', 'all'][tab];
  Future<List<AdminListingReviewItem>> load() => ref.read(adminP42RepositoryProvider).listings(review: review, status: status, categoryId: categoryId, query: query, offset: offset);
  void reload() => setState(() { offset = 0; future = load(); });
  @override void dispose() { debounce?.cancel(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final stats = ref.watch(adminListingsStatsP42Provider);
    final writable = ref.watch(adminAccessProvider).value?.canWrite('listings') == true;
    return CustomScrollView(slivers: [SliverToBoxAdapter(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('admin.listings.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.xs), Text('admin.listings.subtitle'.tr()), const SizedBox(height: AppSpacing.md),
      stats.when(loading: () => const LinearProgressIndicator(), error: (_, __) => const SizedBox.shrink(), data: (value) => AdminListingsKpis(stats: value)),
      const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: ['admin.listings.tabs.pending'.tr(), 'admin.listings.tabs.rejected'.tr(), 'admin.listings.tabs.all'.tr()], selectedIndex: tab, onChanged: (value) => setState(() { tab = value; offset = 0; future = load(); })),
      const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [HBInput(hint: 'admin.listings.search'.tr(), prefixIcon: const Icon(Icons.search), onChanged: (value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 350), () { query = value; reload(); }); }), const SizedBox(height: AppSpacing.sm), stats.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (value) => Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBChip(label: 'admin.listings.all_categories'.tr(), selected: categoryId == null, onTap: () { categoryId = null; reload(); }), for (final category in value.categories) HBChip(label: '${(category['name_key']?.toString() ?? '').tr()} (${p42Int(category['pending'])})', selected: categoryId == category['id']?.toString(), onTap: () { categoryId = category['id']?.toString(); reload(); })]))])),
      const SizedBox(height: AppSpacing.md), FutureBuilder<List<AdminListingReviewItem>>(future: future, builder: (context, snapshot) { if (snapshot.connectionState == ConnectionState.waiting) return const LinearProgressIndicator(); if (snapshot.hasError) return HBEmptyState(icon: Icons.error_outline, title: 'admin.listings.error'.tr(), message: 'errors.network'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: reload)); final items = snapshot.data ?? const []; if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.fact_check_outlined, title: 'admin.listings.empty'.tr(), message: 'admin.listings.empty_message'.tr())); return Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: AdminListingReviewCard(item: item, writable: writable, onChanged: reload))]); }),
      if (writable) ...[const SizedBox(height: AppSpacing.md), stats.when(loading: () => const SizedBox.shrink(), error: (_, __) => const SizedBox.shrink(), data: (value) => AdminCategoryReviewCard(stats: value, onChanged: () { ref.invalidate(adminListingsStatsP42Provider); reload(); }))],
      const SizedBox(height: AppSpacing.xl),
    ]))]);
  }
}

class AdminListingsKpis extends StatelessWidget {
  final AdminListingsStats stats;
  const AdminListingsKpis({super.key, required this.stats});
  @override Widget build(BuildContext context) => Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [for (final key in ['pending','approved_7d','rejected_7d','active','mediated_active']) SizedBox(width: 190, child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('admin.listings.kpi.$key'.tr()), Text('${stats.value(key)}', style: context.textStyles.headlineSmall), if (key == 'pending') Text('admin.listings.oldest'.tr(namedArgs: {'hours': '${stats.value('pending_oldest_hours')}'}), style: context.textStyles.bodySmall)])))]);
}

class AdminListingReviewCard extends ConsumerWidget {
  final AdminListingReviewItem item;
  final bool writable;
  final VoidCallback onChanged;
  const AdminListingReviewCard({super.key, required this.item, required this.writable, required this.onChanged});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final data = item.data;
    final media = item.media;
    final sellerName = data['seller_name']?.toString() ?? data['seller_username']?.toString() ?? '';
    return AnimatedSize(duration: const Duration(milliseconds: 180), child: HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (media.isNotEmpty) SizedBox(height: 180, child: Row(children: [Expanded(flex: 3, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: Image.network(media.first['url']?.toString() ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.image_not_supported_outlined))))), if (media.length > 1) ...[const SizedBox(width: AppSpacing.xs), Expanded(child: Column(children: [for (final image in media.skip(1).take(2)) Expanded(child: Padding(padding: const EdgeInsets.only(bottom: 4), child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.xs), child: Image.network(image['url']?.toString() ?? '', width: double.infinity, fit: BoxFit.cover))))]))]])),
      const SizedBox(height: AppSpacing.md), Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.title, style: context.textStyles.titleLarge), Text(MoneyFormatter.format(amountMinor: item.priceMinor, currencyCode: item.currencyCode, locale: context.locale), style: context.textStyles.titleMedium), Wrap(spacing: AppSpacing.xs, children: [HBChip(label: (data['category_slug']?.toString() ?? '').replaceAll('_', ' ')), if (data['is_mediated'] == true) HBChip(label: 'admin.listings.mediated'.tr(), selected: true)])])), HBStatusChip(kind: item.reviewStatus == 'approved' ? HBStatusKind.approved : item.reviewStatus == 'rejected' ? HBStatusKind.rejected : HBStatusKind.pending, label: 'admin.listings.review.${item.reviewStatus}'.tr())]),
      if (item.attributes.isNotEmpty) ...[const Divider(), Wrap(spacing: AppSpacing.lg, runSpacing: AppSpacing.xs, children: [for (final entry in item.attributes.entries) if (entry.key != 'serial_number') SizedBox(width: 180, child: Text('${'p42.marketplace_review.attribute.${entry.key}'.tr()}: ${entry.value}'))])],
      const Divider(), Row(children: [HBAvatar(size: 40, name: sellerName, imageUrl: data['seller_avatar_url']?.toString()), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(sellerName), Text('@${data['seller_username'] ?? ''}'), Wrap(spacing: AppSpacing.sm, children: [if (p42Int(data['seller_active_strikes']) > 0) Text('admin.listings.strikes'.tr(namedArgs: {'count': '${p42Int(data['seller_active_strikes'])}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightError)), Text('admin.listings.active_listings'.tr(namedArgs: {'count': '${p42Int(data['seller_active_listings'])}'}))])])), if (data['page_name'] != null) Text(data['page_name'].toString())]),
      const SizedBox(height: AppSpacing.sm), Text('${data['municipality'] ?? data['region_name'] ?? ''} · ${item.requestedAt == null ? '' : 'admin.listings.waiting'.tr(namedArgs: {'time': relativeTime(context, item.requestedAt!)})}'),
      if (writable && item.reviewStatus == 'pending') ...[const SizedBox(height: AppSpacing.md), Row(mainAxisAlignment: MainAxisAlignment.end, children: [HBButton.secondary(label: 'admin.listings.reject'.tr(), onPressed: () => _review(context, ref, false)), const SizedBox(width: AppSpacing.sm), HBButton.primary(label: 'admin.listings.approve'.tr(), onPressed: () => _review(context, ref, true))])],
      if (writable && item.status == 'active') Align(alignment: Alignment.centerRight, child: HBButton.secondary(label: 'admin.listings.remove'.tr(), onPressed: () => _remove(context, ref))),
    ])));
  }
  Future<void> _review(BuildContext context, WidgetRef ref, bool approve) async { String? note; if (!approve) { final controller = TextEditingController(); note = await showDialog<String>(context: context, builder: (dialog) => AlertDialog(title: Text('admin.listings.reject_title'.tr()), content: Column(mainAxisSize: MainAxisSize.min, children: [Text('admin.listings.reject_help'.tr()), HBInput(controller: controller, maxLines: 4, maxLength: 500)]), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop()), HBButton.primary(label: 'admin.listings.reject'.tr(), onPressed: () => controller.text.trim().isEmpty ? null : dialog.pop(controller.text.trim()))])); controller.dispose(); if (note == null) return; } try { await ref.read(adminP42RepositoryProvider).reviewListing(item.id, approve ? 'approve' : 'reject', note); onChanged(); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text((approve ? 'admin.listings.approved' : 'admin.listings.rejected').tr()))); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  Future<void> _remove(BuildContext context, WidgetRef ref) async { final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(title: Text('admin.listings.remove'.tr()), content: Text('admin.listings.remove_confirm'.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialog.pop(false)), HBButton.primary(label: 'common.confirm'.tr(), onPressed: () => dialog.pop(true))])) ?? false; if (!confirmed) return; await ref.read(adminP42RepositoryProvider).removeListing(item.id); onChanged(); }
}

class AdminCategoryReviewCard extends ConsumerWidget {
  final AdminListingsStats stats;
  final VoidCallback onChanged;
  const AdminCategoryReviewCard({super.key, required this.stats, required this.onChanged});
  @override Widget build(BuildContext context, WidgetRef ref) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [Text('admin.listings.categories.title'.tr(), style: context.textStyles.titleMedium), Text('admin.listings.categories.help'.tr()), const SizedBox(height: AppSpacing.sm), for (final category in stats.categories) SwitchListTile(contentPadding: EdgeInsets.zero, title: Text((category['name_key']?.toString() ?? '').tr()), subtitle: Text('admin.listings.categories.pending'.tr(namedArgs: {'count': '${p42Int(category['pending'])}'})), value: category['requires_review'] == true, onChanged: (value) async { await ref.read(adminP42RepositoryProvider).setCategoryReview(category['id'].toString(), value); onChanged(); })]));
}