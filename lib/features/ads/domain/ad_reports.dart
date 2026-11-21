import 'package:hb_social/features/ads/domain/ad_models.dart';

class AdMetricTotals {
  final int impressions;
  final int clicks;
  final int conversions;
  final int spendMinor;
  final int reach;
  final int ctrBasisPoints;
  final int cpmMinor;
  final int cpcMinor;
  const AdMetricTotals({required this.impressions, required this.clicks, required this.conversions, required this.spendMinor, required this.reach, required this.ctrBasisPoints, required this.cpmMinor, required this.cpcMinor});
  factory AdMetricTotals.fromJson(Map<String, dynamic> json) => AdMetricTotals(impressions: _int(json['impressions']), clicks: _int(json['clicks']), conversions: _int(json['conversions']), spendMinor: _int(json['spend_minor']), reach: _int(json['reach']), ctrBasisPoints: _percentageBasisPoints(json['ctr']), cpmMinor: _int(json['cpm_minor']), cpcMinor: _int(json['cpc_minor']));
}

class AdDailyMetric {
  final DateTime day;
  final int impressions;
  final int clicks;
  final int spendMinor;
  const AdDailyMetric({required this.day, required this.impressions, required this.clicks, required this.spendMinor});
  factory AdDailyMetric.fromJson(Map<String, dynamic> json) => AdDailyMetric(day: DateTime.tryParse(json['day']?.toString() ?? '')?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0), impressions: _int(json['impressions']), clicks: _int(json['clicks']), spendMinor: _int(json['spend_minor']));
}

class AdsDashboard {
  final int days;
  final int accounts;
  final int activeCampaigns;
  final int inReview;
  final int rejected;
  final int pausedPayment;
  final int pausedSpendCap;
  final int billingIssues;
  final int missingPaymentMethod;
  final int unbilledMinor;
  final int outstandingMinor;
  final AdMetricTotals totals;
  final AdMetricTotals previous;
  final List<AdDailyMetric> daily;
  final List<Map<String, dynamic>> currencies;
  final List<Map<String, dynamic>> topCampaigns;
  const AdsDashboard({required this.days, required this.accounts, required this.activeCampaigns, required this.inReview, required this.rejected, required this.pausedPayment, required this.pausedSpendCap, required this.billingIssues, required this.missingPaymentMethod, required this.unbilledMinor, required this.outstandingMinor, required this.totals, required this.previous, required this.daily, required this.currencies, required this.topCampaigns});
  factory AdsDashboard.fromJson(Map<String, dynamic> json) => AdsDashboard(days: _int(json['days'], 7), accounts: _int(json['accounts']), activeCampaigns: _int(json['active_campaigns']), inReview: _int(json['in_review']), rejected: _int(json['rejected']), pausedPayment: _int(json['paused_payment']), pausedSpendCap: _int(json['paused_spend_cap']), billingIssues: _int(json['billing_issues']), missingPaymentMethod: _int(json['missing_payment_method']), unbilledMinor: _int(json['unbilled_minor']), outstandingMinor: _int(json['outstanding_minor']), totals: AdMetricTotals.fromJson(_map(json['totals'])), previous: AdMetricTotals.fromJson(_map(json['previous'])), daily: _maps(json['daily']).map(AdDailyMetric.fromJson).toList(), currencies: _maps(json['currencies']), topCampaigns: _maps(json['top_campaigns']));
}

class AdCampaignAggregateReport {
  final AdCampaign campaign;
  final String accountName;
  final AdMetricTotals totals;
  final List<AdDailyMetric> daily;
  final List<Map<String, dynamic>> byPlacement;
  final List<Map<String, dynamic>> adSets;
  const AdCampaignAggregateReport({required this.campaign, required this.accountName, required this.totals, required this.daily, required this.byPlacement, required this.adSets});
  factory AdCampaignAggregateReport.fromJson(Map<String, dynamic> json) { final campaign = _map(json['campaign']); return AdCampaignAggregateReport(campaign: AdCampaign.fromJson(campaign), accountName: (campaign['account_name'] ?? json['account_name'] ?? '').toString(), totals: AdMetricTotals.fromJson(_map(json['totals'])), daily: _maps(json['daily']).map(AdDailyMetric.fromJson).toList(), byPlacement: _maps(json['by_placement']), adSets: _maps(json['ad_sets'])); }
}

class AdAccountBilling {
  final String accountId;
  final String currencyCode;
  final String billingStatus;
  final String? pauseReason;
  final bool ownerIsMe;
  final int unbilledMinor;
  final int billedMinor;
  final int lifetimeSpendMinor;
  final int thresholdMinor;
  final int thresholdLevel;
  final int thresholdProgress;
  final int creditBalanceMinor;
  final int? spendCapMinor;
  final int outstandingMinor;
  final DateTime? nextCutoffOn;
  final Map<String, dynamic>? paymentMethod;
  final List<AdDailyMetric> dailySpend;
  final List<Map<String, dynamic>> charges;
  final List<Map<String, dynamic>> credits;
  final List<Map<String, dynamic>> byCampaign;
  const AdAccountBilling({required this.accountId, required this.currencyCode, required this.billingStatus, this.pauseReason, required this.ownerIsMe, required this.unbilledMinor, required this.billedMinor, required this.lifetimeSpendMinor, required this.thresholdMinor, required this.thresholdLevel, required this.thresholdProgress, required this.creditBalanceMinor, this.spendCapMinor, required this.outstandingMinor, this.nextCutoffOn, this.paymentMethod, required this.dailySpend, required this.charges, required this.credits, required this.byCampaign});
  factory AdAccountBilling.fromJson(Map<String, dynamic> json) => AdAccountBilling(accountId: json['account_id'].toString(), currencyCode: json['currency_code']?.toString() ?? 'EUR', billingStatus: json['billing_status']?.toString() ?? 'ok', pauseReason: json['pause_reason']?.toString(), ownerIsMe: json['owner_is_me'] as bool? ?? false, unbilledMinor: _int(json['unbilled_minor']), billedMinor: _int(json['billed_minor']), lifetimeSpendMinor: _int(json['lifetime_spend_minor']), thresholdMinor: _int(json['threshold_minor']), thresholdLevel: _int(json['threshold_level']), thresholdProgress: _int(json['threshold_progress_pct']).clamp(0, 100), creditBalanceMinor: _int(json['credit_balance_minor']), spendCapMinor: json['spend_cap_minor'] == null ? null : _int(json['spend_cap_minor']), outstandingMinor: _int(json['outstanding_minor']), nextCutoffOn: DateTime.tryParse(json['next_cutoff_on']?.toString() ?? '')?.toLocal(), paymentMethod: json['payment_method'] is Map ? _map(json['payment_method']) : null, dailySpend: _maps(json['daily_spend']).map(AdDailyMetric.fromJson).toList(), charges: _maps(json['charges']), credits: _maps(json['credits']), byCampaign: _maps(json['by_campaign']));
}

class AdAccountReport {
  final AdAccount account;
  final AdMetricTotals totals;
  final List<AdDailyMetric> daily;
  final List<Map<String, dynamic>> campaigns;
  final int members;
  final int audiences;
  final int creatives;
  const AdAccountReport({required this.account, required this.totals, required this.daily, required this.campaigns, required this.members, required this.audiences, required this.creatives});
  factory AdAccountReport.fromJson(Map<String, dynamic> json) => AdAccountReport(account: AdAccount.fromJson(_map(json['account'])), totals: AdMetricTotals.fromJson(_map(json['totals'])), daily: _maps(json['daily']).map(AdDailyMetric.fromJson).toList(), campaigns: _maps(json['campaigns']), members: _count(json['members']), audiences: _count(json['audiences']), creatives: _count(json['creatives']));
}

class AdReviewItem {
  final String creativeId;
  final String accountId;
  final String accountName;
  final String ownerId;
  final String ownerUsername;
  final AdCreative creative;
  final List<Map<String, dynamic>> campaigns;
  final bool isBoost;
  const AdReviewItem({required this.creativeId, required this.accountId, required this.accountName, required this.ownerId, required this.ownerUsername, required this.creative, required this.campaigns, this.isBoost = false});
  factory AdReviewItem.fromJson(Map<String, dynamic> json) => AdReviewItem(creativeId: json['creative_id'].toString(), accountId: json['account_id'].toString(), accountName: json['account_name']?.toString() ?? '', ownerId: json['owner_id']?.toString() ?? '', ownerUsername: json['owner_username']?.toString() ?? '', creative: AdCreative.fromJson({...json, 'id': json['creative_id'], 'rejection_reason': json['review_note'], 'created_at': json['created_at']}), campaigns: _maps(json['campaigns']), isBoost: json['is_boost'] == true || json['review_note'] == 'auto_boost');
}

int _int(Object? value, [int fallback = 0]) => (value as num?)?.toInt() ?? fallback;
int _count(Object? value) => value is List ? value.length : _int(value);
int _percentageBasisPoints(Object? value) { if (value is int) return value; if (value is num) return (value * 100).round(); return 0; }
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _maps(Object? value) => value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : const [];