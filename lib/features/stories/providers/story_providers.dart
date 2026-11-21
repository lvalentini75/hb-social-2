import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/stories/data/story_repository.dart';
import 'package:hb_social/features/stories/domain/story.dart';

final storyRepositoryProvider = Provider<StoryRepository>((ref) => StoryRepository(ref.watch(supabaseClientProvider)));

/// Kept alive for the session and explicitly invalidated after publish/view/delete.
final storyTrayProvider = FutureProvider<List<StoryTrayItem>>((ref) => ref.watch(storyRepositoryProvider).tray());
final authorStoriesProvider = FutureProvider.autoDispose.family<StoryViewerData, String>((ref, authorId) => ref.watch(storyRepositoryProvider).storiesForAuthor(authorId));
final storyViewersProvider = FutureProvider.autoDispose.family<List<StoryViewerProfile>, String>((ref, storyId) => ref.watch(storyRepositoryProvider).viewers(storyId));
final storyHighlightsProvider = FutureProvider.autoDispose.family<List<StoryHighlight>, String>((ref, ownerId) => ref.watch(storyRepositoryProvider).highlights(ownerId));
final myHighlightStoriesProvider = FutureProvider.autoDispose<List<HighlightStory>>((ref) => ref.watch(storyRepositoryProvider).myStories());