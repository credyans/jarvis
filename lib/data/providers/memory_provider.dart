import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/features/memory/data/models/daily_memory_model.dart';
import 'package:jarvis/features/memory/data/repositories/memory_repository_impl.dart';
import 'package:jarvis/features/memory/domain/repositories/memory_repository.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/data/providers/money_provider.dart';

final memoryRepositoryProvider = Provider<MemoryRepository>((ref) {
  return MemoryRepositoryImpl(
    taskRepo: ref.watch(taskRepositoryProvider),
    habitRepo: ref.watch(habitRepositoryProvider),
    moodRepo: ref.watch(moodRepositoryProvider),
    moneyRepo: ref.watch(moneyRepositoryProvider),
  );
});

final dailyMemoryProvider =
    FutureProvider.family<DailyMemoryModel, DateTime>((ref, date) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getDailyMemory(date);
});

final weeklyMemoryProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>(
        (ref, weekStart) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getWeeklySummary(weekStart);
});

final monthlyMemoryProvider =
    FutureProvider.family<Map<String, dynamic>, DateTime>((ref, date) async {
  final repo = ref.watch(memoryRepositoryProvider);
  return repo.getMonthlySummary(date.year, date.month);
});
