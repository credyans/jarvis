class TaskModel {
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

  const TaskModel({
    required this.id,
    required this.title,
    this.description,
    this.tagId,
    this.dueDate,
    this.dueTime,
    this.priority = 0,
    this.completed = false,
    this.emoji = '📝',
    required this.createdAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      tagId: json['tagId'] as String?,
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'] as String)
          : null,
      dueTime: json['dueTime'] as String?,
      priority: json['priority'] as int? ?? 0,
      completed: json['completed'] as bool? ?? false,
      emoji: json['emoji'] as String? ?? '📝',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'tagId': tagId,
      'dueDate': dueDate?.toIso8601String(),
      'dueTime': dueTime,
      'priority': priority,
      'completed': completed,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
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

  @override
  String toString() {
    return 'TaskModel(id: $id, title: $title, description: $description, '
        'tagId: $tagId, dueDate: $dueDate, dueTime: $dueTime, '
        'priority: $priority, completed: $completed, emoji: $emoji, '
        'createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! TaskModel) return false;
    return id == other.id &&
        title == other.title &&
        description == other.description &&
        tagId == other.tagId &&
        dueDate == other.dueDate &&
        dueTime == other.dueTime &&
        priority == other.priority &&
        completed == other.completed &&
        emoji == other.emoji &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      title,
      description,
      tagId,
      dueDate,
      dueTime,
      priority,
      completed,
      emoji,
      createdAt,
    );
  }
}
