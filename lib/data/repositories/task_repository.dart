import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/data/models/task_model.dart';
import 'package:jarvis/data/models/tag_model.dart';

class TaskRepository {
  static const String _tasksBox = 'tasks';
  static const String _tagsBox = 'tags';

  Future<Box> _getTasksBox() async {
    if (!Hive.isBoxOpen(_tasksBox)) {
      return await Hive.openBox(_tasksBox);
    }
    return Hive.box(_tasksBox);
  }

  Future<Box> _getTagsBox() async {
    if (!Hive.isBoxOpen(_tagsBox)) {
      return await Hive.openBox(_tagsBox);
    }
    return Hive.box(_tagsBox);
  }

  // ── Tasks ──

  Future<List<TaskModel>> getAllTasks() async {
    final box = await _getTasksBox();
    return box.values
        .map((e) => TaskModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    final all = await getAllTasks();
    return all.where((t) {
      if (t.dueDate == null) return false;
      return t.dueDate!.year == date.year &&
          t.dueDate!.month == date.month &&
          t.dueDate!.day == date.day;
    }).toList()
      ..sort((a, b) => (a.dueTime ?? '99:99').compareTo(b.dueTime ?? '99:99'));
  }

  Future<List<TaskModel>> getTasksByTag(String tagId) async {
    final all = await getAllTasks();
    return all.where((t) => t.tagId == tagId).toList();
  }

  Future<List<TaskModel>> getIncompleteTasks() async {
    final all = await getAllTasks();
    return all.where((t) => !t.completed).toList();
  }

  Future<void> addTask(TaskModel task) async {
    final box = await _getTasksBox();
    await box.put(task.id, task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await addTask(task);
  }

  Future<void> deleteTask(String id) async {
    final box = await _getTasksBox();
    await box.delete(id);
  }

  Future<void> toggleTaskCompletion(String id) async {
    final box = await _getTasksBox();
    final data = box.get(id);
    if (data == null) return;
    final task = TaskModel.fromJson(Map<String, dynamic>.from(data));
    final updated = task.copyWith(completed: !task.completed);
    await box.put(id, updated.toJson());
  }

  // ── Tags ──

  Future<List<TagModel>> getAllTags() async {
    final box = await _getTagsBox();
    return box.values
        .map((e) => TagModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  Future<void> addTag(TagModel tag) async {
    final box = await _getTagsBox();
    await box.put(tag.id, tag.toJson());
  }

  Future<void> deleteTag(String id) async {
    final box = await _getTagsBox();
    await box.delete(id);
  }

  Future<int> getCompletedCountForDate(DateTime date) async {
    final tasks = await getTasksForDate(date);
    return tasks.where((t) => t.completed).length;
  }

  Future<int> getTotalCountForDate(DateTime date) async {
    final tasks = await getTasksForDate(date);
    return tasks.length;
  }
}
