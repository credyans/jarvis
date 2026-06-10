import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';

class HabitRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference<Map<String, dynamic>> get _habitsRef =>
      _firestore.collection('users').doc(_uid).collection('habits');

  Future<List<HabitModel>> getAllHabits() async {
    final query = await _habitsRef.get();
    return query.docs.map((doc) => HabitModel.fromJson(doc.data())).toList();
  }

  Future<void> addHabit(HabitModel habit) async {
    await _habitsRef.doc(habit.id).set(habit.toJson());
  }

  Future<void> deleteHabit(String id) async {
    await _habitsRef.doc(id).delete();
  }

  Future<HabitModel?> getHabit(String id) async {
    final doc = await _habitsRef.doc(id).get();
    if (!doc.exists || doc.data() == null) return null;
    return HabitModel.fromJson(doc.data()!);
  }
}
