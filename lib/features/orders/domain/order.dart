import 'package:hb_social/core/widgets/hb_status_chip.dart';

enum OrderStatus { pendingPayment, paid, shipped, completed, cancelled, expired, refundRequested, refunded, disputed }

extension OrderStatusApi on OrderStatus {
  String get code => switch (this) { OrderStatus.pendingPayment => 'pending_payment', OrderStatus.refundRequested => 'refund_requested', _ => name };
  String get labelKey => 'orders.status.$code';
  HBStatusKind get chipKind => switch (this) { OrderStatus.pendingPayment || OrderStatus.refundRequested => HBStatusKind.pending, OrderStatus.paid || OrderStatus.shipped => HBStatusKind.info, OrderStatus.completed => HBStatusKind.approved, OrderStatus.disputed => HBStatusKind.rejected, _ => HBStatusKind.neutral };
  static OrderStatus parse(Object? value) => OrderStatus.values.firstWhere((item) => item.code == value, orElse: () => OrderStatus.pendingPayment);
}

class OrderPerson {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  const OrderPerson({required this.id, required this.username, required this.displayName, this.avatarUrl});
  factory OrderPerson.fromJson(Object? value) { final json = _map(value); return OrderPerson(id: json['id']?.toString() ?? '', username: json['username']?.toString() ?? '', displayName: json['display_name']?.toString() ?? '', avatarUrl: json['avatar_url']?.toString()); }
}

class Order {
  final String id;
  final String kind;
  final OrderStatus status;
  final String title;
  final String? listingId;
  final String? eventId;
  final String? imageUrl;
  final int amountMinor;
  final int shippingMinor;
  final int platformFeeMinor;
  final int totalMinor;
  final int sellerPayoutMinor;
  final String currencyCode;
  final String deliveryMethod;
  final Map<String, dynamic> shippingAddress;
  final String? trackingCarrier;
  final String? trackingCode;
  final String? checkoutUrl;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? paidAt;
  final DateTime? shippedAt;
  final DateTime? completedAt;
  final bool canConfirm;
  final bool canShip;
  final bool canReview;
  final OrderPerson? counterpart;

  const Order({required this.id, required this.kind, required this.status, required this.title, this.listingId, this.eventId, this.imageUrl, required this.amountMinor, required this.shippingMinor, required this.platformFeeMinor, required this.totalMinor, required this.sellerPayoutMinor, required this.currencyCode, required this.deliveryMethod, required this.shippingAddress, this.trackingCarrier, this.trackingCode, this.checkoutUrl, required this.createdAt, this.expiresAt, this.paidAt, this.shippedAt, this.completedAt, this.canConfirm = false, this.canShip = false, this.canReview = false, this.counterpart});
  factory Order.fromJson(Map<String, dynamic> json) => Order(id: json['id']?.toString() ?? '', kind: json['kind']?.toString() ?? 'listing', status: OrderStatusApi.parse(json['status']), title: json['title']?.toString() ?? '', listingId: json['listing_id']?.toString(), eventId: json['event_id']?.toString(), imageUrl: (json['image_url'] ?? json['media_path'])?.toString(), amountMinor: _int(json['amount_minor']), shippingMinor: _int(json['shipping_minor']), platformFeeMinor: _int(json['platform_fee_minor']), totalMinor: _int(json['total_minor']), sellerPayoutMinor: _int(json['seller_payout_minor']), currencyCode: json['currency_code']?.toString().trim() ?? 'EUR', deliveryMethod: json['delivery_method']?.toString() ?? 'pickup', shippingAddress: _map(json['shipping_address']), trackingCarrier: json['tracking_carrier']?.toString(), trackingCode: json['tracking_code']?.toString(), checkoutUrl: json['checkout_url']?.toString(), createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), expiresAt: _date(json['expires_at']), paidAt: _date(json['paid_at']), shippedAt: _date(json['shipped_at']), completedAt: _date(json['completed_at']), canConfirm: json['can_confirm'] as bool? ?? false, canShip: json['can_ship'] as bool? ?? false, canReview: json['can_review'] as bool? ?? false, counterpart: json['counterpart'] == null && json['counterpart_id'] == null ? null : OrderPerson.fromJson(json['counterpart'] ?? {'id': json['counterpart_id'], 'username': json['counterpart_username'], 'display_name': json['counterpart_name'], 'avatar_url': json['counterpart_avatar_url']}));
}

class OrderEvent {
  final String id;
  final String kind;
  final String? actorId;
  final DateTime createdAt;
  final Map<String, dynamic> data;
  const OrderEvent({required this.id, required this.kind, this.actorId, required this.createdAt, required this.data});
  factory OrderEvent.fromJson(Map<String, dynamic> json) => OrderEvent(id: json['id']?.toString() ?? '', kind: json['kind']?.toString() ?? 'created', actorId: json['actor_id']?.toString(), createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), data: _map(json['data']));
}

class OrderQuote {
  final String currencyCode;
  final int amountMinor;
  final int platformFeeMinor;
  final int totalMinor;
  final int sellerPayoutMinor;
  final int displayTotalMinor;
  final String displayCurrency;
  final bool purchasable;
  final String? reason;
  final List<String> deliveryMethods;
  final String sellerCurrency;
  const OrderQuote({required this.currencyCode, required this.amountMinor, required this.platformFeeMinor, required this.totalMinor, required this.sellerPayoutMinor, required this.displayTotalMinor, required this.displayCurrency, required this.purchasable, this.reason, required this.deliveryMethods, required this.sellerCurrency});
  factory OrderQuote.fromJson(Map<String, dynamic> json) => OrderQuote(currencyCode: json['currency_code']?.toString().trim() ?? 'EUR', amountMinor: _int(json['amount_minor']), platformFeeMinor: _int(json['platform_fee_minor']), totalMinor: _int(json['total_minor']), sellerPayoutMinor: _int(json['seller_payout_minor']), displayTotalMinor: _int(json['display_total_minor'] ?? json['total_minor']), displayCurrency: json['display_currency']?.toString().trim() ?? json['currency_code']?.toString().trim() ?? 'EUR', purchasable: json['purchasable'] as bool? ?? false, reason: json['not_purchasable_reason']?.toString(), deliveryMethods: (json['delivery_methods'] as List? ?? const []).map((item) => item.toString()).toList(), sellerCurrency: json['seller_currency']?.toString().trim() ?? json['currency_code']?.toString().trim() ?? 'EUR');
}

class OrderDetail {
  final Order order;
  final int displayTotalMinor;
  final String displayCurrency;
  final bool isBuyer;
  final bool isSeller;
  final OrderPerson buyer;
  final OrderPerson seller;
  final List<OrderEvent> events;
  final String? conversationId;
  final bool hasPayment;
  final String? ticketCode;
  const OrderDetail({required this.order, required this.displayTotalMinor, required this.displayCurrency, required this.isBuyer, required this.isSeller, required this.buyer, required this.seller, required this.events, this.conversationId, required this.hasPayment, this.ticketCode});
  factory OrderDetail.fromJson(Map<String, dynamic> json) { final orderJson = {..._map(json['order']), 'shipping_address': json['shipping_address'] ?? _map(json['order'])['shipping_address'], 'can_review': json['can_review']}; final event = _map(json['event']); return OrderDetail(order: Order.fromJson(orderJson), displayTotalMinor: _int(json['display_total_minor'] ?? orderJson['total_minor']), displayCurrency: json['display_currency']?.toString().trim() ?? orderJson['currency_code']?.toString().trim() ?? 'EUR', isBuyer: json['is_buyer'] as bool? ?? false, isSeller: json['is_seller'] as bool? ?? false, buyer: OrderPerson.fromJson(json['buyer']), seller: OrderPerson.fromJson(json['seller']), events: (json['events'] as List? ?? const []).whereType<Map>().map((item) => OrderEvent.fromJson(Map<String, dynamic>.from(item))).toList(), conversationId: json['conversation_id']?.toString(), hasPayment: json['has_payment'] as bool? ?? false, ticketCode: event['ticket_code']?.toString()); }
}

class OrderActionResult {
  final OrderStatus status;
  final bool needsStripeRefund;
  final String? paymentIntentId;
  const OrderActionResult({required this.status, required this.needsStripeRefund, this.paymentIntentId});
  factory OrderActionResult.fromJson(Map<String, dynamic> json) => OrderActionResult(status: OrderStatusApi.parse(json['status']), needsStripeRefund: json['needs_stripe_refund'] as bool? ?? false, paymentIntentId: json['payment_intent_id']?.toString());
}

class SellerAccountStatus {
  final bool exists;
  final String onboardingStatus;
  final bool chargesEnabled;
  final bool payoutsEnabled;
  final bool detailsSubmitted;
  final String defaultCurrency;
  final List<String> requirements;
  const SellerAccountStatus({required this.exists, required this.onboardingStatus, required this.chargesEnabled, required this.payoutsEnabled, required this.detailsSubmitted, required this.defaultCurrency, required this.requirements});
  bool get active => onboardingStatus == 'active' && chargesEnabled && payoutsEnabled;
  factory SellerAccountStatus.fromJson(Map<String, dynamic> json) => SellerAccountStatus(exists: json['exists'] as bool? ?? false, onboardingStatus: json['onboarding_status']?.toString() ?? 'pending', chargesEnabled: json['charges_enabled'] as bool? ?? false, payoutsEnabled: json['payouts_enabled'] as bool? ?? false, detailsSubmitted: json['details_submitted'] as bool? ?? false, defaultCurrency: json['default_currency']?.toString().toUpperCase() ?? 'EUR', requirements: (json['requirements'] is Map ? (_map(json['requirements'])['currently_due'] as List? ?? const []) : json['requirements'] as List? ?? const []).map((item) => item.toString()).toList());
}

class PayoutCurrencySummary { final String currencyCode; final int orders; final int grossMinor; final int feesMinor; final int netMinor; final int pendingMinor; const PayoutCurrencySummary({required this.currencyCode, required this.orders, required this.grossMinor, required this.feesMinor, required this.netMinor, required this.pendingMinor}); factory PayoutCurrencySummary.fromJson(Map<String, dynamic> json) => PayoutCurrencySummary(currencyCode: json['currency_code']?.toString() ?? 'EUR', orders: _int(json['orders']), grossMinor: _int(json['gross_minor']), feesMinor: _int(json['fees_minor']), netMinor: _int(json['net_minor']), pendingMinor: _int(json['pending_minor'])); }
class PayoutsSummary { final List<PayoutCurrencySummary> byCurrency; final int openOrders; final int completedOrders; const PayoutsSummary({required this.byCurrency, required this.openOrders, required this.completedOrders}); factory PayoutsSummary.fromJson(Map<String, dynamic> json) => PayoutsSummary(byCurrency: (json['by_currency'] as List? ?? const []).whereType<Map>().map((item) => PayoutCurrencySummary.fromJson(Map<String, dynamic>.from(item))).toList(), openOrders: _int(json['open_orders']), completedOrders: _int(json['completed_orders'])); }
class CheckoutResult { final Uri url; final String orderId; final String sessionId; final DateTime? expiresAt; const CheckoutResult({required this.url, required this.orderId, required this.sessionId, this.expiresAt}); factory CheckoutResult.fromJson(Map<String, dynamic> json) => CheckoutResult(url: Uri.parse(json['url'].toString()), orderId: json['order_id'].toString(), sessionId: json['session_id']?.toString() ?? '', expiresAt: _date(json['expires_at'])); }

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};