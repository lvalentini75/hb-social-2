import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
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
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_page.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';
import 'package:hb_social/features/orders/presentation/checkout_sheet.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';
import 'package:hb_social/features/safety/presentation/report_sheet.dart';
import 'package:hb_social/features/ads/presentation/boost_sheet.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hb_social/core/widgets/translatable_text.dart';

class ListingDetailPage extends ConsumerStatefulWidget {
  final String listingId;
  const ListingDetailPage({super.key, required this.listingId});
  @override ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  bool viewed = false;
  @override Widget build(BuildContext context) => ref.watch(listingDetailResponseProvider(widget.listingId)).when(
    loading: () => const PageColumns(center: Padding(padding: EdgeInsets.all(AppSpacing.lg), child: HBSkeleton(height: 600))),
    error: (error, __) { final platform = error is AppException && error.messageKey == 'marketplace.firearms.notice.platform'; return PageColumns(center: HBCard(child: HBEmptyState(icon: platform ? Icons.public_off_outlined : Icons.storefront_outlined, title: platform ? 'marketplace.firearms.unavailable_title'.tr() : 'marketplace.not_found_title'.tr(), message: platform ? 'marketplace.firearms.notice.platform'.tr() : 'marketplace.not_found_message'.tr()))); },
    data: (response) { if (response.unavailable != null) return FirearmsUnavailableView(value: response.unavailable!); final detail = response.detail!; if (!viewed && !detail.isMine) { viewed = true; Future.microtask(() => ref.read(marketplaceRepositoryProvider).recordView(widget.listingId)); } return ListingDetailBody(detail: detail); },
  );
}

class ListingDetailBody extends ConsumerWidget {
  final ListingDetail detail;
  const ListingDetailBody({super.key, required this.detail});

  Future<void> favorite(BuildContext context, WidgetRef ref) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    try { await ref.read(marketplaceRepositoryProvider).toggleFavorite(detail.listing.id); ref.invalidate(listingDetailProvider(detail.listing.id)); ref.invalidate(listingDetailResponseProvider(detail.listing.id)); ref.invalidate(listingsProvider); ref.invalidate(favoritesProvider); } on AppException catch (error) { if (context.mounted) _error(context, error); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listing = detail.listing;
    final shown = listing.displayPrice ?? listing.originalPrice;
    final converted = listing.displayPrice != null && shown.currencyCode != listing.originalPrice.currencyCode;
    final unavailable = listing.status == ListingStatus.sold || listing.status == ListingStatus.expired || listing.status == ListingStatus.removed;
    return PageColumns(center: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      if (listing.isMediated) ...[MediatedPanel(policy: detail.firearmsPolicy), const SizedBox(height: AppSpacing.md)],
      ListingGallery(media: detail.media),
      const SizedBox(height: AppSpacing.lg),
      Text(MoneyFormatter.format(amountMinor: shown.amountMinor, currencyCode: shown.currencyCode, locale: context.locale), style: context.textStyles.headlineMedium?.copyWith(fontWeight: FontWeight.w800)),
      if (converted) Text('marketplace.exchange_detail'.tr(namedArgs: {'price': MoneyFormatter.format(amountMinor: listing.originalPrice.amountMinor, currencyCode: listing.originalPrice.currencyCode, locale: context.locale), 'date': listing.rateDate == null ? '' : DateFormat.yMd(context.locale.toString()).format(listing.rateDate!.toLocal())}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.sm), TranslatableText(type: 'listing', id: listing.id, field: 'title', text: listing.title, style: context.textStyles.headlineSmall),
      const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [HBBadge.label(label: listing.condition.labelKey.tr()), HBBadge.label(label: listing.categoryNameKey.tr()), if (listing.negotiable && !listing.isMediated) HBBadge.label(label: 'marketplace.negotiable'.tr()), if (listing.shippingAvailable && !listing.isMediated) HBBadge.label(label: 'marketplace.shipping'.tr()), if (listing.isMediated) HBStatusChip(kind: HBStatusKind.info, label: 'marketplace.firearms.mediated'.tr()), if (listing.status != ListingStatus.active) HBStatusChip(kind: unavailable ? HBStatusKind.neutral : HBStatusKind.pending, label: listing.status.labelKey.tr())]),
      if (unavailable) ...[const SizedBox(height: AppSpacing.md), HBCard(color: LightModeColors.lightBackgroundSoft, child: Text('marketplace.unavailable_note'.tr()))],
      if (detail.description?.isNotEmpty == true) ...[const SizedBox(height: AppSpacing.lg), TranslatableText(type: 'listing', id: listing.id, field: 'description', text: detail.description!, builder: (text) => ListingDescription(text: text))],
      const SizedBox(height: AppSpacing.lg), ListingLocation(listing: listing),
      if (detail.attributes.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), ListingAttributes(attributes: detail.attributes)],
      const SizedBox(height: AppSpacing.md), Text('marketplace.published_stats'.tr(namedArgs: {'time': relativeTime(context, listing.createdAt), 'views': '${listing.viewCount}', 'favorites': '${listing.favoriteCount}'}), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
      const SizedBox(height: AppSpacing.lg), if (listing.isMediated) FirearmsContactBlock(detail: detail) else SellerCard(seller: listing.seller),
      const SizedBox(height: AppSpacing.lg),
      if (detail.isMine) ...[if (!listing.isMediated && listing.status == ListingStatus.active) ...[Row(children: [BoostStatusControl(targetType: 'listing', targetId: listing.id), const Spacer(), HBButton.soft(label: 'boost.action'.tr(), icon: Icons.rocket_launch_outlined, onPressed: () => showBoostSheet(context, targetType: 'listing', targetId: listing.id))]), const SizedBox(height: AppSpacing.md)], ListingOwnerActions(detail: detail)]
      else ListingActions(detail: detail, unavailable: unavailable, onFavorite: () => favorite(context, ref)),
      if (detail.canReview || detail.myReview != null) ...[const SizedBox(height: AppSpacing.lg), ReviewPrompt(detail: detail)],
      const SizedBox(height: AppSpacing.lg), Row(children: [HBButton.ghost(label: 'marketplace.share'.tr(), icon: Icons.share_outlined, onPressed: () => Share.share(Uri.base.resolve(AppRoutes.marketplaceDetailPath(listing.id)).toString())), HBButton.ghost(label: 'marketplace.report'.tr(), icon: Icons.flag_outlined, onPressed: () async { if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; } await showReportSheet(context, targetType: 'listing', targetId: listing.id); })]),
      if (detail.similar.isNotEmpty) ...[const SizedBox(height: AppSpacing.xl), Text('marketplace.similar'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), SizedBox(height: 330, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: detail.similar.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md), itemBuilder: (_, index) => SizedBox(width: 230, child: MarketplaceListingCard(listing: detail.similar[index]))))],
    ]))]));
  }
}

class ListingOwnerActions extends ConsumerWidget {
  final ListingDetail detail;
  const ListingOwnerActions({super.key, required this.detail});
  @override Widget build(BuildContext context, WidgetRef ref) { final listing = detail.listing; final renewable = listing.status == ListingStatus.expired || listing.status == ListingStatus.active && listing.expiresAt != null && listing.expiresAt!.difference(DateTime.now().toUtc()).inDays <= 7; final account = ref.watch(sellerAccountProvider).value; return Column(children: [if (!listing.isMediated && account?.active != true) ...[HBCard(color: LightModeColors.lightPrimarySoft, child: Row(children: [const Icon(Icons.payments_outlined), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('payments.listing_banner'.tr())), HBButton.soft(label: 'payments.activate'.tr(), onPressed: () => context.push(AppRoutes.paymentSettings))])), const SizedBox(height: AppSpacing.md)], HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [HBStatusChip(kind: listing.status == ListingStatus.active ? HBStatusKind.approved : listing.status == ListingStatus.reserved ? HBStatusKind.pending : HBStatusKind.neutral, label: listing.status.labelKey.tr()), const Spacer(), Text('marketplace.mine_contacts'.tr(namedArgs: {'n': '${detail.contactsCount}'}))]), const SizedBox(height: AppSpacing.sm), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.primary(label: 'marketplace.mine.edit'.tr(), onPressed: () => context.push(AppRoutes.marketplaceEditPath(listing.id))), HBButton.secondary(label: 'marketplace.manage'.tr(), onPressed: () => context.push(AppRoutes.marketplaceMine)), if (renewable) HBButton.soft(label: 'marketplace.mine.renew'.tr(), onPressed: () async { try { await ref.read(marketplaceRepositoryProvider).renew(listing.id); ref.invalidate(listingDetailProvider(listing.id)); ref.invalidate(myListingsProvider); } on AppException catch (error) { if (context.mounted) _error(context, error); } })]) ]))]); }
}

class ListingGallery extends StatefulWidget {
  final List<ListingMedia> media;
  const ListingGallery({super.key, required this.media});
  @override State<ListingGallery> createState() => _ListingGalleryState();
}
class _ListingGalleryState extends State<ListingGallery> {
  int index = 0;
  @override Widget build(BuildContext context) { final count = widget.media.isEmpty ? 1 : widget.media.length; return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.lg), child: AspectRatio(aspectRatio: 4 / 3, child: Stack(children: [PageView.builder(itemCount: count, onPageChanged: (value) => setState(() => index = value), itemBuilder: (_, item) => widget.media.isEmpty ? const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.image_outlined, size: 52)) : InteractiveViewer(child: Image.network(widget.media[item].path, width: double.infinity, height: double.infinity, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(Icons.broken_image_outlined))))), if (count > 1) Positioned(bottom: AppSpacing.sm, left: 0, right: 0, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [for (var item = 0; item < count; item++) Container(width: 7, height: 7, margin: const EdgeInsets.all(3), decoration: BoxDecoration(shape: BoxShape.circle, color: item == index ? LightModeColors.lightPrimary : LightModeColors.lightSurface))]))]))); }
}

class ListingDescription extends StatefulWidget { final String text; const ListingDescription({super.key, required this.text}); @override State<ListingDescription> createState() => _ListingDescriptionState(); }
class _ListingDescriptionState extends State<ListingDescription> { bool expanded = false; @override Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(widget.text, maxLines: expanded ? null : 5, overflow: expanded ? null : TextOverflow.ellipsis), if (widget.text.length > 240) HBButton.ghost(label: expanded ? 'marketplace.show_less'.tr() : 'marketplace.show_all'.tr(), onPressed: () => setState(() => expanded = !expanded))]); }

class ListingLocation extends StatelessWidget {
  final Listing listing;
  const ListingLocation({super.key, required this.listing});
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.location_on_outlined), const SizedBox(width: AppSpacing.sm), Expanded(child: Text([listing.municipality, listing.regionName].whereType<String>().join(' · ')))]), if (listing.lat != null && listing.lng != null) ...[const SizedBox(height: AppSpacing.md), MarketplaceMunicipalityMap(lat: listing.lat!, lng: listing.lng!)]]));
}

class MarketplaceMunicipalityMap extends StatelessWidget {
  final double lat;
  final double lng;
  const MarketplaceMunicipalityMap({super.key, required this.lat, required this.lng});
  @override Widget build(BuildContext context) { final center = LatLng(lat, lng); return ClipRRect(borderRadius: BorderRadius.circular(AppRadius.md), child: SizedBox(height: 180, child: FlutterMap(options: MapOptions(initialCenter: center, initialZoom: 11, interactionOptions: const InteractionOptions(flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag)), children: [TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png', userAgentPackageName: 'com.hbsocial.app'), CircleLayer(circles: [CircleMarker(point: center, radius: 38, color: LightModeColors.lightPrimary.withValues(alpha: .18), borderColor: LightModeColors.lightPrimary, borderStrokeWidth: 2)]), RichAttributionWidget(attributions: [TextSourceAttribution('OpenStreetMap contributors')])]))); }
}

class ListingAttributes extends StatelessWidget {
  final Map<String, dynamic> attributes;
  const ListingAttributes({super.key, required this.attributes});
  @override Widget build(BuildContext context) { final visible = attributes.entries.where((entry) => entry.key != 'serial_number' && entry.key != 'serial').toList(); return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.details'.tr(), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.sm), for (final entry in visible) Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: Text(_attributeLabel(entry.key), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))), Expanded(child: Text(entry.key == 'firearm_type' ? 'marketplace.firearms.type.${entry.value}'.tr() : '${entry.value}', textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600)))]))])); }
}

class SellerCard extends ConsumerWidget {
  final SellerSummary seller;
  const SellerCard({super.key, required this.seller});
  @override Widget build(BuildContext context, WidgetRef ref) => GestureDetector(onTap: () => context.push(AppRoutes.marketplaceSellerPath(seller.id)), child: HBCard(child: Column(children: [Row(children: [HBAvatar(name: seller.displayName, imageUrl: seller.avatarUrl, size: 52), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Flexible(child: Text(seller.displayName, style: context.textStyles.titleMedium, overflow: TextOverflow.ellipsis)), if (seller.verificationLevel != 'none') ...[const SizedBox(width: 4), HBBadge.verification(level: seller.verificationLevel)]]), if (seller.ratingCount > 0) Text('marketplace.rating_count'.tr(namedArgs: {'rating': _rating(seller.ratingAverageHundredths), 'n': '${seller.ratingCount}'}))]))]), const SizedBox(height: AppSpacing.sm), if (seller.memberSince != null) Align(alignment: Alignment.centerLeft, child: Text('marketplace.member_since'.tr(namedArgs: {'date': DateFormat.yMMM(context.locale.toString()).format(seller.memberSince!.toLocal())}))), Align(alignment: Alignment.centerLeft, child: Text('marketplace.seller_counts'.tr(namedArgs: {'active': '${seller.activeListings}', 'sold': '${seller.soldListings}'}))), const SizedBox(height: AppSpacing.sm), Align(alignment: Alignment.centerLeft, child: HBButton.ghost(label: 'marketplace.view_all_listings'.tr(), onPressed: () { ref.read(marketplaceFiltersProvider.notifier).set(MarketplaceFilters(sellerId: seller.id)); context.go(AppRoutes.marketplace); }))])));
}

class MediatedPanel extends StatelessWidget {
  final FirearmsListingPolicy? policy;
  const MediatedPanel({super.key, required this.policy});
  @override Widget build(BuildContext context) => HBCard(color: LightModeColors.lightPrimarySoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [const Icon(Icons.shield_outlined, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Text('marketplace.firearms.mediated'.tr(), style: context.textStyles.titleMedium)]), const SizedBox(height: AppSpacing.sm), Text((policy?.noticeKey ?? 'marketplace.firearms.notice.disabled').tr()), const SizedBox(height: AppSpacing.sm), Text('marketplace.firearms.no_payment'.tr(), style: context.textStyles.bodyMedium?.bold), Text('marketplace.firearms.shop_only'.tr()), Text('marketplace.firearms.badge_required'.tr(namedArgs: {'badge': 'verification.badge.${policy?.requiresBadge ?? 'hunter'}'.tr()}))]));
}

class FirearmsUnavailableView extends StatelessWidget {
  final FirearmsUnavailable value;
  const FirearmsUnavailableView({super.key, required this.value});
  @override
  Widget build(BuildContext context) => PageColumns(center: CustomScrollView(slivers: [
    SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl), sliver: SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.public_off_outlined, title: 'marketplace.firearms.unavailable_title'.tr(), message: value.noticeKey.tr(), action: HBButton.secondary(label: 'marketplace.firearms.back'.tr(), onPressed: () => context.go(AppRoutes.marketplace))))))
  ]));
}

class FirearmsContactBlock extends ConsumerWidget {
  final ListingDetail detail;
  const FirearmsContactBlock({super.key, required this.detail});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final policy = detail.firearmsPolicy;
    if (policy?.contactLocked ?? true) return HBCard(color: LightModeColors.lightBackgroundSoft, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.firearms.contacts_locked'.tr(namedArgs: {'badge': 'verification.badge.${policy?.requiresBadge ?? 'hunter'}'.tr()}), style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.md), HBButton.primary(label: (policy?.contactLockReason == 'login_required' ? 'marketplace.firearms.login' : 'marketplace.firearms.request_badge').tr(), onPressed: () => context.push(policy?.contactLockReason == 'login_required' ? AppRoutes.login : AppRoutes.verification))]));
    final shop = detail.shop;
    if (shop == null) return const SizedBox.shrink();
    return HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [HBAvatar(name: shop.name, imageUrl: shop.avatarUrl, size: 48), const SizedBox(width: AppSpacing.md), Expanded(child: Text(shop.name, style: context.textStyles.titleMedium)), HBBadge.verification(level: 'gun_shop')]), if (shop.address != null) FirearmsContactRow(icon: Icons.location_on_outlined, value: shop.address!, onTap: () => _open(Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': shop.address!}))), if (shop.phone != null) FirearmsContactRow(icon: Icons.phone_outlined, value: shop.phone!, onTap: () => _open(Uri(scheme: 'tel', path: shop.phone))), if (shop.email != null) FirearmsContactRow(icon: Icons.email_outlined, value: shop.email!, onTap: () => _open(Uri(scheme: 'mailto', path: shop.email))), if (shop.website != null) FirearmsContactRow(icon: Icons.language_outlined, value: shop.website!, onTap: () => _open(Uri.parse(shop.website!))), const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBButton.primary(label: 'marketplace.firearms.contact_shop'.tr(), onPressed: () => _contactShop(context, ref)), HBButton.secondary(label: 'marketplace.firearms.open_page'.tr(), onPressed: () => context.push(AppRoutes.pageDetailPath(shop.slug)))]) ]));
  }
  Future<void> _contactShop(BuildContext context, WidgetRef ref) async { try { final id = detail.conversationId ?? await ref.read(marketplaceRepositoryProvider).contactSeller(detail.listing.id, message: 'marketplace.firearms.contact_prefill'.tr(namedArgs: {'title': detail.listing.title})); ref.invalidate(listingDetailResponseProvider(detail.listing.id)); if (context.mounted) context.push(AppRoutes.conversationDetailPath(id)); } on AppException catch (error) { if (context.mounted) _error(context, error); } }
  Future<void> _open(Uri uri) => launchUrl(uri, mode: LaunchMode.externalApplication);
}

class FirearmsContactRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final VoidCallback onTap;
  const FirearmsContactRow({super.key, required this.icon, required this.value, required this.onTap});
  @override Widget build(BuildContext context) => InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Row(children: [Icon(icon, size: 20), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(value, overflow: TextOverflow.ellipsis))])));
}

class ListingActions extends ConsumerWidget {
  final ListingDetail detail;
  final bool unavailable;
  final VoidCallback onFavorite;
  const ListingActions({super.key, required this.detail, required this.unavailable, required this.onFavorite});
  @override Widget build(BuildContext context, WidgetRef ref) { final quote = detail.listing.isMediated ? null : ref.watch(orderQuoteProvider(detail.listing.id)); final value = quote?.value; return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [if (value?.purchasable == true) HBButton.primary(label: 'orders.buy'.tr(), onPressed: unavailable ? null : () { if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; } showCheckoutSheet(context, detail.listing); }), if (!detail.listing.isMediated) HBButton.secondary(label: detail.conversationId == null ? 'marketplace.contact'.tr() : 'marketplace.open_chat'.tr(), onPressed: unavailable ? null : () => _contact(context, ref)), HBButton.secondary(label: detail.listing.isFavorite ? 'marketplace.saved'.tr() : 'marketplace.save'.tr(), icon: detail.listing.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, onPressed: onFavorite)]), if (value?.reason == 'seller_not_onboarded' || value?.reason == 'reserved') Padding(padding: const EdgeInsets.only(top: AppSpacing.sm), child: Text((value?.reason == 'reserved' ? 'orders.reserved_info' : 'orders.direct_only').tr(), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)))]); }
  Future<void> _contact(BuildContext context, WidgetRef ref) async { if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; } if (detail.conversationId != null) { context.push(AppRoutes.conversationDetailPath(detail.conversationId!)); return; } final message = await showModalBottomSheet<String>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ContactSellerSheet(title: detail.listing.title)); if (message == null || !context.mounted) return; try { final id = await ref.read(marketplaceRepositoryProvider).contactSeller(detail.listing.id, message: message); ref.invalidate(listingDetailProvider(detail.listing.id)); if (context.mounted) context.push(AppRoutes.conversationDetailPath(id)); } on AppException catch (error) { if (context.mounted) _error(context, error); } }
}

class ContactSellerSheet extends StatefulWidget { final String title; const ContactSellerSheet({super.key, required this.title}); @override State<ContactSellerSheet> createState() => _ContactSellerSheetState(); }
class _ContactSellerSheetState extends State<ContactSellerSheet> { late final TextEditingController text = TextEditingController(text: 'marketplace.contact_prefill'.tr(namedArgs: {'title': widget.title})); @override void dispose() { text.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.contact'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), HBInput(controller: text, maxLines: 5, maxLength: 2000), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'marketplace.send_and_open_chat'.tr(), onPressed: () => context.pop(text.text.trim()))) ])); }

class ReviewPrompt extends StatelessWidget {
  final ListingDetail detail;
  const ReviewPrompt({super.key, required this.detail});
  @override Widget build(BuildContext context) => HBCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(detail.myReview == null ? 'marketplace.review_prompt'.tr() : 'marketplace.your_review'.tr(), style: context.textStyles.titleMedium), if (detail.myReview != null) ...[const SizedBox(height: AppSpacing.xs), StarRow(value: detail.myReview!.rating), if (detail.myReview!.comment?.isNotEmpty == true) Text(detail.myReview!.comment!)], const SizedBox(height: AppSpacing.md), HBButton.secondary(label: detail.myReview == null ? 'marketplace.leave_review'.tr() : 'marketplace.edit_review'.tr(), onPressed: () => showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, builder: (_) => ReviewSheet(listingId: detail.listing.id, review: detail.myReview))) ]));
}

class ReviewSheet extends ConsumerStatefulWidget { final String listingId; final SellerReview? review; const ReviewSheet({super.key, required this.listingId, this.review}); @override ConsumerState<ReviewSheet> createState() => _ReviewSheetState(); }
class _ReviewSheetState extends ConsumerState<ReviewSheet> { late int rating = widget.review?.rating ?? 5; late final TextEditingController comment = TextEditingController(text: widget.review?.comment); bool saving = false; @override void dispose() { comment.dispose(); super.dispose(); } @override Widget build(BuildContext context) => Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.review_title'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.md), StarPicker(value: rating, onChanged: (value) => setState(() => rating = value)), const SizedBox(height: AppSpacing.md), HBInput(controller: comment, hint: 'marketplace.review_comment'.tr(), maxLines: 4, maxLength: 1000), const SizedBox(height: AppSpacing.md), SizedBox(width: double.infinity, child: HBButton.primary(label: 'marketplace.review_save'.tr(), isLoading: saving, onPressed: saving ? null : save))])); Future<void> save() async { setState(() => saving = true); try { await ref.read(marketplaceRepositoryProvider).upsertReview(listingId: widget.listingId, rating: rating, comment: comment.text); ref.invalidate(listingDetailProvider(widget.listingId)); if (mounted) context.pop(); } on AppException catch (error) { if (mounted) _error(context, error); } finally { if (mounted) setState(() => saving = false); } } }

class StarRow extends StatelessWidget { final int value; const StarRow({super.key, required this.value}); @override Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [for (var index = 1; index <= 5; index++) Icon(index <= value ? Icons.star_rounded : Icons.star_border_rounded, color: LightModeColors.lightWarning, size: 20)]); }
class StarPicker extends StatelessWidget { final int value; final ValueChanged<int> onChanged; const StarPicker({super.key, required this.value, required this.onChanged}); @override Widget build(BuildContext context) => Row(children: [for (var index = 1; index <= 5; index++) IconButton(onPressed: () => onChanged(index), icon: Icon(index <= value ? Icons.star_rounded : Icons.star_border_rounded, color: LightModeColors.lightWarning, size: 32))]); }

String _rating(int hundredths) => '${hundredths ~/ 100},${((hundredths % 100) ~/ 10)}';
void _error(BuildContext context, AppException error) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr(namedArgs: error.namedArgs))));
String _attributeLabel(String key) => key == 'firearm_type' ? 'marketplace.firearms.type_label'.tr() : ['brand', 'model', 'size', 'year', 'caliber'].contains(key) ? 'marketplace.attribute.$key'.tr() : 'marketplace.attribute_extra.$key'.tr();