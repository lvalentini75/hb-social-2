import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hb_social/core/i18n/money_formatter.dart';
import 'package:hb_social/core/router/app_router.dart';
import 'package:hb_social/core/theme/app_theme.dart';
import 'package:hb_social/core/widgets/hb_avatar.dart';
import 'package:hb_social/core/widgets/hb_badge.dart';
import 'package:hb_social/core/widgets/hb_button.dart';
import 'package:hb_social/core/widgets/hb_card.dart';
import 'package:hb_social/core/widgets/hb_empty_state.dart';
import 'package:hb_social/core/widgets/hb_list_item_skeleton.dart';
import 'package:hb_social/core/widgets/hb_segmented_tabs.dart';
import 'package:hb_social/core/widgets/hb_status_chip.dart';
import 'package:hb_social/core/widgets/page_columns.dart';
import 'package:hb_social/features/orders/domain/order.dart';
import 'package:hb_social/features/orders/providers/order_providers.dart';

class OrdersPage extends ConsumerStatefulWidget {
  final String initialRole;
  const OrdersPage({super.key, this.initialRole = 'buyer'});
  @override ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  late int role = widget.initialRole == 'seller' ? 1 : 0;
  int filter = 0;
  String get roleCode => role == 0 ? 'buyer' : 'seller';
  String? get status => switch (filter) { 0 => 'open', 1 => 'completed', 2 => 'refunds', 3 => 'disputed', _ => null };
  @override
  Widget build(BuildContext context) {
    final key = OrdersFilter(roleCode, status);
    final value = ref.watch(ordersProvider(key));
    final content = value.when<List<Widget>>(
      loading: () => [const SliverToBoxAdapter(child: HBListSkeleton())],
      error: (_, __) => [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.receipt_long_outlined, title: 'orders.error_title'.tr(), message: 'orders.error_message'.tr(), action: HBButton.secondary(label: 'common.retry'.tr(), onPressed: () => ref.invalidate(ordersProvider(key))))))],
      data: (state) => state.items.isEmpty
          ? [SliverToBoxAdapter(child: HBCard(child: HBEmptyState(icon: Icons.receipt_long_outlined, title: 'orders.empty.$roleCode'.tr(), message: 'orders.empty.${roleCode}_message'.tr(), action: HBButton.primary(label: role == 0 ? 'orders.browse'.tr() : 'orders.activate_payments'.tr(), onPressed: () => context.push(role == 0 ? AppRoutes.marketplace : AppRoutes.paymentSettings)))))]
          : [SliverList.separated(itemCount: state.items.length, separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md), itemBuilder: (_, index) => OrderListCard(order: state.items[index], sellerView: role == 1)), if (state.loadingMore) const SliverToBoxAdapter(child: HBListSkeleton())],
    );
    return PageColumns(center: NotificationListener<ScrollNotification>(onNotification: (event) { if (event.metrics.extentAfter < 400) ref.read(ordersProvider(key).notifier).loadMore(); return false; }, child: CustomScrollView(slivers: [SliverPadding(padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg), sliver: SliverList.list(children: [Text('orders.title'.tr(), style: context.textStyles.headlineSmall), const SizedBox(height: AppSpacing.md), HBSegmentedTabs(labels: ['orders.buyer'.tr(), 'orders.seller'.tr()], selectedIndex: role, onChanged: (index) => setState(() => role = index)), const SizedBox(height: AppSpacing.sm), HBSegmentedTabs(labels: ['orders.filters.open'.tr(), 'orders.filters.completed'.tr(), 'p34b.filters.refunds'.tr(), 'p34b.filters.disputes'.tr(), 'orders.filters.all'.tr()], selectedIndex: filter, scrollable: true, onChanged: (index) => setState(() => filter = index)), const SizedBox(height: AppSpacing.md)])), ...content, const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl))])));
  }
}

class OrderListCard extends StatelessWidget {
  final Order order;
  final bool sellerView;
  const OrderListCard({super.key, required this.order, required this.sellerView});
  @override Widget build(BuildContext context) => GestureDetector(onTap: () => context.push(AppRoutes.orderPath(order.id)), child: HBCard(child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [ClipRRect(borderRadius: BorderRadius.circular(AppRadius.sm), child: SizedBox(width: 88, height: 88, child: order.imageUrl == null ? ColoredBox(color: LightModeColors.lightBackgroundSoft, child: Icon(order.kind == 'event_ticket' ? Icons.confirmation_number_outlined : Icons.image_outlined)) : Image.network(order.imageUrl!, fit: BoxFit.cover))), const SizedBox(width: AppSpacing.md), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Row(children: [Expanded(child: Text(order.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.textStyles.titleMedium)), if (order.canShip || order.canConfirm || sellerView && order.status == OrderStatus.refundRequested) HBBadge.label(label: 'orders.action_required'.tr(), emphasized: true)]), const SizedBox(height: 4), HBStatusChip(kind: order.status.chipKind, label: order.status.labelKey.tr()), const SizedBox(height: 4), Text(sellerView ? 'orders.payout'.tr(namedArgs: {'amount': _money(context, order.sellerPayoutMinor, order.currencyCode)}) : _money(context, order.totalMinor, order.currencyCode), style: context.textStyles.bodyMedium?.bold), if (order.counterpart != null) Row(children: [HBAvatar(name: order.counterpart!.displayName, imageUrl: order.counterpart!.avatarUrl, size: 24), const SizedBox(width: 6), Expanded(child: Text(order.counterpart!.displayName, overflow: TextOverflow.ellipsis))]), Text(DateFormat.yMd(context.locale.toString()).format(order.createdAt.toLocal()), style: context.textStyles.bodySmall?.withColor(LightModeColors.lightOnSurfaceVariant))]))])));
}

String _money(BuildContext context, int amount, String currency) => MoneyFormatter.format(amountMinor: amount, currencyCode: currency, locale: context.locale);