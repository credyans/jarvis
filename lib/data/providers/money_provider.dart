import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/features/money/data/datasources/money_remote_datasource.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';
import 'package:jarvis/features/money/data/repositories/money_repository_impl.dart';
import 'package:jarvis/features/money/data/repositories/local_money_repository.dart';
import 'package:jarvis/features/money/data/repositories/supabase_money_repository.dart';
import 'package:jarvis/features/money/domain/repositories/money_repository.dart';

final moneyRemoteDataSourceProvider = Provider<MoneyRemoteDataSource>((ref) {
  return MoneyRemoteDataSource();
});

final moneyRepositoryProvider = Provider<MoneyRepository>((ref) {
  if (AppConfig.useFirebase) {
    return MoneyRepositoryImpl(ref.watch(moneyRemoteDataSourceProvider));
  } else if (AppConfig.useSupabase) {
    return SupabaseMoneyRepository();
  } else {
    return LocalMoneyRepository();
  }
});

// ── Transactions ──

final transactionProvider = StateNotifierProvider<TransactionNotifier,
    AsyncValue<List<TransactionModel>>>((ref) {
  return TransactionNotifier(ref.watch(moneyRepositoryProvider));
});

final recentTransactionsProvider =
    FutureProvider<List<TransactionModel>>((ref) async {
  final repo = ref.watch(moneyRepositoryProvider);
  return repo.getRecentTransactions(limit: 10);
});

// ── Financial Goals ──

final goalProvider = StateNotifierProvider<GoalNotifier,
    AsyncValue<List<FinancialGoalModel>>>((ref) {
  return GoalNotifier(ref.watch(moneyRepositoryProvider));
});

// ── Debts ──

final debtProvider =
    StateNotifierProvider<DebtNotifier, AsyncValue<List<DebtModel>>>((ref) {
  return DebtNotifier(ref.watch(moneyRepositoryProvider));
});

final owedToMeProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(moneyRepositoryProvider);
  return repo.getOwedToMe();
});

final iOweProvider = FutureProvider<List<DebtModel>>((ref) async {
  final repo = ref.watch(moneyRepositoryProvider);
  return repo.getIOwe();
});

// ── Financial Overview ──

final monthlyIncomeProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(moneyRepositoryProvider);
  final now = DateTime.now();
  return repo.getTotalIncome(year: now.year, month: now.month);
});

final monthlyExpensesProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(moneyRepositoryProvider);
  final now = DateTime.now();
  return repo.getTotalExpenses(year: now.year, month: now.month);
});

final todaySpentProvider = FutureProvider<double>((ref) async {
  final repo = ref.watch(moneyRepositoryProvider);
  return repo.getSpentToday();
});

// ── Notifiers ──

class TransactionNotifier
    extends StateNotifier<AsyncValue<List<TransactionModel>>> {
  final MoneyRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    try {
      final transactions = await _repository.getAllTransactions();
      state = AsyncValue.data(transactions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    await _repository.addTransaction(transaction);
    await loadTransactions();
  }

  Future<void> deleteTransaction(String id) async {
    await _repository.deleteTransaction(id);
    await loadTransactions();
  }
}

class GoalNotifier
    extends StateNotifier<AsyncValue<List<FinancialGoalModel>>> {
  final MoneyRepository _repository;

  GoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals() async {
    try {
      final goals = await _repository.getAllGoals();
      state = AsyncValue.data(goals);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(FinancialGoalModel goal) async {
    await _repository.addGoal(goal);
    await loadGoals();
  }

  Future<void> updateGoal(FinancialGoalModel goal) async {
    await _repository.updateGoal(goal);
    await loadGoals();
  }

  Future<void> deleteGoal(String id) async {
    await _repository.deleteGoal(id);
    await loadGoals();
  }
}

class DebtNotifier extends StateNotifier<AsyncValue<List<DebtModel>>> {
  final MoneyRepository _repository;

  DebtNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadDebts();
  }

  Future<void> loadDebts() async {
    try {
      final debts = await _repository.getAllDebts();
      state = AsyncValue.data(debts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addDebt(DebtModel debt) async {
    await _repository.addDebt(debt);
    await loadDebts();
  }

  Future<void> updateDebt(DebtModel debt) async {
    await _repository.updateDebt(debt);
    await loadDebts();
  }

  Future<void> deleteDebt(String id) async {
    await _repository.deleteDebt(id);
    await loadDebts();
  }
}

// ── Savings Plans ──

final savingsPlanProvider = StateNotifierProvider<SavingsPlanNotifier,
    AsyncValue<List<SavingsPlanModel>>>((ref) {
  return SavingsPlanNotifier(ref.watch(moneyRepositoryProvider));
});

class SavingsPlanNotifier extends StateNotifier<AsyncValue<List<SavingsPlanModel>>> {
  final MoneyRepository _repository;

  SavingsPlanNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadSavingsPlans();
  }

  Future<void> loadSavingsPlans() async {
    try {
      final plans = await _repository.getAllSavingsPlans();
      state = AsyncValue.data(plans);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addSavingsPlan(SavingsPlanModel plan) async {
    await _repository.addSavingsPlan(plan);
    await loadSavingsPlans();
  }

  Future<void> updateSavingsPlan(SavingsPlanModel plan) async {
    await _repository.updateSavingsPlan(plan);
    await loadSavingsPlans();
  }

  Future<void> deleteSavingsPlan(String id) async {
    await _repository.deleteSavingsPlan(id);
    await loadSavingsPlans();
  }
}

// ── Bill Reminders ──

final billReminderProvider = StateNotifierProvider<BillReminderNotifier,
    AsyncValue<List<BillReminderModel>>>((ref) {
  return BillReminderNotifier(ref.watch(moneyRepositoryProvider));
});

class BillReminderNotifier extends StateNotifier<AsyncValue<List<BillReminderModel>>> {
  final MoneyRepository _repository;

  BillReminderNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadBillReminders();
  }

  Future<void> loadBillReminders() async {
    try {
      final reminders = await _repository.getAllBillReminders();
      state = AsyncValue.data(reminders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addBillReminder(BillReminderModel reminder) async {
    await _repository.addBillReminder(reminder);
    await loadBillReminders();
  }

  Future<void> updateBillReminder(BillReminderModel reminder) async {
    await _repository.updateBillReminder(reminder);
    await loadBillReminders();
  }

  Future<void> deleteBillReminder(String id) async {
    await _repository.deleteBillReminder(id);
    await loadBillReminders();
  }
}
