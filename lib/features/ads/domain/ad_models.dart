import 'package:hb_social/features/ads/domain/ad_enums.dart';

class AdMoney {
  final int amountMinor;
  final String currencyCode;
  const AdMoney({required this.amountMinor, required this.currencyCode});
  factory AdMoney.fromJson(Map<String, dynamic> json, String amountKey) => AdMoney(amountMinor: (json[amountKey] as num?)?.toInt() ?? 0, currencyCode: json['currency_code']?.toString() ?? 'EUR');
  Map<String, dynamic> toJson(String amountKey) => {amountKey: amountMinor, 'currency_code': currencyCode};
}

class AdAccount {
  final String id;
  final String ownerId;
  final String name;
  final String currencyCode;
  final String kind;
  final AdAccountStatus status;
  final String? paymentMethodId;
  final String? pageId;
  final String? pageName;
  final String? pageAvatarUrl;
  final String? cardBrand;
  final String? cardLast4;
  final String billingStatus;
  final int lifetimeSpendMinor;
  final int activeCampaigns;
  final int totalCampaigns;
  final int billingThresholdMinor;
  final int unbilledSpendMinor;
  final int promotionalCreditMinor;
  final int? spendCapMinor;
  final AdAccountRole? myRole;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const AdAccount({required this.id, required this.ownerId, required this.name, required this.currencyCode, this.kind = 'business', required this.status, this.paymentMethodId, this.pageId, this.pageName, this.pageAvatarUrl, this.cardBrand, this.cardLast4, this.billingStatus = 'ok', this.lifetimeSpendMinor = 0, this.activeCampaigns = 0, this.totalCampaigns = 0, required this.billingThresholdMinor, required this.unbilledSpendMinor, required this.promotionalCreditMinor, this.spendCapMinor, this.myRole, required this.createdAt, this.updatedAt});
  factory AdAccount.fromJson(Map<String, dynamic> json) { final page = _map(json['page']); final payment = _map(json['payment_method']); return AdAccount(id: json['id'].toString(), ownerId: json['owner_id']?.toString() ?? '', name: json['name']?.toString() ?? '', currencyCode: json['currency_code']?.toString() ?? 'EUR', kind: json['kind']?.toString() ?? 'business', status: AdAccountStatusApi.parse(json['status']?.toString()), paymentMethodId: json['payment_method_id']?.toString(), pageId: json['page_id']?.toString(), pageName: (json['page_name'] ?? page['name'])?.toString(), pageAvatarUrl: (json['page_avatar_url'] ?? page['avatar_url'])?.toString(), cardBrand: (json['card_brand'] ?? payment['brand'])?.toString(), cardLast4: (json['card_last4'] ?? payment['last4'])?.toString(), billingStatus: json['billing_status']?.toString() ?? 'ok', lifetimeSpendMinor: _int(json['lifetime_spend_minor'] ?? (_int(json['lifetime_spend_micro']) ~/ 1000000)), activeCampaigns: _int(json['active_campaigns']), totalCampaigns: _int(json['total_campaigns'] ?? json['campaign_count']), billingThresholdMinor: _int(json['billing_threshold_minor']), unbilledSpendMinor: _int(json['unbilled_spend_minor'] ?? (_int(json['unbilled_micro']) ~/ 1000000)), promotionalCreditMinor: _int(json['credit_balance_minor'] ?? json['promotional_credit_minor'] ?? json['credit_minor']), spendCapMinor: _nullableInt(json['spend_cap_minor']), myRole: json['my_role'] == null && json['role'] == null ? null : AdAccountRoleApi.parse((json['my_role'] ?? json['role']).toString()), createdAt: _date(json['created_at']), updatedAt: _nullableDate(json['updated_at'])); }
  Map<String, dynamic> toJson() => {'id': id, 'owner_id': ownerId, 'name': name, 'currency_code': currencyCode, 'kind': kind, 'status': status.code, 'payment_method_id': paymentMethodId, 'billing_threshold_minor': billingThresholdMinor, 'unbilled_spend_minor': unbilledSpendMinor, 'promotional_credit_minor': promotionalCreditMinor, 'spend_cap_minor': spendCapMinor, 'my_role': myRole?.code, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt?.toIso8601String()};
}

class AdAccountMember {
  final String accountId;
  final String userId;
  final AdAccountRole role;
  final String? displayName;
  final String? username;
  final String? avatarUrl;
  final DateTime createdAt;
  const AdAccountMember({required this.accountId, required this.userId, required this.role, this.displayName, this.username, this.avatarUrl, required this.createdAt});
  factory AdAccountMember.fromJson(Map<String, dynamic> json) { final profile = _map(json['user'] ?? json['profile']); return AdAccountMember(accountId: json['account_id'].toString(), userId: json['user_id'].toString(), role: AdAccountRoleApi.parse(json['role']?.toString()), displayName: (profile['display_name'] ?? json['display_name'])?.toString(), username: (profile['username'] ?? json['username'])?.toString(), avatarUrl: (profile['avatar_url'] ?? json['avatar_url'])?.toString(), createdAt: _date(json['created_at'])); }
  Map<String, dynamic> toJson() => {'account_id': accountId, 'user_id': userId, 'role': role.code, 'created_at': createdAt.toIso8601String()};
}

class AdCampaign {
  final String id;
  final String accountId;
  final String name;
  final AdCampaignObjective objective;
  final AdCampaignStatus status;
  final DateTime startsAt;
  final DateTime? endsAt;
  final int budgetMinor;
  final int? dailyBudgetMinor;
  final String currencyCode;
  final String? rejectionReason;
  final String? pauseReason;
  final int spentMinor;
  final DateTime createdAt;
  final DateTime? updatedAt;
  const AdCampaign({required this.id, required this.accountId, required this.name, required this.objective, required this.status, required this.startsAt, this.endsAt, required this.budgetMinor, this.dailyBudgetMinor, required this.currencyCode, this.rejectionReason, this.pauseReason, this.spentMinor = 0, required this.createdAt, this.updatedAt});
  factory AdCampaign.fromJson(Map<String, dynamic> json) => AdCampaign(id: json['id'].toString(), accountId: json['account_id'].toString(), name: json['name']?.toString() ?? '', objective: AdCampaignObjectiveApi.parse(json['objective']?.toString()), status: AdCampaignStatusApi.parse(json['status']?.toString()), startsAt: _date(json['start_at'] ?? json['starts_at']), endsAt: _nullableDate(json['end_at'] ?? json['ends_at']), budgetMinor: _int(json['total_budget_minor'] ?? json['budget_minor']), dailyBudgetMinor: _nullableInt(json['daily_budget_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR', rejectionReason: (json['review_note'] ?? json['rejection_reason'])?.toString(), pauseReason: json['pause_reason']?.toString(), spentMinor: _int(json['spent_minor'] ?? (_int(json['spent_micro']) ~/ 1000000)), createdAt: _date(json['created_at']), updatedAt: _nullableDate(json['updated_at']));
  Map<String, dynamic> toJson() => {'id': id, 'account_id': accountId, 'name': name, 'objective': objective.code, 'status': status.code, 'starts_at': startsAt.toIso8601String(), 'ends_at': endsAt?.toIso8601String(), 'budget_minor': budgetMinor, 'daily_budget_minor': dailyBudgetMinor, 'currency_code': currencyCode, 'rejection_reason': rejectionReason, 'created_at': createdAt.toIso8601String(), 'updated_at': updatedAt?.toIso8601String()};
}

class AdAudience {
  final String id;
  final String accountId;
  final String name;
  final List<String> countryCodes;
  final List<String> regionIds;
  final List<String> interests;
  final List<String> speciesIds;
  final List<String> verificationLevels;
  final List<String> locales;
  final int estimatedReach;
  final int? ageMin;
  final int? ageMax;
  final DateTime createdAt;
  const AdAudience({required this.id, required this.accountId, required this.name, required this.countryCodes, required this.regionIds, required this.interests, this.speciesIds = const [], this.verificationLevels = const [], this.locales = const [], this.estimatedReach = 0, this.ageMin, this.ageMax, required this.createdAt});
  factory AdAudience.fromJson(Map<String, dynamic> json) => AdAudience(id: json['id'].toString(), accountId: json['account_id'].toString(), name: json['name']?.toString() ?? '', countryCodes: _strings(json['country_codes']), regionIds: _strings(json['region_ids']), interests: _strings(json['interests']), speciesIds: _strings(json['species_ids']), verificationLevels: _strings(json['verification_levels']), locales: _strings(json['locales']), estimatedReach: _int(json['estimated_reach']), ageMin: _nullableInt(json['age_min']), ageMax: _nullableInt(json['age_max']), createdAt: _date(json['created_at']));
  Map<String, dynamic> toJson() => {'id': id, 'account_id': accountId, 'name': name, 'country_codes': countryCodes, 'region_ids': regionIds, 'interests': interests, 'age_min': ageMin, 'age_max': ageMax, 'created_at': createdAt.toIso8601String()};
}

class AdSet {
  final String id;
  final String campaignId;
  final String name;
  final String? audienceId;
  final List<AdPlacement> placements;
  final String optimization;
  final int bidMinor;
  final int? dailyBudgetMinor;
  final int frequencyCap;
  final String pacing;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime createdAt;
  const AdSet({required this.id, required this.campaignId, required this.name, this.audienceId, required this.placements, required this.optimization, required this.bidMinor, this.dailyBudgetMinor, required this.frequencyCap, required this.pacing, this.startsAt, this.endsAt, required this.createdAt});
  factory AdSet.fromJson(Map<String, dynamic> json) => AdSet(id: json['id'].toString(), campaignId: json['campaign_id'].toString(), name: json['name']?.toString() ?? '', audienceId: json['audience_id']?.toString(), placements: _strings(json['placements']).map(AdPlacementApi.parse).toList(), optimization: json['optimization']?.toString() ?? 'cpm', bidMinor: _int(json['bid_minor']), dailyBudgetMinor: _nullableInt(json['daily_budget_minor']), frequencyCap: _int(json['frequency_cap'], fallback: 3), pacing: json['pacing']?.toString() ?? 'standard', startsAt: _nullableDate(json['starts_at']), endsAt: _nullableDate(json['ends_at']), createdAt: _date(json['created_at']));
  Map<String, dynamic> toJson() => {'id': id, 'campaign_id': campaignId, 'name': name, 'audience_id': audienceId, 'placements': placements.map((item) => item.code).toList(), 'optimization': optimization, 'bid_minor': bidMinor, 'daily_budget_minor': dailyBudgetMinor, 'frequency_cap': frequencyCap, 'pacing': pacing, 'starts_at': startsAt?.toIso8601String(), 'ends_at': endsAt?.toIso8601String(), 'created_at': createdAt.toIso8601String()};
}

class AdCreativeMedia {
  final String path;
  final String kind;
  final int sortOrder;
  final int? width;
  final int? height;
  final String? posterPath;
  const AdCreativeMedia({required this.path, required this.kind, this.sortOrder = 0, this.width, this.height, this.posterPath});
  factory AdCreativeMedia.fromJson(Map<String, dynamic> json) => AdCreativeMedia(path: json['path']?.toString() ?? '', kind: json['kind']?.toString() ?? 'image', sortOrder: _int(json['sort_order']), width: _nullableInt(json['width']), height: _nullableInt(json['height']), posterPath: json['poster_path']?.toString());
  Map<String, dynamic> toJson() => {'path': path, 'kind': kind, 'sort_order': sortOrder, if (width != null) 'width': width, if (height != null) 'height': height, if (posterPath != null) 'poster_path': posterPath};
}

class AdCreative {
  final String id;
  final String accountId;
  final AdCreativeKind kind;
  final String headline;
  final String body;
  final String callToAction;
  final String destinationType;
  final String? destinationId;
  final String? destinationUrl;
  final List<AdCreativeMedia> media;
  final String reviewStatus;
  final String? rejectionReason;
  final DateTime createdAt;
  const AdCreative({required this.id, required this.accountId, required this.kind, required this.headline, required this.body, required this.callToAction, required this.destinationType, this.destinationId, this.destinationUrl, required this.media, required this.reviewStatus, this.rejectionReason, required this.createdAt});
  factory AdCreative.fromJson(Map<String, dynamic> json) => AdCreative(id: json['id'].toString(), accountId: json['account_id'].toString(), kind: AdCreativeKindApi.parse(json['kind']?.toString()), headline: json['headline']?.toString() ?? '', body: json['body']?.toString() ?? '', callToAction: (json['cta'] ?? json['call_to_action'])?.toString() ?? 'learn_more', destinationType: json['destination_type']?.toString() ?? 'url', destinationId: json['destination_id']?.toString(), destinationUrl: json['destination_url']?.toString(), media: _mapList(json['media']).map(AdCreativeMedia.fromJson).toList(), reviewStatus: json['review_status']?.toString() ?? 'pending', rejectionReason: (json['review_note'] ?? json['rejection_reason'])?.toString(), createdAt: _date(json['created_at']));
  Map<String, dynamic> toJson() => {'id': id, 'account_id': accountId, 'kind': kind.code, 'headline': headline, 'body': body, 'call_to_action': callToAction, 'destination_type': destinationType, 'destination_id': destinationId, 'destination_url': destinationUrl, 'media': media.map((item) => item.toJson()).toList(), 'review_status': reviewStatus, 'rejection_reason': rejectionReason, 'created_at': createdAt.toIso8601String()};
}

class AdItem {
  final String id;
  final String adSetId;
  final String creativeId;
  final String name;
  final String status;
  final DateTime createdAt;
  const AdItem({required this.id, required this.adSetId, required this.creativeId, required this.name, required this.status, required this.createdAt});
  factory AdItem.fromJson(Map<String, dynamic> json) => AdItem(id: json['id'].toString(), adSetId: json['ad_set_id'].toString(), creativeId: json['creative_id'].toString(), name: json['name']?.toString() ?? '', status: json['status']?.toString() ?? 'draft', createdAt: _date(json['created_at']));
  Map<String, dynamic> toJson() => {'id': id, 'ad_set_id': adSetId, 'creative_id': creativeId, 'name': name, 'status': status, 'created_at': createdAt.toIso8601String()};
}

class AdCampaignReport {
  final String campaignId;
  final int impressions;
  final int clicks;
  final int conversions;
  final int spendMinor;
  final String currencyCode;
  const AdCampaignReport({required this.campaignId, required this.impressions, required this.clicks, required this.conversions, required this.spendMinor, required this.currencyCode});
  factory AdCampaignReport.fromJson(Map<String, dynamic> json) => AdCampaignReport(campaignId: json['campaign_id']?.toString() ?? '', impressions: _int(json['impressions']), clicks: _int(json['clicks']), conversions: _int(json['conversions']), spendMinor: _int(json['spend_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR');
  Map<String, dynamic> toJson() => {'campaign_id': campaignId, 'impressions': impressions, 'clicks': clicks, 'conversions': conversions, 'spend_minor': spendMinor, 'currency_code': currencyCode};
}

class AdBillingCharge {
  final String id;
  final String accountId;
  final int amountMinor;
  final String currencyCode;
  final AdBillingStatus status;
  final String? failureCode;
  final DateTime createdAt;
  final DateTime? chargedAt;
  const AdBillingCharge({required this.id, required this.accountId, required this.amountMinor, required this.currencyCode, required this.status, this.failureCode, required this.createdAt, this.chargedAt});
  factory AdBillingCharge.fromJson(Map<String, dynamic> json) => AdBillingCharge(id: json['id'].toString(), accountId: json['account_id'].toString(), amountMinor: _int(json['amount_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR', status: AdBillingStatusApi.parse(json['status']?.toString()), failureCode: json['failure_code']?.toString(), createdAt: _date(json['created_at']), chargedAt: _nullableDate(json['charged_at']));
  Map<String, dynamic> toJson() => {'id': id, 'account_id': accountId, 'amount_minor': amountMinor, 'currency_code': currencyCode, 'status': status.code, 'failure_code': failureCode, 'created_at': createdAt.toIso8601String(), 'charged_at': chargedAt?.toIso8601String()};
}

class AdCharge {
  final String id;
  final String accountId;
  final String reason;
  final String status;
  final int amountMinor;
  final String currencyCode;
  final DateTime createdAt;
  final DateTime? succeededAt;
  const AdCharge({required this.id, required this.accountId, required this.reason, required this.status, required this.amountMinor, required this.currencyCode, required this.createdAt, this.succeededAt});
  factory AdCharge.fromJson(Map<String, dynamic> json) => AdCharge(id: json['id'].toString(), accountId: json['account_id'].toString(), reason: json['reason']?.toString() ?? 'manual', status: json['status']?.toString() ?? 'pending', amountMinor: _int(json['amount_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR', createdAt: _date(json['created_at']), succeededAt: _nullableDate(json['succeeded_at']));
  Map<String, dynamic> toJson() => {'id': id, 'account_id': accountId, 'reason': reason, 'status': status, 'amount_minor': amountMinor, 'currency_code': currencyCode, 'created_at': createdAt.toIso8601String(), 'succeeded_at': succeededAt?.toIso8601String()};
}

class AdAccountCredit {
  final String id;
  final String accountId;
  final String kind;
  final int amountMinor;
  final String currencyCode;
  final DateTime createdAt;
  const AdAccountCredit({required this.id, required this.accountId, required this.kind, required this.amountMinor, required this.currencyCode, required this.createdAt});
  factory AdAccountCredit.fromJson(Map<String, dynamic> json) => AdAccountCredit(id: json['id'].toString(), accountId: json['account_id'].toString(), kind: json['kind']?.toString() ?? 'welcome', amountMinor: _int(json['amount_minor']), currencyCode: json['currency_code']?.toString() ?? 'EUR', createdAt: _date(json['created_at']));
  Map<String, dynamic> toJson() => {'id': id, 'account_id': accountId, 'kind': kind, 'amount_minor': amountMinor, 'currency_code': currencyCode, 'created_at': createdAt.toIso8601String()};
}

int _int(Object? value, {int fallback = 0}) => (value as num?)?.toInt() ?? fallback;
int? _nullableInt(Object? value) => (value as num?)?.toInt();
DateTime _date(Object? value) => DateTime.tryParse(value?.toString() ?? '')?.toUtc() ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
DateTime? _nullableDate(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : const {};
List<Map<String, dynamic>> _mapList(Object? value) => value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : const [];
List<String> _strings(Object? value) => value is List ? value.map((item) => item.toString()).toList() : const [];