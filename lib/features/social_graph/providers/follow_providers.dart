import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/social_graph/data/follow_repository.dart';

final followRepositoryProvider = Provider<FollowRepository>((ref) => FollowRepository(ref.watch(supabaseClientProvider)));
final isFollowingProvider = FutureProvider.autoDispose.family<bool, String>((ref, userId) => ref.watch(followRepositoryProvider).isFollowing(userId));