import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/features/tasks/data/datasources/task_remote_datasource.dart';
import 'package:jarvis/features/tasks/data/repositories/task_repository_impl.dart';
import 'package:jarvis/features/tasks/data/repositories/local_task_repository.dart';
import 'package:jarvis/features/tasks/data/repositories/supabase_task_repository.dart';
import 'package:jarvis/features/tasks/domain/repositories/task_repository.dart';

// Money imports for Unified Tasks
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';

final taskRemoteDataSourceProvider = Provider<TaskRemoteDataSource>((ref) {
  return TaskRemoteDataSource();
});

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  if (AppConfig.useFirebase) {
    return TaskRepositoryImpl(ref.watch(taskRemoteDataSourceProvider));
  } else if (AppConfig.useSupabase) {
    return SupabaseTaskRepository();
  } else {
    return LocalTaskRepository();
  }
});

final taskProvider =
    StateNotifierProvider<TaskNotifier, AsyncValue<List<TaskModel>>>((ref) {
  return TaskNotifier(ref.watch(taskRepositoryProvider));
});

final tagProvider =
    StateNotifierProvider<TagNotifier, AsyncValue<List<TagModel>>>((ref) {
  return TagNotifier(ref.watch(taskRepositoryProvider));
});

final todayTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getTasksForDate(DateTime.now());
});

final incompleteTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.watch(taskRepositoryProvider);
  return repo.getIncompleteTasks();
});

class TaskNotifier extends StateNotifier<AsyncValue<List<TaskModel>>> {
  final TaskRepository _repository;

  TaskNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTasks();
  }

  Future<void> loadTasks() async {
    try {
      final tasks = await _repository.getAllTasks();
      state = AsyncValue.data(tasks);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTask(TaskModel task) async {
    await _repository.addTask(task);
    await loadTasks();
  }

  Future<void> updateTask(TaskModel task) async {
    await _repository.updateTask(task);
    await loadTasks();
  }

  Future<void> deleteTask(String id) async {
    await _repository.deleteTask(id);
    await loadTasks();
  }

  Future<void> toggleCompletion(String id) async {
    await _repository.toggleTaskCompletion(id);
    await loadTasks();
  }
}

class TagNotifier extends StateNotifier<AsyncValue<List<TagModel>>> {
  final TaskRepository _repository;

  TagNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTags();
  }

  Future<void> loadTags() async {
    try {
      final tags = await _repository.getAllTags();
      state = AsyncValue.data(tags);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addTag(TagModel tag) async {
    await _repository.addTag(tag);
    await loadTags();
  }

  Future<void> deleteTag(String id) async {
    await _repository.deleteTag(id);
    await loadTags();
  }
}

// ── Unified Tasks Integration ──

final unifiedTasksProvider = Provider<AsyncValue<List<TaskModel>>>((ref) {
  final tasksAsync = ref.watch(taskProvider);
  final billsAsync = ref.watch(billReminderProvider);
  final debtsAsync = ref.watch(debtProvider);

  if (tasksAsync is AsyncLoading || billsAsync is AsyncLoading || debtsAsync is AsyncLoading) {
    return const AsyncValue.loading();
  }

  if (tasksAsync is AsyncError) return AsyncValue.error(tasksAsync.error!, tasksAsync.stackTrace!);
  if (billsAsync is AsyncError) return AsyncValue.error(billsAsync.error!, billsAsync.stackTrace!);
  if (debtsAsync is AsyncError) return AsyncValue.error(debtsAsync.error!, debtsAsync.stackTrace!);

  final tasks = tasksAsync.value ?? [];
  final bills = billsAsync.value ?? [];
  final debts = debtsAsync.value ?? [];
  
  final List<TaskModel> unified = [...tasks];
  final now = DateTime.now();

  // Add unpaid bills as tasks
  for (final bill in bills) {
    if (!bill.isPaid) {
      final billDate = DateTime(now.year, now.month, bill.dueDay);
      unified.add(
        TaskModel(
          id: 'bill_${bill.id}',
          title: 'Pay ${bill.title} (₹${bill.amount.toInt()})',
          description: 'Recurring monthly bill reminder',
          tagId: 'money_tag',
          dueDate: billDate,
          priority: 2,
          completed: false,
          emoji: '🧾',
          createdAt: bill.createdAt,
        ),
      );
    }
  }

  // Add unpaid debt payments as tasks
  for (final debt in debts) {
    for (final payment in debt.payments) {
      if (payment.status != 'paid') {
        unified.add(
          TaskModel(
            id: 'debt_${debt.id}_${payment.id}',
            title: '${debt.type == 'owedToMe' ? 'Collect from' : 'Pay'} ${debt.person} — ${debt.category} (₹${payment.amount.toInt()})',
            description: 'Due Date: ${DateHelpers.formatDate(payment.date)}',
            tagId: 'money_tag',
            dueDate: payment.date,
            priority: 2,
            completed: false,
            emoji: debt.type == 'owedToMe' ? '📈' : '📉',
            createdAt: debt.createdAt,
          ),
        );
      }
    }
  }

  return AsyncValue.data(unified);
});

final completeUnifiedTaskProvider = Provider((ref) {
  return (String taskId) async {
    if (taskId.startsWith('bill_')) {
      final billId = taskId.replaceFirst('bill_', '');
      final bills = ref.read(billReminderProvider).value ?? [];
      final billIndex = bills.indexWhere((b) => b.id == billId);
      if (billIndex != -1) {
        final bill = bills[billIndex];
        
        // 1. Log transaction
        final tx = TransactionModel(
          id: IdGenerator.generate(),
          type: 'expense',
          amount: bill.amount,
          category: bill.category,
          description: 'Paid: ${bill.title}',
          emoji: bill.category == 'House Rent'
              ? '🏠'
              : bill.category == 'Food Mess'
                  ? '🍲'
                  : bill.category == 'Credit Card Bill'
                      ? '💳'
                      : bill.category == 'Subscription'
                          ? '🧾'
                          : bill.category == 'Utilities'
                              ? '🔌'
                              : '➕',
          date: DateTime.now(),
          createdAt: DateTime.now(),
        );
        await ref.read(transactionProvider.notifier).addTransaction(tx);

        // 2. Mark reminder as paid
        final updated = bill.copyWith(
          isPaid: true,
          lastPaidDate: () => DateTime.now(),
        );
        await ref.read(billReminderProvider.notifier).updateBillReminder(updated);

        // Invalidate metrics
        ref.invalidate(monthlyExpensesProvider);
        ref.invalidate(todaySpentProvider);
        ref.invalidate(recentTransactionsProvider);
      }
    } else if (taskId.startsWith('debt_')) {
      // Format: 'debt_debtId_paymentId'
      final parts = taskId.split('_');
      if (parts.length >= 3) {
        final debtId = parts[1];
        final paymentId = parts[2];
        final debts = ref.read(debtProvider).value ?? [];
        final debtIndex = debts.indexWhere((d) => d.id == debtId);
        if (debtIndex != -1) {
          final debt = debts[debtIndex];
          final updatedPayments = debt.payments.map((p) {
            if (p.id == paymentId) {
              return p.copyWith(status: 'paid', paidAt: () => DateTime.now());
            }
            return p;
          }).toList();
          
          final updatedDebt = debt.copyWith(payments: updatedPayments);
          await ref.read(debtProvider.notifier).updateDebt(updatedDebt);

          // Log transaction
          final payment = debt.payments.firstWhere((p) => p.id == paymentId);
          final tx = TransactionModel(
            id: IdGenerator.generate(),
            type: debt.type == 'owedToMe' ? 'income' : 'expense',
            amount: payment.amount,
            category: debt.type == 'owedToMe' ? 'Owed to Me (Receipt)' : 'I Owe (Payment)',
            description: '${debt.type == 'owedToMe' ? 'Collected EMI from' : 'Paid EMI to'} ${debt.person}',
            emoji: debt.type == 'owedToMe' ? '📈' : '📉',
            date: DateTime.now(),
            createdAt: DateTime.now(),
          );
          await ref.read(transactionProvider.notifier).addTransaction(tx);
          
          ref.invalidate(monthlyExpensesProvider);
          ref.invalidate(monthlyIncomeProvider);
          ref.invalidate(todaySpentProvider);
          ref.invalidate(recentTransactionsProvider);
        }
      }
    } else {
      // Normal task
      await ref.read(taskProvider.notifier).toggleCompletion(taskId);
    }
  };
});
