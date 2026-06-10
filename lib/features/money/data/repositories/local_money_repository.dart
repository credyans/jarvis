import 'package:jarvis/features/money/domain/repositories/money_repository.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/debt_payment_model.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';
import 'package:jarvis/data/repositories/money_repository.dart' as local;
import 'package:jarvis/data/models/transaction_model.dart' as local_tx;
import 'package:jarvis/data/models/financial_goal_model.dart' as local_goal;
import 'package:jarvis/data/models/debt_model.dart' as local_debt;
import 'package:jarvis/data/models/debt_payment_model.dart' as local_payment;
import 'package:jarvis/data/models/savings_plan_model.dart' as local_savings;
import 'package:jarvis/data/models/bill_reminder_model.dart' as local_bill;

class LocalMoneyRepository implements MoneyRepository {
  final local.MoneyRepository _localRepo = local.MoneyRepository();

  SavingsPlanModel _toFeatureSavings(local_savings.SavingsPlanModel s) {
    return SavingsPlanModel(
      id: s.id,
      name: s.name,
      monthlyAmount: s.monthlyAmount,
      durationMonths: s.durationMonths,
      linkedGoalId: s.linkedGoalId,
      paidMonths: s.paidMonths,
      skippedMonths: s.skippedMonths,
      createdAt: s.createdAt,
      isActive: s.isActive,
    );
  }

  local_savings.SavingsPlanModel _toLocalSavings(SavingsPlanModel s) {
    return local_savings.SavingsPlanModel(
      id: s.id,
      name: s.name,
      monthlyAmount: s.monthlyAmount,
      durationMonths: s.durationMonths,
      linkedGoalId: s.linkedGoalId,
      paidMonths: s.paidMonths,
      skippedMonths: s.skippedMonths,
      createdAt: s.createdAt,
      isActive: s.isActive,
    );
  }

  BillReminderModel _toFeatureBill(local_bill.BillReminderModel b) {
    return BillReminderModel(
      id: b.id,
      title: b.title,
      amount: b.amount,
      dueDay: b.dueDay,
      dueDate: b.dueDate,
      category: b.category,
      isRecurring: b.isRecurring,
      isPaid: b.isPaid,
      lastPaidDate: b.lastPaidDate,
      createdAt: b.createdAt,
    );
  }

  local_bill.BillReminderModel _toLocalBill(BillReminderModel b) {
    return local_bill.BillReminderModel(
      id: b.id,
      title: b.title,
      amount: b.amount,
      dueDay: b.dueDay,
      dueDate: b.dueDate,
      category: b.category,
      isRecurring: b.isRecurring,
      isPaid: b.isPaid,
      lastPaidDate: b.lastPaidDate,
      createdAt: b.createdAt,
    );
  }

  TransactionModel _toFeatureTx(local_tx.TransactionModel t) {
    return TransactionModel(
      id: t.id,
      type: t.type,
      amount: t.amount,
      category: t.category,
      description: t.description,
      emoji: t.emoji,
      date: t.date,
      createdAt: t.createdAt,
    );
  }

  local_tx.TransactionModel _toLocalTx(TransactionModel t) {
    return local_tx.TransactionModel(
      id: t.id,
      type: t.type,
      amount: t.amount,
      category: t.category,
      description: t.description,
      emoji: t.emoji,
      date: t.date,
      createdAt: t.createdAt,
    );
  }

  FinancialGoalModel _toFeatureGoal(local_goal.FinancialGoalModel g) {
    return FinancialGoalModel(
      id: g.id,
      name: g.name,
      icon: g.icon,
      targetAmount: g.targetAmount,
      currentAmount: g.currentAmount,
      deadline: g.deadline,
      createdAt: g.createdAt,
    );
  }

  local_goal.FinancialGoalModel _toLocalGoal(FinancialGoalModel g) {
    return local_goal.FinancialGoalModel(
      id: g.id,
      name: g.name,
      icon: g.icon,
      targetAmount: g.targetAmount,
      currentAmount: g.currentAmount,
      deadline: g.deadline,
      createdAt: g.createdAt,
    );
  }

  DebtModel _toFeatureDebt(local_debt.DebtModel d) {
    return DebtModel(
      id: d.id,
      person: d.person,
      category: d.category,
      amount: d.amount,
      frequency: d.frequency,
      startDate: d.startDate,
      endDate: d.endDate,
      type: d.type,
      payments: d.payments.map((p) => DebtPaymentModel(
        id: p.id,
        date: p.date,
        amount: p.amount,
        status: p.status,
        paidAt: p.paidAt,
      )).toList(),
      createdAt: d.createdAt,
    );
  }

  local_debt.DebtModel _toLocalDebt(DebtModel d) {
    return local_debt.DebtModel(
      id: d.id,
      person: d.person,
      category: d.category,
      amount: d.amount,
      frequency: d.frequency,
      startDate: d.startDate,
      endDate: d.endDate,
      type: d.type,
      payments: d.payments.map((p) => local_payment.DebtPaymentModel(
        id: p.id,
        date: p.date,
        amount: p.amount,
        status: p.status,
        paidAt: p.paidAt,
      )).toList(),
      createdAt: d.createdAt,
    );
  }

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final list = await _localRepo.getAllTransactions();
    return list.map(_toFeatureTx).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForMonth(int year, int month) async {
    final list = await _localRepo.getTransactionsForMonth(year, month);
    return list.map(_toFeatureTx).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForDate(DateTime date) async {
    final list = await _localRepo.getTransactionsForDate(date);
    return list.map(_toFeatureTx).toList();
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions({int limit = 10}) async {
    final list = await _localRepo.getRecentTransactions(limit: limit);
    return list.map(_toFeatureTx).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _localRepo.addTransaction(_toLocalTx(transaction));
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _localRepo.deleteTransaction(id);
  }

  @override
  Future<double> getTotalIncome({int? year, int? month}) async {
    return await _localRepo.getTotalIncome(year: year, month: month);
  }

  @override
  Future<double> getTotalExpenses({int? year, int? month}) async {
    return await _localRepo.getTotalExpenses(year: year, month: month);
  }

  @override
  Future<double> getSpentToday() async {
    return await _localRepo.getSpentToday();
  }

  @override
  Future<Map<String, double>> getExpensesByCategory({int? year, int? month}) async {
    return await _localRepo.getExpensesByCategory(year: year, month: month);
  }

  @override
  Future<List<FinancialGoalModel>> getAllGoals() async {
    final list = await _localRepo.getAllGoals();
    return list.map(_toFeatureGoal).toList();
  }

  @override
  Future<void> addGoal(FinancialGoalModel goal) async {
    await _localRepo.addGoal(_toLocalGoal(goal));
  }

  @override
  Future<void> updateGoal(FinancialGoalModel goal) async {
    await _localRepo.updateGoal(_toLocalGoal(goal));
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _localRepo.deleteGoal(id);
  }

  @override
  Future<List<DebtModel>> getAllDebts() async {
    final list = await _localRepo.getAllDebts();
    return list.map(_toFeatureDebt).toList();
  }

  @override
  Future<List<DebtModel>> getOwedToMe() async {
    final list = await _localRepo.getOwedToMe();
    return list.map(_toFeatureDebt).toList();
  }

  @override
  Future<List<DebtModel>> getIOwe() async {
    final list = await _localRepo.getIOwe();
    return list.map(_toFeatureDebt).toList();
  }

  @override
  Future<void> addDebt(DebtModel debt) async {
    await _localRepo.addDebt(_toLocalDebt(debt));
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    await _localRepo.updateDebt(_toLocalDebt(debt));
  }

  @override
  Future<void> deleteDebt(String id) async {
    await _localRepo.deleteDebt(id);
  }

  @override
  Future<double> getTotalOwedToMe() async {
    return await _localRepo.getTotalOwedToMe();
  }

  @override
  Future<double> getTotalIOwe() async {
    return await _localRepo.getTotalIOwe();
  }

  @override
  Future<List<DebtModel>> getUpcomingPayments() async {
    final list = await _localRepo.getUpcomingPayments();
    return list.map(_toFeatureDebt).toList();
  }

  // ── Savings Plans ──

  @override
  Future<List<SavingsPlanModel>> getAllSavingsPlans() async {
    final list = await _localRepo.getAllSavingsPlans();
    return list.map(_toFeatureSavings).toList();
  }

  @override
  Future<void> addSavingsPlan(SavingsPlanModel plan) async {
    await _localRepo.addSavingsPlan(_toLocalSavings(plan));
  }

  @override
  Future<void> updateSavingsPlan(SavingsPlanModel plan) async {
    await _localRepo.updateSavingsPlan(_toLocalSavings(plan));
  }

  @override
  Future<void> deleteSavingsPlan(String id) async {
    await _localRepo.deleteSavingsPlan(id);
  }

  // ── Bill Reminders ──

  @override
  Future<List<BillReminderModel>> getAllBillReminders() async {
    final list = await _localRepo.getAllBillReminders();
    return list.map(_toFeatureBill).toList();
  }

  @override
  Future<void> addBillReminder(BillReminderModel reminder) async {
    await _localRepo.addBillReminder(_toLocalBill(reminder));
  }

  @override
  Future<void> updateBillReminder(BillReminderModel reminder) async {
    await _localRepo.updateBillReminder(_toLocalBill(reminder));
  }

  @override
  Future<void> deleteBillReminder(String id) async {
    await _localRepo.deleteBillReminder(id);
  }
}
