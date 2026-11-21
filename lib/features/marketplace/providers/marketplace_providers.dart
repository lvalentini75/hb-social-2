import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/i18n/user_settings_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/hunting/data/reference_repository.dart';
import 'package:hb_social/features/marketplace/data/marketplace_repository.dart';
import 'package:hb_social/features/marketplace/domain/listing.dart';
import 'package:hb_social/features/marketplace/domain/marketplace_category.dart';
import 'package:hb_social/core/providers/platform_providers.dart';
import 'package:hb_social/core/services/platform_info.dart';
import 'package:hb_social/core/services/app_exception.dart';

class MarketplaceFilters {
  final String? categoryId;
  final String? regionId;
  final Municipality? municipality;
  final int? radiusKm;
  final int? priceMinMinor;
  final int? priceMaxMinor;
  final Set<ListingCondition> conditions;
  final bool shippingOnly;
  final String query;
  final String sort;
  final String? sellerId;
  const MarketplaceFilters({this.categoryId, this.regionId, this.municipality, this.radiusKm, this.priceMinMinor, this.priceMaxMinor, this.conditions = const {}, this.shippingOnly = false, this.query = '', this.sort = 'recent', this.sellerId});
  int get activeCount => [categoryId, regionId, municipality, priceMinMinor, priceMaxMinor].where((item) => item != null).length + conditions.length + (shippingOnly ? 1 : 0) + (sort == 'recent' ? 0 : 1);
  MarketplaceFilters copyWith({String? categoryId, bool clearCategory = false, String? regionId, bool clearRegion = false, Municipality? municipality, bool clearMunicipality = false, int? radiusKm, int? priceMinMinor, int? priceMaxMinor, Set<ListingCondition>? conditions, bool? shippingOnly, String? query, String? sort, String? sellerId}) => MarketplaceFilters(categoryId: clearCategory ? null : categoryId ?? this.categoryId, regionId: clearRegion ? null : regionId ?? this.regionId, municipality: clearMunicipality ? null : municipality ?? this.municipality, radiusKm: clearMunicipality ? null : radiusKm ?? this.radiusKm, priceMinMinor: priceMinMinor, priceMaxMinor: priceMaxMinor, conditions: conditions ?? this.conditions, shippingOnly: shippingOnly ?? this.shippingOnly, query: query ?? this.query, sort: sort ?? this.sort, sellerId: sellerId ?? this.sellerId);
}

class MarketplaceFiltersNotifier extends Notifier<MarketplaceFilters> { @override MarketplaceFilters build() => const MarketplaceFilters(); void set(MarketplaceFilters value) => state = value; void reset() => state = const MarketplaceFilters(); }
final marketplaceFiltersProvider = NotifierProvider<MarketplaceFiltersNotifier, MarketplaceFilters>(MarketplaceFiltersNotifier.new);
final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) => MarketplaceRepository(ref.watch(supabaseClientProvider)));
final firearmsShowcaseEnabledProvider = Provider<bool>((ref) => ref.watch(platformConfigProvider).value?.release.firearmsShowcasePlatforms.contains(currentPlatformName) ?? false);
final marketplaceCategoriesProvider = FutureProvider<List<MarketplaceCategory>>((ref) async {
  final items = await ref.watch(marketplaceRepositoryProvider).fetchCategories(country: ref.watch(userSettingsProvider).countryCode ?? 'IT');
  return ref.watch(firearmsShowcaseEnabledProvider) ? items : items.where((item) => !item.isRestricted && !item.requiresReview).toList();
});

class ListingsState { final List<Listing> items; final bool hasMore; final bool loadingMore; const ListingsState({required this.items, required this.hasMore, this.loadingMore = false}); ListingsState copyWith({List<Listing>? items, bool? hasMore, bool? loadingMore}) => ListingsState(items: items ?? this.items, hasMore: hasMore ?? this.hasMore, loadingMore: loadingMore ?? this.loadingMore); }

class ListingsNotifier extends AsyncNotifier<ListingsState> {
  @override Future<ListingsState> build() => _load(0);
  Future<ListingsState> _load(int offset) async { final filters = ref.watch(marketplaceFiltersProvider); final settings = ref.watch(userSettingsProvider); final items = await ref.watch(marketplaceRepositoryProvider).browse(country: settings.countryCode ?? 'IT', categoryId: filters.categoryId, regionId: filters.regionId, municipalityId: filters.municipality?.id, lat: filters.municipality?.lat, lng: filters.municipality?.lng, radiusKm: filters.radiusKm, priceMinMinor: filters.priceMinMinor, priceMaxMinor: filters.priceMaxMinor, currency: settings.currencyCode, conditions: filters.conditions.toList(), shipping: filters.shippingOnly ? true : null, query: filters.query, sellerId: filters.sellerId, sort: filters.sort, offset: offset); final visible = ref.watch(firearmsShowcaseEnabledProvider) ? items : items.where((item) => !item.isMediated).toList(); return ListingsState(items: visible, hasMore: items.length == MarketplaceRepository.pageSize); }
  Future<void> loadMore() async { final current = state.value; if (current == null || !current.hasMore || current.loadingMore) return; state = AsyncData(current.copyWith(loadingMore: true)); try { final next = await _load(current.items.length); state = AsyncData(ListingsState(items: [...current.items, ...next.items], hasMore: next.hasMore)); } catch (error, stack) { state = AsyncError(error, stack); } }
  void updateFavorite(String id, bool value) { final current = state.value; if (current == null) return; state = AsyncData(current.copyWith(items: current.items.map((item) => item.id == id ? item.copyWith(isFavorite: value, favoriteCount: (item.favoriteCount + (value ? 1 : -1)).clamp(0, 1 << 31)) : item).toList())); }
}

final listingsProvider = AsyncNotifierProvider<ListingsNotifier, ListingsState>(ListingsNotifier.new);
final listingDetailResponseProvider = FutureProvider.autoDispose.family<ListingDetailResponse, String>((ref, id) async { final settings = ref.watch(userSettingsProvider); final response = await ref.watch(marketplaceRepositoryProvider).detailResponse(id, currency: settings.currencyCode, country: settings.countryCode ?? 'IT'); if (!ref.watch(firearmsShowcaseEnabledProvider) && response.detail?.listing.isMediated == true) throw const AppException('marketplace.firearms.notice.platform'); return response; });
final listingDetailProvider = FutureProvider.autoDispose.family<ListingDetail, String>((ref, id) async { final settings = ref.watch(userSettingsProvider); final detail = await ref.watch(marketplaceRepositoryProvider).detail(id, currency: settings.currencyCode, country: settings.countryCode ?? 'IT'); if (!ref.watch(firearmsShowcaseEnabledProvider) && detail.listing.isMediated) throw const AppException('marketplace.firearms.notice.platform'); return detail; });
final favoritesProvider = FutureProvider.autoDispose<List<Listing>>((ref) async { final items = await ref.watch(marketplaceRepositoryProvider).myFavorites(); return ref.watch(firearmsShowcaseEnabledProvider) ? items : items.where((item) => !item.isMediated).toList(); });
final sellerProfileProvider = FutureProvider.autoDispose.family<SellerSummary, String>((ref, id) => ref.watch(marketplaceRepositoryProvider).sellerProfile(id));
final sellerReviewsProvider = FutureProvider.autoDispose.family<List<SellerReview>, String>((ref, id) => ref.watch(marketplaceRepositoryProvider).sellerReviews(id));
final sellerListingsProvider = FutureProvider.autoDispose.family<List<Listing>, String>((ref, id) async { final settings = ref.watch(userSettingsProvider); final items = await ref.watch(marketplaceRepositoryProvider).browse(country: settings.countryCode ?? 'IT', sellerId: id, currency: settings.currencyCode); return ref.watch(firearmsShowcaseEnabledProvider) ? items : items.where((item) => !item.isMediated).toList(); });
final sellerHasListingsProvider = FutureProvider.autoDispose.family<bool, String>((ref, id) async { final settings = ref.watch(userSettingsProvider); return (await ref.watch(marketplaceRepositoryProvider).browse(country: settings.countryCode ?? 'IT', sellerId: id, currency: settings.currencyCode)).isNotEmpty; });
final myListingsProvider = FutureProvider.autoDispose.family<List<MyListing>, ListingStatus>((ref, status) async { final items = await ref.watch(marketplaceRepositoryProvider).myListings(status); return ref.watch(firearmsShowcaseEnabledProvider) ? items : items.where((item) => !item.listing.isMediated).toList(); });
final listingContactsProvider = FutureProvider.autoDispose.family<List<ListingContact>, String>((ref, id) => ref.watch(marketplaceRepositoryProvider).contacts(id));