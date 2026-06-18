import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/data/models/person_model.dart';

class PersonRepository {
  static const String _boxName = 'people';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<PersonModel>> getAllPeople() async {
    final box = await _getBox();
    return box.values
        .map((data) => PersonModel.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<PersonModel?> getPerson(String id) async {
    final box = await _getBox();
    final data = box.get(id);
    if (data == null) return null;
    return PersonModel.fromJson(Map<String, dynamic>.from(data));
  }

  Future<void> savePerson(PersonModel person) async {
    final box = await _getBox();
    await box.put(person.id, person.toJson());
  }

  Future<void> deletePerson(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
