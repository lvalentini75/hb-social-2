import 'package:hb_social/features/hunting/data/diary_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_outing.dart';

class EmptyDiaryRepository implements DiaryRepository {
  const EmptyDiaryRepository();

  @override
  Future<List<HuntingOuting>> fetchOutings() async => const [];

  @override
  Future<HuntingOuting?> fetchById(String id) async => null;
}