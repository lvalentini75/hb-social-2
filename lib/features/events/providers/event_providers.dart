import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:hb_social/core/data/page_cursor.dart';
import 'package:hb_social/core/data/paged_notifier.dart';
import 'package:hb_social/core/services/supabase_client_provider.dart';
import 'package:hb_social/features/auth/providers/auth_providers.dart';
import 'package:hb_social/features/events/data/event_repository.dart';
import 'package:hb_social/features/events/data/photon_place_service.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';
import 'package:hb_social/features/pages/providers/page_providers.dart';

typedef NearbyRequest = ({double latitude, double longitude, int radiusKm});

final eventRepositoryProvider = Provider<EventRepository>((ref) => EventRepository(ref.watch(supabaseClientProvider)));
final photonPlaceServiceProvider = Provider<PhotonPlaceService>((ref) => PhotonPlaceService());
final eventViewProvider = StateProvider<EventView>((ref) => EventView.upcoming);
final eventCategoryProvider = StateProvider<String?>((ref) => null);
final nearbyRadiusProvider = StateProvider<int>((ref) => 50);
final eventCategoriesProvider = FutureProvider<List<EventCategory>>((ref) => ref.watch(eventRepositoryProvider).fetchCategories());
final eventsProvider = AsyncNotifierProvider.autoDispose<EventsNotifier, PagedState<HuntingEvent>>(EventsNotifier.new);
final nearbyByLocationProvider = FutureProvider.autoDispose.family<List<HuntingEvent>, NearbyRequest>((ref, request) => ref.watch(eventRepositoryProvider).fetchNearby(latitude: request.latitude, longitude: request.longitude, radiusKm: request.radiusKm));
final nearbyEventsProvider = FutureProvider.autoDispose<List<HuntingEvent>>((ref) async => (await ref.watch(eventRepositoryProvider).fetchEvents(view: EventView.upcoming, category: null)).items.take(3).toList());

class EventsNotifier extends PagedNotifier<HuntingEvent> {
  @override
  Future<Page<HuntingEvent>> fetchPage(PageCursor? cursor) async {
    final session = await ref.watch(authSessionProvider.future);
    return ref.watch(eventRepositoryProvider).fetchEvents(view: ref.watch(eventViewProvider), category: ref.watch(eventCategoryProvider), userId: session?.user.id, cursor: cursor);
  }
}

final eventByIdProvider = FutureProvider.autoDispose.family<HuntingEvent?, String>((ref, id) => ref.watch(eventRepositoryProvider).fetchById(id));
final myParticipationProvider = FutureProvider.autoDispose.family<EventParticipation?, String>((ref, id) => ref.watch(eventRepositoryProvider).myParticipation(id));
final eventGoingPreviewProvider = FutureProvider.autoDispose.family<List<EventGoingPreview>, String>((ref, id) async {
  final session = await ref.watch(authSessionProvider.future);
  return session == null ? const [] : ref.watch(eventRepositoryProvider).goingPreview(id);
});
final eventParticipantsProvider = FutureProvider.autoDispose.family<List<EventParticipant>, String>((ref, id) => ref.watch(eventRepositoryProvider).fetchParticipants(id));
final eventOrganizerSummaryProvider = FutureProvider.autoDispose.family<EventOrganizerSummary?, String>((ref, id) => ref.watch(eventRepositoryProvider).organizerSummary(id));
final managedGroupsForEventsProvider = FutureProvider.autoDispose<List<EventOrganizerChoice>>((ref) => ref.watch(eventRepositoryProvider).managedGroups());
final eventCanManageProvider = FutureProvider.autoDispose.family<bool, HuntingEvent>((ref, event) async {
  final session = await ref.watch(authSessionProvider.future);
  if (session == null) return false;
  if (event.organizer.kind == 'user') return event.organizer.id == session.user.id;
  if (event.organizer.kind == 'page') return (await ref.watch(myPagesProvider.future)).any((page) => page.id == event.organizer.id && page.myRole != null);
  return (await ref.watch(managedGroupsForEventsProvider.future)).any((group) => group.id == event.organizer.id);
});