import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_listing.dart';
import 'package:hb_social/features/marketplace/presentation/marketplace_page.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';

class MarketplaceDetailPage extends ConsumerWidget {
  final String listingId;
  final bool debugPreview;

  const MarketplaceDetailPage({super.key, required this.listingId, this.debugPreview = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (debugPreview) return const MarketplaceDetailBody(listing: null);
    return ref.watch(marketplaceListingProvider(listingId)).when(
      loading: () => const PageColumns(center: Center(child: CircularProgressIndicator())),
      error: (error, stack) => PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr()))),
      data: (listing) => listing == null
          ? PageColumns(center: HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.not_found_title'.tr(), message: 'marketplace.not_found_message'.tr())))
          : MarketplaceDetailBody(listing: listing),
    );
  }
}

class MarketplaceDetailBody extends ConsumerWidget {
  final MarketplaceListing? listing;

  const MarketplaceDetailBody({super.key, required this.listing});

  void _soon(BuildContext context) => showComingSoonInfo(context, icon: Icons.storefront_outlined, title: 'common.coming_soon_title'.tr(), message: 'marketplace.sell_soon'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final firearms = listing?.category == MarketplaceCategory.firearms;
    final settings = ref.watch(userSettingsProvider);
    final price = listing?.priceMinor == null ? '—' : MoneyFormatter.format(amountMinor: listing!.priceMinor!, currencyCode: listing!.currencyCode ?? settings.currencyCode, locale: context.locale);
    final content = CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [
      const MarketplaceGallery(),
      const SizedBox(height: AppSpacing.lg),
      Text(listing?.title ?? '—', style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.sm),
      Text(price, style: context.textStyles.headlineSmall?.copyWith(fontSize: 24, fontWeight: FontWeight.w700)),
      const SizedBox(height: AppSpacing.md),
      Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: [HBChip(label: listing?.condition ?? '—', selected: false), HBChip(label: listing?.category?.translationKey.tr() ?? '—', selected: false), HBChip(label: listing?.location ?? '—', selected: false)]),
      if (firearms) ...[const SizedBox(height: AppSpacing.md), const FirearmsInfoBanner()],
      const SizedBox(height: AppSpacing.lg),
      Text(listing?.description ?? '—', style: context.textStyles.bodyMedium),
      if (MediaQuery.sizeOf(context).width < 1200) ...[
        const SizedBox(height: AppSpacing.lg),
        MarketplaceSellerRail(listing: listing, firearms: firearms, onAction: () => _soon(context)),
      ],
      const SizedBox(height: AppSpacing.xl),
      Text('marketplace.similar_title'.tr(), style: context.textStyles.titleLarge),
      const SizedBox(height: AppSpacing.md),
      HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.similar_empty'.tr(), message: 'marketplace.empty_message'.tr())),
      if (MediaQuery.sizeOf(context).width < 900) const SizedBox(height: 88),
    ]))]);
    final page = PageColumns(center: content, rail: MarketplaceSellerRail(listing: listing, firearms: firearms, onAction: () => _soon(context)));
    if (MediaQuery.sizeOf(context).width >= 900) return page;
    return Stack(children: [page, Positioned(left: 0, right: 0, bottom: 0, child: MarketplaceBottomAction(price: price, firearms: firearms, onPressed: firearms ? null : () => _soon(context)))]);
  }
}

class MarketplaceGallery extends StatefulWidget {
  const MarketplaceGallery({super.key});

  @override
  State<MarketplaceGallery> createState() => _MarketplaceGalleryState();
}

class _MarketplaceGalleryState extends State<MarketplaceGallery> {
  int index = 0;

  @override
  Widget build(BuildContext context) => AspectRatio(aspectRatio: 4 / 3, child: Stack(children: [
    PageView.builder(itemCount: 4, onPageChanged: (value) => setState(() => index = value), itemBuilder: (context, item) => Container(color: LightModeColors.lightBackgroundSoft, child: const Center(child: Icon(Icons.image_outlined, size: 44, color: LightModeColors.lightTextTertiary)))),
    Positioned(left: 0, right: 0, bottom: AppSpacing.md, child: Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(4, (item) => Container(width: 7, height: 7, margin: const EdgeInsets.symmetric(horizontal: 3), decoration: BoxDecoration(shape: BoxShape.circle, color: item == index ? LightModeColors.lightPrimary : LightModeColors.lightSurface))))),
  ]));
}

class MarketplaceSellerRail extends StatelessWidget {
  final MarketplaceListing? listing;
  final bool firearms;
  final VoidCallback onAction;

  const MarketplaceSellerRail({super.key, required this.listing, required this.firearms, required this.onAction});

  @override
  Widget build(BuildContext context) => Column(children: [
    HBCard(padding: const EdgeInsets.all(AppSpacing.lg), child: Column(children: [HBAvatar(name: listing?.sellerName, size: 56), const SizedBox(height: AppSpacing.sm), Text(listing?.sellerName ?? '—', style: context.textStyles.titleMedium), const SizedBox(height: AppSpacing.xs), Text('marketplace.member_since'.tr(namedArgs: {'date': '—'})), const SizedBox(height: AppSpacing.md), HBButton.primary(label: firearms ? 'marketplace.contact_shop'.tr() : 'marketplace.contact'.tr(), onPressed: firearms ? null : onAction), if (firearms) ...[const SizedBox(height: AppSpacing.xs), Text('marketplace.license_required'.tr(), textAlign: TextAlign.center, style: context.textStyles.bodySmall)], const SizedBox(height: AppSpacing.sm), HBButton.secondary(label: 'marketplace.save'.tr(), onPressed: onAction)])),
    const SizedBox(height: AppSpacing.md),
    PageRailCard(label: 'marketplace.safety_title'.tr(), child: const MarketplaceSafetyContent()),
  ]);
}

class MarketplaceBottomAction extends StatelessWidget {
  final String price;
  final bool firearms;
  final VoidCallback? onPressed;

  const MarketplaceBottomAction({super.key, required this.price, required this.firearms, required this.onPressed});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: const BoxDecoration(color: LightModeColors.lightSurface, boxShadow: AppShadows.level3),
    child: SafeArea(top: false, child: Row(children: [Expanded(child: Text(price, style: context.textStyles.titleLarge)), HBButton.primary(label: firearms ? 'marketplace.contact_shop'.tr() : 'marketplace.contact'.tr(), onPressed: onPressed)])),
  );
}