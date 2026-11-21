import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_form.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_search_bar.dart';
import 'package:hb_social/core/widgets/hb_place_field.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_select.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_page_header.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_card.dart';
import 'package:hb_social/features/ads/providers/ads_providers.dart';
import 'package:hb_social/features/hunting/providers/reference_providers.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';

class MarketplacePage extends ConsumerStatefulWidget {
  final String? sellerId;
  const MarketplacePage({super.key, this.sellerId});
  @override ConsumerState<MarketplacePage> createState() => _MarketplacePageState();
}

class _MarketplacePageState extends ConsumerState<MarketplacePage> {
  final search = TextEditingController();
  Timer? debounce;
  int tab = 0;
  bool showFloatingAction = true;
  double lastOffset = 0;

  @override void initState() { super.initState(); if (widget.sellerId != null) Future.microtask(() { final filters = ref.read(marketplaceFiltersProvider); ref.read(marketplaceFiltersProvider.notifier).set(filters.copyWith(sellerId: widget.sellerId)); }); }

  @override void dispose() { debounce?.cancel(); search.dispose(); super.dispose(); }

  void onSearch(String value) { debounce?.cancel(); debounce = Timer(const Duration(milliseconds: 400), () { if (!mounted) return; final current = ref.read(marketplaceFiltersProvider); ref.read(marketplaceFiltersProvider.notifier).set(current.copyWith(query: value)); }); }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(marketplaceFiltersProvider);
    final categories = ref.watch(marketplaceCategoriesProvider).value ?? const [];
    final listings = ref.watch(listingsProvider);
    final compact = MediaQuery.sizeOf(context).width < AppBreakpoints.mobile;
    final scroller = NotificationListener<ScrollNotification>(onNotification: (notification) {
      if (notification.metrics.extentAfter < 500 && tab == 0) ref.read(listingsProvider.notifier).loadMore();
      if (compact && notification is ScrollUpdateNotification) {
        final offset = notification.metrics.pixels;
        final goingDown = offset > lastOffset + 8;
        final goingUp = offset < lastOffset - 8;
        if (goingDown && showFloatingAction) setState(() => showFloatingAction = false);
        if ((goingUp || offset <= 0) && !showFloatingAction) setState(() => showFloatingAction = true);
        if (goingDown || goingUp) lastOffset = offset;
      }
      return false;
    }, child: CustomScrollView(slivers: [
      SliverPadding(padding: const EdgeInsets.only(top: AppSpacing.sm), sliver: SliverToBoxAdapter(child: HBPageHeader(title: 'marketplace.title'.tr(), subtitle: 'marketplace.header_subtitle'.tr(), action: compact ? null : HBButton.primary(label: 'marketplace.sell'.tr(), icon: Icons.add_rounded, onPressed: () => context.push(AppRoutes.marketplaceNew)), menu: PopupMenuButton<String>(tooltip: 'marketplace.menu'.tr(), onSelected: (value) => context.push(value == 'mine' ? AppRoutes.marketplaceMine : value == 'orders' ? AppRoutes.orders : AppRoutes.marketplaceNew), itemBuilder: (_) => [PopupMenuItem(value: 'orders', child: Text('orders.title'.tr())), PopupMenuItem(value: 'mine', child: Text('marketplace.mine.title'.tr())), PopupMenuItem(value: 'sell', child: Text('marketplace.sell'.tr()))])))),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      if (tab == 0) ...[
        SliverToBoxAdapter(child: HBListSearchBar(controller: search, hint: 'marketplace.search_hint'.tr(), onChanged: onSearch, activeFilters: filters.activeCount, onFilters: () => showMarketplaceFilters(context, ref))),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      ],
      SliverToBoxAdapter(child: ConstrainedBox(constraints: BoxConstraints(maxWidth: compact ? double.infinity : 420), child: HBSegmentedTabs(labels: ['marketplace.tabs.browse'.tr(), 'marketplace.tabs.favorites'.tr()], selectedIndex: tab, onChanged: (value) => setState(() => tab = value)))),
      const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
      if (tab == 0) ...[
        SliverToBoxAdapter(child: HBFilterChipsRow(labels: ['marketplace.category_all'.tr(), ...categories.map((category) => category.nameKey.tr())], selectedIndex: filters.categoryId == null ? 0 : (categories.indexWhere((category) => category.id == filters.categoryId) + 1).clamp(0, categories.length), onChanged: (index) => ref.read(marketplaceFiltersProvider.notifier).set(index == 0 ? filters.copyWith(clearCategory: true) : filters.copyWith(categoryId: categories[index - 1].id)))),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.md)),
        SliverToBoxAdapter(child: MarketplaceFeaturedStrip(categoryId: filters.categoryId)),
        ...listings.when(loading: () => [const MarketplaceGridSkeleton()], error: (_, __) => [SliverToBoxAdapter(child: MarketplaceLoadError(onRetry: () => ref.invalidate(listingsProvider)))], data: (state) => state.items.isEmpty ? [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.filtered_empty_title'.tr(), message: 'marketplace.filtered_empty_message'.tr(), action: HBButton.secondary(label: 'marketplace.reset'.tr(), onPressed: () { search.clear(); ref.read(marketplaceFiltersProvider.notifier).reset(); }))))] : [MarketplaceGrid(items: state.items), if (state.loadingMore) const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.all(AppSpacing.md), child: HBSkeleton(height: 44)))])
      ] else ...[
        ...ref.watch(favoritesProvider).when(loading: () => [const MarketplaceGridSkeleton()], error: (_, __) => [SliverToBoxAdapter(child: MarketplaceLoadError(onRetry: () => ref.invalidate(favoritesProvider)))], data: (items) => items.isEmpty ? [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.favorite_border_rounded, title: 'marketplace.favorites_empty_title'.tr(), message: 'marketplace.favorites_empty_message'.tr())))] : [MarketplaceGrid(items: items)])
      ],
      const SliverToBoxAdapter(child: SizedBox(height: 96)),
    ]));
    return PageColumns(centerMaxWidth: 1100, center: compact
        ? Stack(children: [
            Positioned.fill(child: scroller),
            Positioned(left: 0, right: 0, bottom: AppSpacing.md, child: Center(child: HBScrollHidingAction(visible: showFloatingAction && tab == 0, label: 'marketplace.publish_listing'.tr(), icon: Icons.sell_outlined, onPressed: () => context.push(AppRoutes.marketplaceNew)))),
          ])
        : scroller);
  }
}

Future<void> showMarketplaceFilters(BuildContext context, WidgetRef ref) async {
  final wide = MediaQuery.sizeOf(context).width >= 900;
  await showModalBottomSheet<void>(context: context, isScrollControlled: true, useSafeArea: true, constraints: wide ? const BoxConstraints(maxWidth: 720) : null, builder: (_) => const MarketplaceFiltersSheet());
}

class MarketplaceFiltersSheet extends ConsumerStatefulWidget {
  const MarketplaceFiltersSheet({super.key});
  @override ConsumerState<MarketplaceFiltersSheet> createState() => _MarketplaceFiltersSheetState();
}

class _MarketplaceFiltersSheetState extends ConsumerState<MarketplaceFiltersSheet> {
  late MarketplaceFilters draft;
  final municipality = TextEditingController();
  final minimum = TextEditingController();
  final maximum = TextEditingController();

  @override void initState() { super.initState(); draft = ref.read(marketplaceFiltersProvider); municipality.text = draft.municipality?.compactName ?? ''; minimum.text = _major(draft.priceMinMinor); maximum.text = _major(draft.priceMaxMinor); }
  @override void dispose() { municipality.dispose(); minimum.dispose(); maximum.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(userSettingsProvider);
    final regions = settings.countryCode == null ? const <ReferenceRegion>[] : ref.watch(regionsProvider(settings.countryCode!)).value ?? const [];
    final symbol = MoneyFormatter.format(amountMinor: 0, currencyCode: settings.currencyCode, locale: context.locale).replaceAll(RegExp(r'[\d\s.,]'), '');
    return Padding(padding: EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.md, AppSpacing.lg, MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg), child: SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text('marketplace.filters'.tr(), style: context.textStyles.titleLarge)), HBButton.ghost(label: 'marketplace.reset'.tr(), onPressed: () => setState(() { draft = const MarketplaceFilters(); municipality.clear(); minimum.clear(); maximum.clear(); }))]),
      const SizedBox(height: AppSpacing.lg),
      HBFormField(label: 'marketplace.region'.tr(), child: HBSelect<String>(value: draft.regionId, options: regions.map((item) => HBSelectOption(value: item.id, label: item.name)).toList(), allowClear: true, placeholder: 'marketplace.all_regions'.tr(), onChanged: (value) => setState(() => draft = draft.copyWith(regionId: value, clearRegion: value == null, clearMunicipality: true)))),
      const SizedBox(height: AppSpacing.md),
      HBFormField(label: 'marketplace.municipality'.tr(), child: HBPlaceField<Municipality>(controller: municipality, hint: 'marketplace.municipality_hint'.tr(), search: (query) async { final items = await ref.read(referenceRepositoryProvider).searchMunicipalities(query, countryCode: settings.countryCode ?? 'IT', regionId: draft.regionId); return items.map((item) => HBPlaceSuggestion(value: item, title: item.compactName, subtitle: item.regionName)).toList(); }, onSelected: (value) => setState(() => draft = draft.copyWith(municipality: value, regionId: value.regionId, radiusKm: draft.radiusKm ?? 25)))),
      if (draft.municipality != null) ...[const SizedBox(height: AppSpacing.md), HBFormField(label: 'marketplace.radius'.tr(), child: HBChoice<int>(options: const [10, 25, 50, 100], value: draft.radiusKm ?? 25, onChanged: (value) => setState(() => draft = draft.copyWith(radiusKm: value)), labelBuilder: (value) => 'marketplace.radius_km'.tr(namedArgs: {'n': '$value'})))],
      const SizedBox(height: AppSpacing.md),
      Row(children: [Expanded(child: HBFormField(label: 'marketplace.price_min'.tr(), child: HBInput(controller: minimum, hint: symbol, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]))), const SizedBox(width: AppSpacing.md), Expanded(child: HBFormField(label: 'marketplace.price_max'.tr(), child: HBInput(controller: maximum, hint: symbol, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]'))]))) ]),
      const SizedBox(height: AppSpacing.md),
      HBFormField(label: 'marketplace.condition_label'.tr(), child: Wrap(spacing: AppSpacing.xs, runSpacing: AppSpacing.xs, children: [for (final condition in ListingCondition.values) HBChip(label: condition.labelKey.tr(), selected: draft.conditions.contains(condition), onTap: () => setState(() { final values = {...draft.conditions}; values.contains(condition) ? values.remove(condition) : values.add(condition); draft = draft.copyWith(conditions: values); }))])),
      const SizedBox(height: AppSpacing.md),
      SwitchListTile(contentPadding: EdgeInsets.zero, title: Text('marketplace.shipping_only'.tr()), value: draft.shippingOnly, onChanged: (value) => setState(() => draft = draft.copyWith(shippingOnly: value))),
      const SizedBox(height: AppSpacing.md),
      HBFormField(label: 'marketplace.sort_label'.tr(), child: HBSelect<String>(value: draft.sort, options: ['recent', 'price_asc', 'price_desc', if (draft.municipality?.lat != null) 'distance', 'popular'].map((item) => HBSelectOption(value: item, label: 'marketplace.sort.$item'.tr())).toList(), onChanged: (value) { if (value != null) setState(() => draft = draft.copyWith(sort: value)); })),
      const SizedBox(height: AppSpacing.lg),
      SizedBox(width: double.infinity, child: HBButton.primary(label: 'marketplace.apply_filters'.tr(), onPressed: () { ref.read(marketplaceFiltersProvider.notifier).set(draft.copyWith(priceMinMinor: _minor(minimum.text), priceMaxMinor: _minor(maximum.text))); context.pop(); })),
    ])));
  }
}

class MarketplaceGrid extends ConsumerWidget {
  final List<Listing> items;
  const MarketplaceGrid({super.key, required this.items});
  @override Widget build(BuildContext context, WidgetRef ref) { final category = ref.watch(marketplaceFiltersProvider).categoryId; final ads = ref.watch(deliveredAdsProvider(AdPlacementRequest(AdPlacement.marketplace, count: 2, context: {if (category != null) 'category_id': category}))).value ?? const []; final insertions = <int, DeliveredAd>{if (ads.isNotEmpty) 2: ads[0], if (ads.length > 1 && items.length >= 13) 14: ads[1]}; return SliverLayoutBuilder(builder: (context, constraints) { final count = ((constraints.crossAxisExtent + 12) / (240 + 12)).floor().clamp(2, 5); final tileWidth = (constraints.crossAxisExtent - 12 * (count - 1)) / count; return SliverGrid.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 12, mainAxisSpacing: 12, mainAxisExtent: tileWidth + 140), itemCount: items.length + insertions.length, itemBuilder: (_, index) { final ad = insertions[index]; if (ad != null) return SponsoredCard(ad: ad, variant: AdPreviewVariant.tile); final before = insertions.keys.where((position) => position < index).length; return MarketplaceListingCard(listing: items[index - before]); }); }); }
}

class MarketplaceFeaturedStrip extends ConsumerWidget {
  final String? categoryId;
  const MarketplaceFeaturedStrip({super.key, this.categoryId});
  @override Widget build(BuildContext context, WidgetRef ref) {
    final ads = ref.watch(deliveredAdsProvider(AdPlacementRequest(AdPlacement.marketplaceTop, count: 6, context: {if (categoryId != null) 'category_id': categoryId}))).value ?? const <DeliveredAd>[];
    if (ads.isEmpty) return const SizedBox.shrink();
    return Padding(padding: const EdgeInsets.only(bottom: AppSpacing.lg), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('boost.featured'.tr(), style: context.textStyles.titleLarge), const SizedBox(height: AppSpacing.sm), SizedBox(height: 280, child: ListView.separated(scrollDirection: Axis.horizontal, itemCount: ads.length, separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm), itemBuilder: (_, index) => SizedBox(width: 190, child: SponsoredCard(ad: ads[index], variant: AdPreviewVariant.tile))))]));
  }
}

/// PD4b listing tile: square media with the favourite button, the promoted
/// chip (only for sponsored listings), price 20/700, title, category and the
/// seller row with the abbreviated name and city.
class MarketplaceListingCard extends ConsumerWidget {
  final Listing listing;

  /// Compact 160 px variant reserved for the future "In evidenza" strip (P39).
  final bool compact;

  /// True only for promoted listings; PD4b never fakes the chip.
  final bool featured;

  const MarketplaceListingCard({super.key, required this.listing, this.compact = false, this.featured = false});

  Future<void> toggle(BuildContext context, WidgetRef ref) async {
    if (ref.read(supabaseClientProvider).auth.currentUser == null) { context.push(AppRoutes.login); return; }
    final optimistic = !listing.isFavorite;
    ref.read(listingsProvider.notifier).updateFavorite(listing.id, optimistic);
    try { await ref.read(marketplaceRepositoryProvider).toggleFavorite(listing.id); ref.invalidate(favoritesProvider); ref.invalidate(listingDetailProvider(listing.id)); ref.invalidate(listingDetailResponseProvider(listing.id)); } on AppException catch (error) { ref.read(listingsProvider.notifier).updateFavorite(listing.id, !optimistic); if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.messageKey.tr()))); }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shown = listing.displayPrice ?? listing.originalPrice;
    final converted = listing.displayPrice != null && listing.displayPrice!.currencyCode != listing.originalPrice.currencyCode;
    return HBCard(
      radius: 18,
      padding: const EdgeInsets.all(AppSpacing.sm),
      onTap: () => context.push(AppRoutes.marketplaceDetailPath(listing.id)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1, child: ClipRRect(borderRadius: BorderRadius.circular(AppRadius.media), child: Stack(fit: StackFit.expand, children: [
          listing.mediaPath == null
              ? ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(_categoryIcon(listing.categorySlug), color: LightModeColors.textTertiary, size: 44))
              : Image.network(listing.mediaPath!, fit: BoxFit.cover, frameBuilder: (context, child, frame, synchronous) => AnimatedOpacity(opacity: frame == null && !synchronous ? 0 : 1, duration: AppMotion.of(context).base, child: child), loadingBuilder: (_, child, progress) => progress == null ? child : const ColoredBox(color: LightModeColors.surfaceSoft), errorBuilder: (_, __, ___) => const ColoredBox(color: LightModeColors.surfaceSoft, child: Icon(Icons.broken_image_outlined, color: LightModeColors.textTertiary))),
          if (featured) Positioned(top: 8, left: 8, child: Container(height: 28, padding: const EdgeInsets.symmetric(horizontal: 10), decoration: BoxDecoration(color: LightModeColors.bosco, borderRadius: BorderRadius.circular(AppRadius.pill)), child: Row(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.rocket_launch_rounded, size: 14, color: Colors.white), const SizedBox(width: 4), Text('marketplace.featured'.tr(), style: AppText.small.copyWith(fontWeight: FontWeight.w600, color: Colors.white))]))),
          Positioned(top: 8, right: 8, child: Material(color: LightModeColors.surface, shape: const CircleBorder(), child: InkWell(customBorder: const CircleBorder(), onTap: () => toggle(context, ref), child: SizedBox(width: 36, height: 36, child: Icon(listing.isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded, size: 20, color: listing.isFavorite ? LightModeColors.danger : LightModeColors.text))))),
        ]))),
        const SizedBox(height: AppSpacing.sm),
        Text(MoneyFormatter.format(amountMinor: shown.amountMinor, currencyCode: shown.currencyCode, locale: context.locale), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.price.withColor(LightModeColors.text)),
        if (converted) Text('marketplace.exchange_line'.tr(namedArgs: {'price': MoneyFormatter.format(amountMinor: listing.originalPrice.amountMinor, currencyCode: listing.originalPrice.currencyCode, locale: context.locale), 'date': listing.rateDate == null ? '' : DateFormat.yMd(context.locale.toString()).format(listing.rateDate!.toLocal())}), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.withColor(LightModeColors.textTertiary)),
        const SizedBox(height: 2),
        Text(listing.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.ui.withColor(LightModeColors.text)),
        Text(listing.isMediated ? 'marketplace.firearms.mediated'.tr() : listing.categoryNameKey.tr(), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.label.withColor(LightModeColors.textSecondary)),
        if (!compact) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            HBAvatar(name: listing.seller.displayName, imageUrl: listing.seller.avatarUrl, size: 28),
            const SizedBox(width: 6),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(abbreviateName(listing.seller.displayName), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption.withColor(LightModeColors.text)),
              if (listing.municipality?.trim().isNotEmpty == true) Text(listing.municipality!, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.small.withColor(LightModeColors.textSecondary)),
            ])),
            if (listing.seller.verificationLevel != 'none') HBBadge.verification(level: listing.seller.verificationLevel),
          ]),
        ],
        if (listing.status == ListingStatus.reserved || listing.status == ListingStatus.sold || listing.status == ListingStatus.expired) ...[
          const SizedBox(height: 6),
          HBStatusChip(kind: listing.status == ListingStatus.reserved ? HBStatusKind.pending : HBStatusKind.neutral, label: listing.status.labelKey.tr()),
        ],
      ]),
    );
  }
}

/// "Marco Rossi" -> "Marco R."; a single word is returned unchanged.
String abbreviateName(String value) {
  final parts = value.trim().split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
  if (parts.length < 2) return parts.isEmpty ? '' : parts.first;
  return '${parts.first} ${parts.last.substring(0, 1).toUpperCase()}.';
}

class MarketplaceGridSkeleton extends StatelessWidget { const MarketplaceGridSkeleton({super.key}); @override Widget build(BuildContext context) => const SliverGrid(delegate: SliverChildListDelegate.fixed([MarketplaceCardSkeleton(), MarketplaceCardSkeleton(), MarketplaceCardSkeleton(), MarketplaceCardSkeleton()]), gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: .62)); }
class MarketplaceCardSkeleton extends StatelessWidget { const MarketplaceCardSkeleton({super.key}); @override Widget build(BuildContext context) => const HBCard(radius: 18, padding: EdgeInsets.all(AppSpacing.sm), child: Column(children: [Expanded(child: HBSkeleton()), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 18), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 12)])); }
class MarketplaceLoadError extends StatelessWidget { final VoidCallback onRetry; const MarketplaceLoadError({super.key, required this.onRetry}); @override Widget build(BuildContext context) => HBCard(child: HBEmptyState(icon: Icons.error_outline, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry))); }

int? _minor(String value) { final normalized = value.trim().replaceAll(',', '.'); if (normalized.isEmpty) return null; final parts = normalized.split('.'); final whole = int.tryParse(parts.first); if (whole == null) return null; final fraction = parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00'; return whole * 100 + (int.tryParse(fraction) ?? 0); }
String _major(int? value) => value == null ? '' : '${value ~/ 100},${(value % 100).toString().padLeft(2, '0')}';
IconData _categoryIcon(String slug) => slug.contains('optic') ? Icons.remove_red_eye_outlined : slug.contains('cloth') ? Icons.checkroom_outlined : slug.contains('firearm') ? Icons.shield_outlined : Icons.inventory_2_outlined;