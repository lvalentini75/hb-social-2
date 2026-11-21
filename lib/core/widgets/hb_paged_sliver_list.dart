import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_button.dart';

/// Sliver list with shared loading, retry and cursor-pagination behavior.
class HBPagedSliverList<T> extends StatelessWidget {
  final AsyncValue<PagedState<T>> value;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final Widget loading;
  final Widget empty;
  final Widget error;
  final VoidCallback onRetry;
  final VoidCallback onLoadMore;
  final double spacing;

  const HBPagedSliverList({super.key, required this.value, required this.itemBuilder, required this.loading, required this.empty, required this.error, required this.onRetry, required this.onLoadMore, this.spacing = AppSpacing.md});

  @override
  Widget build(BuildContext context) => value.when(
    loading: () => SliverToBoxAdapter(child: loading),
    error: (failure, stackTrace) => SliverToBoxAdapter(child: error),
    data: (page) {
      if (page.items.isEmpty) return SliverToBoxAdapter(child: empty);
      final extraCount = page.hasMore ? 1 : 0;
      return SliverList.builder(
        itemCount: page.items.length + extraCount,
        itemBuilder: (context, index) {
          if (index == page.items.length) {
            return Padding(
              padding: EdgeInsets.only(top: spacing),
              child: page.isLoadingMore
                  ? loading
                  : Center(child: HBButton.secondary(label: 'feed.load_more'.tr(), onPressed: onLoadMore)),
            );
          }
          return Padding(padding: EdgeInsets.only(bottom: index < page.items.length - 1 ? spacing : 0), child: itemBuilder(context, page.items[index], index));
        },
      );
    },
  );
}