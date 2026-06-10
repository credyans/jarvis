class Task {
  final String id;
  final String title;
  final String? description;
  final String? tagId;
  final DateTime? dueDate;
  final String? dueTime;
  final int priority;
  final bool completed;
  final String emoji;
  final DateTime createdAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    this.tagId,
    this.dueDate,
    this.dueTime,
    required this.priority,
    required this.completed,
    required this.emoji,
    required this.createdAt,
  });
}
