class HuntingDog {
  final String id;
  final String? name;
  final String? breed;
  final String? sex;
  final DateTime? birthDate;
  final String? pedigreeNumber;
  final String? microchipNumber;
  final String? ownerName;
  final String? avatarUrl;
  final String? coverUrl;

  const HuntingDog({required this.id, this.name, this.breed, this.sex, this.birthDate, this.pedigreeNumber, this.microchipNumber, this.ownerName, this.avatarUrl, this.coverUrl});

  factory HuntingDog.fromJson(Map<String, dynamic> json) => HuntingDog(
    id: json['id'] as String,
    name: json['name'] as String?,
    breed: json['breed'] as String?,
    sex: json['sex'] as String?,
    birthDate: DateTime.tryParse(json['birth_date'] as String? ?? ''),
    pedigreeNumber: json['pedigree_number'] as String?,
    microchipNumber: json['microchip_number'] as String?,
    ownerName: json['owner_name'] as String?,
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
  );

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'breed': breed, 'sex': sex, 'birth_date': birthDate?.toIso8601String(), 'pedigree_number': pedigreeNumber, 'microchip_number': microchipNumber, 'owner_name': ownerName, 'avatar_url': avatarUrl, 'cover_url': coverUrl};
}