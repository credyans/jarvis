class HabitModel {
  final String id;
  final String name;
  final String icon;
  final String frequency;
  final int target;
  final String? reminderTime;
  final DateTime startDate;
  final List<String> completions;

  const HabitModel({
    required this.id,
    required this.name,
    required this.icon,
    this.frequency = 'daily',
    this.target = 1,
    this.reminderTime,
    required this.startDate,
    this.completions = const [],
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: json['id'] as String,
      name: json['name'] as String,
      icon: json['icon'] as String,
      frequency: json['frequency'] as String? ?? 'daily',
      target: json['target'] as int? ?? 1,
      reminderTime: json['reminderTime'] as String?,
      startDate: DateTime.parse(json['startDate'] as String),
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
      'startDate': startDate.toIso8601String(),
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

  @override
  String toString() {
    return 'HabitModel(id: $id, name: $name, icon: $icon, '
        'frequency: $frequency, target: $target, '
        'reminderTime: $reminderTime, startDate: $startDate, '
        'completions: ${completions.length} entries)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! HabitModel) return false;
    return id == other.id &&
        name == other.name &&
        icon == other.icon &&
        frequency == other.frequency &&
        target == other.target &&
        reminderTime == other.reminderTime &&
        startDate == other.startDate &&
        _listEquals(completions, other.completions);
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      icon,
      frequency,
      target,
      reminderTime,
      startDate,
      Object.hashAll(completions),
    );
  }

  static bool _listEquals<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
