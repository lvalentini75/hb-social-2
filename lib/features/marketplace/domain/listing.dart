enum ListingCondition { newItem, likeNew, good, fair }

extension ListingConditionApi on ListingCondition {
  String get code => switch (this) { ListingCondition.newItem => 'new', ListingCondition.likeNew => 'like_new', ListingCondition.good => 'good', ListingCondition.fair => 'fair' };
  String get labelKey => 'marketplace.condition.$code';
  static ListingCondition parse(String? value) => ListingCondition.values.firstWhere((item) => item.code == value, orElse: () => ListingCondition.good);
}

enum ListingStatus { draft, inReview, active, reserved, sold, expired, removed }

extension ListingStatusApi on ListingStatus {
  String get code => this == ListingStatus.inReview ? 'pending' : name;
  String get labelKey => 'marketplace.status.$code';
  static ListingStatus parse(String? value) => ListingStatus.values.firstWhere((item) => item.code == value, orElse: () => ListingStatus.active);
}

class ListingMoney {
  final int amountMinor;
  final String currencyCode;
  const ListingMoney(this.amountMinor, this.currencyCode);
}

class ListingMedia {
  final String id;
  final String path;
  final String storagePath;
  final int sortOrder;
  const ListingMedia({required this.id, required this.path, required this.storagePath, required this.sortOrder});
  factory ListingMedia.fromJson(Map<String, dynamic> json) => ListingMedia(id: json['id']?.toString() ?? '', path: json['path'] as String? ?? '', storagePath: json['storage_path'] as String? ?? json['path'] as String? ?? '', sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0);
}

class MyListing {
  final Listing listing;
  final int contactCount;
  final int? daysLeft;
  final DateTime? updatedAt;
  final DateTime? reservedAt;
  final DateTime? soldAt;
  final String reviewStatus;
  final String? reviewNote;

  const MyListing({required this.listing, required this.contactCount, this.daysLeft, this.updatedAt, this.reservedAt, this.soldAt, required this.reviewStatus, this.reviewNote});
  factory MyListing.fromJson(Map<String, dynamic> json) => MyListing(listing: Listing.fromJson({...json, 'seller': const <String, dynamic>{}}), contactCount: (json['contact_count'] as num?)?.toInt() ?? 0, daysLeft: (json['days_left'] as num?)?.toInt(), updatedAt: _date(json['updated_at']), reservedAt: _date(json['reserved_at']), soldAt: _date(json['sold_at']), reviewStatus: json['review_status']?.toString() ?? 'approved', reviewNote: json['review_note']?.toString());
}

class ListingContact {
  final String userId;
  final String conversationId;
  final DateTime createdAt;
  final SellerSummary user;

  const ListingContact({required this.userId, required this.conversationId, required this.createdAt, required this.user});
  factory ListingContact.fromJson(Map<String, dynamic> json) => ListingContact(userId: json['user_id'] as String? ?? '', conversationId: json['conversation_id'] as String? ?? '', createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), user: SellerSummary.fromJson(_map(json['user'])));
}

class SellerSummary {
  final String id;
  final String username;
  final String displayName;
  final String? avatarUrl;
  final String verificationLevel;
  final int ratingAverageHundredths;
  final int ratingCount;
  final DateTime? memberSince;
  final DateTime? lastSeenAt;
  final int activeListings;
  final int soldListings;
  final String? regionName;
  final Map<int, int> ratingBreakdown;

  const SellerSummary({required this.id, required this.username, required this.displayName, this.avatarUrl, required this.verificationLevel, required this.ratingAverageHundredths, required this.ratingCount, this.memberSince, this.lastSeenAt, this.activeListings = 0, this.soldListings = 0, this.regionName, this.ratingBreakdown = const {}});

  factory SellerSummary.fromJson(Map<String, dynamic> json) {
    final breakdown = _map(json['rating_breakdown']);
    return SellerSummary(
      id: (json['id'] ?? json['seller_id'] ?? json['user_id'])?.toString() ?? '', username: json['username'] as String? ?? '', displayName: json['display_name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?, verificationLevel: json['verification_level'] as String? ?? 'none',
      ratingAverageHundredths: _ratingHundredths(json['rating_avg'] ?? json['seller_rating_avg']), ratingCount: (json['rating_count'] as num?)?.toInt() ?? (json['seller_rating_count'] as num?)?.toInt() ?? 0,
      memberSince: _date(json['member_since'] ?? json['created_at']), lastSeenAt: _date(json['last_seen_at']), activeListings: (json['active_listings'] as num?)?.toInt() ?? 0, soldListings: (json['sold_listings'] as num?)?.toInt() ?? 0, regionName: json['region_name'] as String?,
      ratingBreakdown: {for (var score = 1; score <= 5; score++) score: (breakdown['$score'] as num?)?.toInt() ?? 0},
    );
  }
}

class SellerReview {
  final String id;
  final String listingId;
  final int rating;
  final String? comment;
  final String? reply;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final SellerSummary reviewer;
  final bool isMine;
  final bool canEdit;

  const SellerReview({required this.id, required this.listingId, required this.rating, this.comment, this.reply, required this.createdAt, this.updatedAt, required this.reviewer, this.isMine = false, this.canEdit = false});
  factory SellerReview.fromJson(Map<String, dynamic> json) => SellerReview(id: json['id'] as String, listingId: json['listing_id'] as String? ?? '', rating: (json['rating'] as num).toInt(), comment: json['comment'] as String?, reply: (json['seller_reply'] ?? json['reply']) as String?, createdAt: _date(json['created_at'])!, updatedAt: _date(json['updated_at']), reviewer: SellerSummary.fromJson(_map(json['reviewer'])), isMine: json['is_mine'] as bool? ?? false, canEdit: json['can_edit'] as bool? ?? false);
}

class FirearmsListingPolicy {
  final String mode;
  final String? requiresBadge;
  final String? contactVia;
  final bool viewerHasBadge;
  final bool inAppPayment;
  final String? noticeKey;
  final String? countryCode;
  final bool contactLocked;
  final String? contactLockReason;
  const FirearmsListingPolicy({required this.mode, this.requiresBadge, this.contactVia, required this.viewerHasBadge, required this.inAppPayment, this.noticeKey, this.countryCode, required this.contactLocked, this.contactLockReason});
  factory FirearmsListingPolicy.fromJson(Map<String, dynamic> json) => FirearmsListingPolicy(mode: json['mode'] as String? ?? 'disabled', requiresBadge: json['requires_badge'] as String?, contactVia: json['contact_via'] as String?, viewerHasBadge: json['viewer_has_badge'] as bool? ?? false, inAppPayment: json['in_app_payment'] as bool? ?? false, noticeKey: json['notice_key'] as String?, countryCode: json['country_code'] as String?, contactLocked: json['contact_locked'] as bool? ?? false, contactLockReason: json['contact_lock_reason'] as String?);
}

class FirearmsShop {
  final String id;
  final String slug;
  final String name;
  final String? avatarUrl;
  final String verificationStatus;
  final String? address;
  final String? phone;
  final String? email;
  final String? website;
  final String? regionName;
  const FirearmsShop({required this.id, required this.slug, required this.name, this.avatarUrl, required this.verificationStatus, this.address, this.phone, this.email, this.website, this.regionName});
  factory FirearmsShop.fromJson(Map<String, dynamic> json) => FirearmsShop(id: json['id'] as String? ?? '', slug: json['slug'] as String? ?? '', name: json['name'] as String? ?? '', avatarUrl: json['avatar_url'] as String?, verificationStatus: json['verification_status'] as String? ?? 'verified', address: json['address'] as String?, phone: json['phone'] as String?, email: json['email'] as String?, website: json['website'] as String?, regionName: json['region_name'] as String?);
}

class FirearmsUnavailable {
  final String countryCode;
  final String noticeKey;
  const FirearmsUnavailable({required this.countryCode, required this.noticeKey});
  factory FirearmsUnavailable.fromJson(Map<String, dynamic> json) => FirearmsUnavailable(countryCode: json['country_code'] as String? ?? '', noticeKey: json['notice_key'] as String? ?? 'marketplace.firearms.notice.disabled');
}

class ListingDetailResponse {
  final ListingDetail? detail;
  final FirearmsUnavailable? unavailable;
  const ListingDetailResponse.detail(this.detail) : unavailable = null;
  const ListingDetailResponse.unavailable(this.unavailable) : detail = null;
}

class Listing {
  final String id;
  final String sellerId;
  final String categoryId;
  final String categorySlug;
  final String categoryNameKey;
  final String title;
  final String? description;
  final String countryCode;
  final ListingMoney originalPrice;
  final ListingMoney? displayPrice;
  final DateTime? rateDate;
  final ListingCondition condition;
  final ListingStatus status;
  final bool isMediated;
  final bool negotiable;
  final bool shippingAvailable;
  final String? municipality;
  final String? municipalityId;
  final String? regionId;
  final String? regionName;
  final double? lat;
  final double? lng;
  final int? distanceM;
  final String? mediaPath;
  final int mediaCount;
  final int favoriteCount;
  final int viewCount;
  final bool isFavorite;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final SellerSummary seller;
  final String? shopName;

  const Listing({required this.id, required this.sellerId, required this.categoryId, required this.categorySlug, required this.categoryNameKey, required this.title, this.description, this.countryCode = 'IT', required this.originalPrice, this.displayPrice, this.rateDate, required this.condition, required this.status, required this.isMediated, required this.negotiable, required this.shippingAvailable, this.municipality, this.municipalityId, this.regionId, this.regionName, this.lat, this.lng, this.distanceM, this.mediaPath, required this.mediaCount, required this.favoriteCount, required this.viewCount, required this.isFavorite, required this.createdAt, this.expiresAt, required this.seller, this.shopName});

  factory Listing.fromJson(Map<String, dynamic> json) {
    final sellerJson = _map(json['seller']);
    final aliases = {'id': 'seller_id', 'username': 'seller_username', 'display_name': 'seller_display_name', 'avatar_url': 'seller_avatar_url', 'verification_level': 'seller_verification_level', 'rating_avg': 'seller_rating_avg', 'rating_count': 'seller_rating_count'};
    for (final entry in aliases.entries) { sellerJson.putIfAbsent(entry.key, () => json[entry.value]); }
    final displayMinor = (json['display_price_minor'] as num?)?.toInt();
    return Listing(
      id: json['id'] as String, sellerId: json['seller_id'] as String? ?? sellerJson['id'] as String? ?? '', categoryId: json['category_id'] as String? ?? '', categorySlug: json['category_slug'] as String? ?? _map(json['category'])['slug'] as String? ?? '', categoryNameKey: json['category_name_key'] as String? ?? _map(json['category'])['name_key'] as String? ?? 'marketplace.category_other', title: json['title'] as String? ?? '', description: json['description'] as String?, countryCode: json['country_code'] as String? ?? 'IT',
      originalPrice: ListingMoney((json['price_minor'] as num?)?.toInt() ?? 0, (json['currency_code'] as String? ?? 'EUR').trim()), displayPrice: displayMinor == null ? null : ListingMoney(displayMinor, (json['display_currency'] as String? ?? json['currency_code'] as String? ?? 'EUR').trim()), rateDate: _date(json['rate_date']),
      condition: ListingConditionApi.parse(json['condition'] as String?), status: ListingStatusApi.parse(json['status'] as String?), isMediated: json['is_mediated'] as bool? ?? false, negotiable: json['negotiable'] as bool? ?? false, shippingAvailable: json['shipping_available'] as bool? ?? false,
      municipality: json['municipality'] as String?, municipalityId: json['municipality_id'] as String?, regionId: json['region_id'] as String?, regionName: json['region_name'] as String?, lat: (json['lat'] as num?)?.toDouble(), lng: (json['lng'] as num?)?.toDouble(), distanceM: (json['distance_m'] as num?)?.toInt(), mediaPath: json['media_path'] as String?, mediaCount: (json['media_count'] as num?)?.toInt() ?? 0,
      favoriteCount: (json['favorite_count'] as num?)?.toInt() ?? 0, viewCount: (json['view_count'] as num?)?.toInt() ?? 0, isFavorite: json['is_favorite'] as bool? ?? false, createdAt: _date(json['created_at']) ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true), expiresAt: _date(json['expires_at']), seller: SellerSummary.fromJson(sellerJson), shopName: json['shop_name'] as String?,
    );
  }

  Listing copyWith({bool? isFavorite, int? favoriteCount}) => Listing(id: id, sellerId: sellerId, categoryId: categoryId, categorySlug: categorySlug, categoryNameKey: categoryNameKey, title: title, description: description, countryCode: countryCode, originalPrice: originalPrice, displayPrice: displayPrice, rateDate: rateDate, condition: condition, status: status, isMediated: isMediated, negotiable: negotiable, shippingAvailable: shippingAvailable, municipality: municipality, municipalityId: municipalityId, regionId: regionId, regionName: regionName, lat: lat, lng: lng, distanceM: distanceM, mediaPath: mediaPath, mediaCount: mediaCount, favoriteCount: favoriteCount ?? this.favoriteCount, viewCount: viewCount, isFavorite: isFavorite ?? this.isFavorite, createdAt: createdAt, expiresAt: expiresAt, seller: seller, shopName: shopName);
}

class ListingDetail {
  final Listing listing;
  final String? description;
  final Map<String, dynamic> attributes;
  final List<ListingMedia> media;
  final bool isMine;
  final String? conversationId;
  final bool canReview;
  final SellerReview? myReview;
  final FirearmsListingPolicy? firearmsPolicy;
  final FirearmsShop? shop;
  final int contactsCount;
  final List<Listing> similar;
  final List<SellerReview> reviews;

  const ListingDetail({required this.listing, this.description, required this.attributes, required this.media, required this.isMine, this.conversationId, required this.canReview, this.myReview, this.firearmsPolicy, this.shop, required this.contactsCount, required this.similar, required this.reviews});
  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    final listingJson = _map(json['listing']);
    for (final key in ['display_price_minor', 'display_currency', 'rate_date']) { listingJson[key] = json[key]; }
    final media = _list(json['media']).map(ListingMedia.fromJson).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    if (listingJson['media_path'] == null && media.isNotEmpty) listingJson['media_path'] = media.first.path;
    listingJson['seller'] = json['seller']; listingJson['category'] = json['category']; listingJson['region_name'] = _map(json['region'])['name']; listingJson['municipality_id'] = _map(json['municipality'])['id'];
    final review = _mapOrNull(json['my_review']); final policy = _mapOrNull(json['firearms_policy']); final shop = _mapOrNull(json['shop']);
    return ListingDetail(listing: Listing.fromJson(listingJson), description: listingJson['description'] as String?, attributes: _map(listingJson['attributes']), media: media, isMine: json['is_mine'] as bool? ?? false, conversationId: _mapOrNull(json['contact'])?['conversation_id'] as String?, canReview: json['can_review'] as bool? ?? false, myReview: review == null ? null : SellerReview.fromJson(review), firearmsPolicy: policy == null ? null : FirearmsListingPolicy.fromJson(policy), shop: shop == null ? null : FirearmsShop.fromJson(shop), contactsCount: (json['contacts_count'] as num?)?.toInt() ?? 0, similar: _list(json['similar']).map(Listing.fromJson).toList(), reviews: _list(json['reviews']).map(SellerReview.fromJson).toList());
  }
}

DateTime? _date(Object? value) => value == null ? null : DateTime.tryParse(value.toString())?.toUtc();
Map<String, dynamic> _map(Object? value) => value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};
Map<String, dynamic>? _mapOrNull(Object? value) => value is Map ? Map<String, dynamic>.from(value) : null;
List<Map<String, dynamic>> _list(Object? value) => value is List ? value.whereType<Map>().map((item) => Map<String, dynamic>.from(item)).toList() : const [];
int _ratingHundredths(Object? value) { if (value is int) return value > 5 ? value : value * 100; if (value is num) return (value * 100).round(); return 0; }