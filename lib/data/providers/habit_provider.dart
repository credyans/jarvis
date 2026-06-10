import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/features/habits/data/datasources/habit_remote_datasource.dart';
import 'package:jarvis/features/habits/data/repositories/habit_repository_impl.dart';
import 'package:jarvis/features/habits/data/repositories/local_habit_repository.dart';
import 'package:jarvis/features/habits/data/repositories/supabase_habit_repository.dart';
import 'package:jarvis/features/habits/domain/repositories/habit_repository.dart';

final habitRemoteDataSourceProvider = Provider<HabitRemoteDataSource>((ref) {
  return HabitRemoteDataSource();
});

final habitRepositoryProvider = Provider<HabitRepository>((ref) {
  if (AppConfig.useFirebase) {
    return HabitRepositoryImpl(ref.watch(habitRemoteDataSourceProvider));
  } else if (AppConfig.useSupabase) {
    return SupabaseHabitRepository();
  } else {
    return LocalHabitRepository();
  }
});

final habitProvider =
    StateNotifierProvider<HabitNotifier, AsyncValue<List<HabitModel>>>((ref) {
  return HabitNotifier(ref.watch(habitRepositoryProvider));
});

class HabitNotifier extends StateNotifier<AsyncValue<List<HabitModel>>> {
  final HabitRepository _repository;

  HabitNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadHabits();
  }

  Future<void> loadHabits() async {
    try {
      final habits = await _repository.getAllHabits();
      state = AsyncValue.data(habits);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addHabit(HabitModel habit) async {
    await _repository.addHabit(habit);
    await loadHabits();
  }

  Future<void> updateHabit(HabitModel habit) async {
    await _repository.updateHabit(habit);
    await loadHabits();
  }

  Future<void> deleteHabit(String id) async {
    await _repository.deleteHabit(id);
    await loadHabits();
  }

  Future<void> toggleCompletion(String id, DateTime date) async {
    await _repository.toggleCompletion(id, date);
    await loadHabits();
  }

  int getCurrentStreak(HabitModel habit) {
    return _repository.getCurrentStreak(habit);
  }

  int getBestStreak(HabitModel habit) {
    return _repository.getBestStreak(habit);
  }

  double getCompletionPercentage(HabitModel habit, {int days = 30}) {
    return _repository.getCompletionPercentage(habit, days);
  }

  bool isCompletedToday(HabitModel habit) {
    return _repository.isCompletedForDate(habit, DateTime.now());
  }
}
