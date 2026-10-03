enum MarketplaceCategory { all, optics, clothing, accessories, dogs, vehicles, firearms, services }

/// Closed UI categories until they are replaced by the P04 `categories` table.
extension MarketplaceCategoryKey on MarketplaceCategory {
  String get translationKey => 'marketplace.category_$name';
}

class MarketplaceListing {
  final String id;
  final String? title;
  final String? description;
  final int? priceMinor;
  final String? currencyCode;
  final MarketplaceCategory? category;
  final String? condition;
  final String? location;
  final String? sellerName;
  final DateTime? sellerMemberSince;
  final DateTime? createdAt;
  final List<String> imageUrls;

  const MarketplaceListing({required this.id, this.title, this.description, this.priceMinor, this.currencyCode, this.category, this.condition, this.location, this.sellerName, this.sellerMemberSince, this.createdAt, this.imageUrls = const []});

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) => MarketplaceListing(
    id: json['id'] as String,
    title: json['title'] as String?,
    description: json['description'] as String?,
    priceMinor: (json['price_minor'] as num?)?.toInt(),
    currencyCode: json['currency_code'] as String?,
    category: MarketplaceCategory.values.where((value) => value.name == json['category']).firstOrNull,
    condition: json['condition'] as String?,
    location: json['location'] as String?,
    sellerName: json['seller_name'] as String?,
    sellerMemberSince: DateTime.tryParse(json['seller_member_since'] as String? ?? ''),
    createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    imageUrls: (json['image_urls'] as List?)?.whereType<String>().toList() ?? const [],
  );

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'description': description, 'price_minor': priceMinor, 'currency_code': currencyCode, 'category': category?.name, 'condition': condition, 'location': location, 'seller_name': sellerName, 'seller_member_since': sellerMemberSince?.toUtc().toIso8601String(), 'created_at': createdAt?.toUtc().toIso8601String(), 'image_urls': imageUrls};
}