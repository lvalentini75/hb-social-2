class HuntingUnit {
  final String id;
  final String name;
  final String unitType;
  final String? code;

  const HuntingUnit({required this.id, required this.name, required this.unitType, this.code});

  factory HuntingUnit.fromJson(Map<String, dynamic> json) => HuntingUnit(id: json['id'] as String, name: json['name'] as String, unitType: json['unit_type'] as String? ?? '', code: json['code'] as String?);
}

class HuntingUnitTypeInfo {
  final String countryCode;
  final String code;
  final String nameKey;
  final int sortOrder;

  const HuntingUnitTypeInfo({required this.countryCode, required this.code, required this.nameKey, required this.sortOrder});

  factory HuntingUnitTypeInfo.fromJson(Map<String, dynamic> json) => HuntingUnitTypeInfo(countryCode: json['country_code'] as String, code: json['code'] as String, nameKey: json['name_key'] as String, sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0);
}