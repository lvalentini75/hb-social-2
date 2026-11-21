import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/social_graph/domain/online_friend.dart';

/// Friends currently online, read from the `online_friends(limit)` RPC.
/// Refreshed every 60 seconds while the page is mounted.
final onlineFriendsProvider = FutureProvider.autoDispose.family<List<OnlineFriend>, int>((ref, limit) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return const <OnlineFriend>[];
  final timer = Timer.periodic(const Duration(seconds: 60), (_) => ref.invalidateSelf());
  ref.onDispose(timer.cancel);
  final rows = await ref.watch(supabaseClientProvider).rpc('online_friends', params: {'p_limit': limit});
  if (rows is! List) return const <OnlineFriend>[];
  return rows.map((row) => OnlineFriend.fromJson(Map<String, dynamic>.from(row as Map))).toList();
});
