class MoodEntry {
  final String id;
  final DateTime date;
  final String mood;
  final String? note;
  final DateTime createdAt;

  const MoodEntry({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    required this.createdAt,
  });
}
