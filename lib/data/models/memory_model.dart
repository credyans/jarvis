class DailyMemoryModel {
  final String date;
  final String? mood;
  final int tasksCompleted;
  final int tasksTotal;
  final int habitsCompleted;
  final int habitsTotal;
  final double moneySpent;
  final double moneyEarned;
  final List<String> highlights;

  const DailyMemoryModel({
    required this.date,
    this.mood,
    this.tasksCompleted = 0,
    this.tasksTotal = 0,
    this.habitsCompleted = 0,
    this.habitsTotal = 0,
    this.moneySpent = 0.0,
    this.moneyEarned = 0.0,
    this.highlights = const [],
  });

  factory DailyMemoryModel.fromJson(Map<String, dynamic> json) {
    return DailyMemoryModel(
      date: json['date'] as String,
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

  @override
  String toString() {
    return 'DailyMemoryModel(date: $date, mood: $mood, '
        'tasks: $tasksCompleted/$tasksTotal, '
        'habits: $habitsCompleted/$habitsTotal, '
        'spent: $moneySpent, earned: $moneyEarned, '
        'highlights: ${highlights.length} entries)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! DailyMemoryModel) return false;
    return date == other.date &&
        mood == other.mood &&
        tasksCompleted == other.tasksCompleted &&
        tasksTotal == other.tasksTotal &&
        habitsCompleted == other.habitsCompleted &&
        habitsTotal == other.habitsTotal &&
        moneySpent == other.moneySpent &&
        moneyEarned == other.moneyEarned &&
        _listEquals(highlights, other.highlights);
  }

  @override
  int get hashCode {
    return Object.hash(
      date,
      mood,
      tasksCompleted,
      tasksTotal,
      habitsCompleted,
      habitsTotal,
      moneySpent,
      moneyEarned,
      Object.hashAll(highlights),
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
