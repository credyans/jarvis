import 'package:jarvis/features/tasks/domain/entities/task.dart';

class TaskModel extends Task {
  const TaskModel({
    required super.id,
    required super.title,
    super.description,
    super.tagId,
    super.dueDate,
    super.dueTime,
    super.priority = 0,
    super.completed = false,
    super.emoji = '📝',
    required super.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDueDate;
    final rawDueDate = json['dueDate'] ?? json['due_date'];
    if (rawDueDate is String) {
      parsedDueDate = DateTime.tryParse(rawDueDate);
    } else if (rawDueDate != null) {
      try { parsedDueDate = (rawDueDate as dynamic).toDate() as DateTime; } catch (_) {}
    }

    DateTime parsedCreatedAt;
    final rawCreatedAt = json['createdAt'] ?? json['created_at'];
    if (rawCreatedAt is String) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt) ?? DateTime.now();
    } else if (rawCreatedAt != null) {
      try { parsedCreatedAt = (rawCreatedAt as dynamic).toDate() as DateTime; } catch (_) { parsedCreatedAt = DateTime.now(); }
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return TaskModel(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      tagId: (json['tagId'] ?? json['tag_id']) as String?,
      dueDate: parsedDueDate,
      dueTime: (json['dueTime'] ?? json['due_time']) as String?,
      priority: json['priority'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      emoji: json['emoji'] as String? ?? '📝',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tagId': tagId,
      'dueDate': dueDate?.toUtc().toIso8601String(),
      'dueTime': dueTime,
      'priority': priority,
      'completed': completed,
      'emoji': emoji,
      'createdAt': createdAt.toUtc().toIso8601String(),
    };
  }

  TaskModel copyWith({
    String? id,
    String? title,
    String? Function()? description,
    String? Function()? tagId,
    DateTime? Function()? dueDate,
    String? Function()? dueTime,
    int? priority,
    bool? completed,
    String? emoji,
    DateTime? createdAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description != null ? description() : this.description,
      tagId: tagId != null ? tagId() : this.tagId,
      dueDate: dueDate != null ? dueDate() : this.dueDate,
      dueTime: dueTime != null ? dueTime() : this.dueTime,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      emoji: emoji ?? this.emoji,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
