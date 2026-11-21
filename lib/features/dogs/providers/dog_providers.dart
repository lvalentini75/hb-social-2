import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/dogs/data/dogs_repository.dart';
import 'package:hb_social/features/dogs/domain/dog.dart';

final dogsRepositoryProvider = Provider<DogsRepository>((ref) => DogsRepository(ref.watch(supabaseClientProvider)));
final dogBreedsProvider = FutureProvider<List<DogBreed>>((ref) => ref.watch(dogsRepositoryProvider).breeds());
final myDogsProvider = FutureProvider.autoDispose<List<Dog>>((ref) => ref.watch(dogsRepositoryProvider).myDogs());
final dogsOfProvider = FutureProvider.autoDispose.family<List<Dog>, String>((ref, userId) => ref.watch(dogsRepositoryProvider).dogsOf(userId));
final dogProfileProvider = FutureProvider.autoDispose.family<DogProfile, String>((ref, dogId) => ref.watch(dogsRepositoryProvider).profile(dogId));
final dogRemindersProvider = FutureProvider.autoDispose<List<DogReminder>>((ref) => ref.watch(dogsRepositoryProvider).reminders());
final urgentDogReminderCountProvider = FutureProvider.autoDispose<int>((ref) async => (await ref.watch(dogsRepositoryProvider).reminders(days: 7)).length);
final breederDogsProvider = FutureProvider.autoDispose.family<List<Dog>, String>((ref, pageId) => ref.watch(dogsRepositoryProvider).breederDogs(pageId));
final dogTrialEventsProvider = FutureProvider.autoDispose<List<DogEventChoice>>((ref) => ref.watch(dogsRepositoryProvider).trialEvents());

void invalidateDogs(Ref ref, {String? ownerId, String? dogId}) {
  ref.invalidate(myDogsProvider);
  if (ownerId != null) ref.invalidate(dogsOfProvider(ownerId));
  if (dogId != null) ref.invalidate(dogProfileProvider(dogId));
}