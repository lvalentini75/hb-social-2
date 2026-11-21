import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/services/media_upload_provider.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/ads/data/ads_repository.dart';
import 'package:hb_social/features/ads/data/ads_delivery_repository.dart';
import 'package:hb_social/features/ads/domain/ad_delivery.dart';
import 'package:hb_social/features/ads/domain/ad_models.dart';
import 'package:hb_social/features/ads/domain/ad_reports.dart';
import 'package:hb_social/features/ads/domain/boost_models.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

final adsRepositoryProvider = Provider<AdsRepository>((ref) => AdsRepository(ref.watch(supabaseClientProvider), ref.watch(mediaUploadServiceProvider)));
final adAccountsProvider = FutureProvider.autoDispose<List<AdAccount>>((ref) => ref.watch(adsRepositoryProvider).accounts());
final adAccountProvider = FutureProvider.autoDispose.family<AdAccount, String>((ref, id) => ref.watch(adsRepositoryProvider).account(id));
final adAccountMembersProvider = FutureProvider.autoDispose.family<List<AdAccountMember>, String>((ref, id) => ref.watch(adsRepositoryProvider).members(id));
final adCampaignsProvider = FutureProvider.autoDispose.family<List<AdCampaign>, String>((ref, id) async => (await ref.watch(adsRepositoryProvider).campaigns(id)).items);
final adAudiencesProvider = FutureProvider.autoDispose.family<List<AdAudience>, String>((ref, id) async => (await ref.watch(adsRepositoryProvider).audiences(id)).items);
final adCreativesProvider = FutureProvider.autoDispose.family<List<AdCreative>, String>((ref, id) async => (await ref.watch(adsRepositoryProvider).creatives(id)).items);
final adCampaignReportProvider = FutureProvider.autoDispose.family<AdCampaignReport?, String>((ref, id) => ref.watch(adsRepositoryProvider).campaignReport(id));
final adBillingChargesProvider = FutureProvider.autoDispose.family<List<AdBillingCharge>, String>((ref, id) async => (await ref.watch(adsRepositoryProvider).charges(id)).items);
final adsDashboardDaysProvider = StateProvider<int>((ref) => 7);
final adsDashboardProvider = FutureProvider.autoDispose.family<AdsDashboard, int>((ref, days) => ref.watch(adsRepositoryProvider).dashboard(days));
final adCampaignAggregateProvider = FutureProvider.autoDispose.family<AdCampaignAggregateReport?, String>((ref, id) => ref.watch(adsRepositoryProvider).aggregateCampaignReport(id));
final adAccountBillingProvider = FutureProvider.autoDispose.family<AdAccountBilling?, String>((ref, id) => ref.watch(adsRepositoryProvider).accountBilling(id));
final adAccountReportProvider = FutureProvider.autoDispose.family<AdAccountReport?, String>((ref, id) => ref.watch(adsRepositoryProvider).accountReport(id));
final adReviewQueueProvider = FutureProvider.autoDispose.family<List<AdReviewItem>, String>((ref, status) => ref.watch(adsRepositoryProvider).reviewQueue(status));
final myAdChargesProvider = FutureProvider.autoDispose<List<AdCharge>>((ref) => ref.watch(adsRepositoryProvider).myAdCharges());

class BoostQuoteRequest {
  final String targetType;
  final String targetId;
  final int budgetMinor;
  final int days;
  final String audience;
  const BoostQuoteRequest({required this.targetType, required this.targetId, required this.budgetMinor, required this.days, required this.audience});
  @override bool operator ==(Object other) => other is BoostQuoteRequest && other.targetType == targetType && other.targetId == targetId && other.budgetMinor == budgetMinor && other.days == days && other.audience == audience;
  @override int get hashCode => Object.hash(targetType, targetId, budgetMinor, days, audience);
}

class BoostTargetRequest {
  final String targetType;
  final String targetId;
  const BoostTargetRequest(this.targetType, this.targetId);
  @override bool operator ==(Object other) => other is BoostTargetRequest && other.targetType == targetType && other.targetId == targetId;
  @override int get hashCode => Object.hash(targetType, targetId);
}

final boostQuoteProvider = FutureProvider.autoDispose.family<BoostQuote, BoostQuoteRequest>((ref, request) => ref.watch(adsRepositoryProvider).boostQuote(targetType: request.targetType, targetId: request.targetId, budgetMinor: request.budgetMinor, days: request.days, audience: request.audience));
final boostStatusProvider = FutureProvider.family<BoostStatus?, BoostTargetRequest>((ref, request) => ref.watch(adsRepositoryProvider).boostStatusOf(targetType: request.targetType, targetId: request.targetId));
final myBoostsProvider = AsyncNotifierProvider<MyBoostsNotifier, List<Boost>>(MyBoostsNotifier.new);

class MyBoostsNotifier extends AsyncNotifier<List<Boost>> {
  bool hasMore = true;
  bool loadingMore = false;
  @override Future<List<Boost>> build() async { hasMore = true; final items = await ref.watch(adsRepositoryProvider).myBoosts(); hasMore = items.length == AdsRepository.pageSize; return items; }
  Future<void> loadMore() async { final current = state.value ?? const <Boost>[]; if (!hasMore || loadingMore) return; loadingMore = true; try { final items = await ref.read(adsRepositoryProvider).myBoosts(offset: current.length); hasMore = items.length == AdsRepository.pageSize; state = AsyncData([...current, ...items]); } finally { loadingMore = false; } }
  Future<void> refresh() async { state = const AsyncLoading(); state = await AsyncValue.guard(build); }
}

enum AdsDatePreset { today, yesterday, last7, last14, last30, thisMonth, lastMonth }

extension AdsDatePresetRange on AdsDatePreset {
  DateTimeRangeValue get range {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      AdsDatePreset.today => DateTimeRangeValue(today, today.add(const Duration(days: 1))),
      AdsDatePreset.yesterday => DateTimeRangeValue(today.subtract(const Duration(days: 1)), today),
      AdsDatePreset.last7 => DateTimeRangeValue(today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1))),
      AdsDatePreset.last14 => DateTimeRangeValue(today.subtract(const Duration(days: 13)), today.add(const Duration(days: 1))),
      AdsDatePreset.last30 => DateTimeRangeValue(today.subtract(const Duration(days: 29)), today.add(const Duration(days: 1))),
      AdsDatePreset.thisMonth => DateTimeRangeValue(DateTime(now.year, now.month), DateTime(now.year, now.month + 1)),
      AdsDatePreset.lastMonth => DateTimeRangeValue(DateTime(now.year, now.month - 1), DateTime(now.year, now.month)),
    };
  }
  int get dashboardDays => range.to.difference(range.from).inDays;
}

class DateTimeRangeValue {
  final DateTime from;
  final DateTime to;
  const DateTimeRangeValue(this.from, this.to);
}

class AdReportRequest {
  final String accountId;
  final DateTime from;
  final DateTime to;
  const AdReportRequest(this.accountId, this.from, this.to);
  @override bool operator ==(Object other) => other is AdReportRequest && other.accountId == accountId && other.from == from && other.to == to;
  @override int get hashCode => Object.hash(accountId, from, to);
}

final adsDatePresetProvider = StateProvider<AdsDatePreset>((ref) => AdsDatePreset.last7);
final adsManagerSearchProvider = StateProvider<String>((ref) => '');
final adAccountPeriodReportProvider = FutureProvider.autoDispose.family<AdAccountReport?, AdReportRequest>((ref, request) => ref.watch(adsRepositoryProvider).accountReport(request.accountId, from: request.from, to: request.to));
final adAccountPeriodBillingProvider = FutureProvider.autoDispose.family<AdAccountBilling?, AdReportRequest>((ref, request) => ref.watch(adsRepositoryProvider).accountBilling(request.accountId, from: request.from, to: request.to));
final adAccountCampaignReportsProvider = FutureProvider.autoDispose.family<List<AdCampaignAggregateReport>, AdReportRequest>((ref, request) async {
  final campaigns = await ref.watch(adCampaignsProvider(request.accountId).future);
  final reports = await Future.wait([for (final campaign in campaigns) ref.watch(adsRepositoryProvider).aggregateCampaignReport(campaign.id, from: request.from, to: request.to)]);
  return reports.whereType<AdCampaignAggregateReport>().toList();
});

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) => SharedPreferences.getInstance());
final adsDeliveryRepositoryProvider = FutureProvider<AdsDeliveryRepository>((ref) async => AdsDeliveryRepository(ref.watch(supabaseClientProvider), await ref.watch(sharedPreferencesProvider.future)));
final deliveredAdsProvider = FutureProvider.autoDispose.family<List<DeliveredAd>, AdPlacementRequest>((ref, request) async {
  ref.watch(authSessionProvider);
  return (await ref.watch(adsDeliveryRepositoryProvider.future)).adsForPlacement(request.placement, request.count, request.context);
});
final adsPreferencesProvider = FutureProvider.autoDispose<AdsPreferences>((ref) async { ref.watch(authSessionProvider); return (await ref.watch(adsDeliveryRepositoryProvider.future)).myPreferences(); });
final hiddenAdsProvider = FutureProvider.autoDispose<List<HiddenAd>>((ref) async { ref.watch(authSessionProvider); return (await ref.watch(adsDeliveryRepositoryProvider.future)).myHiddenAds(); });