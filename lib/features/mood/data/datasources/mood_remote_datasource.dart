import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';

class MoodRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference<Map<String, dynamic>> get _moodsRef =>
      _firestore.collection('users').doc(_uid).collection('moods');

  Future<List<MoodEntryModel>> getAllMoods() async {
    final query = await _moodsRef.get();
    final list = query.docs.map((doc) => MoodEntryModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> saveMood(MoodEntryModel mood) async {
    await _moodsRef.doc(mood.id).set(mood.toJson());
  }

  Future<void> deleteMood(String id) async {
    await _moodsRef.doc(id).delete();
  }
}
