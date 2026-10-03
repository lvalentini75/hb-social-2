import 'package:hb_social/features/hunting/domain/hunting_dog.dart';

abstract interface class DogRepository {
  Future<List<HuntingDog>> fetchDogs();
  Future<HuntingDog?> fetchById(String id);
}