enum EventCategory { all, gatherings, shooting, hunts, fairs, courses }

extension EventCategoryKey on EventCategory {
  String get translationKey => 'events.category_$name';
}

class HuntingEvent {
  final String id;
  final String? title;
  final String? description;
  final String? location;
  final DateTime? startsAt;
  final String? organizerName;
  final int? costMinor;
  final String? currencyCode;
  final int? capacity;
  final int participantCount;
  final EventCategory? category;
  final String? coverUrl;

  const HuntingEvent({required this.id, this.title, this.description, this.location, this.startsAt, this.organizerName, this.costMinor, this.currencyCode, this.capacity, this.participantCount = 0, this.category, this.coverUrl});

  factory HuntingEvent.fromJson(Map<String, dynamic> json) => HuntingEvent(
    id: json['id'] as String,
    title: json['title'] as String?,
    description: json['description'] as String?,
    location: json['location'] as String?,
    startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
    organizerName: json['organizer_name'] as String?,
    costMinor: (json['cost_minor'] as num?)?.toInt(),
    currencyCode: json['currency_code'] as String?,
    capacity: (json['capacity'] as num?)?.toInt(),
    participantCount: (json['participant_count'] as num?)?.toInt() ?? 0,
    category: EventCategory.values.where((value) => value.name == json['category']).firstOrNull,
    coverUrl: json['cover_url'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'location': location, 'starts_at': startsAt?.toUtc().toIso8601String(), 'organizer_name': organizerName, 'cost_minor': costMinor, 'currency_code': currencyCode, 'capacity': capacity, 'participant_count': participantCount, 'category': category?.name, 'cover_url': coverUrl};
}