import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/admin_data_table.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';

/// Shared dense list chrome for the admin console.
class AdminListPage extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> actions;
  final Widget filters;
  final List<AdminKpiValue> kpis;
  final List<String>? headers;
  final List<List<Widget>> rows;
  final List<double>? columnWidths;
  final String emptyMessage;
  final bool isLoading;
  final Widget? content;
  final List<VoidCallback?> rowCallbacks;
  final bool hasMore;
  final bool isLoadingMore;
  final VoidCallback? onLoadMore;
  final VoidCallback? onRetry;

  const AdminListPage({super.key, required this.title, required this.description, this.actions = const [], required this.filters, this.kpis = const [], this.headers, this.rows = const [], this.columnWidths, required this.emptyMessage, this.isLoading = false, this.content, this.rowCallbacks = const [], this.hasMore = false, this.isLoadingMore = false, this.onLoadMore, this.onRetry});

  @override
  Widget build(BuildContext context) => CustomScrollView(
    slivers: [
      SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AdminListHeader(title: title, description: description, actions: actions),
            const SizedBox(height: AppSpacing.md),
            HBCard(radius: AppRadius.sm, padding: const EdgeInsets.all(AppSpacing.md), child: filters),
            if (kpis.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), AdminKpiRow(values: kpis)],
            const SizedBox(height: AppSpacing.md),
            HBCard(
              radius: AppRadius.sm,
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                   content ?? (onRetry != null ? Center(child: Padding(padding: const EdgeInsets.all(AppSpacing.xl), child: HBButton.secondary(label: 'common.retry'.tr(), onPressed: onRetry, icon: Icons.refresh))) : AdminDataTable(headers: headers!, rows: rows, emptyMessage: emptyMessage, isLoading: isLoading, columnWidths: columnWidths, rowCallbacks: rowCallbacks)),
                  const Divider(height: AppSpacing.lg),
                   AdminPaginationFooter(hasMore: hasMore, isLoading: isLoadingMore, onLoadMore: onLoadMore),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    ],
  );
}

class AdminListHeader extends StatelessWidget {
  final String title;
  final String description;
  final List<Widget> actions;

  const AdminListHeader({super.key, required this.title, required this.description, required this.actions});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final heading = Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: context.textStyles.headlineSmall?.withColor(LightModeColors.lightOnSurface).copyWith(fontSize: 22, fontWeight: FontWeight.w700)), const SizedBox(height: AppSpacing.xs), Text(description, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]);
      if (constraints.maxWidth < 700) return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [heading, if (actions.isNotEmpty) ...[const SizedBox(height: AppSpacing.md), Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions)]]);
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [Expanded(child: heading), if (actions.isNotEmpty) Wrap(spacing: AppSpacing.sm, runSpacing: AppSpacing.sm, children: actions)]);
    },
  );
}

class AdminKpiValue {
  final String label;
  final String value;
  final Widget? detail;
  const AdminKpiValue({required this.label, required this.value, this.detail});
}

class AdminKpiRow extends StatelessWidget {
  final List<AdminKpiValue> values;
  const AdminKpiRow({super.key, required this.values});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: constraints.maxWidth >= 800 ? values.length : 2,
      childAspectRatio: constraints.maxWidth >= 800 ? 3.6 : 2.8,
      crossAxisSpacing: AppSpacing.sm,
      mainAxisSpacing: AppSpacing.sm,
      children: [for (final value in values) HBCard(radius: AppRadius.sm, padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm), child: Row(children: [Expanded(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(value.label, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant)), if (value.detail != null) ...[const SizedBox(height: 4), value.detail!]])), Text(value.value, style: context.textStyles.titleLarge?.withColor(LightModeColors.lightOnSurface).bold)]))],
    ),
  );
}

class AdminPaginationFooter extends StatelessWidget {
  final bool hasMore;
  final bool isLoading;
  final VoidCallback? onLoadMore;
  const AdminPaginationFooter({super.key, this.hasMore = false, this.isLoading = false, this.onLoadMore});

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.end,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: AppSpacing.sm,
    runSpacing: AppSpacing.sm,
     children: [HBButton.secondary(label: 'admin.p05b.loadMore'.tr(), onPressed: hasMore && !isLoading ? onLoadMore : null, icon: isLoading ? Icons.hourglass_top : Icons.add, size: HBButtonSize.sm)],
  );
}

class AdminCompactDropdown extends StatelessWidget {
  final String label;
  final List<String> items;
  final ValueChanged<int>? onSelected;
  final bool enabled;

  const AdminCompactDropdown({super.key, required this.label, required this.items, this.onSelected, this.enabled = true});

  @override
  Widget build(BuildContext context) => PopupMenuButton<int>(
    enabled: enabled,
    onSelected: onSelected,
    itemBuilder: (context) => [for (var i = 0; i < items.length; i++) PopupMenuItem(value: i, child: Text(items[i]))],
    child: Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(color: LightModeColors.lightBackgroundSoft, borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [Text(label, style: context.textStyles.bodySmall?.withColor(enabled ? LightModeColors.lightOnSurface : LightModeColors.lightTextTertiary)), const SizedBox(width: AppSpacing.xs), Icon(Icons.arrow_drop_down, size: 18, color: enabled ? LightModeColors.lightOnSurfaceVariant : LightModeColors.lightTextTertiary)]),
    ),
  );
}