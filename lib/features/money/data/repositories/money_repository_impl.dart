import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/money/data/datasources/money_remote_datasource.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';
import 'package:jarvis/features/money/domain/repositories/money_repository.dart';

class MoneyRepositoryImpl implements MoneyRepository {
  final MoneyRemoteDataSource _remoteDataSource;

  MoneyRepositoryImpl(this._remoteDataSource);

  // ── Transactions ──

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    return await _remoteDataSource.getAllTransactions();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForMonth(
    int year,
    int month,
  ) async {
    final all = await getAllTransactions();
    return all
        .where((t) => t.date.year == year && t.date.month == month)
        .toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForDate(DateTime date) async {
    final all = await getAllTransactions();
    return all.where((t) => DateHelpers.isSameDay(t.date, date)).toList();
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final all = await getAllTransactions();
    return all.take(limit).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _remoteDataSource.saveTransaction(transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _remoteDataSource.deleteTransaction(id);
  }

  @override
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

  @override
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

  @override
  Future<double> getSpentToday() async {
    final transactions = await getTransactionsForDate(DateTime.now());
    return transactions
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
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

  @override
  Future<List<FinancialGoalModel>> getAllGoals() async {
    return await _remoteDataSource.getAllGoals();
  }

  @override
  Future<void> addGoal(FinancialGoalModel goal) async {
    await _remoteDataSource.saveGoal(goal);
  }

  @override
  Future<void> updateGoal(FinancialGoalModel goal) async {
    await addGoal(goal);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _remoteDataSource.deleteGoal(id);
  }

  // ── Debts ──

  @override
  Future<List<DebtModel>> getAllDebts() async {
    return await _remoteDataSource.getAllDebts();
  }

  @override
  Future<List<DebtModel>> getOwedToMe() async {
    final all = await getAllDebts();
    return all.where((d) => d.type == 'owedToMe').toList();
  }

  @override
  Future<List<DebtModel>> getIOwe() async {
    final all = await getAllDebts();
    return all.where((d) => d.type == 'iOwe').toList();
  }

  @override
  Future<void> addDebt(DebtModel debt) async {
    await _remoteDataSource.saveDebt(debt);
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    await addDebt(debt);
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _remoteDataSource.deleteDebt(id);
  }

  @override
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

  @override
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

  @override
  Future<List<DebtModel>> getUpcomingPayments() async {
    final debts = await getAllDebts();
    final now = DateTime.now();
    return debts.where((d) {
      return !d.endDate.isBefore(now);
    }).toList();
  }

  // ── Savings Plans Placeholder ──

  @override
  Future<List<SavingsPlanModel>> getAllSavingsPlans() async {
    throw UnimplementedError();
  }

  @override
  Future<void> addSavingsPlan(SavingsPlanModel plan) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateSavingsPlan(SavingsPlanModel plan) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteSavingsPlan(String id) async {
    throw UnimplementedError();
  }

  // ── Bill Reminders Placeholder ──

  @override
  Future<List<BillReminderModel>> getAllBillReminders() async {
    throw UnimplementedError();
  }

  @override
  Future<void> addBillReminder(BillReminderModel reminder) async {
    throw UnimplementedError();
  }

  @override
  Future<void> updateBillReminder(BillReminderModel reminder) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteBillReminder(String id) async {
    throw UnimplementedError();
  }
}
