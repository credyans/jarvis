import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';

abstract class TaskRepository {
  Future<List<TaskModel>> getAllTasks();
  Future<List<TaskModel>> getTasksForDate(DateTime date);
  Future<List<TaskModel>> getTasksByTag(String tagId);
  Future<List<TaskModel>> getIncompleteTasks();
  Future<void> addTask(TaskModel task);
  Future<void> updateTask(TaskModel task);
  Future<void> deleteTask(String id);
  Future<void> toggleTaskCompletion(String id);
  Future<List<TagModel>> getAllTags();
  Future<void> addTag(TagModel tag);
  Future<void> deleteTag(String id);
  Future<int> getCompletedCountForDate(DateTime date);
  Future<int> getTotalCountForDate(DateTime date);
}
