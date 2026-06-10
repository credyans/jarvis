import 'package:jarvis/features/mood/domain/entities/mood_entry.dart';

class MoodEntryModel extends MoodEntry {
  const MoodEntryModel({
    required super.id,
    required super.date,
    required super.mood,
    super.note,
    required super.createdAt,
  });

  factory MoodEntryModel.fromJson(Map<String, dynamic> json) {
    DateTime parsedDate;
    final rawDate = json['date'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate != null) {
      try { parsedDate = (rawDate as dynamic).toDate() as DateTime; } catch (_) { parsedDate = DateTime.now(); }
    } else {
      parsedDate = DateTime.now();
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

    return MoodEntryModel(
      id: json['id'] as String? ?? '',
      date: parsedDate,
      mood: json['mood'] as String? ?? 'good',
      note: json['note'] as String?,
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toUtc().toIso8601String(),
      'mood': mood,
      'note': note,
      'createdAt': createdAt.toUtc().toIso8601String(),
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
}
