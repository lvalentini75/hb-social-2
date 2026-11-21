enum AdAccountRole { owner, admin, advertiser, analyst }

extension AdAccountRoleApi on AdAccountRole {
  String get code => name;
  String get labelKey => 'ads.role.$name';
  static AdAccountRole parse(String? value) => AdAccountRole.values.firstWhere((item) => item.name == value, orElse: () => AdAccountRole.analyst);
}

enum AdAccountStatus { active, suspended, closed }

extension AdAccountStatusApi on AdAccountStatus {
  String get code => name;
  String get labelKey => 'ads.account_status.$name';
  static AdAccountStatus parse(String? value) => AdAccountStatus.values.firstWhere((item) => item.name == value, orElse: () => AdAccountStatus.active);
}

enum AdCampaignObjective { awareness, traffic, engagement, listingPromo, eventPromo, pageFollowers }

extension AdCampaignObjectiveApi on AdCampaignObjective {
  String get code => switch (this) { AdCampaignObjective.listingPromo => 'listing_promo', AdCampaignObjective.eventPromo => 'event_promo', AdCampaignObjective.pageFollowers => 'page_followers', _ => name };
  String get labelKey => 'ads.objective.$code';
  static AdCampaignObjective parse(String? value) => AdCampaignObjective.values.firstWhere((item) => item.name == value, orElse: () => AdCampaignObjective.awareness);
}

enum AdCampaignStatus { draft, inReview, scheduled, active, paused, rejected, completed, archived }

extension AdCampaignStatusApi on AdCampaignStatus {
  String get code => this == AdCampaignStatus.inReview ? 'in_review' : name;
  String get labelKey => 'ads.campaign_status.$code';
  static AdCampaignStatus parse(String? value) => AdCampaignStatus.values.firstWhere((item) => item.code == value, orElse: () => AdCampaignStatus.draft);
}

enum AdCreativeKind { image, video, carousel, post, listing, event, page }

extension AdCreativeKindApi on AdCreativeKind {
  String get code => name;
  String get labelKey => 'ads.creative_kind.$name';
  static AdCreativeKind parse(String? value) => AdCreativeKind.values.firstWhere((item) => item.name == value, orElse: () => AdCreativeKind.image);
}

enum AdPlacement { feed, marketplace, marketplaceTop, events, eventsTop, rightRail, stories, search, reels }

extension AdPlacementApi on AdPlacement {
  String get code => switch (this) { AdPlacement.rightRail => 'right_rail', AdPlacement.marketplaceTop => 'marketplace_top', AdPlacement.eventsTop => 'events_top', _ => name };
  String get labelKey => this == AdPlacement.reels ? 'reels.title' : 'ads.placement.$code';
  static AdPlacement parse(String? value) => AdPlacement.values.firstWhere((item) => item.code == value, orElse: () => AdPlacement.feed);
}

enum AdBillingStatus { current, thresholdDue, charging, paid, failed, pastDue, suspended }

extension AdBillingStatusApi on AdBillingStatus {
  String get code => switch (this) { AdBillingStatus.thresholdDue => 'threshold_due', AdBillingStatus.pastDue => 'past_due', _ => name };
  String get labelKey => 'ads_schema.billing_status.$code';
  static AdBillingStatus parse(String? value) => AdBillingStatus.values.firstWhere((item) => item.code == value, orElse: () => AdBillingStatus.current);
}