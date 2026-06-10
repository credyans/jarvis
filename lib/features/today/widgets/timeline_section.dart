import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/data/providers/todo_countdown_provider.dart';
import 'package:jarvis/features/today/widgets/timeline_item.dart';
import 'package:jarvis/shared/widgets/section_header.dart';

class TimelineSection extends ConsumerWidget {
  const TimelineSection({super.key});

  int _getPeriodIndex(String timeStr) {
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      if (hour >= 5 && hour < 12) return 0; // Morning
      if (hour >= 12 && hour < 17) return 1; // Afternoon
      if (hour >= 17 && hour < 21) return 2; // Evening
      return 3; // Night
    } catch (_) {
      return 0; // Default to Morning
    }
  }

  Widget _buildPeriodBlock({
    required String periodName,
    required IconData icon,
    required List<Widget> children,
  }) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left connecting indicator line
          Column(
            children: [
              Icon(icon, size: 20.0, color: AppColors.primary.withOpacity(0.7)),
              Expanded(
                child: Container(
                  width: 1.5,
                  color: AppColors.primary.withOpacity(0.15),
                  margin: const EdgeInsets.symmetric(vertical: 4.0),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  periodName.toUpperCase(),
                  style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8.0),
                ...children,
                const SizedBox(height: 12.0),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final habitsAsync = ref.watch(habitProvider);
    final debtsAsync = ref.watch(debtProvider);
    final countdowns = ref.watch(todoCountdownProvider);

    if (tasksAsync.isLoading || habitsAsync.isLoading || debtsAsync.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: CircularProgressIndicator(),
        ),
      );
    }

    final tasks = tasksAsync.value ?? [];
    final habits = habitsAsync.value ?? [];
    final debts = debtsAsync.value ?? [];

    final items = _mergeAndFilterTimeline(ref, tasks, habits, debts, countdowns);
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    // Categorize items into 4 lists: Morning, Afternoon, Evening, Night
    final List<List<Widget>> periodLists = [[], [], [], []];
    
    for (final item in items) {
      final pIdx = _getPeriodIndex(item.time);
      periodLists[pIdx].add(
        TimelineItem(
          title: item.title,
          subtitle: item.subtitle,
          time: item.time,
          color: item.color,
          isCompleted: item.isCompleted,
          icon: item.icon,
          isInCountdown: countdowns.containsKey(item.id),
          secondsLeft: countdowns[item.id] ?? 0,
          onTap: () {
            // Check item -> start countdown
            ref.read(todoCountdownProvider.notifier).startCountdown(item.id, () {
              item.onComplete();
            });
          },
          onUndo: () {
            // Undo -> cancel countdown
            ref.read(todoCountdownProvider.notifier).undoCountdown(item.id);
          },
        ),
      );
    }

    final List<Widget> blocks = [];
    final periodNames = ['Morning', 'Afternoon', 'Evening', 'Night'];
    final periodIcons = [
      Icons.light_mode_outlined,
      Icons.wb_sunny_outlined,
      Icons.nights_stay_outlined,
      Icons.dark_mode_outlined
    ];

    for (int i = 0; i < 4; i++) {
      if (periodLists[i].isNotEmpty) {
        blocks.add(
          _buildPeriodBlock(
            periodName: periodNames[i],
            icon: periodIcons[i],
            children: periodLists[i],
          ),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'To Do',
          onActionTap: () {
            // Can switch tabs
          },
        ),
        const SizedBox(height: 12.0),
        Column(
          children: blocks,
        ),
      ],
    );
  }

  List<_TodoItemData> _mergeAndFilterTimeline(
    WidgetRef ref,
    List<TaskModel> tasks,
    List<HabitModel> habits,
    List<DebtModel> debts,
    Map<String, int> countdowns,
  ) {
    final List<_TodoItemData> data = [];
    final today = DateTime.now();

    // 1. Process Tasks
    for (final task in tasks) {
      final inCountdown = countdowns.containsKey(task.id);
      // Include if incomplete OR if it is in the active countdown
      if (!task.completed || inCountdown) {
        data.add(_TodoItemData(
          id: task.id,
          title: task.title,
          subtitle: task.description,
          time: task.dueTime ?? '09:00',
          color: AppColors.primary,
          isCompleted: task.completed,
          icon: Icons.check_circle_outline_rounded,
          onComplete: () {
            ref.read(taskProvider.notifier).toggleCompletion(task.id);
            ref.invalidate(todayTasksProvider);
          },
        ));
      }
    }

    // 2. Process Habits
    for (final habit in habits) {
      bool isDueToday = false;
      if (habit.frequency == 'daily') {
        isDueToday = true;
      } else if (habit.frequency == 'weekdays') {
        isDueToday = today.weekday >= 1 && today.weekday <= 5;
      } else {
        isDueToday = true;
      }

      if (isDueToday) {
        final isDone = ref.read(habitProvider.notifier).isCompletedToday(habit);
        final inCountdown = countdowns.containsKey(habit.id);
        
        if (!isDone || inCountdown) {
          data.add(_TodoItemData(
            id: habit.id,
            title: habit.name,
            subtitle: 'Habit • ${habit.frequency}',
            time: habit.reminderTime ?? '07:00',
            color: AppColors.secondary,
            isCompleted: isDone,
            icon: Icons.loop_rounded,
            onComplete: () {
              ref.read(habitProvider.notifier).toggleCompletion(habit.id, today);
            },
          ));
        }
      }
    }

    // 3. Process Debts
    for (final debt in debts) {
      final unpaid = debt.payments.where((p) => p.status != 'paid');
      for (final p in unpaid) {
        final isDueToday = DateHelpers.isSameDay(p.date, today);
        final isOverdue = p.date.isBefore(today) && !isDueToday;
        
        if (isDueToday || isOverdue) {
          final debtItemId = 'debt_${debt.id}_${p.id}';
          final inCountdown = countdowns.containsKey(debtItemId);
          
          if (p.status != 'paid' || inCountdown) {
            data.add(_TodoItemData(
              id: debtItemId,
              title: '${debt.type == 'owedToMe' ? 'Collect' : 'Pay'} ${debt.person}',
              subtitle: '${debt.category} • ₹${p.amount.toStringAsFixed(0)}${isOverdue ? ' (Overdue)' : ''}',
              time: '12:00',
              color: AppColors.warning,
              isCompleted: p.status == 'paid',
              icon: Icons.monetization_on_outlined,
              onComplete: () async {
                final updatedPayments = debt.payments.map((pm) {
                  if (pm.id == p.id) {
                    return pm.copyWith(
                      status: 'paid',
                      paidAt: () => DateTime.now(),
                    );
                  }
                  return pm;
                }).toList();
                final updatedDebt = debt.copyWith(payments: updatedPayments);
                await ref.read(debtProvider.notifier).updateDebt(updatedDebt);
              },
            ));
          }
        }
      }
    }

    // Sort chronologically by time
    data.sort((a, b) => a.time.compareTo(b.time));
    return data;
  }
}

class _TodoItemData {
  final String id;
  final String title;
  final String? subtitle;
  final String time;
  final Color color;
  final bool isCompleted;
  final IconData icon;
  final VoidCallback onComplete;

  _TodoItemData({
    required this.id,
    required this.title,
    this.subtitle,
    required this.time,
    required this.color,
    required this.isCompleted,
    required this.icon,
    required this.onComplete,
  });
}
