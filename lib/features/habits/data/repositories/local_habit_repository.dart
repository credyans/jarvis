import 'package:jarvis/features/habits/domain/repositories/habit_repository.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/data/repositories/habit_repository.dart' as local;
import 'package:jarvis/data/models/habit_model.dart' as local_habit;

class LocalHabitRepository implements HabitRepository {
  final local.HabitRepository _localRepo = local.HabitRepository();

  HabitModel _toFeatureHabit(local_habit.HabitModel h) {
    return HabitModel(
      id: h.id,
      name: h.name,
      icon: h.icon,
      frequency: h.frequency,
      target: h.target,
      reminderTime: h.reminderTime,
      startDate: h.startDate,
      completions: h.completions,
    );
  }

  local_habit.HabitModel _toLocalHabit(HabitModel h) {
    return local_habit.HabitModel(
      id: h.id,
      name: h.name,
      icon: h.icon,
      frequency: h.frequency,
      target: h.target,
      reminderTime: h.reminderTime,
      startDate: h.startDate,
      completions: h.completions,
    );
  }

  @override
  Future<List<HabitModel>> getAllHabits() async {
    final list = await _localRepo.getAllHabits();
    return list.map(_toFeatureHabit).toList();
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    await _localRepo.addHabit(_toLocalHabit(habit));
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await _localRepo.updateHabit(_toLocalHabit(habit));
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _localRepo.deleteHabit(id);
  }

  @override
  Future<void> toggleCompletion(String id, DateTime date) async {
    await _localRepo.toggleCompletion(id, date);
  }

  @override
  bool isCompletedForDate(HabitModel habit, DateTime date) {
    return _localRepo.isCompletedForDate(_toLocalHabit(habit), date);
  }

  @override
  int getCurrentStreak(HabitModel habit) {
    return _localRepo.getCurrentStreak(_toLocalHabit(habit));
  }

  @override
  int getBestStreak(HabitModel habit) {
    return _localRepo.getBestStreak(_toLocalHabit(habit));
  }

  @override
  double getCompletionPercentage(HabitModel habit, int days) {
    return _localRepo.getCompletionPercentage(_toLocalHabit(habit), days);
  }

  @override
  int getMissedDays(HabitModel habit, int days) {
    return _localRepo.getMissedDays(_toLocalHabit(habit), days);
  }

  @override
  Future<int> getCompletedCountForDate(DateTime date) async {
    return await _localRepo.getCompletedCountForDate(date);
  }

  @override
  Future<int> getTotalCountForDate(DateTime date) async {
    return await _localRepo.getTotalCountForDate(date);
  }
}
