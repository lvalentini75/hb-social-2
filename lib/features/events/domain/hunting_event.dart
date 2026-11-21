import 'package:hb_social/features/profile/domain/user_profile.dart';

enum EventView { upcoming, past, mine, nearby }

class EventCategory {
  final String slug;
  final String nameKey;
  final int sortOrder;
  const EventCategory({required this.slug, required this.nameKey, required this.sortOrder});
  factory EventCategory.fromJson(Map<String, dynamic> json) => EventCategory(slug: json['slug'] as String, nameKey: json['name_key'] as String, sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0);
}

class EventOrganizer {
  final String kind;
  final String id;
  final String name;
  final String? avatarUrl;
  final String? slug;
  final String? username;
  const EventOrganizer({required this.kind, required this.id, required this.name, this.avatarUrl, this.slug, this.username});
  factory EventOrganizer.fromEventJson(Map<String, dynamic> json) {
    final userJson = json['organizer_user'];
    if (userJson is Map) {
      final profile = UserProfile.fromJson(Map<String, dynamic>.from(userJson));
      return EventOrganizer(kind: 'user', id: profile.id, name: profile.displayName, avatarUrl: profile.avatarUrl, username: profile.username);
    }
    final page = json['organizer_page'];
    if (page is Map) return EventOrganizer(kind: 'page', id: page['id'] as String, name: page['name'] as String, avatarUrl: page['avatar_url'] as String?, slug: page['slug'] as String?);
    final group = Map<String, dynamic>.from(json['organizer_group'] as Map);
    return EventOrganizer(kind: 'group', id: group['id'] as String, name: group['name'] as String, avatarUrl: group['avatar_url'] as String?, slug: group['slug'] as String?);
  }
}

class EventParticipation {
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? ticketCode;
  final DateTime? checkedInAt;
  final DateTime? waitlistedAt;
  final int? waitlistPosition;
  const EventParticipation({required this.status, required this.paymentStatus, this.paymentMethod, this.ticketCode, this.checkedInAt, this.waitlistedAt, this.waitlistPosition});
  factory EventParticipation.fromJson(Map<String, dynamic> json) => EventParticipation(status: json['status'] as String, paymentStatus: json['payment_status'] as String? ?? 'none', paymentMethod: json['payment_method'] as String?, ticketCode: json['ticket_code'] as String?, checkedInAt: json['checked_in_at'] == null ? null : DateTime.parse(json['checked_in_at'].toString()).toUtc(), waitlistedAt: json['waitlisted_at'] == null ? null : DateTime.parse(json['waitlisted_at'].toString()).toUtc(), waitlistPosition: (json['waitlist_position'] as num?)?.toInt());
}

class EventGoingPreview {
  final UserProfile profile;
  final bool isFriend;
  const EventGoingPreview({required this.profile, required this.isFriend});
  factory EventGoingPreview.fromJson(Map<String, dynamic> json) => EventGoingPreview(profile: UserProfile.fromJson({...json, 'id': json['user_id']}), isFriend: json['is_friend'] as bool? ?? false);
}

class EventParticipant {
  final String id;
  final UserProfile profile;
  final String status;
  final String paymentStatus;
  final String? paymentMethod;
  final String? ticketCode;
  final DateTime createdAt;
  final DateTime? waitlistedAt;
  final DateTime? checkedInAt;
  const EventParticipant({required this.id, required this.profile, required this.status, this.paymentStatus = 'none', this.paymentMethod, this.ticketCode, required this.createdAt, this.waitlistedAt, this.checkedInAt});
  factory EventParticipant.fromJson(Map<String, dynamic> json) => EventParticipant(id: json['id'] as String, profile: UserProfile.fromJson(Map<String, dynamic>.from(json['user'] as Map)), status: json['status'] as String, paymentStatus: json['payment_status'] as String? ?? 'none', paymentMethod: json['payment_method'] as String?, ticketCode: json['ticket_code'] as String?, createdAt: DateTime.parse(json['created_at'] as String).toUtc(), waitlistedAt: json['waitlisted_at'] == null ? null : DateTime.parse(json['waitlisted_at'].toString()).toUtc(), checkedInAt: json['checked_in_at'] == null ? null : DateTime.parse(json['checked_in_at'].toString()).toUtc());
}

class EventOrganizerSummary {
  final int going;
  final int interested;
  final int waitlist;
  final int checkedIn;
  final int paid;
  final int pendingPayment;
  final int? capacity;
  final bool isPaidEvent;
  const EventOrganizerSummary({required this.going, required this.interested, required this.waitlist, required this.checkedIn, required this.paid, required this.pendingPayment, this.capacity, required this.isPaidEvent});
  int get confirmed => going + checkedIn;
  factory EventOrganizerSummary.fromJson(Map<String, dynamic> json) => EventOrganizerSummary(going: (json['going'] as num?)?.toInt() ?? 0, interested: (json['interested'] as num?)?.toInt() ?? 0, waitlist: (json['waitlist'] as num?)?.toInt() ?? 0, checkedIn: (json['checked_in'] as num?)?.toInt() ?? 0, paid: (json['paid'] as num?)?.toInt() ?? 0, pendingPayment: (json['pending_payment'] as num?)?.toInt() ?? 0, capacity: (json['capacity'] as num?)?.toInt(), isPaidEvent: json['is_paid_event'] as bool? ?? false);
}

class EventPaymentResult {
  final String paymentStatus;
  final String? ticketCode;
  const EventPaymentResult({required this.paymentStatus, this.ticketCode});
  factory EventPaymentResult.fromJson(Map<String, dynamic> json) => EventPaymentResult(paymentStatus: json['payment_status'] as String, ticketCode: json['ticket_code'] as String?);
}

class EventCheckinResult {
  final String participantId;
  final String userId;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String status;
  final DateTime checkedInAt;
  final String eventId;
  final String eventTitle;
  const EventCheckinResult({required this.participantId, required this.userId, required this.username, required this.displayName, this.avatarUrl, required this.status, required this.checkedInAt, required this.eventId, required this.eventTitle});
  factory EventCheckinResult.fromJson(Map<String, dynamic> json) => EventCheckinResult(participantId: json['participant_id'] as String, userId: json['user_id'] as String, username: json['username'] as String? ?? '', displayName: json['display_name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?, status: json['status'] as String, checkedInAt: DateTime.parse(json['checked_in_at'].toString()).toUtc(), eventId: json['event_id'] as String, eventTitle: json['event_title'] as String? ?? '');
}

class EventOrganizerChoice {
  final String kind;
  final String id;
  final String name;
  final String? avatarUrl;
  const EventOrganizerChoice({required this.kind, required this.id, required this.name, this.avatarUrl});
}

class HuntingEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final String? address;
  final double? latitude;
  final double? longitude;
  final String? regionId;
  final String? huntingUnitId;
  final DateTime startsAt;
  final DateTime? endsAt;
  final EventOrganizer organizer;
  final int priceMinor;
  final String currencyCode;
  final int? capacity;
  final int participantCount;
  final int interestedCount;
  final String category;
  final String status;
  final String? coverUrl;
  final DateTime createdAt;
  final double? distanceKm;
  const HuntingEvent({required this.id, required this.title, this.description, this.location, this.address, this.latitude, this.longitude, this.regionId, this.huntingUnitId, required this.startsAt, this.endsAt, required this.organizer, required this.priceMinor, required this.currencyCode, this.capacity, required this.participantCount, required this.interestedCount, required this.category, required this.status, this.coverUrl, required this.createdAt, this.distanceKm});
  bool get isFull => capacity != null && participantCount >= capacity!;
  bool get isPastForRsvp => startsAt.isBefore(DateTime.now().toUtc().subtract(const Duration(hours: 12)));
  factory HuntingEvent.fromJson(Map<String, dynamic> json) => HuntingEvent(id: json['id'] as String, title: json['title'] as String, description: json['description'] as String?, location: json['location_name'] as String?, address: json['address'] as String?, latitude: (json['lat'] as num?)?.toDouble(), longitude: (json['lng'] as num?)?.toDouble(), regionId: json['region_id'] as String?, huntingUnitId: json['hunting_unit_id'] as String?, startsAt: DateTime.parse(json['starts_at'] as String).toUtc(), endsAt: json['ends_at'] == null ? null : DateTime.parse(json['ends_at'] as String).toUtc(), organizer: EventOrganizer.fromEventJson(json), priceMinor: (json['price_minor'] as num?)?.toInt() ?? 0, currencyCode: (json['currency_code'] as String? ?? 'EUR').trim(), capacity: (json['capacity'] as num?)?.toInt(), participantCount: (json['attendee_count'] as num?)?.toInt() ?? 0, interestedCount: (json['interested_count'] as num?)?.toInt() ?? 0, category: json['category'] as String, status: json['status'] as String? ?? 'published', coverUrl: json['cover_url'] as String?, createdAt: DateTime.parse(json['created_at'] as String).toUtc(), distanceKm: (json['distance_km'] as num?)?.toDouble());
}