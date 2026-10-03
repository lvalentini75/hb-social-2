import 'package:hb_social/features/hunting/domain/hunting_outing.dart';

abstract interface class DiaryRepository {
  Future<List<HuntingOuting>> fetchOutings();
  Future<HuntingOuting?> fetchById(String id);
}