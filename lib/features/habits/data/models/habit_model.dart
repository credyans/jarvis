import 'package:jarvis/features/habits/domain/entities/habit.dart';

class HabitModel extends Habit {
  const HabitModel({
    required super.id,
    required super.name,
    required super.icon,
    super.frequency = 'daily',
    super.target = 1,
    super.reminderTime,
    required super.startDate,
    super.completions = const [],
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedStartDate;
    final rawStartDate = json['startDate'] ?? json['start_date'];
    if (rawStartDate is String) {
      parsedStartDate = DateTime.tryParse(rawStartDate) ?? DateTime.now();
    } else if (rawStartDate != null) {
      try { parsedStartDate = (rawStartDate as dynamic).toDate() as DateTime; } catch (_) { parsedStartDate = DateTime.now(); }
    } else {
      parsedStartDate = DateTime.now();
    }

    return HabitModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      icon: json['icon'] as String? ?? '🔄',
      frequency: json['frequency'] as String? ?? 'daily',
      target: json['target'] as int? ?? 1,
      reminderTime: (json['reminderTime'] ?? json['reminder_time']) as String?,
      startDate: parsedStartDate,
      completions: (json['completions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'frequency': frequency,
      'target': target,
      'reminderTime': reminderTime,
      'startDate': startDate.toUtc().toIso8601String(),
      'completions': completions,
    };
  }

  HabitModel copyWith({
    String? id,
    String? name,
    String? icon,
    String? frequency,
    int? target,
    String? Function()? reminderTime,
    DateTime? startDate,
    List<String>? completions,
  }) {
    return HabitModel(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      frequency: frequency ?? this.frequency,
      target: target ?? this.target,
      reminderTime:
          reminderTime != null ? reminderTime() : this.reminderTime,
      startDate: startDate ?? this.startDate,
      completions: completions ?? this.completions,
    );
  }
}
