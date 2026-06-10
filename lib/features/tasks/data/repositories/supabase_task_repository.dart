import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jarvis/features/tasks/domain/repositories/task_repository.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class SupabaseTaskRepository implements TaskRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    return uid;
  }

  // ── Tasks ────────────────────────────────────────────────────────────────────

  TaskModel _rowToTask(Map<String, dynamic> row) {
    DateTime? dueDate;
    final rawDue = row['due_date'];
    if (rawDue is String) dueDate = DateTime.tryParse(rawDue);

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return TaskModel(
      id: row['id'] as String,
      title: row['title'] as String,
      description: row['description'] as String?,
      tagId: row['tag_id'] as String?,
      dueDate: dueDate,
      dueTime: row['due_time'] as String?,
      priority: row['priority'] as int? ?? 0,
      completed: row['completed'] as bool? ?? false,
      emoji: row['emoji'] as String? ?? '📌',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> _taskToRow(TaskModel task) {
    return {
      'id': task.id,
      'user_id': _userId,
      'title': task.title,
      'description': task.description,
      'tag_id': task.tagId,
      'due_date': task.dueDate?.toUtc().toIso8601String(),
      'due_time': task.dueTime,
      'priority': task.priority,
      'completed': task.completed,
      'emoji': task.emoji,
    };
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map((r) => _rowToTask(r)).toList();
  }

  @override
  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    final all = await getAllTasks();
    return all.where((t) {
      if (t.dueDate == null) return false;
      return DateHelpers.isSameDay(t.dueDate!, date);
    }).toList()
      ..sort((a, b) => (a.dueTime ?? '99:99').compareTo(b.dueTime ?? '99:99'));
  }

  @override
  Future<List<TaskModel>> getTasksByTag(String tagId) async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .eq('tag_id', tagId)
        .order('created_at', ascending: false);
    return rows.map((r) => _rowToTask(r)).toList();
  }

  @override
  Future<List<TaskModel>> getIncompleteTasks() async {
    final rows = await _client
        .from('tasks')
        .select()
        .eq('user_id', _userId)
        .eq('completed', false)
        .order('created_at', ascending: false);
    return rows.map((r) => _rowToTask(r)).toList();
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await _client.from('tasks').upsert(_taskToRow(task));
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _client.from('tasks').update({
      'title': task.title,
      'description': task.description,
      'tag_id': task.tagId,
      'due_date': task.dueDate?.toUtc().toIso8601String(),
      'due_time': task.dueTime,
      'priority': task.priority,
      'completed': task.completed,
      'emoji': task.emoji,
    }).eq('id', task.id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _client.from('tasks').delete().eq('id', id).eq('user_id', _userId);
  }

  @override
  Future<void> toggleTaskCompletion(String id) async {
    final rows = await _client
        .from('tasks')
        .select('completed')
        .eq('id', id)
        .eq('user_id', _userId)
        .maybeSingle();
    if (rows == null) return;
    final current = rows['completed'] as bool? ?? false;
    await _client
        .from('tasks')
        .update({'completed': !current})
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<int> getCompletedCountForDate(DateTime date) async {
    final tasks = await getTasksForDate(date);
    return tasks.where((t) => t.completed).length;
  }

  @override
  Future<int> getTotalCountForDate(DateTime date) async {
    final tasks = await getTasksForDate(date);
    return tasks.length;
  }

  // ── Tags ─────────────────────────────────────────────────────────────────────

  TagModel _rowToTag(Map<String, dynamic> row) {
    return TagModel(
      id: row['id'] as String,
      name: row['name'] as String,
      color: row['color'] as String,
      emoji: row['emoji'] as String?,
      sortOrder: row['sort_order'] as int? ?? 0,
    );
  }

  @override
  Future<List<TagModel>> getAllTags() async {
    final rows = await _client
        .from('tags')
        .select()
        .eq('user_id', _userId)
        .order('sort_order', ascending: true);
    return rows.map((r) => _rowToTag(r)).toList();
  }

  @override
  Future<void> addTag(TagModel tag) async {
    await _client.from('tags').upsert({
      'id': tag.id,
      'user_id': _userId,
      'name': tag.name,
      'color': tag.color,
      'emoji': tag.emoji,
      'sort_order': tag.sortOrder,
    });
  }

  @override
  Future<void> deleteTag(String id) async {
    await _client.from('tags').delete().eq('id', id).eq('user_id', _userId);
  }
}
