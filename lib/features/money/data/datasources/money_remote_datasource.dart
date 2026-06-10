import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';

class MoneyRemoteDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _uid => _auth.currentUser?.uid ?? 'anonymous';

  CollectionReference<Map<String, dynamic>> get _transactionsRef =>
      _firestore.collection('users').doc(_uid).collection('transactions');

  CollectionReference<Map<String, dynamic>> get _goalsRef =>
      _firestore.collection('users').doc(_uid).collection('financial_goals');

  CollectionReference<Map<String, dynamic>> get _debtsRef =>
      _firestore.collection('users').doc(_uid).collection('debts');

  // Transactions
  Future<List<TransactionModel>> getAllTransactions() async {
    final query = await _transactionsRef.get();
    final list = query.docs.map((doc) => TransactionModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> saveTransaction(TransactionModel transaction) async {
    await _transactionsRef.doc(transaction.id).set(transaction.toJson());
  }

  Future<void> deleteTransaction(String id) async {
    await _transactionsRef.doc(id).delete();
  }

  // Goals
  Future<List<FinancialGoalModel>> getAllGoals() async {
    final query = await _goalsRef.get();
    final list = query.docs.map((doc) => FinancialGoalModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveGoal(FinancialGoalModel goal) async {
    await _goalsRef.doc(goal.id).set(goal.toJson());
  }

  Future<void> deleteGoal(String id) async {
    await _goalsRef.doc(id).delete();
  }

  // Debts
  Future<List<DebtModel>> getAllDebts() async {
    final query = await _debtsRef.get();
    final list = query.docs.map((doc) => DebtModel.fromJson(doc.data())).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  Future<void> saveDebt(DebtModel debt) async {
    await _debtsRef.doc(debt.id).set(debt.toJson());
  }

  Future<void> deleteDebt(String id) async {
    await _debtsRef.doc(id).delete();
  }
}
