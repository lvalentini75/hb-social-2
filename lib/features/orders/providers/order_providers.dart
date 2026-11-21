import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/orders/data/orders_repository.dart';
import 'package:hb_social/features/orders/data/payments_repository.dart';
import 'package:hb_social/features/orders/domain/order.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) => OrdersRepository(ref.watch(supabaseClientProvider)));
final paymentsRepositoryProvider = Provider<PaymentsRepository>((ref) => PaymentsRepository(ref.watch(supabaseClientProvider)));
final sellerAccountProvider = FutureProvider.autoDispose<SellerAccountStatus>((ref) => ref.watch(paymentsRepositoryProvider).connectStatus());
final payoutsSummaryProvider = FutureProvider.autoDispose<PayoutsSummary>((ref) => ref.watch(ordersRepositoryProvider).payoutsSummary());
final orderQuoteProvider = FutureProvider.autoDispose.family<OrderQuote, String>((ref, listingId) => ref.watch(ordersRepositoryProvider).quote(listingId, 'pickup'));

class OrdersFilter {
  final String role;
  final String? status;
  const OrdersFilter(this.role, this.status);
  @override bool operator ==(Object other) => other is OrdersFilter && other.role == role && other.status == status;
  @override int get hashCode => Object.hash(role, status);
}

class OrdersState { final List<Order> items; final bool hasMore; final bool loadingMore; const OrdersState({required this.items, required this.hasMore, this.loadingMore = false}); }
class OrdersNotifier extends AsyncNotifier<OrdersState> {
  final OrdersFilter filter;
  OrdersNotifier(this.filter);
  @override Future<OrdersState> build() => _load(0);
  Future<OrdersState> _load(int offset) async { final items = await ref.watch(ordersRepositoryProvider).myOrders(role: filter.role, status: filter.status, offset: offset); return OrdersState(items: items, hasMore: items.length == OrdersRepository.pageSize); }
  Future<void> loadMore() async { final current = state.value; if (current == null || !current.hasMore || current.loadingMore) return; state = AsyncData(OrdersState(items: current.items, hasMore: current.hasMore, loadingMore: true)); try { final next = await _load(current.items.length); state = AsyncData(OrdersState(items: [...current.items, ...next.items], hasMore: next.hasMore)); } catch (error, stack) { state = AsyncError(error, stack); } }
}
final ordersProvider = AsyncNotifierProvider.family<OrdersNotifier, OrdersState, OrdersFilter>((arg) => OrdersNotifier(arg));

class OrderDetailNotifier extends AsyncNotifier<OrderDetail> {
  final String id;
  OrderDetailNotifier(this.id);
  StreamSubscription<Map<String, dynamic>>? subscription;
  @override Future<OrderDetail> build() async { ref.onDispose(() => subscription?.cancel()); subscription = ref.read(ordersRepositoryProvider).watchOrder(id).listen((row) { if (row.isNotEmpty) ref.invalidateSelf(); }); return ref.watch(ordersRepositoryProvider).detail(id); }
  Future<void> refresh() async => ref.invalidateSelf();
}
final orderDetailProvider = AsyncNotifierProvider.family<OrderDetailNotifier, OrderDetail, String>((id) => OrderDetailNotifier(id));