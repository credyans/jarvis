import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/data/models/long_term_memory_model.dart';

class LongTermMemoryRepository {
  static const String _boxName = 'long_term_memories';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<LongTermMemoryModel>> getAllMemories() async {
    final box = await _getBox();
    return box.values
        .map((data) => LongTermMemoryModel.fromJson(Map<String, dynamic>.from(data)))
        .toList();
  }

  Future<List<LongTermMemoryModel>> getMemoriesByPerson(String personId) async {
    final list = await getAllMemories();
    return list.where((m) => m.connectedPeopleIds.contains(personId)).toList();
  }

  Future<void> saveMemory(LongTermMemoryModel memory) async {
    final box = await _getBox();
    await box.put(memory.id, memory.toJson());
  }

  Future<void> deleteMemory(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }
}
