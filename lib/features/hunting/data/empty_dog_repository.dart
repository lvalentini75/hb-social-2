import 'package:hb_social/features/hunting/data/dog_repository.dart';
import 'package:hb_social/features/hunting/domain/hunting_dog.dart';

class EmptyDogRepository implements DogRepository {
  const EmptyDogRepository();

  @override
  Future<List<HuntingDog>> fetchDogs() async => const [];

  @override
  Future<HuntingDog?> fetchById(String id) async => null;
}