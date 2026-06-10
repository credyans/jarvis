import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/tasks/domain/repositories/task_repository.dart';
import 'package:jarvis/features/habits/domain/repositories/habit_repository.dart';
import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';
import 'package:jarvis/features/money/domain/repositories/money_repository.dart';
import 'package:jarvis/features/memory/data/models/daily_memory_model.dart';
import 'package:jarvis/features/memory/domain/repositories/memory_repository.dart';

class MemoryRepositoryImpl implements MemoryRepository {
  final TaskRepository _taskRepo;
  final HabitRepository _habitRepo;
  final MoodRepository _moodRepo;
  final MoneyRepository _moneyRepo;

  MemoryRepositoryImpl({
    required TaskRepository taskRepo,
    required HabitRepository habitRepo,
    required MoodRepository moodRepo,
    required MoneyRepository moneyRepo,
  })  : _taskRepo = taskRepo,
        _habitRepo = habitRepo,
        _moodRepo = moodRepo,
        _moneyRepo = moneyRepo;

  @override
  Future<DailyMemoryModel> getDailyMemory(DateTime date) async {
    final tasks = await _taskRepo.getTasksForDate(date);
    final tasksCompleted = tasks.where((t) => t.completed).length;

    final habits = await _habitRepo.getAllHabits();
    final habitsForDate = habits.where((h) {
      if (date.isBefore(h.startDate)) return false;
      if (h.frequency == 'daily') return true;
      if (h.frequency == 'weekdays') {
        return date.weekday >= 1 && date.weekday <= 5;
      }
      return true;
    }).toList();
    final habitsCompleted = habitsForDate
        .where((h) => h.completions.contains(DateHelpers.dateKey(date)))
        .length;

    final mood = await _moodRepo.getMoodForDate(date);

    final transactions = await _moneyRepo.getTransactionsForDate(date);
    final spent = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
    final earned = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);

    final highlights = <String>[];
    if (tasksCompleted == tasks.length && tasks.isNotEmpty) {
      highlights.add('All tasks completed! 🎉');
    }
    if (habitsCompleted == habitsForDate.length && habitsForDate.isNotEmpty) {
      highlights.add('Perfect habit day! 💪');
    }
    if (mood?.mood == 'great') {
      highlights.add('Feeling great today! 🤩');
    }

    return DailyMemoryModel(
      date: DateHelpers.dateKey(date),
      mood: mood?.mood,
      tasksCompleted: tasksCompleted,
      tasksTotal: tasks.length,
      habitsCompleted: habitsCompleted,
      habitsTotal: habitsForDate.length,
      moneySpent: spent,
      moneyEarned: earned,
      highlights: highlights,
    );
  }

  @override
  Future<Map<String, dynamic>> getWeeklySummary(DateTime weekStart) async {
    final days = List.generate(
      7,
      (i) => weekStart.add(Duration(days: i)),
    );

    final moodTrend = <double>[];
    int totalTasksDone = 0;
    int totalTasksAll = 0;
    int totalHabitsDone = 0;
    int totalHabitsAll = 0;
    double totalSpent = 0;
    double totalEarned = 0;

    for (final day in days) {
      final memory = await getDailyMemory(day);
      moodTrend
          .add(memory.mood != null ? _moodToValue(memory.mood!) : 0);
      totalTasksDone += memory.tasksCompleted;
      totalTasksAll += memory.tasksTotal;
      totalHabitsDone += memory.habitsCompleted;
      totalHabitsAll += memory.habitsTotal;
      totalSpent += memory.moneySpent;
      totalEarned += memory.moneyEarned;
    }

    return {
      'moodTrend': moodTrend,
      'tasksCompleted': totalTasksDone,
      'tasksTotal': totalTasksAll,
      'habitsCompleted': totalHabitsDone,
      'habitsTotal': totalHabitsAll,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'habitConsistency': totalHabitsAll > 0
          ? (totalHabitsDone / totalHabitsAll * 100).round()
          : 0,
      'taskCompletionRate': totalTasksAll > 0
          ? (totalTasksDone / totalTasksAll * 100).round()
          : 0,
    };
  }

  @override
  Future<Map<String, dynamic>> getMonthlySummary(int year, int month) async {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final days = List.generate(
      daysInMonth,
      (i) => DateTime(year, month, i + 1),
    );

    final now = DateTime.now();
    final moodValues = <double>[];
    int totalTasksDone = 0;
    int totalTasksAll = 0;
    int totalHabitsDone = 0;
    int totalHabitsAll = 0;
    double totalSpent = 0;
    double totalEarned = 0;
    String? bestHabit;
    int bestHabitCount = 0;
    DateTime? mostProductiveDay;
    int mostProductiveTasks = 0;

    final habits = await _habitRepo.getAllHabits();

    for (final day in days) {
      if (day.isAfter(now)) break;

      final memory = await getDailyMemory(day);
      if (memory.mood != null) {
        moodValues.add(_moodToValue(memory.mood!));
      }
      totalTasksDone += memory.tasksCompleted;
      totalTasksAll += memory.tasksTotal;
      totalHabitsDone += memory.habitsCompleted;
      totalHabitsAll += memory.habitsTotal;
      totalSpent += memory.moneySpent;
      totalEarned += memory.moneyEarned;

      if (memory.tasksCompleted > mostProductiveTasks) {
        mostProductiveTasks = memory.tasksCompleted;
        mostProductiveDay = day;
      }
    }

    // Find best habit
    for (final habit in habits) {
      final count = habit.completions
          .where((c) {
            final d = DateTime.tryParse(c);
            return d != null && d.year == year && d.month == month;
          })
          .length;
      if (count > bestHabitCount) {
        bestHabitCount = count;
        bestHabit = habit.name;
      }
    }

    return {
      'moodAverage':
          moodValues.isNotEmpty
               ? moodValues.reduce((a, b) => a + b) / moodValues.length
               : 0.0,
      'tasksCompleted': totalTasksDone,
      'tasksTotal': totalTasksAll,
      'habitsCompleted': totalHabitsDone,
      'habitsTotal': totalHabitsAll,
      'totalSpent': totalSpent,
      'totalEarned': totalEarned,
      'savings': totalEarned - totalSpent,
      'bestHabit': bestHabit,
      'bestHabitCount': bestHabitCount,
      'mostProductiveDay': mostProductiveDay?.toIso8601String(),
      'mostProductiveTasks': mostProductiveTasks,
      'habitConsistency': totalHabitsAll > 0
          ? (totalHabitsDone / totalHabitsAll * 100).round()
          : 0,
    };
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
