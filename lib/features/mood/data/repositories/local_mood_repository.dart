import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/data/repositories/mood_repository.dart' as local;
import 'package:jarvis/data/models/mood_entry_model.dart' as local_mood;

class LocalMoodRepository implements MoodRepository {
  final local.MoodRepository _localRepo = local.MoodRepository();

  MoodEntryModel _toFeatureMood(local_mood.MoodEntryModel m) {
    return MoodEntryModel(
      id: m.id,
      date: m.date,
      mood: m.mood,
      note: m.note,
      createdAt: m.createdAt,
    );
  }

  local_mood.MoodEntryModel _toLocalMood(MoodEntryModel m) {
    return local_mood.MoodEntryModel(
      id: m.id,
      date: m.date,
      mood: m.mood,
      note: m.note,
      createdAt: m.createdAt,
    );
  }

  @override
  Future<List<MoodEntryModel>> getAllMoods() async {
    final list = await _localRepo.getAllMoods();
    return list.map(_toFeatureMood).toList();
  }

  @override
  Future<MoodEntryModel?> getMoodForDate(DateTime date) async {
    final m = await _localRepo.getMoodForDate(date);
    if (m == null) return null;
    return _toFeatureMood(m);
  }

  @override
  Future<MoodEntryModel?> getTodaysMood() async {
    final m = await _localRepo.getTodaysMood();
    if (m == null) return null;
    return _toFeatureMood(m);
  }

  @override
  Future<void> saveMood(MoodEntryModel mood) async {
    await _localRepo.saveMood(_toLocalMood(mood));
  }

  @override
  Future<void> deleteMood(String id) async {
    await _localRepo.deleteMood(id);
  }

  @override
  Future<List<MoodEntryModel>> getMoodsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final list = await _localRepo.getMoodsForRange(start, end);
    return list.map(_toFeatureMood).toList();
  }

  @override
  Future<Map<String, int>> getMoodDistribution(int days) async {
    return await _localRepo.getMoodDistribution(days);
  }

  @override
  Future<List<double>> getMoodTrend(int days) async {
    return await _localRepo.getMoodTrend(days);
  }
}
