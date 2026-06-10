import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';

abstract class MoneyRepository {
  // Transactions
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getTransactionsForMonth(int year, int month);
  Future<List<TransactionModel>> getTransactionsForDate(DateTime date);
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10});
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<double> getTotalIncome({int? year, int? month});
  Future<double> getTotalExpenses({int? year, int? month});
  Future<double> getSpentToday();
  Future<Map<String, double>> getExpensesByCategory({int? year, int? month});

  // Financial Goals
  Future<List<FinancialGoalModel>> getAllGoals();
  Future<void> addGoal(FinancialGoalModel goal);
  Future<void> updateGoal(FinancialGoalModel goal);
  Future<void> deleteGoal(String id);

  // Debts
  Future<List<DebtModel>> getAllDebts();
  Future<List<DebtModel>> getOwedToMe();
  Future<List<DebtModel>> getIOwe();
  Future<void> addDebt(DebtModel debt);
  Future<void> updateDebt(DebtModel debt);
  Future<void> deleteDebt(String id);
  Future<double> getTotalOwedToMe();
  Future<double> getTotalIOwe();
  Future<List<DebtModel>> getUpcomingPayments();

  // Savings Plans (Chitu, etc.)
  Future<List<SavingsPlanModel>> getAllSavingsPlans();
  Future<void> addSavingsPlan(SavingsPlanModel plan);
  Future<void> updateSavingsPlan(SavingsPlanModel plan);
  Future<void> deleteSavingsPlan(String id);

  // Bill Reminders (Rent, Subscriptions, Utilities)
  Future<List<BillReminderModel>> getAllBillReminders();
  Future<void> addBillReminder(BillReminderModel reminder);
  Future<void> updateBillReminder(BillReminderModel reminder);
  Future<void> deleteBillReminder(String id);
}
