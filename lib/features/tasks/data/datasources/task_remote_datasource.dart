import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';

class TaskRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference<Map<String, dynamic>> get _tasksRef =>
      _firestore.collection('users').doc(_uid).collection('tasks');

  CollectionReference<Map<String, dynamic>> get _tagsRef =>
      _firestore.collection('users').doc(_uid).collection('tags');

  Future<List<TaskModel>> getAllTasks() async {
    final query = await _tasksRef.get();
    final list = query.docs.map((doc) => TaskModel.fromJson(doc.data())).toList();
    // Sort in memory by descending createdAt
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> addTask(TaskModel task) async {
    await _tasksRef.doc(task.id).set(task.toJson());
  }

  Future<void> updateTask(TaskModel task) async {
    await addTask(task);
  }

  Future<void> deleteTask(String id) async {
    await _tasksRef.doc(id).delete();
  }

  Future<void> toggleTaskCompletion(String id) async {
    final doc = await _tasksRef.doc(id).get();
    if (doc.exists && doc.data() != null) {
      final task = TaskModel.fromJson(doc.data()!);
      final updated = task.copyWith(completed: !task.completed);
      await _tasksRef.doc(id).set(updated.toJson());
    }
  }

  Future<List<TagModel>> getAllTags() async {
    final query = await _tagsRef.get();
    final list = query.docs.map((doc) => TagModel.fromJson(doc.data())).toList();
    // Sort in memory by sortOrder
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  }

  Future<void> addTag(TagModel tag) async {
    await _tagsRef.doc(tag.id).set(tag.toJson());
  }

  Future<void> deleteTag(String id) async {
    await _tagsRef.doc(id).delete();
  }
}
