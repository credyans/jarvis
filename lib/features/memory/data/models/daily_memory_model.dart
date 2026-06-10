import 'package:jarvis/features/memory/domain/entities/daily_memory.dart';

class DailyMemoryModel extends DailyMemory {
  const DailyMemoryModel({
    required super.date,
    super.mood,
    super.tasksCompleted = 0,
    super.tasksTotal = 0,
    super.habitsCompleted = 0,
    super.habitsTotal = 0,
    super.moneySpent = 0.0,
    super.moneyEarned = 0.0,
    super.highlights = const [],
  });

  factory DailyMemoryModel.fromJson(Map<String, dynamic> json) {
    return DailyMemoryModel(
      date: json['date'] as String? ?? '',
      mood: json['mood'] as String?,
      tasksCompleted: json['tasksCompleted'] as int? ?? 0,
      tasksTotal: json['tasksTotal'] as int? ?? 0,
      habitsCompleted: json['habitsCompleted'] as int? ?? 0,
      habitsTotal: json['habitsTotal'] as int? ?? 0,
      moneySpent: (json['moneySpent'] as num?)?.toDouble() ?? 0.0,
      moneyEarned: (json['moneyEarned'] as num?)?.toDouble() ?? 0.0,
      highlights: (json['highlights'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'mood': mood,
      'tasksCompleted': tasksCompleted,
      'tasksTotal': tasksTotal,
      'habitsCompleted': habitsCompleted,
      'habitsTotal': habitsTotal,
      'moneySpent': moneySpent,
      'moneyEarned': moneyEarned,
      'highlights': highlights,
    };
  }

  DailyMemoryModel copyWith({
    String? date,
    String? Function()? mood,
    int? tasksCompleted,
    int? tasksTotal,
    int? habitsCompleted,
    int? habitsTotal,
    double? moneySpent,
    double? moneyEarned,
    List<String>? highlights,
  }) {
    return DailyMemoryModel(
      date: date ?? this.date,
      mood: mood != null ? mood() : this.mood,
      tasksCompleted: tasksCompleted ?? this.tasksCompleted,
      tasksTotal: tasksTotal ?? this.tasksTotal,
      habitsCompleted: habitsCompleted ?? this.habitsCompleted,
      habitsTotal: habitsTotal ?? this.habitsTotal,
      moneySpent: moneySpent ?? this.moneySpent,
      moneyEarned: moneyEarned ?? this.moneyEarned,
      highlights: highlights ?? this.highlights,
    );
  }

  /// Returns the task completion ratio (0.0 to 1.0).
  double get taskCompletionRate {
    if (tasksTotal <= 0) return 0.0;
    return (tasksCompleted / tasksTotal).clamp(0.0, 1.0);
  }

  /// Returns the habit completion ratio (0.0 to 1.0).
  double get habitCompletionRate {
    if (habitsTotal <= 0) return 0.0;
    return (habitsCompleted / habitsTotal).clamp(0.0, 1.0);
  }

  /// Net money flow for the day (earned - spent).
  double get netMoney => moneyEarned - moneySpent;
}
