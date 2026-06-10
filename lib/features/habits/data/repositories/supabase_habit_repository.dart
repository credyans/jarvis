import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jarvis/features/habits/domain/repositories/habit_repository.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class SupabaseHabitRepository implements HabitRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    return uid;
  }

  // ── Mapping helpers ──────────────────────────────────────────────────────────

  HabitModel _rowToHabit(Map<String, dynamic> row) {
    DateTime startDate;
    final rawStart = row['start_date'];
    if (rawStart is String) {
      startDate = DateTime.tryParse(rawStart) ?? DateTime.now();
    } else {
      startDate = DateTime.now();
    }

    final completions = List<String>.from(row['completions'] ?? []);

    return HabitModel(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String? ?? '🔄',
      frequency: row['frequency'] as String? ?? 'daily',
      target: row['target'] as int? ?? 1,
      reminderTime: row['reminder_time'] as String?,
      startDate: startDate,
      completions: completions,
    );
  }

  Map<String, dynamic> _habitToRow(HabitModel habit) {
    return {
      'id': habit.id,
      'user_id': _userId,
      'name': habit.name,
      'icon': habit.icon,
      'frequency': habit.frequency,
      'target': habit.target,
      'reminder_time': habit.reminderTime,
      'start_date': habit.startDate.toUtc().toIso8601String(),
      'completions': habit.completions,
    };
  }

  // ── CRUD ─────────────────────────────────────────────────────────────────────

  @override
  Future<List<HabitModel>> getAllHabits() async {
    final rows = await _client
        .from('habits')
        .select()
        .eq('user_id', _userId)
        .order('start_date', ascending: true);
    return rows.map((r) => _rowToHabit(r)).toList();
  }

  @override
  Future<void> addHabit(HabitModel habit) async {
    await _client.from('habits').upsert(_habitToRow(habit));
  }

  @override
  Future<void> updateHabit(HabitModel habit) async {
    await _client.from('habits').update({
      'name': habit.name,
      'icon': habit.icon,
      'frequency': habit.frequency,
      'target': habit.target,
      'reminder_time': habit.reminderTime,
      'start_date': habit.startDate.toUtc().toIso8601String(),
      'completions': habit.completions,
    }).eq('id', habit.id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteHabit(String id) async {
    await _client.from('habits').delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> toggleCompletion(String id, DateTime date) async {
    final rows = await _client
        .from('habits')
        .select('completions')
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (rows == null) return;

    final dateStr = DateHelpers.dateKey(date);
    final completions = List<String>.from(rows['completions'] ?? []);

    if (completions.contains(dateStr)) {
      completions.remove(dateStr);
    } else {
      completions.add(dateStr);
    }

    await _client
        .from('habits')
        .update({'completions': completions})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Analytics (computed in-memory from fetched records) ──────────────────────

  @override
  bool isCompletedForDate(HabitModel habit, DateTime date) {
    return habit.completions.contains(DateHelpers.dateKey(date));
  }

  @override
  int getCurrentStreak(HabitModel habit) {
    if (habit.completions.isEmpty) return 0;
    final sorted = List<String>.from(habit.completions)..sort();
    final today = DateHelpers.dateKey(DateTime.now());
    final yesterday = DateHelpers.dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );
    if (!sorted.contains(today) && !sorted.contains(yesterday)) return 0;

    int streak = 0;
    DateTime checkDate = sorted.contains(today)
        ? DateTime.now()
        : DateTime.now().subtract(const Duration(days: 1));

    while (sorted.contains(DateHelpers.dateKey(checkDate))) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  @override
  int getBestStreak(HabitModel habit) {
    if (habit.completions.isEmpty) return 0;
    final sorted = List<String>.from(habit.completions)..sort();
    int best = 1, current = 1;
    for (int i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);
      if (curr.difference(prev).inDays == 1) {
        current++;
        if (current > best) best = current;
      } else if (curr.difference(prev).inDays > 1) {
        current = 1;
      }
    }
    return best;
  }

  @override
  double getCompletionPercentage(HabitModel habit, int days) {
    final now = DateTime.now();
    int completed = 0;
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      if (habit.completions.contains(DateHelpers.dateKey(date))) completed++;
    }
    return days > 0 ? (completed / days) * 100 : 0;
  }

  @override
  int getMissedDays(HabitModel habit, int days) {
    final now = DateTime.now();
    int missed = 0;
    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      if (date.isBefore(habit.startDate)) break;
      if (!habit.completions.contains(DateHelpers.dateKey(date))) missed++;
    }
    return missed;
  }

  @override
  Future<int> getCompletedCountForDate(DateTime date) async {
    final habits = await getAllHabits();
    return habits.where((h) => isCompletedForDate(h, date)).length;
  }

  @override
  Future<int> getTotalCountForDate(DateTime date) async {
    final habits = await getAllHabits();
    return habits.where((h) {
      if (date.isBefore(h.startDate)) return false;
      if (h.frequency == 'daily') return true;
      if (h.frequency == 'weekdays') {
        return date.weekday >= 1 && date.weekday <= 5;
      }
      return true;
    }).length;
  }
}
