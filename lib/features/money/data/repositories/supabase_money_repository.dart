import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jarvis/features/money/domain/repositories/money_repository.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/debt_payment_model.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

class SupabaseMoneyRepository implements MoneyRepository {
  SupabaseClient get _client => Supabase.instance.client;

  String get _userId {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw Exception('Not authenticated');
    return uid;
  }

  // ── Transaction helpers ──────────────────────────────────────────────────────

  TransactionModel _rowToTx(Map<String, dynamic> row) {
    DateTime date;
    final rawDate = row['date'];
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return TransactionModel(
      id: row['id'] as String,
      type: row['type'] as String,
      amount: (row['amount'] as num).toDouble(),
      category: row['category'] as String,
      description: row['description'] as String?,
      emoji: row['emoji'] as String? ?? '💰',
      date: date,
      createdAt: createdAt,
    );
  }

  // ── Transactions ─────────────────────────────────────────────────────────────

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false);
    return rows.map((r) => _rowToTx(r)).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForMonth(
      int year, int month) async {
    final start = DateTime(year, month, 1).toUtc().toIso8601String();
    final end = DateTime(year, month + 1, 1).toUtc().toIso8601String();
    final rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .gte('date', start)
        .lt('date', end)
        .order('date', ascending: false);
    return rows.map((r) => _rowToTx(r)).toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsForDate(DateTime date) async {
    final all = await getAllTransactions();
    return all.where((t) => DateHelpers.isSameDay(t.date, date)).toList();
  }

  @override
  Future<List<TransactionModel>> getRecentTransactions(
      {int limit = 10}) async {
    final rows = await _client
        .from('transactions')
        .select()
        .eq('user_id', _userId)
        .order('date', ascending: false)
        .limit(limit);
    return rows.map((r) => _rowToTx(r)).toList();
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await _client.from('transactions').insert({
      'id': transaction.id,
      'user_id': _userId,
      'type': transaction.type,
      'amount': transaction.amount,
      'category': transaction.category,
      'description': transaction.description,
      'emoji': transaction.emoji,
      'date': transaction.date.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  @override
  Future<double> getTotalIncome({int? year, int? month}) async {
    List<TransactionModel> txs;
    if (year != null && month != null) {
      txs = await getTransactionsForMonth(year, month);
    } else {
      txs = await getAllTransactions();
    }
    return txs
        .where((t) => t.type == 'income')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getTotalExpenses({int? year, int? month}) async {
    List<TransactionModel> txs;
    if (year != null && month != null) {
      txs = await getTransactionsForMonth(year, month);
    } else {
      txs = await getAllTransactions();
    }
    return txs
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<double> getSpentToday() async {
    final txs = await getTransactionsForDate(DateTime.now());
    return txs
        .where((t) => t.type == 'expense')
        .fold<double>(0.0, (sum, t) => sum + t.amount);
  }

  @override
  Future<Map<String, double>> getExpensesByCategory(
      {int? year, int? month}) async {
    List<TransactionModel> txs;
    if (year != null && month != null) {
      txs = await getTransactionsForMonth(year, month);
    } else {
      txs = await getAllTransactions();
    }
    final categories = <String, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      categories[t.category] = (categories[t.category] ?? 0) + t.amount;
    }
    return categories;
  }

  // ── Financial Goals ──────────────────────────────────────────────────────────

  FinancialGoalModel _rowToGoal(Map<String, dynamic> row) {
    DateTime? deadline;
    final rawDeadline = row['deadline'];
    if (rawDeadline is String) deadline = DateTime.tryParse(rawDeadline);

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return FinancialGoalModel(
      id: row['id'] as String,
      name: row['name'] as String,
      icon: row['icon'] as String? ?? '🎯',
      targetAmount: (row['target_amount'] as num).toDouble(),
      currentAmount: (row['current_amount'] as num?)?.toDouble() ?? 0.0,
      deadline: deadline,
      createdAt: createdAt,
    );
  }

  @override
  Future<List<FinancialGoalModel>> getAllGoals() async {
    final rows = await _client
        .from('financial_goals')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map((r) => _rowToGoal(r)).toList();
  }

  @override
  Future<void> addGoal(FinancialGoalModel goal) async {
    await _client.from('financial_goals').insert({
      'id': goal.id,
      'user_id': _userId,
      'name': goal.name,
      'icon': goal.icon,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'deadline': goal.deadline?.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateGoal(FinancialGoalModel goal) async {
    await _client.from('financial_goals').update({
      'name': goal.name,
      'icon': goal.icon,
      'target_amount': goal.targetAmount,
      'current_amount': goal.currentAmount,
      'deadline': goal.deadline?.toUtc().toIso8601String(),
    }).eq('id', goal.id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteGoal(String id) async {
    await _client
        .from('financial_goals')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Debts ────────────────────────────────────────────────────────────────────

  DebtModel _rowToDebt(Map<String, dynamic> row) {
    DateTime startDate;
    final rawStart = row['start_date'];
    if (rawStart is String) {
      startDate = DateTime.tryParse(rawStart) ?? DateTime.now();
    } else {
      startDate = DateTime.now();
    }

    DateTime endDate;
    final rawEnd = row['end_date'];
    if (rawEnd is String) {
      endDate = DateTime.tryParse(rawEnd) ?? DateTime.now();
    } else {
      endDate = DateTime.now();
    }

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    final rawPayments = row['debt_payments'] as List<dynamic>?;
    final payments = rawPayments
            ?.map((p) => _rowToPayment(Map<String, dynamic>.from(p as Map)))
            .toList() ??
        <DebtPaymentModel>[];

    return DebtModel(
      id: row['id'] as String,
      person: row['person'] as String,
      category: row['category'] as String,
      amount: (row['amount'] as num).toDouble(),
      frequency: row['frequency'] as String? ?? 'monthly',
      startDate: startDate,
      endDate: endDate,
      type: row['type'] as String,
      payments: payments,
      createdAt: createdAt,
    );
  }

  DebtPaymentModel _rowToPayment(Map<String, dynamic> row) {
    DateTime date;
    final rawDate = row['date'];
    if (rawDate is String) {
      date = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      date = DateTime.now();
    }

    DateTime? paidAt;
    final rawPaidAt = row['paid_at'];
    if (rawPaidAt is String) paidAt = DateTime.tryParse(rawPaidAt);

    return DebtPaymentModel(
      id: row['id'] as String,
      date: date,
      amount: (row['amount'] as num).toDouble(),
      status: row['status'] as String? ?? 'unpaid',
      paidAt: paidAt,
    );
  }

  @override
  Future<List<DebtModel>> getAllDebts() async {
    final rows = await _client
        .from('debts')
        .select('*, debt_payments(*)')
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map((r) => _rowToDebt(r)).toList();
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
    await _client.from('debts').insert({
      'id': debt.id,
      'user_id': _userId,
      'person': debt.person,
      'category': debt.category,
      'amount': debt.amount,
      'frequency': debt.frequency,
      'start_date': debt.startDate.toUtc().toIso8601String(),
      'end_date': debt.endDate.toUtc().toIso8601String(),
      'type': debt.type,
    });

    // Insert payment schedule rows
    for (final payment in debt.payments) {
      await _client.from('debt_payments').insert({
        'id': payment.id,
        'debt_id': debt.id,
        'date': payment.date.toUtc().toIso8601String(),
        'amount': payment.amount,
        'status': payment.status,
        'paid_at': payment.paidAt?.toUtc().toIso8601String(),
      });
    }
  }

  @override
  Future<void> updateDebt(DebtModel debt) async {
    await _client.from('debts').update({
      'person': debt.person,
      'category': debt.category,
      'amount': debt.amount,
      'frequency': debt.frequency,
      'start_date': debt.startDate.toUtc().toIso8601String(),
      'end_date': debt.endDate.toUtc().toIso8601String(),
      'type': debt.type,
    }).eq('id', debt.id).eq('user_id', _userId);

    // Update each payment in place
    for (final payment in debt.payments) {
      await _client.from('debt_payments').upsert({
        'id': payment.id,
        'debt_id': debt.id,
        'date': payment.date.toUtc().toIso8601String(),
        'amount': payment.amount,
        'status': payment.status,
        'paid_at': payment.paidAt?.toUtc().toIso8601String(),
      });
    }
  }

  @override
  Future<void> deleteDebt(String id) async {
    // Debt payments are cascade-deleted by DB foreign key
    await _client.from('debts').delete().eq('id', id).eq('user_id', _userId);
  }

  double _calculateTotalExpected(DebtModel debt) {
    if (debt.frequency == 'one-time') return debt.amount;
    final months = debt.endDate.difference(debt.startDate).inDays ~/ 30;
    return debt.amount * (months > 0 ? months : 1);
  }

  @override
  Future<double> getTotalOwedToMe() async {
    final debts = await getOwedToMe();
    double total = 0;
    for (final d in debts) {
      final paid =
          d.payments.where((p) => p.status == 'paid').fold(0.0, (s, p) => s + p.amount);
      total += (_calculateTotalExpected(d) - paid);
    }
    return total;
  }

  @override
  Future<double> getTotalIOwe() async {
    final debts = await getIOwe();
    double total = 0;
    for (final d in debts) {
      final paid =
          d.payments.where((p) => p.status == 'paid').fold(0.0, (s, p) => s + p.amount);
      total += (_calculateTotalExpected(d) - paid);
    }
    return total;
  }

  @override
  Future<List<DebtModel>> getUpcomingPayments() async {
    final all = await getAllDebts();
    final now = DateTime.now();
    return all.where((d) => !d.endDate.isBefore(now)).toList();
  }

  // ── Savings Plans ────────────────────────────────────────────────────────────

  SavingsPlanModel _rowToSavings(Map<String, dynamic> row) {
    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return SavingsPlanModel(
      id: row['id'] as String,
      name: row['name'] as String,
      monthlyAmount: (row['monthly_amount'] as num).toDouble(),
      durationMonths: row['duration_months'] as int?,
      linkedGoalId: row['linked_goal_id'] as String?,
      paidMonths: List<String>.from(row['paid_months'] ?? []),
      skippedMonths: List<String>.from(row['skipped_months'] ?? []),
      createdAt: createdAt,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  @override
  Future<List<SavingsPlanModel>> getAllSavingsPlans() async {
    final rows = await _client
        .from('savings_plans')
        .select()
        .eq('user_id', _userId)
        .order('created_at', ascending: false);
    return rows.map((r) => _rowToSavings(r)).toList();
  }

  @override
  Future<void> addSavingsPlan(SavingsPlanModel plan) async {
    await _client.from('savings_plans').insert({
      'id': plan.id,
      'user_id': _userId,
      'name': plan.name,
      'monthly_amount': plan.monthlyAmount,
      'duration_months': plan.durationMonths,
      'linked_goal_id': plan.linkedGoalId,
      'paid_months': plan.paidMonths,
      'skipped_months': plan.skippedMonths,
      'is_active': plan.isActive,
    });
  }

  @override
  Future<void> updateSavingsPlan(SavingsPlanModel plan) async {
    await _client.from('savings_plans').update({
      'name': plan.name,
      'monthly_amount': plan.monthlyAmount,
      'duration_months': plan.durationMonths,
      'linked_goal_id': plan.linkedGoalId,
      'paid_months': plan.paidMonths,
      'skipped_months': plan.skippedMonths,
      'is_active': plan.isActive,
    }).eq('id', plan.id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteSavingsPlan(String id) async {
    await _client
        .from('savings_plans')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }

  // ── Bill Reminders ───────────────────────────────────────────────────────────

  BillReminderModel _rowToBill(Map<String, dynamic> row) {
    DateTime? dueDate;
    final rawDueDate = row['due_date'];
    if (rawDueDate is String) dueDate = DateTime.tryParse(rawDueDate);

    DateTime? lastPaidDate;
    final rawLastPaid = row['last_paid_date'];
    if (rawLastPaid is String) lastPaidDate = DateTime.tryParse(rawLastPaid);

    DateTime createdAt;
    final rawCreated = row['created_at'];
    if (rawCreated is String) {
      createdAt = DateTime.tryParse(rawCreated) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return BillReminderModel(
      id: row['id'] as String,
      title: row['title'] as String,
      amount: (row['amount'] as num).toDouble(),
      dueDay: row['due_day'] as int? ?? 1,
      dueDate: dueDate,
      category: row['category'] as String,
      isRecurring: row['is_recurring'] as bool? ?? true,
      isPaid: row['is_paid'] as bool? ?? false,
      lastPaidDate: lastPaidDate,
      createdAt: createdAt,
    );
  }

  @override
  Future<List<BillReminderModel>> getAllBillReminders() async {
    final rows = await _client
        .from('bill_reminders')
        .select()
        .eq('user_id', _userId)
        .order('due_day', ascending: true);
    return rows.map((r) => _rowToBill(r)).toList();
  }

  @override
  Future<void> addBillReminder(BillReminderModel reminder) async {
    await _client.from('bill_reminders').insert({
      'id': reminder.id,
      'user_id': _userId,
      'title': reminder.title,
      'amount': reminder.amount,
      'due_day': reminder.dueDay,
      'due_date': reminder.dueDate?.toUtc().toIso8601String(),
      'category': reminder.category,
      'is_recurring': reminder.isRecurring,
      'is_paid': reminder.isPaid,
      'last_paid_date': reminder.lastPaidDate?.toUtc().toIso8601String(),
    });
  }

  @override
  Future<void> updateBillReminder(BillReminderModel reminder) async {
    await _client.from('bill_reminders').update({
      'title': reminder.title,
      'amount': reminder.amount,
      'due_day': reminder.dueDay,
      'due_date': reminder.dueDate?.toUtc().toIso8601String(),
      'category': reminder.category,
      'is_recurring': reminder.isRecurring,
      'is_paid': reminder.isPaid,
      'last_paid_date': reminder.lastPaidDate?.toUtc().toIso8601String(),
    }).eq('id', reminder.id).eq('user_id', _userId);
  }

  @override
  Future<void> deleteBillReminder(String id) async {
    await _client
        .from('bill_reminders')
        .delete()
        .eq('id', id)
        .eq('user_id', _userId);
  }
}
