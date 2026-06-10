class Habit {
  final String id;
  final String name;
  final String icon;
  final String frequency;
  final int target;
  final String? reminderTime;
  final DateTime startDate;
  final List<String> completions;

  const Habit({
    required this.id,
    required this.name,
    required this.icon,
    required this.frequency,
    required this.target,
    this.reminderTime,
    required this.startDate,
    required this.completions,
  });
}
