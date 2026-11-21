import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';
import 'package:share_plus/share_plus.dart';
import 'package:hb_social/features/ads/presentation/boost_sheet.dart';

class MyListingsPage extends ConsumerStatefulWidget {
  const MyListingsPage({super.key});
  @override ConsumerState<MyListingsPage> createState() => _MyListingsPageState();
}

class _MyListingsPageState extends ConsumerState<MyListingsPage> {
  static const statuses = [ListingStatus.active, ListingStatus.inReview, ListingStatus.reserved, ListingStatus.draft, ListingStatus.sold, ListingStatus.expired];
  int selected = 0;
  @override Widget build(BuildContext context) {
    final labels = [for (final status in statuses) 'marketplace.mine.tabs.${status.name}'.tr(namedArgs: {'n': '${ref.watch(myListingsProvider(status)).value?.length ?? 0}'})];
    final status = statuses[selected];
    final value = ref.watch(myListingsProvider(status));
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      Row(children: [Expanded(child: Text('marketplace.mine.title'.tr(), style: context.textStyles.headlineSmall)), HBButton.primary(label: 'marketplace.sell'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.marketplaceNew))]),
      if (ref.watch(sellerAccountProvider).value?.active != true) ...[const SizedBox(height: AppSpacing.md), HBCard(color: LightModeColors.lightPrimarySoft, child: Row(children: [const Icon(Icons.payments_outlined), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('payments.listing_banner'.tr())), HBButton.soft(label: 'payments.activate'.tr(), onPressed: () => context.push(AppRoutes.paymentSettings))]))],
      const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: labels, selectedIndex: selected, onChanged: (index) => setState(() => selected = index)),
      const SizedBox(height: AppSpacing.md), value.when(loading: () => const HBSkeleton(height: 280), error: (_, __) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(myListingsProvider(status))))), data: (items) => items.isEmpty ? HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.mine.empty.${status.name}'.tr(), message: 'marketplace.mine.empty_message'.tr(), action: HBButton.primary(label: 'marketplace.mine.sell_something'.tr(), onPressed: () => context.push(AppRoutes.marketplaceNew)))) : Column(children: [for (final item in items) Padding(padding: const EdgeInsets.only(bottom: AppSpacing.md), child: MyListingCard(item: item))])),
    ]))]));
  }
}

class MyListingCard extends ConsumerWidget {
  final MyListing item;
  const MyListingCard({super.key, required this.item});
  Listing get listing => item.listing;

  @override Widget build(BuildContext context, WidgetRef ref) {
    final expiring = listing.status == ListingStatus.active && item.daysLeft != null && item.daysLeft! <= 7;
    return GestureDetector(onTap: () => context.push(listing.status == ListingStatus.draft || item.reviewStatus != 'approved' ? AppRoutes.marketplaceEditPath(listing.id) : AppRoutes.marketplaceDetailPath(listing.id)), child: HBCard(child: LayoutBuilder(builder: (context, constraints) {
      final image = ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: SizedBox(width: constraints.maxWidth < 560 ? 96 : 150, height: constraints.maxWidth < 560 ? 96 : 120, child: listing.mediaPath == null ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.image_outlined)) : Image.network(listing.mediaPath!, fit: BoxFit.cover)));
      final details = Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(listing.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium)), ListingActionsMenu(item: item)]), const SizedBox(height: 4), Text(MoneyFormatter.format(amountMinor: listing.originalPrice.amountMinor, currencyCode: listing.originalPrice.currencyCode, locale: context.locale), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.xs), if (item.reviewStatus == 'pending') ...[HBStatusChip(kind: HBStatusKind.pending, label: 'p42.marketplace_review.pending'.tr()), Text('p42.marketplace_review.pending_help'.tr(), style: context.textStyles.bodySmall)] else if (item.reviewStatus == 'rejected') ...[HBStatusChip(kind: HBStatusKind.rejected, label: 'p42.marketplace_review.rejected'.tr()), HBCard(color: LightModeColors.lightError.withValues(alpha: 0.08), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(item.reviewNote ?? 'p42.marketplace_review.rejected_help'.tr()), HBButton.soft(label: 'p42.marketplace_review.edit_republish'.tr(), onPressed: () => context.push(AppRoutes.marketplaceEditPath(listing.id)), size: HBButtonSize.sm)]))] else HBStatusChip(kind: _statusKind(listing.status), label: listing.status.labelKey.tr()), const SizedBox(height: AppSpacing.xs), Text('marketplace.mine.stats'.tr(namedArgs: {'views': '${listing.viewCount}', 'favorites': '${listing.favoriteCount}', 'contacts': '${item.contactCount}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (listing.status == ListingStatus.expired) Text('marketplace.mine.expired_on'.tr(namedArgs: {'date': listing.expiresAt == null ? '' : DateFormat.yMd(context.locale.toString()).format(listing.expiresAt!.toLocal())}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightWarning)) else if (item.daysLeft != null) Text('marketplace.mine.expires_in'.tr(namedArgs: {'n': '${item.daysLeft}'}), style: context.textStyles.bodySmall?.withColor(expiring ? LightModeColors.lightWarning : LightModeColors.lightOnSurfaceVariant)), if (expiring || listing.status == ListingStatus.expired) Padding(padding: const EdgeInsets.only(top: AppSpacing.xs), child: HBButton.soft(label: 'marketplace.mine.renew'.tr(), onPressed: () => _renew(context, ref), size: HBButtonSize.sm))]));
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [image, const SizedBox(width: AppSpacing.md), details]);
    })));
  }

  Future<void> _renew(BuildContext context, WidgetRef ref) async { try { await ref.read(marketplaceRepositoryProvider).renew(listing.id); _refresh(ref); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('marketplace.mine.renewed'.tr()))); } on AppException catch (error) { if (context.mounted) _error(context, error); } }
}

class ListingActionsMenu extends ConsumerWidget {
  final MyListing item;
  const ListingActionsMenu({super.key, required this.item});
  @override Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded), onSelected: (value) => act(context, ref, value), itemBuilder: (_) => [if (item.listing.status == ListingStatus.active && !item.listing.isMediated) PopupMenuItem(value: 'boost', child: Text('boost.action'.tr())), if ({ListingStatus.draft, ListingStatus.active, ListingStatus.reserved, ListingStatus.expired}.contains(item.listing.status)) PopupMenuItem(value: 'edit', child: Text('marketplace.mine.edit'.tr())), if (item.listing.status == ListingStatus.active) PopupMenuItem(value: 'reserved', child: Text('marketplace.mine.mark_reserved'.tr())), if (item.listing.status == ListingStatus.reserved) PopupMenuItem(value: 'active', child: Text('marketplace.mine.available'.tr())), if ({ListingStatus.active, ListingStatus.reserved}.contains(item.listing.status)) PopupMenuItem(value: 'sold', child: Text('marketplace.mine.mark_sold'.tr())), PopupMenuItem(value: 'contacts', child: Text('marketplace.mine.contacts'.tr())), PopupMenuItem(value: 'share', child: Text('marketplace.share'.tr())), PopupMenuItem(value: 'removed', child: Text('marketplace.mine.delete'.tr()))]);

  Future<void> act(BuildContext context, WidgetRef ref, String value) async {
    final listing = item.listing;
    if (value == 'boost') { await showBoostSheet(context, targetType: 'listing', targetId: listing.id); return; }
    if (value == 'edit') { context.push(AppRoutes.marketplaceEditPath(listing.id)); return; }
    if (value == 'contacts') { await showModalBottomSheet<void>(context: context, useSafeArea: true, isScrollControlled: true, builder: (_) => ListingContactsSheet(listingId: listing.id)); return; }
    if (value == 'share') { await Share.share(Uri.base.resolve(AppRoutes.marketplaceDetailPath(listing.id)).toString()); return; }
    if (value == 'sold' && !await _confirm(context, 'marketplace.mine.sold_confirm_title', 'marketplace.mine.sold_confirm_message')) return;
    if (value == 'removed' && !await _confirm(context, 'marketplace.mine.delete_confirm_title', 'marketplace.mine.delete_confirm_message')) return;
    try { await ref.read(marketplaceRepositoryProvider).setStatus(listing.id, ListingStatusApi.parse(value)); _refresh(ref); ref.invalidate(listingDetailProvider(listing.id)); } on AppException catch (error) { if (context.mounted) _error(context, error); }
  }
}

class ListingContactsSheet extends ConsumerWidget {
  final String listingId;
  const ListingContactsSheet({super.key, required this.listingId});
  @override Widget build(BuildContext context, WidgetRef ref) => SafeArea(child: Padding(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.mine.contacts'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), Flexible(child: ref.watch(listingContactsProvider(listingId)).when(loading: () => const HBSkeleton(height: 120), error: (_, __) => Text('marketplace.error_message'.tr()), data: (items) => items.isEmpty ? HBEmptyState(icon: Icons.chat_bubble_outline, title: 'marketplace.mine.contacts_empty'.tr(), message: 'marketplace.mine.contacts_empty_message'.tr()) : ListView.separated(shrinkWrap: true, itemCount: items.length, separatorBuilder: (_, __) => const Divider(), itemBuilder: (_, index) { final contact = items[index]; return ListTile(contentPadding: EdgeInsets.zero, leading: HBAvatar(name: contact.user.displayName, imageUrl: contact.user.avatarUrl), title: Text(contact.user.displayName), subtitle: Text('@${contact.user.username}'), trailing: const Icon(Icons.chevron_right_rounded), onTap: () { context.pop(); context.push(AppRoutes.conversationDetailPath(contact.conversationId)); }); })))])));
}

Future<bool> _confirm(BuildContext context, String title, String message) async => await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(title: Text(title.tr()), content: Text(message.tr()), actions: [HBButton.ghost(label: 'common.cancel'.tr(), onPressed: () => dialogContext.pop(false)), HBButton.primary(label: 'marketplace.mine.confirm'.tr(), onPressed: () => dialogContext.pop(true))])) ?? false;
void _refresh(WidgetRef ref) { ref.invalidate(myListingsProvider); ref.invalidate(listingsProvider); ref.invalidate(favoritesProvider); }
void _error(BuildContext context, AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
HBStatusKind _statusKind(ListingStatus status) => switch (status) { ListingStatus.active => HBStatusKind.approved, ListingStatus.inReview || ListingStatus.reserved => HBStatusKind.pending, ListingStatus.draft => HBStatusKind.neutral, ListingStatus.sold => HBStatusKind.info, ListingStatus.expired || ListingStatus.removed => HBStatusKind.rejected };