import 'package:jarvis/features/tasks/domain/repositories/task_repository.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/data/repositories/task_repository.dart' as local;
import 'package:jarvis/data/models/task_model.dart' as local_task;
import 'package:jarvis/data/models/tag_model.dart' as local_tag;

class LocalTaskRepository implements TaskRepository {
  final local.TaskRepository _localRepo = local.TaskRepository();

  TaskModel _toFeatureTask(local_task.TaskModel t) {
    return TaskModel(
      id: t.id,
      title: t.title,
      description: t.description,
      tagId: t.tagId,
      dueDate: t.dueDate,
      dueTime: t.dueTime,
      priority: t.priority,
      completed: t.completed,
      emoji: t.emoji,
      createdAt: t.createdAt,
    );
  }

  local_task.TaskModel _toLocalTask(TaskModel t) {
    return local_task.TaskModel(
      id: t.id,
      title: t.title,
      description: t.description,
      tagId: t.tagId,
      dueDate: t.dueDate,
      dueTime: t.dueTime,
      priority: t.priority,
      completed: t.completed,
      emoji: t.emoji,
      createdAt: t.createdAt,
    );
  }

  TagModel _toFeatureTag(local_tag.TagModel t) {
    return TagModel(
      id: t.id,
      name: t.name,
      color: t.color,
      emoji: t.emoji,
      sortOrder: t.sortOrder,
    );
  }

  local_tag.TagModel _toLocalTag(TagModel t) {
    return local_tag.TagModel(
      id: t.id,
      name: t.name,
      color: t.color,
      emoji: t.emoji,
      sortOrder: t.sortOrder,
    );
  }

  @override
  Future<List<TaskModel>> getAllTasks() async {
    final list = await _localRepo.getAllTasks();
    return list.map(_toFeatureTask).toList();
  }

  @override
  Future<List<TaskModel>> getTasksForDate(DateTime date) async {
    final list = await _localRepo.getTasksForDate(date);
    return list.map(_toFeatureTask).toList();
  }

  @override
  Future<List<TaskModel>> getTasksByTag(String tagId) async {
    final list = await _localRepo.getTasksByTag(tagId);
    return list.map(_toFeatureTask).toList();
  }

  @override
  Future<List<TaskModel>> getIncompleteTasks() async {
    final list = await _localRepo.getIncompleteTasks();
    return list.map(_toFeatureTask).toList();
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await _localRepo.addTask(_toLocalTask(task));
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _localRepo.updateTask(_toLocalTask(task));
  }

  @override
  Future<void> deleteTask(String id) async {
    await _localRepo.deleteTask(id);
  }

  @override
  Future<void> toggleTaskCompletion(String id) async {
    await _localRepo.toggleTaskCompletion(id);
  }

  @override
  Future<List<TagModel>> getAllTags() async {
    final list = await _localRepo.getAllTags();
    return list.map(_toFeatureTag).toList();
  }

  @override
  Future<void> addTag(TagModel tag) async {
    await _localRepo.addTag(_toLocalTag(tag));
  }

  @override
  Future<void> deleteTag(String id) async {
    await _localRepo.deleteTag(id);
  }

  @override
  Future<int> getCompletedCountForDate(DateTime date) async {
    return await _localRepo.getCompletedCountForDate(date);
  }

  @override
  Future<int> getTotalCountForDate(DateTime date) async {
    return await _localRepo.getTotalCountForDate(date);
  }
}
