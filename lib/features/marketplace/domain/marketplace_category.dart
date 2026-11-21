class MarketplaceCategory {
  final String id;
  final String kind;
  final String slug;
  final String nameKey;
  final String? parentId;
  final bool isRestricted;
  final bool available;
  final String? requiresBadge;
  final String? noticeKey;
  final String? mode;
  final List<String> allowedTypes;
  final int sortOrder;
  final bool requiresReview;

  const MarketplaceCategory({required this.id, required this.kind, required this.slug, required this.nameKey, this.parentId, required this.isRestricted, this.available = true, this.requiresBadge, this.noticeKey, this.mode, this.allowedTypes = const [], required this.sortOrder, this.requiresReview = false});

  factory MarketplaceCategory.fromJson(Map<String, dynamic> json) => MarketplaceCategory(id: json['id'] as String, kind: json['kind'] as String? ?? 'marketplace', slug: json['slug'] as String, nameKey: json['name_key'] as String, parentId: json['parent_id'] as String?, isRestricted: json['is_restricted'] as bool? ?? false, available: json['available'] as bool? ?? true, requiresBadge: json['requires_badge'] as String?, noticeKey: json['notice_key'] as String?, mode: json['mode'] as String?, allowedTypes: (json['allowed_types'] as List? ?? const []).map((item) => item.toString()).toList(), sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0, requiresReview: json['requires_review'] as bool? ?? false);
}

class FirearmsPolicy {
  final String mode;
  final String? requiresBadge;
  final String? contactVia;
  final bool inAppPayment;

  const FirearmsPolicy({required this.mode, this.requiresBadge, this.contactVia, required this.inAppPayment});

  factory FirearmsPolicy.fromJson(Map<String, dynamic> json) => FirearmsPolicy(mode: json['mode'] as String? ?? 'disabled', requiresBadge: json['requires_badge'] as String?, contactVia: json['contact_via'] as String?, inAppPayment: json['in_app_payment'] as bool? ?? false);
}