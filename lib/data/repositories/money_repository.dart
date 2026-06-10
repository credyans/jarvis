import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/data/models/transaction_model.dart';
import 'package:jarvis/data/models/financial_goal_model.dart';
import 'package:jarvis/data/models/debt_model.dart';
import 'package:jarvis/data/models/savings_plan_model.dart';
import 'package:jarvis/data/models/bill_reminder_model.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class MoneyRepository {
  static const String _transactionsBox = 'transactions';
  static const String _goalsBox = 'financial_goals';
  static const String _debtsBox = 'debts';
  static const String _savingsBox = 'savings_plans';
  static const String _billsBox = 'bill_reminders';

  Future<Box> _getTransactionsBox() async {
    if (!Hive.isBoxOpen(_transactionsBox)) {
      return await Hive.openBox(_transactionsBox);
    }
    return Hive.box(_transactionsBox);
  }

  Future<Box> _getGoalsBox() async {
    if (!Hive.isBoxOpen(_goalsBox)) {
      return await Hive.openBox(_goalsBox);
    }
    return Hive.box(_goalsBox);
  }

  Future<Box> _getDebtsBox() async {
    if (!Hive.isBoxOpen(_debtsBox)) {
      return await Hive.openBox(_debtsBox);
    }
    return Hive.box(_debtsBox);
  }

  Future<Box> _getSavingsBox() async {
    if (!Hive.isBoxOpen(_savingsBox)) {
      return await Hive.openBox(_savingsBox);
    }
    return Hive.box(_savingsBox);
  }

  Future<Box> _getBillsBox() async {
    if (!Hive.isBoxOpen(_billsBox)) {
      return await Hive.openBox(_billsBox);
    }
    return Hive.box(_billsBox);
  }

  // ── Transactions ──

  Future<List<TransactionModel>> getAllTransactions() async {
    final box = await _getTransactionsBox();
    return box.values
        .map((e) => TransactionModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  Future<List<TransactionModel>> getTransactionsForMonth(
    int year,
    int month,
  ) async {
    final all = await getAllTransactions();
    return all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  Future<List<TransactionModel>> getTransactionsForDate(DateTime date) async {
    final all = await getAllTransactions();
    return all.where((t) => DateHelpers.isSameDay(t.date, date)).toList();
  }

  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final all = await getAllTransactions();
    return all.take(limit).toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final box = await _getTransactionsBox();
    await box.put(transaction.id, transaction.toJson());
  }

  Future<void> deleteTransaction(String id) async {
    final box = await _getTransactionsBox();
    await box.delete(id);
  }

  Future<double> getTotalIncome({int? year, int? month}) async {
    List<TransactionModel> transactions;
    if (year != null && month != null) {
      transactions = await getTransactionsForMonth(year, month);
    } else {
      transactions = await getAllTransactions();
    }
    return transactions
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getTotalExpenses({int? year, int? month}) async {
    List<TransactionModel> transactions;
    if (year != null && month != null) {
      transactions = await getTransactionsForMonth(year, month);
    } else {
      transactions = await getAllTransactions();
    }
    return transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<double> getSpentToday() async {
    final transactions = await getTransactionsForDate(DateTime.now());
    return transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  Future<Map<String, double>> getExpensesByCategory({
    int? year,
    int? month,
  }) async {
    List<TransactionModel> transactions;
    if (year != null && month != null) {
      transactions = await getTransactionsForMonth(year, month);
    } else {
      transactions = await getAllTransactions();
    }

    final categories = <String, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      categories[t.category] = (categories[t.category] ?? 0) + t.amount;
    }
    return categories;
  }

  // ── Financial Goals ──

  Future<List<FinancialGoalModel>> getAllGoals() async {
    final box = await _getGoalsBox();
    return box.values
        .map((e) => FinancialGoalModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addGoal(FinancialGoalModel goal) async {
    final box = await _getGoalsBox();
    await box.put(goal.id, goal.toJson());
  }

  Future<void> updateGoal(FinancialGoalModel goal) async {
    await addGoal(goal);
  }

  Future<void> deleteGoal(String id) async {
    final box = await _getGoalsBox();
    await box.delete(id);
  }

  // ── Debts (Owed To Me / I Owe) ──

  Future<List<DebtModel>> getAllDebts() async {
    final box = await _getDebtsBox();
    return box.values
        .map((e) => DebtModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<List<DebtModel>> getOwedToMe() async {
    final all = await getAllDebts();
    return all.where((d) => d.type == 'owedToMe').toList();
  }

  Future<List<DebtModel>> getIOwe() async {
    final all = await getAllDebts();
    return all.where((d) => d.type == 'iOwe').toList();
  }

  Future<void> addDebt(DebtModel debt) async {
    final box = await _getDebtsBox();
    await box.put(debt.id, debt.toJson());
  }

  Future<void> updateDebt(DebtModel debt) async {
    await addDebt(debt);
  }

  Future<void> deleteDebt(String id) async {
    final box = await _getDebtsBox();
    await box.delete(id);
  }

  Future<double> getTotalOwedToMe() async {
    final debts = await getOwedToMe();
    double total = 0;
    for (final debt in debts) {
      final paidAmount = debt.payments
          .where((p) => p.status == 'paid')
          .fold(0.0, (sum, p) => sum + p.amount);
      final totalExpected = _calculateTotalExpected(debt);
      total += (totalExpected - paidAmount);
    }
    return total;
  }

  Future<double> getTotalIOwe() async {
    final debts = await getIOwe();
    double total = 0;
    for (final debt in debts) {
      final paidAmount = debt.payments
          .where((p) => p.status == 'paid')
          .fold(0.0, (sum, p) => sum + p.amount);
      final totalExpected = _calculateTotalExpected(debt);
      total += (totalExpected - paidAmount);
    }
    return total;
  }

  double _calculateTotalExpected(DebtModel debt) {
    if (debt.frequency == 'one-time') return debt.amount;
    final months = debt.endDate.difference(debt.startDate).inDays ~/ 30;
    return debt.amount * (months > 0 ? months : 1);
  }

  /// Get debts with upcoming payments due
  Future<List<DebtModel>> getUpcomingPayments() async {
    final debts = await getAllDebts();
    final now = DateTime.now();
    return debts.where((d) {
      return !d.endDate.isBefore(now);
    }).toList();
  }

  // ── Savings Plans ──

  Future<List<SavingsPlanModel>> getAllSavingsPlans() async {
    final box = await _getSavingsBox();
    return box.values
        .map((e) => SavingsPlanModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> addSavingsPlan(SavingsPlanModel plan) async {
    final box = await _getSavingsBox();
    await box.put(plan.id, plan.toJson());
  }

  Future<void> updateSavingsPlan(SavingsPlanModel plan) async {
    await addSavingsPlan(plan);
  }

  Future<void> deleteSavingsPlan(String id) async {
    final box = await _getSavingsBox();
    await box.delete(id);
  }

  // ── Bill Reminders ──

  Future<List<BillReminderModel>> getAllBillReminders() async {
    final box = await _getBillsBox();
    return box.values
        .map((e) => BillReminderModel.fromJson(Map<String, dynamic>.from(e)))
        .toList()
      ..sort((a, b) => a.dueDay.compareTo(b.dueDay));
  }

  Future<void> addBillReminder(BillReminderModel reminder) async {
    final box = await _getBillsBox();
    await box.put(reminder.id, reminder.toJson());
  }

  Future<void> updateBillReminder(BillReminderModel reminder) async {
    await addBillReminder(reminder);
  }

  Future<void> deleteBillReminder(String id) async {
    final box = await _getBillsBox();
    await box.delete(id);
  }
}
