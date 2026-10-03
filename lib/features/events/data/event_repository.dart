import 'package:hb_social/features/events/domain/hunting_event.dart';

abstract interface class EventRepository {
  Future<List<HuntingEvent>> fetchEvents();
  Future<HuntingEvent?> fetchById(String id);
}