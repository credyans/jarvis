import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:jarvis/core/config.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/utils/date_helpers.dart';

// Firebase Models
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/tasks/data/models/tag_model.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/debt_payment_model.dart';

// Local Hive Models
import 'package:jarvis/data/models/task_model.dart' as local_task;
import 'package:jarvis/data/models/tag_model.dart' as local_tag;
import 'package:jarvis/data/models/habit_model.dart' as local_habit;
import 'package:jarvis/data/models/mood_entry_model.dart' as local_mood;
import 'package:jarvis/data/models/transaction_model.dart' as local_tx;
import 'package:jarvis/data/models/financial_goal_model.dart' as local_goal;
import 'package:jarvis/data/models/debt_model.dart' as local_debt;
import 'package:jarvis/data/models/debt_payment_model.dart' as local_payment;
import 'package:jarvis/data/models/savings_plan_model.dart' as local_savings;
import 'package:jarvis/data/models/bill_reminder_model.dart' as local_bill;

class SeedData {
  static Future<void> seed(String uid, {bool force = false}) async {
    if (AppConfig.useFirebase) {
      await _seedFirebase(uid, force: force);
    } else {
      await _seedHive(force: force);
    }
  }

  static Future<void> _seedFirebase(String uid, {bool force = false}) async {
    final firestore = FirebaseFirestore.instance;
    final userDoc = firestore.collection('users').doc(uid);

    final tasksRef = userDoc.collection('tasks');
    final tagsRef = userDoc.collection('tags');
    final habitsRef = userDoc.collection('habits');
    final moodsRef = userDoc.collection('moods');
    final transactionsRef = userDoc.collection('transactions');
    final goalsRef = userDoc.collection('financial_goals');
    final debtsRef = userDoc.collection('debts');

    Future<void> clearCollection(CollectionReference col) async {
      final snapshot = await col.get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    }

    if (!force) {
      final querySnapshot = await tasksRef.limit(1).get();
      if (querySnapshot.docs.isNotEmpty) {
        return;
      }
    }

    if (force) {
      await clearCollection(tasksRef);
      await clearCollection(tagsRef);
      await clearCollection(habitsRef);
      await clearCollection(moodsRef);
      await clearCollection(transactionsRef);
      await clearCollection(goalsRef);
      await clearCollection(debtsRef);
    }

    final personalTag = TagModel(id: IdGenerator.generate(), name: 'Personal', color: '#E8847C', emoji: '🌸', sortOrder: 0);
    final workTag = TagModel(id: IdGenerator.generate(), name: 'Work', color: '#C4A0E8', emoji: '💼', sortOrder: 1);
    final homeTag = TagModel(id: IdGenerator.generate(), name: 'Home', color: '#7BC47F', emoji: '🏠', sortOrder: 2);
    final healthTag = TagModel(id: IdGenerator.generate(), name: 'Health', color: '#E8B44C', emoji: '💪', sortOrder: 3);

    for (final tag in [personalTag, workTag, homeTag, healthTag]) {
      await tagsRef.doc(tag.id).set(tag.toJson());
    }

    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    final tasks = [
      TaskModel(
        id: IdGenerator.generate(),
        title: 'Buy fresh eggs',
        description: 'Get at least a dozen cage-free brown eggs.',
        tagId: homeTag.id,
        dueDate: today,
        dueTime: '08:30',
        priority: 2,
        completed: false,
        emoji: '🥚',
        createdAt: yesterday,
      ),
      TaskModel(
        id: IdGenerator.generate(),
        title: 'Call Dad & Mom',
        description: 'Weekly catchup call. Ask about Dad\'s doctor visit.',
        tagId: personalTag.id,
        dueDate: today,
        dueTime: '20:00',
        priority: 3,
        completed: false,
        emoji: '📞',
        createdAt: yesterday,
      ),
      TaskModel(
        id: IdGenerator.generate(),
        title: 'Pay monthly electricity bill',
        description: 'Pay via UPI, due date is soon.',
        tagId: homeTag.id,
        dueDate: today,
        dueTime: '11:00',
        priority: 2,
        completed: true,
        emoji: '🔌',
        createdAt: yesterday.subtract(const Duration(days: 1)),
      ),
      TaskModel(
        id: IdGenerator.generate(),
        title: 'Book train tickets for weekend trip',
        description: 'Book IRCTC sleeper class tickets.',
        tagId: personalTag.id,
        dueDate: tomorrow,
        dueTime: '10:00',
        priority: 3,
        completed: false,
        emoji: '🚂',
        createdAt: today,
      ),
      TaskModel(
        id: IdGenerator.generate(),
        title: 'Submit monthly sprint review presentation',
        description: 'Prepare slides for Q2 review.',
        tagId: workTag.id,
        dueDate: today,
        dueTime: '17:00',
        priority: 3,
        completed: false,
        emoji: '📊',
        createdAt: yesterday,
      ),
      TaskModel(
        id: IdGenerator.generate(),
        title: 'Plan tomorrow\'s priorities',
        description: 'Spend 5 minutes listing down top 3 highlights for tomorrow.',
        tagId: personalTag.id,
        dueDate: today,
        dueTime: '21:30',
        priority: 2,
        completed: false,
        emoji: '📝',
        createdAt: yesterday,
      ),
    ];

    for (final task in tasks) {
      await tasksRef.doc(task.id).set(task.toJson());
    }

    final List<String> readCompletions = [];
    final List<String> workoutCompletions = [];
    final List<String> medCompletions = [];

    for (int i = 1; i <= 7; i++) {
      final dateStr = DateHelpers.dateKey(today.subtract(Duration(days: i)));
      if (i <= 5) readCompletions.add(dateStr);
      if (i == 1 || i == 3 || i == 4) workoutCompletions.add(dateStr);
      if (i == 1 || i == 3) medCompletions.add(dateStr);
    }

    final habits = [
      HabitModel(
        id: IdGenerator.generate(),
        name: 'Read a book',
        icon: '📚',
        frequency: 'daily',
        target: 1,
        reminderTime: '21:30',
        startDate: today.subtract(const Duration(days: 10)),
        completions: readCompletions,
      ),
      HabitModel(
        id: IdGenerator.generate(),
        name: 'Morning Workout',
        icon: '💪',
        frequency: 'daily',
        target: 1,
        reminderTime: '06:30',
        startDate: today.subtract(const Duration(days: 10)),
        completions: workoutCompletions,
      ),
      HabitModel(
        id: IdGenerator.generate(),
        name: 'Meditation',
        icon: '🧘',
        frequency: 'daily',
        target: 1,
        reminderTime: '08:00',
        startDate: today.subtract(const Duration(days: 10)),
        completions: medCompletions,
      ),
      HabitModel(
        id: IdGenerator.generate(),
        name: 'Sleep Before 11 PM',
        icon: '😴',
        frequency: 'daily',
        target: 1,
        reminderTime: '22:45',
        startDate: today.subtract(const Duration(days: 5)),
        completions: const [],
      ),
    ];

    for (final habit in habits) {
      await habitsRef.doc(habit.id).set(habit.toJson());
    }

    final moods = [
      MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 6)),
        mood: 'okay',
        note: 'Feeling a bit tired from the weekend travel.',
        createdAt: today.subtract(const Duration(days: 6)),
      ),
      MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 5)),
        mood: 'good',
        note: 'Productive day at work, got some exercises in.',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 4)),
        mood: 'great',
        note: 'Fantastic dinner with friends! Highly energizing.',
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 3)),
        mood: 'okay',
        note: 'Slow day, struggled with focus.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 2)),
        mood: 'low',
        note: 'Felt burned out in the afternoon. Need rest.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 1)),
        mood: 'good',
        note: 'Recovered well, reading habit is going strong.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ];

    for (final mood in moods) {
      await moodsRef.doc(mood.id).set(mood.toJson());
    }

    final transactions = [
      TransactionModel(
        id: IdGenerator.generate(),
        type: 'income',
        amount: 55000.0,
        category: 'Salary',
        description: 'Monthly Q1 salary credit',
        emoji: '💼',
        date: today.subtract(const Duration(days: 4)),
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 1200.0,
        category: 'Groceries',
        description: 'Supermarket weekly grocery run',
        emoji: '🛒',
        date: today.subtract(const Duration(days: 2)),
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 350.0,
        category: 'Dining Out',
        description: 'Starbucks coffee and snack',
        emoji: '☕',
        date: today.subtract(const Duration(days: 1)),
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 450.0,
        category: 'Transport',
        description: 'Uber ride to office',
        emoji: '🚗',
        date: today,
        createdAt: today,
      ),
      TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 2500.0,
        category: 'Entertainment',
        description: 'Concert tickets purchased online',
        emoji: '🎵',
        date: today.subtract(const Duration(days: 3)),
        createdAt: today.subtract(const Duration(days: 3)),
      ),
    ];

    for (final tx in transactions) {
      await transactionsRef.doc(tx.id).set(tx.toJson());
    }

    final goals = [
      FinancialGoalModel(
        id: IdGenerator.generate(),
        name: 'Emergency Fund',
        icon: '🚨',
        targetAmount: 100000.0,
        currentAmount: 35000.0,
        deadline: today.add(const Duration(days: 180)),
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      FinancialGoalModel(
        id: IdGenerator.generate(),
        name: 'New Laptop',
        icon: '💻',
        targetAmount: 75000.0,
        currentAmount: 15000.0,
        deadline: today.add(const Duration(days: 90)),
        createdAt: today.subtract(const Duration(days: 15)),
      ),
    ];

    for (final goal in goals) {
      await goalsRef.doc(goal.id).set(goal.toJson());
    }

    final startOfDebts = today.subtract(const Duration(days: 60));
    final endOfDebts = today.add(const Duration(days: 120));

    final debts = [
      DebtModel(
        id: IdGenerator.generate(),
        person: 'Saroo',
        category: 'Monitor EMI',
        amount: 3500.0,
        frequency: 'monthly',
        startDate: startOfDebts,
        endDate: endOfDebts,
        type: 'owedToMe',
        payments: [
          DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 30)),
            amount: 3500.0,
            status: 'paid',
            paidAt: startOfDebts.add(const Duration(days: 30)),
          ),
          DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 60)),
            amount: 3500.0,
            status: 'unpaid',
          ),
        ],
        createdAt: startOfDebts,
      ),
      DebtModel(
        id: IdGenerator.generate(),
        person: 'Saroo',
        category: 'Mobile EMI',
        amount: 2000.0,
        frequency: 'monthly',
        startDate: startOfDebts,
        endDate: endOfDebts,
        type: 'owedToMe',
        payments: [
          DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 30)),
            amount: 2000.0,
            status: 'paid',
            paidAt: startOfDebts.add(const Duration(days: 31)),
          ),
          DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 60)),
            amount: 2000.0,
            status: 'unpaid',
          ),
        ],
        createdAt: startOfDebts,
      ),
      DebtModel(
        id: IdGenerator.generate(),
        person: 'Ramesh',
        category: 'Office Lunch Share',
        amount: 450.0,
        frequency: 'one-time',
        startDate: today.subtract(const Duration(days: 2)),
        endDate: today.add(const Duration(days: 5)),
        type: 'iOwe',
        payments: const [],
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    ];

    for (final debt in debts) {
      await debtsRef.doc(debt.id).set(debt.toJson());
    }
  }

  static Future<void> _seedHive({bool force = false}) async {
    final tasksBox = await Hive.openBox('tasks');
    final tagsBox = await Hive.openBox('tags');
    final habitsBox = await Hive.openBox('habits');
    final moodsBox = await Hive.openBox('moods');
    final transactionsBox = await Hive.openBox('transactions');
    final goalsBox = await Hive.openBox('financial_goals');
    final debtsBox = await Hive.openBox('debts');
    final savingsBox = await Hive.openBox('savings_plans');
    final billsBox = await Hive.openBox('bill_reminders');

    if (!force && tasksBox.isNotEmpty) {
      return;
    }

    if (force) {
      await tasksBox.clear();
      await tagsBox.clear();
      await habitsBox.clear();
      await moodsBox.clear();
      await transactionsBox.clear();
      await goalsBox.clear();
      await debtsBox.clear();
      await savingsBox.clear();
      await billsBox.clear();
    }

    // ── Seed Tags ──
    final personalTag = local_tag.TagModel(id: IdGenerator.generate(), name: 'Personal', color: '#E8847C', emoji: '🌸', sortOrder: 0);
    final workTag = local_tag.TagModel(id: IdGenerator.generate(), name: 'Work', color: '#C4A0E8', emoji: '💼', sortOrder: 1);
    final homeTag = local_tag.TagModel(id: IdGenerator.generate(), name: 'Home', color: '#7BC47F', emoji: '🏠', sortOrder: 2);
    final healthTag = local_tag.TagModel(id: IdGenerator.generate(), name: 'Health', color: '#E8B44C', emoji: '💪', sortOrder: 3);

    for (final tag in [personalTag, workTag, homeTag, healthTag]) {
      await tagsBox.put(tag.id, tag.toJson());
    }

    // ── Seed Tasks ──
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    final tasks = [
      local_task.TaskModel(
        id: IdGenerator.generate(),
        title: 'Buy fresh eggs',
        description: 'Get at least a dozen cage-free brown eggs.',
        tagId: homeTag.id,
        dueDate: today,
        dueTime: '08:30',
        priority: 2,
        completed: false,
        emoji: '🥚',
        createdAt: yesterday,
      ),
      local_task.TaskModel(
        id: IdGenerator.generate(),
        title: 'Call Dad & Mom',
        description: 'Weekly catchup call. Ask about Dad\'s doctor visit.',
        tagId: personalTag.id,
        dueDate: today,
        dueTime: '20:00',
        priority: 3,
        completed: false,
        emoji: '📞',
        createdAt: yesterday,
      ),
      local_task.TaskModel(
        id: IdGenerator.generate(),
        title: 'Pay monthly electricity bill',
        description: 'Pay via UPI, due date is soon.',
        tagId: homeTag.id,
        dueDate: today,
        dueTime: '11:00',
        priority: 2,
        completed: true,
        emoji: '🔌',
        createdAt: yesterday.subtract(const Duration(days: 1)),
      ),
      local_task.TaskModel(
        id: IdGenerator.generate(),
        title: 'Book train tickets for weekend trip',
        description: 'Book IRCTC sleeper class tickets.',
        tagId: personalTag.id,
        dueDate: tomorrow,
        dueTime: '10:00',
        priority: 3,
        completed: false,
        emoji: '🚂',
        createdAt: today,
      ),
      local_task.TaskModel(
        id: IdGenerator.generate(),
        title: 'Submit monthly sprint review presentation',
        description: 'Prepare slides for Q2 review.',
        tagId: workTag.id,
        dueDate: today,
        dueTime: '17:00',
        priority: 3,
        completed: false,
        emoji: '📊',
        createdAt: yesterday,
      ),
      local_task.TaskModel(
        id: IdGenerator.generate(),
        title: 'Plan tomorrow\'s priorities',
        description: 'Spend 5 minutes listing down top 3 highlights for tomorrow.',
        tagId: personalTag.id,
        dueDate: today,
        dueTime: '21:30',
        priority: 2,
        completed: false,
        emoji: '📝',
        createdAt: yesterday,
      ),
    ];

    for (final task in tasks) {
      await tasksBox.put(task.id, task.toJson());
    }

    // ── Seed Habits ──
    final List<String> readCompletions = [];
    final List<String> workoutCompletions = [];
    final List<String> medCompletions = [];

    for (int i = 1; i <= 7; i++) {
      final dateStr = DateHelpers.dateKey(today.subtract(Duration(days: i)));
      if (i <= 5) readCompletions.add(dateStr);
      if (i == 1 || i == 3 || i == 4) workoutCompletions.add(dateStr);
      if (i == 1 || i == 3) medCompletions.add(dateStr);
    }

    final habits = [
      local_habit.HabitModel(
        id: IdGenerator.generate(),
        name: 'Read a book',
        icon: '📚',
        frequency: 'daily',
        target: 1,
        reminderTime: '21:30',
        startDate: today.subtract(const Duration(days: 10)),
        completions: readCompletions,
      ),
      local_habit.HabitModel(
        id: IdGenerator.generate(),
        name: 'Morning Workout',
        icon: '💪',
        frequency: 'daily',
        target: 1,
        reminderTime: '06:30',
        startDate: today.subtract(const Duration(days: 10)),
        completions: workoutCompletions,
      ),
      local_habit.HabitModel(
        id: IdGenerator.generate(),
        name: 'Meditation',
        icon: '🧘',
        frequency: 'daily',
        target: 1,
        reminderTime: '08:00',
        startDate: today.subtract(const Duration(days: 10)),
        completions: medCompletions,
      ),
      local_habit.HabitModel(
        id: IdGenerator.generate(),
        name: 'Sleep Before 11 PM',
        icon: '😴',
        frequency: 'daily',
        target: 1,
        reminderTime: '22:45',
        startDate: today.subtract(const Duration(days: 5)),
        completions: const [],
      ),
    ];

    for (final habit in habits) {
      await habitsBox.put(habit.id, habit.toJson());
    }

    // ── Seed Moods ──
    final moods = [
      local_mood.MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 6)),
        mood: 'okay',
        note: 'Feeling a bit tired from the weekend travel.',
        createdAt: today.subtract(const Duration(days: 6)),
      ),
      local_mood.MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 5)),
        mood: 'good',
        note: 'Productive day at work, got some exercises in.',
        createdAt: today.subtract(const Duration(days: 5)),
      ),
      local_mood.MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 4)),
        mood: 'great',
        note: 'Fantastic dinner with friends! Highly energizing.',
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      local_mood.MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 3)),
        mood: 'okay',
        note: 'Slow day, struggled with focus.',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
      local_mood.MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 2)),
        mood: 'low',
        note: 'Felt burned out in the afternoon. Need rest.',
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      local_mood.MoodEntryModel(
        id: IdGenerator.generate(),
        date: today.subtract(const Duration(days: 1)),
        mood: 'good',
        note: 'Recovered well, reading habit is going strong.',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    ];

    for (final mood in moods) {
      await moodsBox.put(mood.id, mood.toJson());
    }

    // ── Seed Transactions ──
    final transactions = [
      local_tx.TransactionModel(
        id: IdGenerator.generate(),
        type: 'income',
        amount: 55000.0,
        category: 'Salary',
        description: 'Monthly Q1 salary credit',
        emoji: '💼',
        date: today.subtract(const Duration(days: 4)),
        createdAt: today.subtract(const Duration(days: 4)),
      ),
      local_tx.TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 1200.0,
        category: 'Groceries',
        description: 'Supermarket weekly grocery run',
        emoji: '🛒',
        date: today.subtract(const Duration(days: 2)),
        createdAt: today.subtract(const Duration(days: 2)),
      ),
      local_tx.TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 350.0,
        category: 'Dining Out',
        description: 'Starbucks coffee and snack',
        emoji: '☕',
        date: today.subtract(const Duration(days: 1)),
        createdAt: today.subtract(const Duration(days: 1)),
      ),
      local_tx.TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 450.0,
        category: 'Transport',
        description: 'Uber ride to office',
        emoji: '🚗',
        date: today,
        createdAt: today,
      ),
      local_tx.TransactionModel(
        id: IdGenerator.generate(),
        type: 'expense',
        amount: 2500.0,
        category: 'Entertainment',
        description: 'Concert tickets purchased online',
        emoji: '🎵',
        date: today.subtract(const Duration(days: 3)),
        createdAt: today.subtract(const Duration(days: 3)),
      ),
    ];

    for (final tx in transactions) {
      await transactionsBox.put(tx.id, tx.toJson());
    }

    // ── Seed Financial Goals ──
    final goals = [
      local_goal.FinancialGoalModel(
        id: 'emergency_fund_goal',
        name: 'Emergency Fund',
        icon: '🚨',
        targetAmount: 100000.0,
        currentAmount: 35000.0,
        deadline: today.add(const Duration(days: 180)),
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      local_goal.FinancialGoalModel(
        id: 'new_laptop_goal',
        name: 'New Laptop',
        icon: '💻',
        targetAmount: 75000.0,
        currentAmount: 15000.0,
        deadline: today.add(const Duration(days: 90)),
        createdAt: today.subtract(const Duration(days: 15)),
      ),
    ];

    for (final goal in goals) {
      await goalsBox.put(goal.id, goal.toJson());
    }

    // ── Seed Savings Plans (Chitu) ──
    final savingsPlans = [
      local_savings.SavingsPlanModel(
        id: 'chitu_3l_plan',
        name: 'Chitu 3L',
        monthlyAmount: 10000.0,
        durationMonths: 30,
        linkedGoalId: 'emergency_fund_goal',
        paidMonths: ['2026-04', '2026-05'],
        skippedMonths: const [],
        createdAt: today.subtract(const Duration(days: 60)),
        isActive: true,
      ),
      local_savings.SavingsPlanModel(
        id: 'laptop_savings_plan',
        name: 'Laptop Fund SIP',
        monthlyAmount: 5000.0,
        durationMonths: 12,
        linkedGoalId: 'new_laptop_goal',
        paidMonths: ['2026-05'],
        skippedMonths: const [],
        createdAt: today.subtract(const Duration(days: 30)),
        isActive: true,
      ),
    ];

    for (final plan in savingsPlans) {
      await savingsBox.put(plan.id, plan.toJson());
    }

    // ── Seed Bill Reminders ──
    final billReminders = [
      local_bill.BillReminderModel(
        id: 'rent_reminder',
        title: 'House Rent',
        amount: 15000.0,
        dueDay: 5,
        category: 'House Rent',
        isRecurring: true,
        isPaid: false,
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      local_bill.BillReminderModel(
        id: 'food_mess_reminder',
        title: 'Food Mess',
        amount: 4500.0,
        dueDay: 10,
        category: 'Food Mess',
        isRecurring: true,
        isPaid: false,
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      local_bill.BillReminderModel(
        id: 'credit_card_reminder',
        title: 'Credit Card Bill',
        amount: 8200.0,
        dueDay: 15,
        category: 'Credit Card Bill',
        isRecurring: true,
        isPaid: true,
        lastPaidDate: today.subtract(const Duration(days: 2)),
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      local_bill.BillReminderModel(
        id: 'parents_expense_reminder',
        title: 'Parents Monthly Expense',
        amount: 10000.0,
        dueDay: 8,
        category: 'Parents Expense',
        isRecurring: true,
        isPaid: false,
        createdAt: today.subtract(const Duration(days: 30)),
      ),
      local_bill.BillReminderModel(
        id: 'netflix_reminder',
        title: 'Netflix Premium',
        amount: 649.0,
        dueDay: 22,
        category: 'Subscription',
        isRecurring: true,
        isPaid: false,
        createdAt: today.subtract(const Duration(days: 30)),
      ),
    ];

    for (final reminder in billReminders) {
      await billsBox.put(reminder.id, reminder.toJson());
    }

    // ── Seed Debts ──
    final startOfDebts = today.subtract(const Duration(days: 60));
    final endOfDebts = today.add(const Duration(days: 120));

    final debts = [
      local_debt.DebtModel(
        id: IdGenerator.generate(),
        person: 'Saroo',
        category: 'Monitor EMI',
        amount: 3500.0,
        frequency: 'monthly',
        startDate: startOfDebts,
        endDate: endOfDebts,
        type: 'owedToMe',
        payments: [
          local_payment.DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 30)),
            amount: 3500.0,
            status: 'paid',
            paidAt: startOfDebts.add(const Duration(days: 30)),
          ),
          local_payment.DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 60)),
            amount: 3500.0,
            status: 'unpaid',
          ),
        ],
        createdAt: startOfDebts,
      ),
      local_debt.DebtModel(
        id: IdGenerator.generate(),
        person: 'Saroo',
        category: 'Mobile EMI',
        amount: 2000.0,
        frequency: 'monthly',
        startDate: startOfDebts,
        endDate: endOfDebts,
        type: 'owedToMe',
        payments: [
          local_payment.DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 30)),
            amount: 2000.0,
            status: 'paid',
            paidAt: startOfDebts.add(const Duration(days: 31)),
          ),
          local_payment.DebtPaymentModel(
            id: IdGenerator.generate(),
            date: startOfDebts.add(const Duration(days: 60)),
            amount: 2000.0,
            status: 'unpaid',
          ),
        ],
        createdAt: startOfDebts,
      ),
      local_debt.DebtModel(
        id: IdGenerator.generate(),
        person: 'Ramesh',
        category: 'Office Lunch Share',
        amount: 450.0,
        frequency: 'one-time',
        startDate: today.subtract(const Duration(days: 2)),
        endDate: today.add(const Duration(days: 5)),
        type: 'iOwe',
        payments: const [],
        createdAt: today.subtract(const Duration(days: 2)),
      ),
    ];

    for (final debt in debts) {
      await debtsBox.put(debt.id, debt.toJson());
    }
  }
}
