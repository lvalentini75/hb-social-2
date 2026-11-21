import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/home/domain/community_stats.dart';

/// Public community counters from the `hb_community_stats()` RPC.
/// Callable by guests; when it fails the card hides itself.
final communityStatsProvider = FutureProvider<CommunityStats>((ref) async {
  final rows = await ref.watch(supabaseClientProvider).rpc('hb_community_stats');
  if (rows is List && rows.isNotEmpty) return CommunityStats.fromJson(Map<String, dynamic>.from(rows.first as Map));
  if (rows is Map) return CommunityStats.fromJson(Map<String, dynamic>.from(rows));
  return const CommunityStats(hunters: 0, groups: 0, listings: 0);
});
