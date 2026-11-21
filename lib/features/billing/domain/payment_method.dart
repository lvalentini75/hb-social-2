class BillingPaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final int expMonth;
  final int expYear;
  final String? countryCode;
  final bool isDefault;
  final String status;
  final String? lastFailureCode;
  final DateTime createdAt;

  const BillingPaymentMethod({required this.id, required this.brand, required this.last4, required this.expMonth, required this.expYear, this.countryCode, required this.isDefault, required this.status, this.lastFailureCode, required this.createdAt});

  factory BillingPaymentMethod.fromJson(Map<String, dynamic> json) => BillingPaymentMethod(
    id: json['id'].toString(),
    brand: json['brand']?.toString().toLowerCase() ?? 'card',
    last4: json['last4']?.toString() ?? '',
    expMonth: (json['exp_month'] as num?)?.toInt() ?? 0,
    expYear: (json['exp_year'] as num?)?.toInt() ?? 0,
    countryCode: json['country_code']?.toString(),
    isDefault: json['is_default'] as bool? ?? false,
    status: json['status']?.toString() ?? 'active',
    lastFailureCode: json['last_failure_code']?.toString(),
    createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
  );
}