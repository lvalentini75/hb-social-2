enum DogStatus {
  active,
  retired,
  deceased;

  String get code => name;
  String get labelKey => 'dogs.status.$code';
  static DogStatus fromCode(String? value) => values.firstWhere((item) => item.code == value, orElse: () => DogStatus.active);
}

enum DogVisibility {
  public,
  followers,
  private;

  String get code => name;
  String get labelKey => 'dogs.visibility.$code';
  static DogVisibility fromCode(String? value) => values.firstWhere((item) => item.code == value, orElse: () => DogVisibility.public);
}

class DogBreed {
  final String id;
  final String slug;
  final int fciGroup;
  final String workType;
  final String? origin;
  final int sortOrder;
  final Map<String, String> names;

  const DogBreed({required this.id, required this.slug, required this.fciGroup, required this.workType, this.origin, required this.sortOrder, required this.names});

  String localizedName(String locale) => names[locale] ?? names['it'] ?? names.values.firstOrNull ?? slug;

  factory DogBreed.fromJson(Map<String, dynamic> json) => DogBreed(
    id: json['id'] as String,
    slug: json['slug'] as String? ?? '',
    fciGroup: (json['fci_group'] as num?)?.toInt() ?? 0,
    workType: json['work_type'] as String? ?? 'other',
    origin: json['origin'] as String?,
    sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    names: (json['names'] as Map? ?? const {}).map((key, value) => MapEntry(key.toString(), value.toString())),
  );

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'fci_group': fciGroup, 'work_type': workType, 'origin': origin, 'sort_order': sortOrder, 'names': names};
}

class Dog {
  final String id;
  final String ownerId;
  final String name;
  final String? breed;
  final String? breedId;
  final Map<String, String> breedNames;
  final String? sex;
  final DateTime? birthDate;
  final String? description;
  final String? color;
  final double? weightKg;
  final String? pedigreeNumber;
  final String? microchipNumber;
  final String? fatherName;
  final String? motherName;
  final String? kennelName;
  final String? breederPageId;
  final String? avatarUrl;
  final String? coverUrl;
  final DogStatus status;
  final DateTime? deceasedOn;
  final DogVisibility visibility;
  final int outingCount;
  final int harvestTotal;
  final int postCount;
  final int trialCount;
  final int? ageMonthsValue;

  const Dog({required this.id, required this.ownerId, required this.name, this.breed, this.breedId, this.breedNames = const {}, this.sex, this.birthDate, this.description, this.color, this.weightKg, this.pedigreeNumber, this.microchipNumber, this.fatherName, this.motherName, this.kennelName, this.breederPageId, this.avatarUrl, this.coverUrl, required this.status, this.deceasedOn, required this.visibility, required this.outingCount, required this.harvestTotal, required this.postCount, required this.trialCount, this.ageMonthsValue});

  int? get ageMonths {
    if (ageMonthsValue != null) return ageMonthsValue;
    if (birthDate == null) return null;
    final now = DateTime.now();
    return (now.year - birthDate!.year) * 12 + now.month - birthDate!.month - (now.day < birthDate!.day ? 1 : 0);
  }

  factory Dog.fromJson(Map<String, dynamic> json) {
    final names = json['breed_names'] is Map ? Map<String, dynamic>.from(json['breed_names'] as Map) : const <String, dynamic>{};
    return Dog(
      id: json['id'] as String, ownerId: json['owner_id'] as String? ?? '', name: json['name'] as String? ?? '', breed: json['breed'] as String?, breedId: json['breed_id'] as String?, breedNames: names.map((key, value) => MapEntry(key, value.toString())), sex: json['sex'] as String?, birthDate: DateTime.tryParse(json['birth_date']?.toString() ?? ''), description: json['description'] as String?, color: json['color'] as String?, weightKg: (json['weight_kg'] as num?)?.toDouble(), pedigreeNumber: json['pedigree_number'] as String?, microchipNumber: json['microchip_number'] as String?, fatherName: json['father_name'] as String?, motherName: json['mother_name'] as String?, kennelName: json['kennel_name'] as String?, breederPageId: json['breeder_page_id'] as String?, avatarUrl: json['avatar_url'] as String?, coverUrl: json['cover_url'] as String?, status: DogStatus.fromCode(json['status'] as String?), deceasedOn: DateTime.tryParse(json['deceased_on']?.toString() ?? ''), visibility: DogVisibility.fromCode(json['visibility'] as String?), outingCount: (json['outing_count'] as num?)?.toInt() ?? 0, harvestTotal: (json['harvest_total'] as num?)?.toInt() ?? 0, postCount: (json['post_count'] as num?)?.toInt() ?? 0, trialCount: (json['trial_count'] as num?)?.toInt() ?? 0, ageMonthsValue: (json['age_months'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'owner_id': ownerId, 'name': name, 'breed': breed, 'breed_id': breedId, 'breed_names': breedNames, 'sex': sex, 'birth_date': birthDate?.toIso8601String(), 'description': description, 'color': color, 'weight_kg': weightKg, 'pedigree_number': pedigreeNumber, 'microchip_number': microchipNumber, 'father_name': fatherName, 'mother_name': motherName, 'kennel_name': kennelName, 'breeder_page_id': breederPageId, 'avatar_url': avatarUrl, 'cover_url': coverUrl, 'status': status.code, 'deceased_on': deceasedOn?.toIso8601String(), 'visibility': visibility.code, 'outing_count': outingCount, 'harvest_total': harvestTotal, 'post_count': postCount, 'trial_count': trialCount, 'age_months': ageMonthsValue};
}

class DogPerson {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String? verificationLevel;
  const DogPerson({required this.id, required this.username, required this.displayName, this.avatarUrl, this.verificationLevel});
  factory DogPerson.fromJson(Map<String, dynamic> json) => DogPerson(id: json['id'] as String? ?? '', username: json['username'] as String? ?? '', displayName: json['display_name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?, verificationLevel: json['verification_level'] as String?);
}

class DogBreeder {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;
  final String category;
  const DogBreeder({required this.id, required this.slug, required this.name, this.avatarUrl, required this.category});
  factory DogBreeder.fromJson(Map<String, dynamic> json) => DogBreeder(id: json['id'] as String? ?? '', slug: json['slug']?.toString() ?? '', name: json['name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?, category: json['category'] as String? ?? 'breeder');
}

class DogSpeciesStat {
  final String speciesId;
  final String nameIt;
  final String scientificName;
  final int harvests;
  final int outings;
  const DogSpeciesStat({required this.speciesId, required this.nameIt, required this.scientificName, required this.harvests, required this.outings});
  factory DogSpeciesStat.fromJson(Map<String, dynamic> json) => DogSpeciesStat(speciesId: json['species_id'] as String? ?? '', nameIt: json['name_it'] as String? ?? '', scientificName: json['scientific_name'] as String? ?? '', harvests: (json['harvests'] as num?)?.toInt() ?? 0, outings: (json['outings'] as num?)?.toInt() ?? 0);
}

class DogStats {
  final int outings;
  final int harvests;
  final int posts;
  final int trials;
  final int seasons;
  final DateTime? lastOuting;
  final List<DogSpeciesStat> bySpecies;
  const DogStats({required this.outings, required this.harvests, required this.posts, required this.trials, required this.seasons, this.lastOuting, required this.bySpecies});
  factory DogStats.fromJson(Map<String, dynamic> json) => DogStats(outings: (json['outings'] as num?)?.toInt() ?? 0, harvests: (json['harvests'] as num?)?.toInt() ?? 0, posts: (json['posts'] as num?)?.toInt() ?? 0, trials: (json['trials'] as num?)?.toInt() ?? 0, seasons: (json['seasons'] as num?)?.toInt() ?? 0, lastOuting: DateTime.tryParse(json['last_outing']?.toString() ?? ''), bySpecies: [for (final item in json['by_species'] as List? ?? const []) DogSpeciesStat.fromJson(Map<String, dynamic>.from(item as Map))]);
}

class DogRecentOuting {
  final String id;
  final String? title;
  final String? zoneName;
  final DateTime startedAt;
  final int harvestTotal;
  const DogRecentOuting({required this.id, this.title, this.zoneName, required this.startedAt, required this.harvestTotal});
  factory DogRecentOuting.fromJson(Map<String, dynamic> json) => DogRecentOuting(id: (json['log_id'] ?? json['id']) as String, title: json['title'] as String?, zoneName: json['zone_name'] as String?, startedAt: DateTime.parse(json['started_at'].toString()).toUtc(), harvestTotal: (json['harvest_total'] as num?)?.toInt() ?? 0);
}

class DogRecentPost {
  final String id;
  final String kind;
  final String? content;
  final DateTime createdAt;
  final String? mediaUrl;
  const DogRecentPost({required this.id, required this.kind, this.content, required this.createdAt, this.mediaUrl});
  factory DogRecentPost.fromJson(Map<String, dynamic> json) => DogRecentPost(id: json['id'] as String, kind: json['kind'] as String? ?? 'text', content: json['content'] as String?, createdAt: DateTime.parse(json['created_at'].toString()).toUtc(), mediaUrl: (json['media_url'] ?? json['media_path']) as String?);
}

class DogProfile {
  final Dog dog;
  final DogBreed? breed;
  final DogPerson owner;
  final DogBreeder? breeder;
  final bool isOwner;
  final DogStats stats;
  final List<DogTrial> trials;
  final List<DogHealthRecord>? health;
  final DogHealthRecord? nextDue;
  final List<DogRecentPost> recentPosts;
  final List<DogRecentOuting> recentOutings;
  const DogProfile({required this.dog, this.breed, required this.owner, this.breeder, required this.isOwner, required this.stats, required this.trials, this.health, this.nextDue, required this.recentPosts, required this.recentOutings});
  factory DogProfile.fromJson(Map<String, dynamic> json) => DogProfile(dog: Dog.fromJson(Map<String, dynamic>.from(json['dog'] as Map)), breed: json['breed'] is Map ? DogBreed.fromJson(Map<String, dynamic>.from(json['breed'] as Map)) : null, owner: DogPerson.fromJson(Map<String, dynamic>.from(json['owner'] as Map)), breeder: json['breeder'] is Map ? DogBreeder.fromJson(Map<String, dynamic>.from(json['breeder'] as Map)) : null, isOwner: json['is_owner'] as bool? ?? false, stats: DogStats.fromJson(Map<String, dynamic>.from(json['stats'] as Map? ?? const {})), trials: [for (final item in json['trials'] as List? ?? const []) DogTrial.fromJson(Map<String, dynamic>.from(item as Map))], health: json['health'] is List ? [for (final item in json['health'] as List) DogHealthRecord.fromJson(Map<String, dynamic>.from(item as Map))] : null, nextDue: json['next_due'] is Map ? DogHealthRecord.fromJson(Map<String, dynamic>.from(json['next_due'] as Map)) : null, recentPosts: [for (final item in json['recent_posts'] as List? ?? const []) DogRecentPost.fromJson(Map<String, dynamic>.from(item as Map))], recentOutings: [for (final item in json['recent_outings'] as List? ?? const []) DogRecentOuting.fromJson(Map<String, dynamic>.from(item as Map))]);
}

class DogTrial {
  final String id;
  final String kind;
  final String title;
  final DateTime trialDate;
  final String? place;
  final String? organizer;
  final String? judge;
  final String? result;
  final String? points;
  final String? notes;
  final String? eventId;
  final String? eventTitle;
  final String? certificatePath;
  final bool hasCertificate;
  const DogTrial({required this.id, required this.kind, required this.title, required this.trialDate, this.place, this.organizer, this.judge, this.result, this.points, this.notes, this.eventId, this.eventTitle, this.certificatePath, required this.hasCertificate});
  factory DogTrial.fromJson(Map<String, dynamic> json) => DogTrial(id: json['id'] as String, kind: json['kind'] as String? ?? 'other', title: json['title'] as String? ?? '', trialDate: DateTime.parse(json['trial_date'].toString()), place: json['place'] as String?, organizer: json['organizer'] as String?, judge: json['judge'] as String?, result: json['result'] as String?, points: json['points'] as String?, notes: json['notes'] as String?, eventId: json['event_id'] as String?, eventTitle: json['event_title'] as String?, certificatePath: json['certificate_path'] as String?, hasCertificate: json['has_certificate'] as bool? ?? json['certificate_path'] != null);
}

class DogHealthRecord {
  final String id;
  final String kind;
  final String title;
  final DateTime? performedOn;
  final DateTime? dueOn;
  final String? vetName;
  final String? notes;
  const DogHealthRecord({required this.id, required this.kind, required this.title, this.performedOn, this.dueOn, this.vetName, this.notes});
  factory DogHealthRecord.fromJson(Map<String, dynamic> json) => DogHealthRecord(id: json['id'] as String, kind: json['kind'] as String? ?? 'other', title: json['title'] as String? ?? '', performedOn: DateTime.tryParse(json['performed_on']?.toString() ?? ''), dueOn: DateTime.tryParse(json['due_on']?.toString() ?? ''), vetName: json['vet_name'] as String?, notes: json['notes'] as String?);
}

class DogReminder {
  final String dogId;
  final String dogName;
  final String recordId;
  final String kind;
  final String title;
  final DateTime dueOn;
  final int daysLeft;
  const DogReminder({required this.dogId, required this.dogName, required this.recordId, required this.kind, required this.title, required this.dueOn, required this.daysLeft});
  factory DogReminder.fromJson(Map<String, dynamic> json) => DogReminder(dogId: json['dog_id'] as String, dogName: json['dog_name'] as String? ?? '', recordId: json['record_id'] as String, kind: json['kind'] as String? ?? 'other', title: json['title'] as String? ?? '', dueOn: DateTime.parse(json['due_on'].toString()), daysLeft: (json['days_left'] as num?)?.toInt() ?? 0);
}

class DogSearchResult {
  final Dog dog;
  final DogPerson owner;
  final String? regionName;
  const DogSearchResult({required this.dog, required this.owner, this.regionName});
  factory DogSearchResult.fromJson(Map<String, dynamic> json) => DogSearchResult(dog: Dog.fromJson({...json, 'owner_id': json['owner_id'], 'status': json['status'] ?? 'active', 'visibility': 'public', 'harvest_total': json['harvest_total'] ?? 0, 'post_count': json['post_count'] ?? 0}), owner: DogPerson(id: json['owner_id'] as String? ?? '', username: json['owner_username'] as String? ?? '', displayName: json['owner_display_name'] as String? ?? '', avatarUrl: json['owner_avatar_url'] as String?), regionName: json['region_name'] as String?);
}

class DogTrialInput {
  final String dogId;
  final String? id;
  final String kind;
  final String title;
  final DateTime date;
  final String? place, organizer, judge, result, points, notes, eventId, certificatePath;
  const DogTrialInput({required this.dogId, this.id, required this.kind, required this.title, required this.date, this.place, this.organizer, this.judge, this.result, this.points, this.notes, this.eventId, this.certificatePath});
}

class DogHealthInput {
  final String dogId;
  final String? id;
  final String kind;
  final String title;
  final DateTime performedOn;
  final DateTime? dueOn;
  final String? vetName, notes;
  const DogHealthInput({required this.dogId, this.id, required this.kind, required this.title, required this.performedOn, this.dueOn, this.vetName, this.notes});
}

class DogEventChoice {
  final String id;
  final String title;
  const DogEventChoice({required this.id, required this.title});
}

class DogInput {
  final String? id;
  final String name;
  final String? breedId;
  final String? sex;
  final DateTime? birthDate;
  final String? description;
  final String? color;
  final double? weightKg;
  final String? pedigreeNumber;
  final String? microchipNumber;
  final String? fatherName;
  final String? motherName;
  final String? kennelName;
  final String? breederPageId;
  final String? avatarUrl;
  final String? coverUrl;
  final DogVisibility visibility;
  const DogInput({this.id, required this.name, this.breedId, this.sex, this.birthDate, this.description, this.color, this.weightKg, this.pedigreeNumber, this.microchipNumber, this.fatherName, this.motherName, this.kennelName, this.breederPageId, this.avatarUrl, this.coverUrl, this.visibility = DogVisibility.public});
}