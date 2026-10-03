import 'package:hb_social/features/events/data/event_repository.dart';
import 'package:hb_social/features/events/domain/hunting_event.dart';

class EmptyEventRepository implements EventRepository {
  const EmptyEventRepository();

  @override
  Future<List<HuntingEvent>> fetchEvents() async => const [];

  @override
  Future<HuntingEvent?> fetchById(String id) async => null;
}