import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/mood/data/datasources/mood_remote_datasource.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';

class MoodRepositoryImpl implements MoodRepository {
  final MoodRemoteDataSource _remoteDataSource;

  MoodRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<MoodEntryModel>> getAllMoods() async {
    return await _remoteDataSource.getAllMoods();
  }

  @override
  Future<MoodEntryModel?> getMoodForDate(DateTime date) async {
    final all = await getAllMoods();
    try {
      return all.firstWhere(
        (m) => DateHelpers.isSameDay(m.date, date),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MoodEntryModel?> getTodaysMood() async {
    return getMoodForDate(DateTime.now());
  }

  @override
  Future<void> saveMood(MoodEntryModel mood) async {
    // Remove existing mood for the same date
    final existing = await getMoodForDate(mood.date);
    if (existing != null) {
      await _remoteDataSource.deleteMood(existing.id);
    }
    await _remoteDataSource.saveMood(mood);
  }

  @override
  Future<void> deleteMood(String id) async {
    await _remoteDataSource.deleteMood(id);
  }

  @override
  Future<List<MoodEntryModel>> getMoodsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllMoods();
    return all.where((m) {
      return !m.date.isBefore(start) && !m.date.isAfter(end);
    }).toList();
  }

  @override
  Future<Map<String, int>> getMoodDistribution(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final moods = await getMoodsForRange(start, now);

    final distribution = <String, int>{
      'great': 0,
      'good': 0,
      'okay': 0,
      'low': 0,
      'burnedOut': 0,
    };

    for (final mood in moods) {
      distribution[mood.mood] = (distribution[mood.mood] ?? 0) + 1;
    }

    return distribution;
  }

  @override
  Future<List<double>> getMoodTrend(int days) async {
    final now = DateTime.now();
    final trend = <double>[];

    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final mood = await getMoodForDate(date);
      if (mood != null) {
        trend.add(_moodToValue(mood.mood));
      } else {
        trend.add(0); // no data
      }
    }

    return trend;
  }

  double _moodToValue(String mood) {
    switch (mood) {
      case 'great':
        return 5;
      case 'good':
        return 4;
      case 'okay':
        return 3;
      case 'low':
        return 2;
      case 'burnedOut':
        return 1;
      default:
        return 0;
    }
  }
}
