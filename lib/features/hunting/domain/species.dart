class Species {
  final String id;
  final String scientificName;
  final String category;
  final String localizedName;

  const Species({required this.id, required this.scientificName, required this.category, required this.localizedName});

  factory Species.fromJson(Map<String, dynamic> json, String locale) {
    final names = (json['names'] as List? ?? const []).map((item) => Map<String, dynamic>.from(item as Map)).toList();
    String? nameFor(String code) {
      for (final name in names) {
        if (name['locale'] == code) return name['name'] as String?;
      }
      return null;
    }

    final scientificName = json['scientific_name'] as String;
    return Species(id: json['id'] as String, scientificName: scientificName, category: json['category'] as String? ?? '', localizedName: nameFor(locale) ?? nameFor('it') ?? scientificName);
  }
}