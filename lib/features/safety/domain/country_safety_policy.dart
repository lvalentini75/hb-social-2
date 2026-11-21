class CountrySafetyPolicy {
  final bool blurHarvestPhotos;
  final bool allowHarvestPhotos;

  const CountrySafetyPolicy({this.blurHarvestPhotos = true, this.allowHarvestPhotos = true});

  factory CountrySafetyPolicy.fromJson(Object? value) {
    final json = value is Map ? Map<String, dynamic>.from(value) : const <String, dynamic>{};
    return CountrySafetyPolicy(
      blurHarvestPhotos: json['blur_harvest_photos'] as bool? ?? true,
      allowHarvestPhotos: json['allow_harvest_photos'] as bool? ?? true,
    );
  }
}