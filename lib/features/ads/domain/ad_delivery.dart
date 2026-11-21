import 'package:hb_social/features/ads/domain/ad_enums.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';

class DeliveredAdvertiser {
  final String name;
  final String? avatarUrl;
  final String? pageSlug;
  final String? username;
  final String? pageId;
  final bool verified;
  const DeliveredAdvertiser({required this.name, this.avatarUrl, this.pageSlug, this.username, this.pageId, required this.verified});
  factory DeliveredAdvertiser.fromJson(Map<String, dynamic> json) => DeliveredAdvertiser(name: json['name']?.toString() ?? '', avatarUrl: json['avatar_url']?.toString(), pageSlug: json['page_slug']?.toString(), username: json['username']?.toString(), pageId: json['page_id']?.toString(), verified: json['verified'] == true);
}

class DeliveredAd {
  final String adId;
  final String campaignId;
  final String accountId;
  final AdPlacement placement;
  final String objective;
  final String bidType;
  final AdCreative creative;
  final Map<String, dynamic> destination;
  final DeliveredAdvertiser advertiser;
  final List<String> why;
  final bool isBoost;
  const DeliveredAd({required this.adId, required this.campaignId, required this.accountId, required this.placement, required this.objective, required this.bidType, required this.creative, required this.destination, required this.advertiser, required this.why, this.isBoost = false});
  factory DeliveredAd.fromJson(Map<String, dynamic> json) {
    final creative = Map<String, dynamic>.from(json['creative'] as Map? ?? const {});
    creative['account_id'] = json['account_id'];
    creative['review_status'] = 'approved';
    creative['created_at'] = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true).toIso8601String();
    return DeliveredAd(adId: json['ad_id'].toString(), campaignId: json['campaign_id'].toString(), accountId: json['account_id'].toString(), placement: AdPlacementApi.parse(json['placement']?.toString()), objective: json['objective']?.toString() ?? '', bidType: json['bid_type']?.toString() ?? '', creative: AdCreative.fromJson(creative), destination: Map<String, dynamic>.from(creative['destination'] as Map? ?? json['destination'] as Map? ?? const {}), advertiser: DeliveredAdvertiser.fromJson(Map<String, dynamic>.from(json['advertiser'] as Map? ?? const {})), why: (json['why'] as List? ?? const []).map((item) => item.toString()).toList(), isBoost: json['is_boost'] == true);
  }
}

class HiddenAd {
  final String id;
  final String? adId;
  final String accountId;
  final String accountName;
  final String headline;
  final String? reason;
  final DateTime createdAt;
  const HiddenAd({required this.id, this.adId, required this.accountId, required this.accountName, required this.headline, this.reason, required this.createdAt});
  factory HiddenAd.fromJson(Map<String, dynamic> json) => HiddenAd(id: json['id'].toString(), adId: json['ad_id']?.toString(), accountId: json['account_id'].toString(), accountName: json['account_name']?.toString() ?? '', headline: json['headline']?.toString() ?? '', reason: json['reason']?.toString(), createdAt: DateTime.parse(json['created_at'].toString()).toUtc());
}

class AdsPreferences {
  final bool personalized;
  final int hiddenCount;
  final List<String> criteria;
  const AdsPreferences({required this.personalized, required this.hiddenCount, required this.criteria});
  factory AdsPreferences.fromJson(Map<String, dynamic> json) => AdsPreferences(personalized: json['ads_personalized'] != false, hiddenCount: (json['hidden_count'] as num?)?.toInt() ?? 0, criteria: (json['criteria'] as List? ?? const []).map((item) => item.toString()).toList());
}

class AdPlacementRequest {
  final AdPlacement placement;
  final int count;
  final Map<String, dynamic> context;
  const AdPlacementRequest(this.placement, {this.count = 1, this.context = const {}});
  @override bool operator ==(Object other) => other is AdPlacementRequest && placement == other.placement && count == other.count && context.toString() == other.context.toString();
  @override int get hashCode => Object.hash(placement, count, context.toString());
}