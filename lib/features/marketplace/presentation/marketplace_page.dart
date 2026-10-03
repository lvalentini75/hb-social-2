import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/coming_soon_sheet.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_listing.dart';
import 'package:hb_social/features/marketplace/providers/marketplace_providers.dart';

class MarketplacePage extends ConsumerWidget {
  const MarketplacePage({super.key});

  void _sell(BuildContext context) => showComingSoonInfo(context, icon: Icons.storefront_outlined, title: 'common.coming_soon_title'.tr(), message: 'marketplace.sell_soon'.tr());

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(marketplaceCategoryProvider);
    final listings = ref.watch(marketplaceListingsProvider);
    return ListPageScaffold(
      title: 'marketplace.title'.tr(),
      subtitle: 'marketplace.subtitle'.tr(),
      action: HBButton.primary(label: 'marketplace.sell'.tr(), icon: Icons.add_rounded, onPressed: () => _sell(context)),
      filters: Column(
        children: [
          HBInput(hint: 'marketplace.search_hint'.tr(), prefixIcon: const Icon(Icons.search_rounded)),
          const SizedBox(height: AppSpacing.md),
          HBFilterChipsRow(
            labels: MarketplaceCategory.values.map((category) => category.translationKey.tr()).toList(),
            selectedIndex: selected.index,
            onChanged: (index) => ref.read(marketplaceCategoryProvider.notifier).state = MarketplaceCategory.values[index],
          ),
        ],
      ),
      body: Column(
        children: [
          MarketplaceToolsRow(selectedSort: ref.watch(marketplaceSortProvider), onSortChanged: (value) => ref.read(marketplaceSortProvider.notifier).state = value, onSetZone: () => context.go(AppRoutes.hunting)),
          if (selected == MarketplaceCategory.firearms) ...[const SizedBox(height: AppSpacing.md), const FirearmsInfoBanner()],
          const SizedBox(height: AppSpacing.md),
          listings.when(
            loading: () => const MarketplaceGridSkeleton(),
            error: (error, stack) => HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'marketplace.error_title'.tr(), message: 'marketplace.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(marketplaceListingsProvider)))),
            data: (items) => items.isEmpty
                ? HBCard(child: HBEmptyState(icon: Icons.storefront_outlined, title: 'marketplace.empty_title'.tr(), message: 'marketplace.empty_message'.tr(), action: HBButton.primary(label: 'marketplace.empty_cta'.tr(), onPressed: () => _sell(context))))
                : MarketplaceListingsGrid(items: items),
          ),
        ],
      ),
      rail: MarketplaceRail(onSell: () => _sell(context), onCategory: (category) => ref.read(marketplaceCategoryProvider.notifier).state = category),
    );
  }
}

class MarketplaceToolsRow extends StatelessWidget {
  final int selectedSort;
  final ValueChanged<int> onSortChanged;
  final VoidCallback onSetZone;

  const MarketplaceToolsRow({super.key, required this.selectedSort, required this.onSortChanged, required this.onSetZone});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: selectedSort,
            isExpanded: true,
            items: List.generate(4, (index) => DropdownMenuItem(value: index, child: Text('marketplace.sort_$index'.tr(), overflow: TextOverflow.ellipsis))),
            onChanged: (value) { if (value != null) onSortChanged(value); },
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      HBButton.soft(label: 'marketplace.set_zone'.tr(), icon: Icons.location_on_outlined, onPressed: onSetZone),
    ],
  );
}

class FirearmsInfoBanner extends StatelessWidget {
  const FirearmsInfoBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(color: LightModeColors.lightPrimarySoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
    child: Row(children: [
      const Icon(Icons.shield_outlined, color: LightModeColors.lightForest),
      const SizedBox(width: AppSpacing.sm),
      Expanded(child: Text('marketplace.firearms_banner'.tr(), style: context.textStyles.bodyMedium?.withColor(LightModeColors.lightForest))),
    ]),
  );
}

class MarketplaceListingsGrid extends StatelessWidget {
  final List<MarketplaceListing> items;

  const MarketplaceListingsGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
    final columns = constraints.maxWidth >= 760 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columns, crossAxisSpacing: AppSpacing.md, mainAxisSpacing: AppSpacing.md, childAspectRatio: 0.62),
      itemCount: items.length,
      itemBuilder: (context, index) => MarketplaceListingCard(listing: items[index]),
    );
  });
}

class MarketplaceListingCard extends ConsumerWidget {
  final MarketplaceListing listing;

  const MarketplaceListingCard({super.key, required this.listing});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final price = listing.priceMinor == null
        ? 'money.unavailable'.tr()
        : MoneyFormatter.format(amountMinor: listing.priceMinor!, currencyCode: listing.currencyCode ?? settings.currencyCode, locale: context.locale);
    return GestureDetector(
    onTap: () => context.push(AppRoutes.marketplaceDetailPath(listing.id)),
    child: HBCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AspectRatio(aspectRatio: 1, child: Container(color: LightModeColors.lightBackgroundSoft, child: const Icon(Icons.image_outlined, color: LightModeColors.lightTextTertiary))),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(price, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppSpacing.xs),
            Text(listing.title ?? '—', maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
            const SizedBox(height: AppSpacing.xs),
            Text('${listing.location ?? '—'} · —', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
            const SizedBox(height: AppSpacing.sm),
            Row(children: [HBAvatar(name: listing.sellerName, size: 24), const SizedBox(width: AppSpacing.sm), Expanded(child: Text(listing.sellerName ?? '—', overflow: TextOverflow.ellipsis)), const SizedBox(width: AppSpacing.xs)]),
          ]),
        ),
      ]),
    ),
    );
  }
}

class MarketplaceGridSkeleton extends StatelessWidget {
  const MarketplaceGridSkeleton({super.key});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) => GridView.count(
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    crossAxisCount: constraints.maxWidth >= 760 ? 3 : 2,
    crossAxisSpacing: AppSpacing.md,
    mainAxisSpacing: AppSpacing.md,
    childAspectRatio: 0.62,
    children: List.generate(6, (_) => const HBCard(padding: EdgeInsets.all(AppSpacing.sm), child: Column(children: [Expanded(child: HBSkeleton(radius: AppRadius.sm)), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 14), SizedBox(height: AppSpacing.sm), HBSkeleton(height: 12, width: 100)]))),
  ));
}

class MarketplaceRail extends StatelessWidget {
  final VoidCallback onSell;
  final ValueChanged<MarketplaceCategory> onCategory;

  const MarketplaceRail({super.key, required this.onSell, required this.onCategory});

  @override
  Widget build(BuildContext context) => Column(children: [
    PageRailCard(label: 'marketplace.rail_my_title'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('marketplace.rail_my_empty'.tr()), const SizedBox(height: AppSpacing.md), HBButton.soft(label: 'marketplace.sell'.tr(), onPressed: onSell)])),
    const SizedBox(height: AppSpacing.md),
    PageRailCard(label: 'marketplace.safety_title'.tr(), child: const MarketplaceSafetyContent()),
    const SizedBox(height: AppSpacing.md),
    PageRailCard(label: 'marketplace.rail_categories'.tr(), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: MarketplaceCategory.values.skip(1).map((category) => TextButton(onPressed: () => onCategory(category), child: Text(category.translationKey.tr()))).toList())),
  ]);
}

class MarketplaceSafetyContent extends StatelessWidget {
  const MarketplaceSafetyContent({super.key});

  @override
  Widget build(BuildContext context) => Column(children: List.generate(3, (index) => Padding(padding: const EdgeInsets.only(bottom: AppSpacing.sm), child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.check_circle_outline_rounded, size: 18, color: LightModeColors.lightPrimary), const SizedBox(width: AppSpacing.sm), Expanded(child: Text('marketplace.safety_$index'.tr(), style: context.textStyles.bodySmall))]))));
}