import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/hunting/data/diary_repository.dart';
import 'package:hb_social/features/hunting/data/dog_repository.dart';
import 'package:hb_social/features/hunting/data/empty_diary_repository.dart';
import 'package:hb_social/features/hunting/data/empty_dog_repository.dart';
import 'package:hb_social/features/hunting/data/empty_hunting_repository.dart';
import 'package:hb_social/features/hunting/data/hunting_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_dog.dart';
import 'package:hb_social/features/hunting/domain/hunting_outing.dart';

final huntingRepositoryProvider = Provider<HuntingRepository>((ref) => const EmptyHuntingRepository());
final diaryRepositoryProvider = Provider<DiaryRepository>((ref) => const EmptyDiaryRepository());
final dogRepositoryProvider = Provider<DogRepository>((ref) => const EmptyDogRepository());

final diaryViewProvider = StateProvider<int>((ref) => 0);
final diaryFilterProvider = StateProvider<int>((ref) => 0);
final outingsProvider = FutureProvider.autoDispose<List<HuntingOuting>>((ref) {
  ref.watch(diaryFilterProvider);
  return ref.watch(diaryRepositoryProvider).fetchOutings();
});
final outingByIdProvider = FutureProvider.autoDispose.family<HuntingOuting?, String>((ref, id) => ref.watch(diaryRepositoryProvider).fetchById(id));

final dogsProvider = FutureProvider.autoDispose<List<HuntingDog>>((ref) => ref.watch(dogRepositoryProvider).fetchDogs());
final dogByIdProvider = FutureProvider.autoDispose.family<HuntingDog?, String>((ref, id) => ref.watch(dogRepositoryProvider).fetchById(id));