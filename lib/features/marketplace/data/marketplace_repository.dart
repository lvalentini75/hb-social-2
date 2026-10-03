import 'package:hb_social/features/marketplace/domain/marketplace_listing.dart';

abstract interface class MarketplaceRepository {
  Future<List<MarketplaceListing>> fetchListings();
  Future<List<MarketplaceListing>> fetchMyListings();
  Future<MarketplaceListing?> fetchById(String id);
}