import 'package:jarvis/features/habits/data/models/habit_model.dart';

abstract class HabitRepository {
  Future<List<HabitModel>> getAllHabits();
  Future<void> addHabit(HabitModel habit);
  Future<void> updateHabit(HabitModel habit);
  Future<void> deleteHabit(String id);
  Future<void> toggleCompletion(String id, DateTime date);
  bool isCompletedForDate(HabitModel habit, DateTime date);
  int getCurrentStreak(HabitModel habit);
  int getBestStreak(HabitModel habit);
  double getCompletionPercentage(HabitModel habit, int days);
  int getMissedDays(HabitModel habit, int days);
  Future<int> getCompletedCountForDate(DateTime date);
  Future<int> getTotalCountForDate(DateTime date);
}
