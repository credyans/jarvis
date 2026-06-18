import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/data/models/long_term_memory_model.dart';
import 'package:jarvis/data/repositories/long_term_memory_repository.dart';

final longTermMemoryRepositoryProvider = Provider<LongTermMemoryRepository>((ref) => LongTermMemoryRepository());

final longTermMemoryProvider = StateNotifierProvider<LongTermMemoryNotifier, AsyncValue<List<LongTermMemoryModel>>>((ref) {
  return LongTermMemoryNotifier(ref.watch(longTermMemoryRepositoryProvider));
});

class LongTermMemoryNotifier extends StateNotifier<AsyncValue<List<LongTermMemoryModel>>> {
  final LongTermMemoryRepository _repository;

  LongTermMemoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMemories();
  }

  Future<void> loadMemories() async {
    try {
      final list = await _repository.getAllMemories();
      state = AsyncValue.data(list);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveMemory(LongTermMemoryModel memory) async {
    await _repository.saveMemory(memory);
    await loadMemories();
  }

  Future<void> deleteMemory(String id) async {
    await _repository.deleteMemory(id);
    await loadMemories();
  }
}
