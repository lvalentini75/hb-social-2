class AdminListingReviewItem {
  final Map<String, dynamic> data;
  const AdminListingReviewItem(this.data);
  factory AdminListingReviewItem.fromJson(Map<String, dynamic> json) => AdminListingReviewItem(json);
  String get id => data['id'].toString();
  String get title => data['title']?.toString() ?? '';
  String get reviewStatus => data['review_status']?.toString() ?? 'pending';
  String get status => data['status']?.toString() ?? 'draft';
  String get currencyCode => data['currency_code']?.toString() ?? 'EUR';
  int get priceMinor => _int(data['price_minor']);
  int get total => _int(data['total']);
  DateTime? get requestedAt => _date(data['review_requested_at']);
  List<Map<String, dynamic>> get media => _maps(data['media']);
  Map<String, dynamic> get attributes => _map(data['attributes']);
}

class AdminListingsStats {
  final Map<String, dynamic> data;
  const AdminListingsStats(this.data);
  factory AdminListingsStats.fromJson(Map<String, dynamic> json) => AdminListingsStats(json);
  int value(String key) => _int(data[key]);
  List<Map<String, dynamic>> get categories => _maps(data['categories']);
}

class AdminOrderRecord {
  final Map<String, dynamic> data;
  const AdminOrderRecord(this.data);
  factory AdminOrderRecord.fromJson(Map<String, dynamic> json) => AdminOrderRecord(json);
  String get id => data['id'].toString();
  String get title => data['title']?.toString() ?? '';
  String get status => data['status']?.toString() ?? 'pending_payment';
  String get kind => data['kind']?.toString() ?? 'listing';
  String get currencyCode => data['currency_code']?.toString() ?? 'EUR';
  int get totalMinor => _int(data['total_minor']);
  int get total => _int(data['total']);
  DateTime? get createdAt => _date(data['created_at']);
}

class AdminPromoCode {
  final Map<String, dynamic> data;
  const AdminPromoCode(this.data);
  factory AdminPromoCode.fromJson(Map<String, dynamic> json) => AdminPromoCode(json);
  String get id => data['id'].toString();
  String get code => data['code']?.toString() ?? '';
  String get status => data['status']?.toString() ?? 'active';
  String get currencyCode => data['currency_code']?.toString() ?? 'EUR';
  int get creditMinor => _int(data['credit_minor']);
  int get redeemedCount => _int(data['redeemed_count']);
  int? get maxRedemptions => data['max_redemptions'] == null ? null : _int(data['max_redemptions']);
}

class AdminAdCharge {
  final Map<String, dynamic> data;
  const AdminAdCharge(this.data);
  factory AdminAdCharge.fromJson(Map<String, dynamic> json) => AdminAdCharge(json);
  String get id => data['id'].toString();
  String get status => data['status']?.toString() ?? 'pending';
  String get currencyCode => data['currency_code']?.toString() ?? 'EUR';
  int get amountMinor => _int(data['amount_minor']);
  int get total => _int(data['total']);
  DateTime? get createdAt => _date(data['created_at']);
}

class AdminRevenueReport {
  final Map<String, dynamic> ads;
  final Map<String, dynamic> marketplace;
  final Map<String, dynamic> events;
  final Map<String, dynamic> promo;
  const AdminRevenueReport({required this.ads, required this.marketplace, required this.events, required this.promo});
  factory AdminRevenueReport.fromJson(Map<String, dynamic> json) => AdminRevenueReport(ads: _map(json['ads']), marketplace: _map(json['marketplace']), events: _map(json['events']), promo: _map(json['promo']));
}

Map<String, dynamic> p42Map(Object? value) => _map(value);
List<Map<String, dynamic>> p42Maps(Object? value) => _maps(value);
int p42Int(Object? value) => _int(value);
DateTime? p42Date(Object? value) => _date(value);
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
List<Map<String, dynamic>> _maps(Object? value) => value is List ? [for (final item in value) if (item is Map) Map<String, dynamic>.from(item)] : const [];
int _int(Object? value) => value is num ? value.toInt() : int.tryParse('$value') ?? 0;
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();