import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/features/mood/data/datasources/mood_remote_datasource.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/features/mood/data/repositories/mood_repository_impl.dart';
import 'package:jarvis/features/mood/data/repositories/local_mood_repository.dart';
import 'package:jarvis/features/mood/data/repositories/supabase_mood_repository.dart';
import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';

final moodRemoteDataSourceProvider = Provider<MoodRemoteDataSource>((ref) {
  return MoodRemoteDataSource();
});

final moodRepositoryProvider = Provider<MoodRepository>((ref) {
  if (AppConfig.useFirebase) {
    return MoodRepositoryImpl(ref.watch(moodRemoteDataSourceProvider));
  } else if (AppConfig.useSupabase) {
    return SupabaseMoodRepository();
  } else {
    return LocalMoodRepository();
  }
});

final moodProvider =
    StateNotifierProvider<MoodNotifier, AsyncValue<List<MoodEntryModel>>>(
        (ref) {
  return MoodNotifier(ref.watch(moodRepositoryProvider));
});

final todayMoodProvider = FutureProvider<MoodEntryModel?>((ref) async {
  final repo = ref.watch(moodRepositoryProvider);
  return repo.getTodaysMood();
});

class MoodNotifier extends StateNotifier<AsyncValue<List<MoodEntryModel>>> {
  final MoodRepository _repository;

  MoodNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadMoods();
  }

  Future<void> loadMoods() async {
    try {
      final moods = await _repository.getAllMoods();
      state = AsyncValue.data(moods);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveMood(MoodEntryModel mood) async {
    await _repository.saveMood(mood);
    await loadMoods();
  }

  Future<void> deleteMood(String id) async {
    await _repository.deleteMood(id);
    await loadMoods();
  }

  Future<Map<String, int>> getMoodDistribution({int days = 30}) async {
    return _repository.getMoodDistribution(days);
  }

  Future<List<double>> getMoodTrend({int days = 7}) async {
    return _repository.getMoodTrend(days);
  }
}
