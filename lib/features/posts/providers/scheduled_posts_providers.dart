import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/posts/data/scheduled_posts_repository.dart';
import 'package:hb_social/features/posts/domain/scheduled_post.dart';

final scheduledPostsRepositoryProvider = Provider<ScheduledPostsRepository>((ref) => ScheduledPostsRepository(ref.watch(supabaseClientProvider)));
final scheduledPostsProvider = FutureProvider.autoDispose.family<List<ScheduledPost>, String?>((ref, pageId) => ref.watch(scheduledPostsRepositoryProvider).list(pageId: pageId));