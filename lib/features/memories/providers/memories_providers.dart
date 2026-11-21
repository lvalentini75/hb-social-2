import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/memories/data/memories_repository.dart';
import 'package:hb_social/features/memories/domain/memory.dart';

final memoriesRepositoryProvider = Provider<MemoriesRepository>((ref) => MemoriesRepository(ref.watch(supabaseClientProvider)));
final memoriesTodayProvider = FutureProvider.autoDispose<List<MemoryItem>>((ref) async {
  if (await ref.watch(authSessionProvider.future) == null) return const [];
  return ref.watch(memoriesRepositoryProvider).today();
});