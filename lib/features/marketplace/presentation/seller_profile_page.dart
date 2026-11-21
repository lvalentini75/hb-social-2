import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_tile.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/presentation/listing_detail_page.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_page.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';

class SellerProfilePage extends ConsumerStatefulWidget {
  final String userId;
  const SellerProfilePage({super.key, required this.userId});
  @override ConsumerState<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends ConsumerState<SellerProfilePage> {
  int tab = 0;
  @override Widget build(BuildContext context) => ref.watch(sellerProfileProvider(widget.userId)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBSkeleton(height: 520))),
    error: (_, __) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.seller_not_found'.tr(), message: 'marketplace.error_message'.tr()))),
    data: (seller) => PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [SellerProfileHeader(seller: seller), const SizedBox(height: AppSpacing.lg), HBSegmentedTabs(variant: HBSegmentedTabsVariant.underlined, labels: ['marketplace.tabs.listings'.tr(), 'marketplace.tabs.reviews'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)), const SizedBox(height: AppSpacing.md), if (tab == 0) SellerListings(userId: widget.userId) else SellerReviews(userId: widget.userId, seller: seller)]))])),
  );
}

class SellerProfileHeader extends StatelessWidget {
  final SellerSummary seller;
  const SellerProfileHeader({super.key, required this.seller});
  @override Widget build(BuildContext context) => HBCard(child: Column(children: [Row(crossAxisAlignment: CrossAxisAlignment.start, children: [HBAvatar(name: seller.displayName, imageUrl: seller.avatarUrl, size: 72), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(seller.displayName, style: context.textStyles.headlineSmall)), if (seller.verificationLevel != 'none') ...[const SizedBox(width: AppSpacing.xs), HBBadge.verification(level: seller.verificationLevel)]]), Text('${_rating(seller.ratingAverageHundredths)} ★ · ${'marketplace.reviews_count'.tr(namedArgs: {'n': '${seller.ratingCount}'})}', style: context.textStyles.titleMedium), if (seller.memberSince != null) Text('marketplace.member_since'.tr(namedArgs: {'date': DateFormat.yMMM(context.locale.toString()).format(seller.memberSince!.toLocal())})), if (seller.regionName != null) Text(seller.regionName!), Text('marketplace.seller_counts'.tr(namedArgs: {'active': '${seller.activeListings}', 'sold': '${seller.soldListings}'}))]))]), const SizedBox(height: AppSpacing.md), for (var score = 5; score >= 1; score--) Padding(padding: const EdgeInsets.symmetric(vertical: 3), child: Row(children: [SizedBox(width: 28, child: Text('$score ★')), const SizedBox(width: AppSpacing.sm), Expanded(child: LinearProgressIndicator(value: seller.ratingCount == 0 ? 0 : (seller.ratingBreakdown[score] ?? 0) / seller.ratingCount, minHeight: 8, borderRadius: BorderRadius.circular(AppRadius.pill), color: LightModeColors.lightWarning, backgroundColor: LightModeColors.lightBackgroundSoft)), const SizedBox(width: AppSpacing.sm), SizedBox(width: 24, child: Text('${seller.ratingBreakdown[score] ?? 0}', textAlign: TextAlign.end))])), const SizedBox(height: AppSpacing.md), Align(alignment: Alignment.centerLeft, child: HBButton.secondary(label: 'marketplace.view_profile'.tr(), onPressed: seller.username.isEmpty ? null : () => context.push(AppRoutes.publicProfilePath(seller.username))))]));
}

class SellerListings extends ConsumerWidget {
  final String userId;
  const SellerListings({super.key, required this.userId});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(sellerListingsProvider(userId)).when(loading: () => const HBSkeleton(height: 400), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr())), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.empty_title'.tr(), message: 'marketplace.empty_message'.tr())) : LayoutBuilder(builder: (context, constraints) => GridView.builder(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: constraints.maxWidth >= 760 ? 3 : 2, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: .62), itemCount: items.length, itemBuilder: (_, index) => MarketplaceListingCard(listing: items[index]))));
}

class SellerReviews extends ConsumerWidget {
  final String userId;
  final SellerSummary seller;
  const SellerReviews({super.key, required this.userId, required this.seller});
  @override Widget build(BuildContext context, WidgetRef ref) => ref.watch(sellerReviewsProvider(userId)).when(loading: () => const HBSkeleton(height: 360), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr())), data: (reviews) => reviews.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.star_border_rounded, title: 'marketplace.reviews_empty_title'.tr(), message: 'marketplace.reviews_empty_message'.tr())) : Column(children: [for (final review in reviews) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: SellerReviewCard(review: review, sellerId: userId))]));
}

class SellerReviewCard extends ConsumerWidget {
  final SellerReview review;
  final String sellerId;
  const SellerReviewCard({super.key, required this.review, required this.sellerId});
  @override Widget build(BuildContext context, WidgetRef ref) { final isSeller = ref.watch(supabaseClientProvider).auth.currentUser?.id == sellerId; return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [GestureDetector(onTap: review.reviewer.username.isEmpty ? null : () => context.push(AppRoutes.publicProfilePath(review.reviewer.username)), child: HBAvatar(name: review.reviewer.displayName, imageUrl: review.reviewer.avatarUrl, size: 38)), const SizedBox(width: AppSpacing.sm), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(review.reviewer.displayName, style: context.textStyles.titleSmall), Text(relativeTime(context, review.createdAt), style: context.textStyles.bodySmall)])), StarRow(value: review.rating)]), if (review.comment?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.sm), Text(review.comment!)], if (review.reply?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.sm), HBTile(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.seller_reply'.tr(), style: context.textStyles.labelLarge), Text(review.reply!)]))], const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, children: [if (isSeller) HBButton.ghost(label: review.reply == null ? 'marketplace.reply'.tr() : 'marketplace.edit_reply'.tr(), onPressed: () => _reply(context, ref)), if (review.isMine && review.canEdit) HBButton.ghost(label: 'marketplace.edit_review'.tr(), onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ReviewSheet(listingId: review.listingId, review: review))), if (review.isMine) HBButton.ghost(label: 'common.delete'.tr(), onPressed: () => _delete(context, ref))]) ])); }
  Future<void> _reply(BuildContext context, WidgetRef ref) async { final controller = TextEditingController(text: review.reply); final value = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, children: [HBInput(controller: controller, maxLines: 4, maxLength: 1000, hint: 'marketplace.reply_hint'.tr()), const SizedBox(height: AppSpacing.md), HBButton.primary(label: 'common.save'.tr(), onPressed: () => context.pop(controller.text))]))); controller.dispose(); if (value == null) return; try { await ref.read(marketplaceRepositoryProvider).replyReview(review.id, value); ref.invalidate(sellerReviewsProvider(sellerId)); } on AppException catch (error) { if (context.mounted) _showError(context, error); } }
  Future<void> _delete(BuildContext context, WidgetRef ref) async { try { await ref.read(marketplaceRepositoryProvider).deleteReview(review.id); ref.invalidate(sellerReviewsProvider(sellerId)); ref.invalidate(sellerProfileProvider(sellerId)); } on AppException catch (error) { if (context.mounted) _showError(context, error); } }
}

String _rating(int hundredths) => '${hundredths ~/ 100},${((hundredths % 100) ~/ 10)}';
void _showError(BuildContext context, AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));