import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';

class AdsPreferencesPage extends ConsumerWidget {
  const AdsPreferencesPage({super.key});
  Future<void> setPersonalized(BuildContext context, WidgetRef ref, bool value) async { try { await (await ref.read(adsDeliveryRepositoryProvider.future)).setPersonalized(value); ref.invalidate(adsPreferencesProvider); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  Future<void> restore(BuildContext context, WidgetRef ref, HiddenAd item) async { try { await (await ref.read(adsDeliveryRepositoryProvider.future)).unhideAd(item.id); ref.invalidate(hiddenAdsProvider); ref.invalidate(adsPreferencesProvider); } on AppException catch (error) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); } }
  @override Widget build(BuildContext context, WidgetRef ref) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
    Row(children: [HBButton.icon(icon: Icons.arrow_back_rounded, onPressed: () => context.pop()), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('ads.delivery.preferences'.tr(), style: context.textStyles.headlineSmall))]), const SizedBox(height: AppSpacing.lg),
    HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads.delivery.privacy_intro'.tr()), const SizedBox(height: AppSpacing.md), ref.watch(adsPreferencesProvider).when(loading: () => const HBListSkeleton(count: 1), error: (_, __) => Text('ads.delivery.errors.generic'.tr()), data: (preferences) => SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('ads.delivery.personalized'.tr(), style: context.textStyles.bodyMedium?.bold), subtitle: Text('ads.delivery.personalized_help'.tr()), value: preferences.personalized, activeColor: LightModeColors.lightPrimary, onChanged: (value) => setPersonalized(context, ref, value))) ])),
    const SizedBox(height: AppSpacing.md), Text('ads.delivery.hidden_section'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm),
    ref.watch(hiddenAdsProvider).when(loading: () => const HBCard(child: HBListSkeleton()), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'ads.delivery.errors.generic'.tr(), message: 'ads.delivery.errors.retry'.tr())), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.visibility_outlined, title: 'ads.delivery.hidden_empty'.tr(), message: 'ads.delivery.hidden_empty_help'.tr())) : HBCard(child: Column(children: [for (var index = 0; index < items.length; index++) ...[AdsHiddenRow(item: items[index], onRestore: () => restore(context, ref, items[index])), if (index < items.length - 1) const Divider(color: LightModeColors.lightDivider)]]))),
    const SizedBox(height: AppSpacing.md), HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('ads.delivery.promote'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), HBButton.primary(label: 'ads.delivery.open_center'.tr(), onPressed: () => context.push(AppRoutes.ads)), const SizedBox(height: AppSpacing.md), Text('ads.delivery.policy_note'.tr()), HBButton.ghost(label: 'settings.privacy'.tr(), onPressed: () => context.push(AppRoutes.settings))])),
  ]))]));
}

class AdsHiddenRow extends StatelessWidget {
  final HiddenAd item;
  final VoidCallback onRestore;
  const AdsHiddenRow({super.key, required this.item, required this.onRestore});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm), child: Row(children: [Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.accountName, style: context.textStyles.bodyMedium?.bold), if (item.headline.isNotEmpty) Text(item.headline, maxLines: 1, overflow: TextOverflow.ellipsis), Text('${item.reason == null ? 'ads.delivery.hidden_advertiser'.tr() : 'ads.delivery.hide_reason.${item.reason}'.tr()} · ${relativeTime(context, item.createdAt)}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])), HBButton.soft(label: 'ads.delivery.restore'.tr(), onPressed: onRestore, size: HBButtonSize.sm)]));
}