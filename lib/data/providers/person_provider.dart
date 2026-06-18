import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/data/models/person_model.dart';
import 'package:jarvis/data/repositories/person_repository.dart';

final personRepositoryProvider = Provider<PersonRepository>((ref) => PersonRepository());

final personProvider = StateNotifierProvider<PersonNotifier, AsyncValue<List<PersonModel>>>((ref) {
  return PersonNotifier(ref.watch(personRepositoryProvider));
});

class PersonNotifier extends StateNotifier<AsyncValue<List<PersonModel>>> {
  final PersonRepository _repository;

  PersonNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadPeople();
  }

  Future<void> loadPeople() async {
    try {
      final list = await _repository.getAllPeople();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> savePerson(PersonModel person) async {
    await _repository.savePerson(person);
    await loadPeople();
  }

  Future<void> deletePerson(String id) async {
    await _repository.deletePerson(id);
    await loadPeople();
  }
}
