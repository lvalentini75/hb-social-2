import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/marketplace/data/empty_marketplace_repository.dart';
import 'package:hb_social/features/marketplace/data/marketplace_repository.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_listing.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) => const EmptyMarketplaceRepository());
final marketplaceCategoryProvider = StateProvider<MarketplaceCategory>((ref) => MarketplaceCategory.all);
final marketplaceSortProvider = StateProvider<int>((ref) => 0);
final marketplaceListingsProvider = FutureProvider.autoDispose<List<MarketplaceListing>>((ref) {
  ref.watch(marketplaceCategoryProvider);
  ref.watch(marketplaceSortProvider);
  return ref.watch(marketplaceRepositoryProvider).fetchListings();
});
final marketplaceListingProvider = FutureProvider.autoDispose.family<MarketplaceListing?, String>((ref, id) => ref.watch(marketplaceRepositoryProvider).fetchById(id));