import 'package:jarvis/features/habits/data/datasources/habit_remote_datasource.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/features/habits/domain/repositories/habit_repository.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class HabitRepositoryImpl implements HabitRepository {
  final HabitRemoteDataSource _remoteDataSource;

  HabitRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<HabitModel>> getAllHabits() async {
    return await _remoteDataSource.getAllHabits();
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    await _remoteDataSource.addHabit(habit);
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await addHabit(habit);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _remoteDataSource.deleteHabit(id);
  }

  @override
  Future<void> toggleCompletion(String id, DateTime date) async {
    final habit = await _remoteDataSource.getHabit(id);
    if (habit == null) return;

    final dateStr = DateHelpers.dateKey(date);
    final completions = List<String>.from(habit.completions);

    if (completions.contains(dateStr)) {
      completions.remove(dateStr);
    } else {
      completions.add(dateStr);
    }

    final updated = habit.copyWith(completions: completions);
    await _remoteDataSource.addHabit(updated);
  }

  @override
  bool isCompletedForDate(HabitModel habit, DateTime date) {
    return habit.completions.contains(DateHelpers.dateKey(date));
  }

  @override
  int getCurrentStreak(HabitModel habit) {
    if (habit.completions.isEmpty) return 0;

    final sorted = List<String>.from(habit.completions)..sort();
    final today = DateHelpers.dateKey(DateTime.now());
    final yesterday = DateHelpers.dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    if (!sorted.contains(today) && !sorted.contains(yesterday)) {
      return 0;
    }

    int streak = 0;
    DateTime checkDate = sorted.contains(today)
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    while (sorted.contains(DateHelpers.dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    return streak;
  }

  @override
  int getBestStreak(HabitModel habit) {
    if (habit.completions.isEmpty) return 0;

    final sorted = List<String>.from(habit.completions)..sort();
    int bestStreak = 1;
    int currentStreak = 1;

    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);
      final diff = curr.difference(prev).inDays;

      if (diff == 1) {
        currentStreak++;
        if (currentStreak > bestStreak) {
          bestStreak = currentStreak;
        }
      } else if (diff > 1) {
        currentStreak = 1;
      }
    }

    return bestStreak;
  }

  @override
  double getCompletionPercentage(HabitModel habit, int days) {
    final now = DateTime.now();
    int completedDays = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      if (habit.completions.contains(DateHelpers.dateKey(date))) {
        completedDays++;
      }
    }

    return days > 0 ? (completedDays / days) * 100 : 0;
  }

  @override
  int getMissedDays(HabitModel habit, int days) {
    final now = DateTime.now();
    int missed = 0;

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      if (date.isBefore(habit.startDate)) break;
      if (!habit.completions.contains(DateHelpers.dateKey(date))) {
        missed++;
      }
    }

    return missed;
  }

  @override
  Future<int> getCompletedCountForDate(DateTime date) async {
    final habits = await getAllHabits();
    return habits.where((h) => isCompletedForDate(h, date)).length;
  }

  @override
  Future<int> getTotalCountForDate(DateTime date) async {
    final habits = await getAllHabits();
    return habits.where((h) {
      if (date.isBefore(h.startDate)) return false;
      if (h.frequency == 'daily') return true;
      if (h.frequency == 'weekdays') {
        return date.weekday >= 1 && date.weekday <= 5;
      }
      return true;
    }).length;
  }
}
