class BoostPaymentMethod {
  final String id;
  final String brand;
  final String last4;
  final String status;
  const BoostPaymentMethod({required this.id, required this.brand, required this.last4, required this.status});
  factory BoostPaymentMethod.fromJson(Map<String, dynamic> json) => BoostPaymentMethod(id: json['id']?.toString() ?? '', brand: json['brand']?.toString() ?? '', last4: json['last4']?.toString() ?? '', status: json['status']?.toString() ?? 'active');
}

class BoostTargetPreview {
  final String title;
  final String? subtitle;
  final String? imagePath;
  final String? route;
  final String? countryCode;
  final String? regionName;
  final Map<String, dynamic> data;
  const BoostTargetPreview({required this.title, this.subtitle, this.imagePath, this.route, this.countryCode, this.regionName, this.data = const {}});
  factory BoostTargetPreview.fromJson(Map<String, dynamic> json) => BoostTargetPreview(title: json['title']?.toString() ?? '', subtitle: json['subtitle']?.toString(), imagePath: (json['image_path'] ?? json['image_url'])?.toString(), route: json['route']?.toString(), countryCode: json['country_code']?.toString(), regionName: json['region_name']?.toString(), data: json);
}

class BoostQuote {
  final bool eligible;
  final String? reason;
  final BoostTargetPreview? target;
  final String? objective;
  final List<String> placements;
  final int budgetMinor;
  final int days;
  final int dailyBudgetMinor;
  final int cpmMinor;
  final int estimatedImpressions;
  final int estimatedReach;
  final String currencyCode;
  final String? accountId;
  final String billingStatus;
  final int creditBalanceMinor;
  final int thresholdMinor;
  final BoostPaymentMethod? paymentMethod;
  final bool paymentReady;
  final List<int> presets;
  final int minBudgetMinor;
  final int maxBudgetMinor;
  final List<int> durationsDays;
  const BoostQuote({required this.eligible, this.reason, this.target, this.objective, this.placements = const [], this.budgetMinor = 0, this.days = 0, this.dailyBudgetMinor = 0, this.cpmMinor = 0, this.estimatedImpressions = 0, this.estimatedReach = 0, this.currencyCode = 'EUR', this.accountId, this.billingStatus = 'ok', this.creditBalanceMinor = 0, this.thresholdMinor = 0, this.paymentMethod, this.paymentReady = false, this.presets = const [], this.minBudgetMinor = 0, this.maxBudgetMinor = 0, this.durationsDays = const []});
  factory BoostQuote.fromJson(Map<String, dynamic> json) => BoostQuote(eligible: json['eligible'] == true, reason: json['reason']?.toString(), target: json['target'] is Map ? BoostTargetPreview.fromJson(Map<String, dynamic>.from(json['target'] as Map)) : null, objective: json['objective']?.toString(), placements: _strings(json['placements']), budgetMinor: _int(json['budget_minor']), days: _int(json['days']), dailyBudgetMinor: _int(json['daily_budget_minor']), cpmMinor: _int(json['cpm_minor']), estimatedImpressions: _int(json['estimated_impressions']), estimatedReach: _int(json['estimated_reach']), currencyCode: json['currency_code']?.toString() ?? 'EUR', accountId: json['account_id']?.toString(), billingStatus: json['billing_status']?.toString() ?? 'ok', creditBalanceMinor: _int(json['credit_balance_minor']), thresholdMinor: _int(json['threshold_minor']), paymentMethod: json['payment_method'] is Map ? BoostPaymentMethod.fromJson(Map<String, dynamic>.from(json['payment_method'] as Map)) : null, paymentReady: json['payment_ready'] == true, presets: _ints(json['presets']), minBudgetMinor: _int(json['min_budget_minor']), maxBudgetMinor: _int(json['max_budget_minor']), durationsDays: _ints(json['durations_days']));
}

class BoostResult {
  final String campaignId;
  final String accountId;
  final String status;
  final DateTime endsAt;
  final int dailyBudgetMinor;
  final bool autoApproved;
  const BoostResult({required this.campaignId, required this.accountId, required this.status, required this.endsAt, required this.dailyBudgetMinor, required this.autoApproved});
  factory BoostResult.fromJson(Map<String, dynamic> json) => BoostResult(campaignId: json['campaign_id'].toString(), accountId: json['account_id'].toString(), status: json['status']?.toString() ?? 'in_review', endsAt: _date(json['ends_at'])!, dailyBudgetMinor: _int(json['daily_budget_minor']), autoApproved: json['auto_approved'] == true);
}

class BoostStatus {
  final String campaignId;
  final String status;
  final String? pauseReason;
  final DateTime? endsAt;
  final int totalBudgetMinor;
  final int spentMinor;
  final String currencyCode;
  final int impressions;
  final int clicks;
  final int conversions;
  const BoostStatus({required this.campaignId, required this.status, this.pauseReason, this.endsAt, required this.totalBudgetMinor, required this.spentMinor, required this.currencyCode, required this.impressions, required this.clicks, required this.conversions});
  factory BoostStatus.fromJson(Map<String, dynamic> json) => BoostStatus(campaignId: json['campaign_id'].toString(), status: json['status']?.toString() ?? '', pauseReason: json['pause_reason']?.toString(), endsAt: _date(json['ends_at']), totalBudgetMinor: _int(json['total_budget_minor']), spentMinor: _int(json['spent_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR', impressions: _int(json['impressions']), clicks: _int(json['clicks']), conversions: _int(json['conversions']));
}

class Boost {
  final String campaignId;
  final String accountId;
  final String targetType;
  final String targetId;
  final String title;
  final String status;
  final String? pauseReason;
  final DateTime startAt;
  final DateTime? endAt;
  final int totalBudgetMinor;
  final int spentMinor;
  final String currencyCode;
  final int impressions;
  final int clicks;
  final int conversions;
  final BoostTargetPreview destination;
  final DateTime createdAt;
  const Boost({required this.campaignId, required this.accountId, required this.targetType, required this.targetId, required this.title, required this.status, this.pauseReason, required this.startAt, this.endAt, required this.totalBudgetMinor, required this.spentMinor, required this.currencyCode, required this.impressions, required this.clicks, required this.conversions, required this.destination, required this.createdAt});
  bool get isActive => const {'active', 'in_review', 'scheduled', 'paused'}.contains(status);
  factory Boost.fromJson(Map<String, dynamic> json) => Boost(campaignId: json['campaign_id'].toString(), accountId: json['account_id'].toString(), targetType: json['target_type']?.toString() ?? '', targetId: json['target_id'].toString(), title: json['title']?.toString() ?? '', status: json['status']?.toString() ?? '', pauseReason: json['pause_reason']?.toString(), startAt: _date(json['start_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), endAt: _date(json['end_at']), totalBudgetMinor: _int(json['total_budget_minor']), spentMinor: _int(json['spent_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR', impressions: _int(json['impressions']), clicks: _int(json['clicks']), conversions: _int(json['conversions']), destination: BoostTargetPreview.fromJson(json['destination'] is Map ? Map<String, dynamic>.from(json['destination'] as Map) : const {}), createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true));
}

int _int(Object? value) => (value as num?)?.toInt() ?? 0;
DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
List<int> _ints(Object? value) => value is List ? value.map(_int).toList() : const [];
List<String> _strings(Object? value) => value is List ? value.map((item) => item.toString()).toList() : const [];