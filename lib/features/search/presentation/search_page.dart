import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/services/app_exception.dart';
import 'package:hb_social/core/services/time_format.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_chip.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_highlight_text.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_price.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/features/home/presentation/widgets/feed_post_card.dart';
import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/presentation/widgets/ad_preview_card.dart';
import 'package:hb_social/features/ads/presentation/widgets/sponsored_placement.dart';
import 'package:hb_social/features/profile/domain/user_profile.dart';
import 'package:hb_social/features/search/domain/search_result.dart';
import 'package:hb_social/features/search/providers/search_providers.dart';
import 'package:hb_social/features/social_graph/presentation/widgets/follow_button.dart';

class SearchPage extends ConsumerStatefulWidget {
  final String initialQuery;
  final SearchCategory initialCategory;
  final bool autofocus;

  const SearchPage({super.key, this.initialQuery = '', this.initialCategory = SearchCategory.all, this.autofocus = false});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  late final TextEditingController _controller = TextEditingController(text: widget.initialQuery);
  Timer? _debounce;
  List<Object> _additionalItems = const [];
  bool _loadingMore = false;
  bool _additionalHasMore = true;

  String get _query => widget.initialQuery.trim();

  @override
  void didUpdateWidget(covariant SearchPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuery != widget.initialQuery && _controller.text != widget.initialQuery) {
      _controller.value = TextEditingValue(text: widget.initialQuery, selection: TextSelection.collapsed(offset: widget.initialQuery.length));
    }
    if (oldWidget.initialQuery != widget.initialQuery || oldWidget.initialCategory != widget.initialCategory) {
      _additionalItems = const [];
      _additionalHasMore = true;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () => _navigate(query: value.trim()));
  }

  void _navigate({String? query, SearchCategory? category}) {
    final value = query ?? _query;
    final tab = category ?? widget.initialCategory;
    final parameters = <String, String>{if (value.isNotEmpty) 'q': value, if (tab != SearchCategory.all) 'tab': tab.value};
    context.go(Uri(path: AppRoutes.search, queryParameters: parameters).toString());
    if (value.length >= 2) ref.read(recentSearchesProvider.notifier).add(value);
  }

  Future<void> _loadMore(int currentCount) async {
    if (_loadingMore || !_additionalHasMore) return;
    setState(() => _loadingMore = true);
    try {
      final page = await ref.read(searchRepositoryProvider).searchType(query: _query, category: widget.initialCategory, offset: currentCount);
      if (mounted) setState(() {
        _additionalItems = [..._additionalItems, ...page.items];
        _additionalHasMore = page.hasMore;
      });
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('search.error_message'.tr())));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = _query.length >= 2 ? ref.watch(searchOverviewProvider(_query)) : const AsyncData(SearchOverview({}));
    final counts = overview.value;
    final labels = SearchCategory.values.map((category) {
      final label = _categoryLabel(category);
      final count = counts?.total(category) ?? 0;
      return count > 0 ? '$label · $count' : label;
    }).toList();
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          sliver: SliverToBoxAdapter(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 880),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Text('nav.search'.tr(), style: context.textStyles.headlineSmall?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: AppSpacing.md),
                  HBInput(
                    controller: _controller, autofocus: widget.autofocus, hint: 'search.input_hint'.tr(), onChanged: _onChanged,
                    prefixIcon: const Icon(Icons.search_rounded, color: LightModeColors.lightOnSurfaceVariant),
                    suffixIcon: _controller.text.isEmpty ? null : IconButton(icon: const Icon(Icons.close_rounded), tooltip: 'search.clear'.tr(), onPressed: () { _controller.clear(); _onChanged(''); }),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  HBSegmentedTabs(labels: labels, selectedIndex: widget.initialCategory.index, scrollable: true, onChanged: (index) => _navigate(category: SearchCategory.values[index])),
                  const SizedBox(height: AppSpacing.lg),
                  if (_query.isEmpty)
                    const RecentSearches()
                  else if (_query.length < 2)
                    HBCard(child: HBEmptyState(icon: Icons.manage_search_rounded, title: 'search.start_title'.tr(), message: 'search.minimum_characters'.tr()))
                  else if (widget.initialCategory == SearchCategory.all)
                    Column(children: [if (_query.length >= 3) ...[SponsoredPlacement(placement: AdPlacement.search, variant: AdPreviewVariant.search, contextData: {'query': _query}), const SizedBox(height: AppSpacing.md)], SearchOverviewBody(query: _query, value: overview, onRetry: () => ref.invalidate(searchOverviewProvider(_query)), onSelectCategory: (category) => _navigate(category: category))])
                  else
                    SearchTypeBody(
                      query: _query, category: widget.initialCategory,
                      value: ref.watch(searchTypeProvider(SearchRequest(_query, widget.initialCategory, 0))),
                      onRetry: () => ref.invalidate(searchTypeProvider(SearchRequest(_query, widget.initialCategory, 0))),
                      additionalItems: _additionalItems, loadingMore: _loadingMore, additionalHasMore: _additionalHasMore, onLoadMore: _loadMore,
                    ),
                ]),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class RecentSearches extends ConsumerWidget {
  const RecentSearches({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(recentSearchesProvider).value ?? const [];
    if (recent.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.manage_search_rounded, title: 'search.start_title'.tr(), message: 'search.start_message'.tr()));
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [Expanded(child: Text('search.recent_title'.tr(), style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700))), HBButton.ghost(label: 'search.clear_all'.tr(), onPressed: () => ref.read(recentSearchesProvider.notifier).clear())]),
        const SizedBox(height: AppSpacing.md),
        Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: recent.map((query) => HBChip(label: query, selected: false, onTap: () => context.go('${AppRoutes.search}?q=${Uri.encodeQueryComponent(query)}'), onDeleted: () => ref.read(recentSearchesProvider.notifier).remove(query))).toList()),
      ]),
    );
  }
}

class SearchOverviewBody extends StatelessWidget {
  final String query;
  final AsyncValue<SearchOverview> value;
  final ValueChanged<SearchCategory> onSelectCategory;
  final VoidCallback onRetry;

  const SearchOverviewBody({super.key, required this.query, required this.value, required this.onSelectCategory, required this.onRetry});

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const SearchLoadingSections(),
    error: (error, stack) => SearchErrorState(error: error, onRetry: onRetry),
    data: (overview) {
      if (overview.isEmpty) return SearchAllEmpty(query: query);
      return Column(children: [
        for (final category in SearchCategory.values.where((item) => item != SearchCategory.all && overview.total(item) > 0)) ...[
          SearchOverviewSection(query: query, category: category, items: overview.sections[category] ?? const [], total: overview.total(category), onSeeAll: () => onSelectCategory(category)),
          const SizedBox(height: AppSpacing.md),
        ],
      ]);
    },
  );
}

class SearchOverviewSection extends StatelessWidget {
  final String query;
  final SearchCategory category;
  final List<SearchPreview> items;
  final int total;
  final VoidCallback onSeeAll;

  const SearchOverviewSection({super.key, required this.query, required this.category, required this.items, required this.total, required this.onSeeAll});

  @override
  Widget build(BuildContext context) => HBCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: Column(children: [
      Row(children: [Expanded(child: Text('${_categoryLabel(category)} · $total', style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700))), HBButton.ghost(label: 'common.see_all'.tr(), onPressed: onSeeAll)]),
      for (final item in items) CompactSearchResult(query: query, item: item),
    ]),
  );
}

class CompactSearchResult extends StatelessWidget {
  final String query;
  final SearchPreview item;
  final bool selected;

  const CompactSearchResult({super.key, required this.query, required this.item, this.selected = false});

  @override
  Widget build(BuildContext context) => Material(
    color: selected ? LightModeColors.lightBackgroundHover : Colors.transparent,
    borderRadius: BorderRadius.circular(AppRadius.sm),
    child: InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm), onTap: () => _openPreview(context, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: Row(children: [
          HBAvatar(name: item.title, imageUrl: item.imageUrl, size: 32),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            HBHighlightText(text: item.title, query: query, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
            if (item.subtitle?.isNotEmpty == true) HBHighlightText(text: item.subtitle!, query: query, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
          ])),
        ]),
      ),
    ),
  );
}

class SearchTypeBody extends StatelessWidget {
  final String query;
  final SearchCategory category;
  final AsyncValue<SearchPageResult> value;
  final List<Object> additionalItems;
  final bool loadingMore;
  final bool additionalHasMore;
  final ValueChanged<int> onLoadMore;
  final VoidCallback onRetry;

  const SearchTypeBody({super.key, required this.query, required this.category, required this.value, required this.additionalItems, required this.loadingMore, required this.additionalHasMore, required this.onLoadMore, required this.onRetry});

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => const HBListSkeleton(showTrailing: false),
    error: (error, stack) => SearchErrorState(error: error, onRetry: onRetry),
    data: (page) {
      final items = [...page.items, ...additionalItems];
      if (items.isEmpty) return HBCard(child: HBEmptyState(icon: Icons.search_off_rounded, title: _emptyLabel(category), message: 'search.empty_message'.tr()));
      final hasMore = additionalItems.isEmpty ? page.hasMore : additionalHasMore;
      return Column(children: [
        for (final item in items) ...[SearchTypedResult(query: query, item: item), const SizedBox(height: AppSpacing.sm)],
        if (hasMore) HBButton.secondary(label: loadingMore ? 'common.loading'.tr() : 'search.load_more'.tr(), onPressed: loadingMore ? null : () => onLoadMore(items.length)),
      ]);
    },
  );
}

class SearchTypedResult extends StatelessWidget {
  final String query;
  final Object item;

  const SearchTypedResult({super.key, required this.query, required this.item});

  @override
  Widget build(BuildContext context) {
    if (item is SearchPostResult) {
      final result = item as SearchPostResult;
      return FeedPostCard(post: result.post, poll: result.poll);
    }
    if (item is SearchHashtag) {
      final hashtag = item as SearchHashtag;
      return Align(alignment: Alignment.centerLeft, child: HBChip(label: '#${hashtag.tag} · ${'search.hashtag_posts'.plural(hashtag.postCount)}', selected: false, onTap: () => context.push(AppRoutes.tagPath(hashtag.tag))));
    }
    if (item is UserProfile) return SearchProfileRow(query: query, profile: item as UserProfile);
    return SearchCommunityRow(query: query, item: item as SearchCommunityResult);
  }
}

class SearchProfileRow extends StatelessWidget {
  final String query;
  final UserProfile profile;

  const SearchProfileRow({super.key, required this.query, required this.profile});

  @override
  Widget build(BuildContext context) => HBCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: InkWell(
      onTap: () => context.push(AppRoutes.publicProfilePath(profile.username)),
      child: Row(children: [
        HBAvatar(name: profile.displayName, imageUrl: profile.avatarUrl, size: 48), const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [HBHighlightText(text: profile.displayName, query: query, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)), HBHighlightText(text: profile.bio?.isNotEmpty == true ? profile.bio! : '@${profile.username}', query: query, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))])),
        const SizedBox(width: AppSpacing.sm), FollowButton(userId: profile.id, username: profile.username, size: HBButtonSize.sm),
      ]),
    ),
  );
}

class SearchCommunityRow extends StatelessWidget {
  final String query;
  final SearchCommunityResult item;

  const SearchCommunityRow({super.key, required this.query, required this.item});

  @override
  Widget build(BuildContext context) => HBCard(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: InkWell(
      onTap: () => _openCommunity(context, item),
      child: Row(children: [
        HBAvatar(name: item.title, imageUrl: item.imageUrl, size: 48), const SizedBox(width: AppSpacing.md),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          HBHighlightText(text: item.title, query: query, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
          if (item.subtitle?.isNotEmpty == true) HBHighlightText(text: item.subtitle!, query: query, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)),
          if (item.category == SearchCategory.forum) Text('${'search.replies'.plural(item.count ?? 0)} · ${item.date == null ? '' : relativeTime(context, item.date!)}', style: context.textStyles.bodySmall?.withColor(LightModeColors.lightTextTertiary)),
        ])),
        if (item.priceMinor != null && item.currencyCode != null) HBPrice(amountMinor: item.priceMinor!, currencyCode: item.currencyCode!),
      ]),
    ),
  );
}

class SearchAllEmpty extends ConsumerWidget {
  final String query;

  const SearchAllEmpty({super.key, required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trending = ref.watch(trendingHashtagsProvider).value ?? const [];
    return HBCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(children: [
        HBEmptyState(icon: Icons.search_off_rounded, title: 'search.no_results_for'.tr(namedArgs: {'query': query}), message: 'search.empty_message'.tr()),
        if (trending.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, alignment: WrapAlignment.center, children: trending.map((item) => HBChip(label: '#${item.tag}', selected: false, onTap: () => context.push(AppRoutes.tagPath(item.tag)))).toList())],
      ]),
    );
  }
}

class SearchLoadingSections extends StatelessWidget {
  const SearchLoadingSections({super.key});

  @override
  Widget build(BuildContext context) => const Column(children: [HBListSkeleton(showTrailing: false), SizedBox(height: AppSpacing.md), HBListSkeleton(showTrailing: false)]);
}

class SearchErrorState extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const SearchErrorState({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final exception = AppException.from(error);
    return HBCard(child: HBEmptyState(icon: Icons.error_outline_rounded, title: 'search.error_title'.tr(), message: exception.messageKey.tr(namedArgs: exception.namedArgs), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry)));
  }
}

String _categoryLabel(SearchCategory category) => switch (category) {
  SearchCategory.all => 'search.category_all'.tr(), SearchCategory.people => 'search.category_people'.tr(), SearchCategory.posts => 'search.category_posts'.tr(),
  SearchCategory.hashtags => 'search.category_hashtags'.tr(), SearchCategory.groups => 'search.category_groups'.tr(), SearchCategory.pages => 'search.category_pages'.tr(),
  SearchCategory.listings => 'search.category_listings'.tr(), SearchCategory.events => 'search.category_events'.tr(), SearchCategory.forum => 'search.category_forum'.tr(),
};

String _emptyLabel(SearchCategory category) => switch (category) {
  SearchCategory.people => 'search.empty_people'.tr(), SearchCategory.posts => 'search.empty_posts'.tr(), SearchCategory.hashtags => 'search.empty_hashtags'.tr(),
  SearchCategory.groups => 'search.empty_groups'.tr(), SearchCategory.pages => 'search.empty_pages'.tr(), SearchCategory.listings => 'search.empty_listings'.tr(),
  SearchCategory.events => 'search.empty_events'.tr(), SearchCategory.forum => 'search.empty_forum'.tr(), SearchCategory.all => 'search.empty_title'.tr(),
};

void _openPreview(BuildContext context, SearchPreview item) {
  final path = switch (item.category) {
    SearchCategory.people when item.slug != null => AppRoutes.publicProfilePath(item.slug!), SearchCategory.posts => AppRoutes.postPath(item.id),
    SearchCategory.hashtags => AppRoutes.tagPath((item.slug ?? item.title).replaceFirst('#', '')), SearchCategory.groups => AppRoutes.groupDetailPath(item.id),
    SearchCategory.pages when item.slug != null => AppRoutes.pageDetailPath(item.slug!), SearchCategory.listings => AppRoutes.marketplaceDetailPath(item.id),
    SearchCategory.events => AppRoutes.eventDetailPath(item.id), SearchCategory.forum when item.extra['forum_slug'] != null => AppRoutes.threadPath(item.extra['forum_slug'] as String, item.id), _ => null,
  };
  if (path != null) context.push(path);
}

void _openCommunity(BuildContext context, SearchCommunityResult item) {
  final path = switch (item.category) {
    SearchCategory.groups => AppRoutes.groupDetailPath(item.id), SearchCategory.pages when item.slug != null => AppRoutes.pageDetailPath(item.slug!),
    SearchCategory.listings => AppRoutes.marketplaceDetailPath(item.id), SearchCategory.events => AppRoutes.eventDetailPath(item.id),
    SearchCategory.forum when item.forumSlug != null => AppRoutes.threadPath(item.forumSlug!, item.id), _ => null,
  };
  if (path != null) context.push(path);
}