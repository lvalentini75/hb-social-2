class FinanceOrder {
  final String id;
  final String kind;
  final String status;
  final String title;
  final String buyerId;
  final String sellerId;
  final String buyerName;
  final String sellerName;
  final int totalMinor;
  final int feeMinor;
  final String currencyCode;
  final bool hasPayment;
  final DateTime createdAt;
  const FinanceOrder({required this.id, required this.kind, required this.status, required this.title, required this.buyerId, required this.sellerId, required this.buyerName, required this.sellerName, required this.totalMinor, required this.feeMinor, required this.currencyCode, required this.hasPayment, required this.createdAt});
  factory FinanceOrder.fromJson(Map<String, dynamic> json, Map<String, String> names) => FinanceOrder(id: json['id'].toString(), kind: json['kind']?.toString() ?? 'listing', status: json['status']?.toString() ?? '', title: json['title']?.toString() ?? '', buyerId: json['buyer_id']?.toString() ?? '', sellerId: json['seller_id']?.toString() ?? '', buyerName: names[json['buyer_id']?.toString()] ?? '', sellerName: names[json['seller_id']?.toString()] ?? '', totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0, feeMinor: (json['platform_fee_minor'] as num?)?.toInt() ?? 0, currencyCode: json['currency_code']?.toString().trim() ?? 'EUR', hasPayment: json['payment_intent_id'] != null, createdAt: DateTime.parse(json['created_at'].toString()).toUtc());
}

class FinanceSeller {
  final String userId;
  final String name;
  final String status;
  final bool chargesEnabled;
  final String currencyCode;
  final int orderCount;
  final int revenueMinor;
  const FinanceSeller({required this.userId, required this.name, required this.status, required this.chargesEnabled, required this.currencyCode, required this.orderCount, required this.revenueMinor});
}

class StripeEventRecord {
  final String id;
  final String? orderId;
  final String type;
  final String result;
  final DateTime receivedAt;
  final DateTime? processedAt;
  const StripeEventRecord({required this.id, this.orderId, required this.type, required this.result, required this.receivedAt, this.processedAt});
  bool get stalled => processedAt == null && DateTime.now().toUtc().difference(receivedAt) > const Duration(minutes: 5);
  factory StripeEventRecord.fromJson(Map<String, dynamic> json) => StripeEventRecord(id: json['id'].toString(), orderId: json['order_id']?.toString(), type: json['type']?.toString() ?? '', result: json['result']?.toString() ?? '', receivedAt: DateTime.parse((json['received_at'] ?? json['created_at']).toString()).toUtc(), processedAt: json['processed_at'] == null ? null : DateTime.tryParse(json['processed_at'].toString())?.toUtc());
}

class FinanceCurrencyKpi {
  final String currencyCode;
  final int paidOrders;
  final int grossMinor;
  final int feesMinor;
  final int refunds;
  final int disputes;
  const FinanceCurrencyKpi({required this.currencyCode, required this.paidOrders, required this.grossMinor, required this.feesMinor, required this.refunds, required this.disputes});
}

class FinanceSnapshot {
  final List<FinanceOrder> orders;
  final List<FinanceSeller> sellers;
  final List<StripeEventRecord> stripeEvents;
  final List<FinanceCurrencyKpi> kpis;
  final Map<String, Map<String, dynamic>> settings;
  const FinanceSnapshot({required this.orders, required this.sellers, required this.stripeEvents, required this.kpis, required this.settings});
}