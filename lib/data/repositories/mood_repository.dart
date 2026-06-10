import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/data/models/mood_entry_model.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class MoodRepository {
  static const String _boxName = 'moods';

  Future<Box> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox(_boxName);
    }
    return Hive.box(_boxName);
  }

  Future<List<MoodEntryModel>> getAllMoods() async {
    final box = await _getBox();
    return box.values
        .map((e) => MoodEntryModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

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

  Future<MoodEntryModel?> getTodaysMood() async {
    return getMoodForDate(DateTime.now());
  }

  Future<void> saveMood(MoodEntryModel mood) async {
    final box = await _getBox();
    // Remove existing mood for the same date
    final existing = await getMoodForDate(mood.date);
    if (existing != null) {
      await box.delete(existing.id);
    }
    await box.put(mood.id, mood.toJson());
  }

  Future<void> deleteMood(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  Future<List<MoodEntryModel>> getMoodsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final all = await getAllMoods();
    return all.where((m) {
      return !m.date.isBefore(start) && !m.date.isAfter(end);
    }).toList();
  }

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

  /// Returns mood trend as list of numeric values (5=great, 1=burnedOut)
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

  static String moodEmoji(String mood) {
    switch (mood) {
      case 'great':
        return '🤩';
      case 'good':
        return '😊';
      case 'okay':
        return '😐';
      case 'low':
        return '😔';
      case 'burnedOut':
        return '😫';
      default:
        return '😐';
    }
  }

  static String moodLabel(String mood) {
    switch (mood) {
      case 'great':
        return 'Great';
      case 'good':
        return 'Good';
      case 'okay':
        return 'Okay';
      case 'low':
        return 'Low';
      case 'burnedOut':
        return 'Burned Out';
      default:
        return 'Unknown';
    }
  }
}
