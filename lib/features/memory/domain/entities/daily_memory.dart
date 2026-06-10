class DailyMemory {
  final String date;
  final String? mood;
  final int tasksCompleted;
  final int tasksTotal;
  final int habitsCompleted;
  final int habitsTotal;
  final double moneySpent;
  final double moneyEarned;
  final List<String> highlights;

  const DailyMemory({
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
}
