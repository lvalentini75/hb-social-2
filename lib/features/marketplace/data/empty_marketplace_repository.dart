import 'package:hb_social/features/marketplace/data/marketplace_repository.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_listing.dart';

class EmptyMarketplaceRepository implements MarketplaceRepository {
  const EmptyMarketplaceRepository();

  @override
  Future<List<MarketplaceListing>> fetchListings() async => const [];

  @override
  Future<List<MarketplaceListing>> fetchMyListings() async => const [];

  @override
  Future<MarketplaceListing?> fetchById(String id) async => null;
}