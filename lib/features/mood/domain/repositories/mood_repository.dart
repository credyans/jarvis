import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';

abstract class MoodRepository {
  Future<List<MoodEntryModel>> getAllMoods();
  Future<MoodEntryModel?> getMoodForDate(DateTime date);
  Future<MoodEntryModel?> getTodaysMood();
  Future<void> saveMood(MoodEntryModel mood);
  Future<void> deleteMood(String id);
  Future<List<MoodEntryModel>> getMoodsForRange(DateTime start, DateTime end);
  Future<Map<String, int>> getMoodDistribution(int days);
  Future<List<double>> getMoodTrend(int days);

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
