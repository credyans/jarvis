class MoodEntryModel {
  final String id;
  final DateTime date;
  final String mood;
  final String? note;
  final DateTime createdAt;

  const MoodEntryModel({
    required this.id,
    required this.date,
    required this.mood,
    this.note,
    required this.createdAt,
  });

  factory MoodEntryModel.fromJson(Map<String, dynamic> json) {
    return MoodEntryModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      mood: json['mood'] as String,
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'mood': mood,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MoodEntryModel copyWith({
    String? id,
    DateTime? date,
    String? mood,
    String? Function()? note,
    DateTime? createdAt,
  }) {
    return MoodEntryModel(
      id: id ?? this.id,
      date: date ?? this.date,
      mood: mood ?? this.mood,
      note: note != null ? note() : this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'MoodEntryModel(id: $id, date: $date, mood: $mood, '
        'note: $note, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! MoodEntryModel) return false;
    return id == other.id &&
        date == other.date &&
        mood == other.mood &&
        note == other.note &&
        createdAt == other.createdAt;
  }

  @override
  int get hashCode {
    return Object.hash(id, date, mood, note, createdAt);
  }
}
