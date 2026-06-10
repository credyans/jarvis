import 'package:jarvis/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/features/tasks/domain/repositories/task_repository.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskRemoteDataSource _remoteDataSource;

  TaskRepositoryImpl(this._remoteDataSource);

  @override
  Future<List<TaskModel>> getAllTasks() async {
    return await _remoteDataSource.getAllTasks();
  }

  @override
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

  @override
  Future<List<TaskModel>> getTasksByTag(String tagId) async {
    final all = await getAllTasks();
    return all.where((t) => t.tagId == tagId).toList();
  }

  @override
  Future<List<TaskModel>> getIncompleteTasks() async {
    final all = await getAllTasks();
    return all.where((t) => !t.completed).toList();
  }

  @override
  Future<void> addTask(TaskModel task) async {
    await _remoteDataSource.addTask(task);
  }

  @override
  Future<void> updateTask(TaskModel task) async {
    await _remoteDataSource.updateTask(task);
  }

  @override
  Future<void> deleteTask(String id) async {
    await _remoteDataSource.deleteTask(id);
  }

  @override
  Future<void> toggleTaskCompletion(String id) async {
    await _remoteDataSource.toggleTaskCompletion(id);
  }

  @override
  Future<List<TagModel>> getAllTags() async {
    return await _remoteDataSource.getAllTags();
  }

  @override
  Future<void> addTag(TagModel tag) async {
    await _remoteDataSource.addTag(tag);
  }

  @override
  Future<void> deleteTag(String id) async {
    await _remoteDataSource.deleteTag(id);
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
}
