import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_filter_chips_row.dart';
import 'package:hb_social/core/widgets/hb_input.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/list_page_scaffold.dart';
import 'package:hb_social/features/search/domain/search_result.dart';
import 'package:hb_social/features/search/providers/search_providers.dart';

/// Ricerca screen: a query field plus seven cross-community category filters.
/// No backend yet, so results always resolve empty; below
/// the fold this renders a "start typing" state, loading skeleton, error or
/// "no results" state instead of any sample content.
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String categoryLabel(SearchCategory category) {
    switch (category) {
      case SearchCategory.all:
        return 'search.category_all'.tr();
      case SearchCategory.people:
        return 'search.category_people'.tr();
      case SearchCategory.groups:
        return 'search.category_groups'.tr();
      case SearchCategory.posts:
        return 'search.category_posts'.tr();
      case SearchCategory.listings:
        return 'search.category_listings'.tr();
      case SearchCategory.forum:
        return 'search.category_forum'.tr();
      case SearchCategory.hashtags:
        return 'search.category_hashtags'.tr();
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final category = ref.watch(searchCategoryProvider);
    final results = ref.watch(searchResultsProvider);

    return ListPageScaffold(
      title: 'nav.search'.tr(),
      filters: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HBInput(
            controller: _controller,
            hint: 'common.search_hint'.tr(),
            prefixIcon: const Icon(Icons.search_rounded, color: LightModeColors.lightOnSurfaceVariant),
            onChanged: (value) => ref.read(searchQueryProvider.notifier).state = value,
          ),
          const SizedBox(height: AppSpacing.md),
          HBFilterChipsRow(
            labels: SearchCategory.values.map(categoryLabel).toList(),
            selectedIndex: SearchCategory.values.indexOf(category),
            onChanged: (index) => ref.read(searchCategoryProvider.notifier).state = SearchCategory.values[index],
          ),
        ],
      ),
      body: query.trim().isEmpty
          ? HBCard(
              child: HBEmptyState(icon: Icons.manage_search_rounded, title: 'search.start_title'.tr(), message: 'search.start_message'.tr()),
            )
          : results.when(
              loading: () => const HBListSkeleton(showTrailing: false),
              error: (error, stackTrace) => HBCard(
                child: HBEmptyState(
                  icon: Icons.error_outline_rounded,
                  title: 'search.error_title'.tr(),
                  message: 'search.error_message'.tr(),
                  action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(searchResultsProvider)),
                ),
              ),
              data: (items) => HBCard(
                child: HBEmptyState(icon: Icons.search_off_rounded, title: 'search.empty_title'.tr(), message: 'search.empty_message'.tr()),
              ),
            ),
    );
  }
}
