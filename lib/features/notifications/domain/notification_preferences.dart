class NotificationChannelPreference {
  final bool app;
  final bool push;

  const NotificationChannelPreference({this.app = true, this.push = true});

  factory NotificationChannelPreference.fromJson(Object? value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};
    return NotificationChannelPreference(app: json['app'] as bool? ?? true, push: json['push'] as bool? ?? true);
  }

  Map<String, dynamic> toJson() => {'app': app, 'push': push};

  NotificationChannelPreference copyWith({bool? app, bool? push}) => NotificationChannelPreference(app: app ?? this.app, push: push ?? this.push);
}

class NotificationPreferences {
  static const generalKinds = ['follow', 'reaction', 'comment', 'reply', 'comment_like', 'share', 'mention', 'friend_request', 'friend_accepted', 'follow_request', 'group_accepted', 'event_request', 'strike', 'account_suspended'];
  static const forumKinds = ['forum_reply', 'forum_solution', 'forum_mention', 'forum_reply_like'];
  static const eventKinds = ['event_waitlist_promoted', 'event_paid', 'event_checkin', 'event_cancelled'];
  static const managedKinds = ['forum_request', 'group_request', 'event_rsvp', 'forum_member_joined', 'group_member_joined', 'page_follower_new', 'forum_thread_new', 'group_post_new'];
  static const messageKinds = ['message'];
  static const sightingKinds = ['sighting_alert'];
  static const orderKinds = ['order_paid', 'order_shipped', 'order_completed', 'order_expired'];
  static const adsKinds = ['ads_member_added', 'ads_campaign_approved', 'ads_campaign_rejected', 'ads_budget_completed', 'ads_charge_succeeded', 'ads_payment_failed', 'ads_account_suspended', 'ads_spend_cap_reached', 'ads_credit_granted', 'ads_boost_started', 'ads_boost_completed'];
  static const kinds = [...generalKinds, ...sightingKinds, ...orderKinds, ...adsKinds, ...messageKinds, ...forumKinds, ...eventKinds, ...managedKinds];
  final Map<String, NotificationChannelPreference> values;

  const NotificationPreferences({this.values = const {}});

  factory NotificationPreferences.fromJson(Object? value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};
    return NotificationPreferences(values: {for (final kind in kinds) kind: NotificationChannelPreference.fromJson(json[kind])});
  }

  NotificationChannelPreference forKind(String kind) => values[kind] ?? const NotificationChannelPreference();

  NotificationPreferences update(String kind, NotificationChannelPreference preference) => NotificationPreferences(values: {...values, kind: preference});

  Map<String, dynamic> toJson() => {for (final entry in values.entries) entry.key: entry.value.toJson()};
}