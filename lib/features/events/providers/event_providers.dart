import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/features/events/data/empty_event_repository.dart';
import 'package:hb_social/features/events/data/event_repository.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';

final eventRepositoryProvider = Provider<EventRepository>((ref) => const EmptyEventRepository());
final eventViewProvider = StateProvider<int>((ref) => 0);
final eventCategoryProvider = StateProvider<EventCategory>((ref) => EventCategory.all);
final eventsProvider = FutureProvider.autoDispose<List<HuntingEvent>>((ref) {
  ref.watch(eventViewProvider);
  ref.watch(eventCategoryProvider);
  return ref.watch(eventRepositoryProvider).fetchEvents();
});
final eventByIdProvider = FutureProvider.autoDispose.family<HuntingEvent?, String>((ref, id) => ref.watch(eventRepositoryProvider).fetchById(id));