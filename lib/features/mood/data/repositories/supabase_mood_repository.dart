import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jarvis/features/mood/domain/repositories/mood_repository.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class SupabaseMoodRepository implements MoodRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    return uid;
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────────

  MoodEntryModel _rowToMood(Map<String, dynamic> row) {
    DateTime date;
    final rawDate = row['date'];
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return MoodEntryModel(
      id: row['id'] as String,
      date: date,
      mood: row['mood'] as String? ?? 'okay',
      note: row['note'] as String?,
      createdAt: createdAt,
    );
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  @override
  Future<List<MoodEntryModel>> getAllMoods() async {
    final rows = await _client
        .from('mood_entries')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return rows.map((r) => _rowToMood(r)).toList();
  }

  @override
  Future<MoodEntryModel?> getMoodForDate(DateTime date) async {
    final all = await getAllMoods();
    try {
      return all.firstWhere((m) => DateHelpers.isSameDay(m.date, date));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<MoodEntryModel?> getTodaysMood() async {
    return getMoodForDate(DateTime.now());
  }

  @override
  Future<void> saveMood(MoodEntryModel mood) async {
    // Remove existing entry for the same date to ensure one-per-day
    final existing = await getMoodForDate(mood.date);
    if (existing != null) {
      await deleteMood(existing.id);
    }
    await _client.from('mood_entries').insert({
      'id': mood.id,
      'user_id': _userId,
      'date': mood.date.toUtc().toIso8601String(),
      'mood': mood.mood,
      'note': mood.note,
    });
  }

  @override
  Future<void> deleteMood(String id) async {
    await _client
        .from('mood_entries')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<List<MoodEntryModel>> getMoodsForRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _client
        .from('mood_entries')
        .select()
        .eq('user_id', _userId)
        .gte('date', start.toUtc().toIso8601String())
        .lte('date', end.toUtc().toIso8601String())
        .order('date', ascending: true);
    return rows.map((r) => _rowToMood(r)).toList();
  }

  // ── Analytics (computed in-memory) ───────────────────────────────────────────

  @override
  Future<Map<String, int>> getMoodDistribution(int days) async {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    final moods = await getMoodsForRange(start, now);

    final distribution = <String, int>{
      'great': 0,
      'good': 0,
      'okay': 0,
      'low': 0,
      'burnedOut': 0,
    };
    for (final mood in moods) {
      distribution[mood.mood] = (distribution[mood.mood] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Future<List<double>> getMoodTrend(int days) async {
    final now = DateTime.now();
    final trend = <double>[];
    for (int i = days - 1; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final mood = await getMoodForDate(date);
      trend.add(mood != null ? _moodToValue(mood.mood) : 0);
    }
    return trend;
  }

  double _moodToValue(String mood) {
    switch (mood) {
      case 'great':
        return 5;
      case 'good':
        return 4;
      case 'okay':
        return 3;
      case 'low':
        return 2;
      case 'burnedOut':
        return 1;
      default:
        return 0;
    }
  }
}
