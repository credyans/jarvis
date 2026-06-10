import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/constants/emoji_map.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/section_header.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';
import 'package:jarvis/shared/widgets/empty_state.dart';
import 'package:jarvis/features/money/screens/widgets/add_bill_reminder_sheet.dart';

class BillRemindersSection extends ConsumerWidget {
  const BillRemindersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final billsAsync = ref.watch(billReminderProvider);

    return billsAsync.when(
      data: (reminders) {
        if (reminders.isEmpty) {
          return Center(
            child: EmptyState(
              emoji: '🧾',
              title: 'Never miss a bill payment',
              subtitle: 'Bills tracker helps you monitor recurring utilities and services. Set up reminders to prevent late fees and protect your credit score.',
              actionLabel: 'Add Bill Reminder',
              onActionPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AddBillReminderSheet(),
                );
              },
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SectionHeader(
                title: 'Bill Reminders',
                onActionTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddBillReminderSheet(),
                  );
                },
                actionLabel: '+ Add Bill',
              ),
            ),
            const SizedBox(height: 10.0),
            Column(
              children: reminders.map((b) => _BillReminderCard(reminder: b)).toList(),
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _BillReminderCard extends ConsumerWidget {
  final BillReminderModel reminder;

  const _BillReminderCard({required this.reminder});

  String _getCategoryEmoji(String category) {
    switch (category) {
      case 'House Rent':
        return '🏠';
      case 'Food Mess':
        return '🍲';
      case 'Credit Card Bill':
        return '💳';
      case 'Subscription':
        return '🧾';
      case 'Utilities':
        return '🔌';
      default:
        return '➕';
    }
  }

  void _payBill(BuildContext context, WidgetRef ref) async {
    // 1. Log transaction
    final tx = TransactionModel(
      id: IdGenerator.generate(),
      type: 'expense',
      amount: reminder.amount,
      category: reminder.category,
      description: 'Paid: ${reminder.title}',
      emoji: _getCategoryEmoji(reminder.category),
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await ref.read(transactionProvider.notifier).addTransaction(tx);

    // 2. Mark reminder as paid
    final updatedReminder = reminder.copyWith(
      isPaid: true,
      lastPaidDate: () => DateTime.now(),
    );
    await ref.read(billReminderProvider.notifier).updateBillReminder(updatedReminder);

    // 3. Invalidate metrics
    ref.invalidate(monthlyExpensesProvider);
    ref.invalidate(todaySpentProvider);
    ref.invalidate(recentTransactionsProvider);

    if (context.mounted) {
      ToastNotification.show(context, 'Paid: ${reminder.title} (${CurrencyFormatter.format(reminder.amount)})');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPaid = reminder.isPaid;
    final emoji = _getCategoryEmoji(reminder.category);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: JarvisCard(
        padding: 16.0,
        child: Row(
          children: [
            Container(
              width: 44.0,
              height: 44.0,
              decoration: BoxDecoration(
                color: isPaid ? AppColors.success.withOpacity(0.1) : AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10.0),
              ),
              alignment: Alignment.center,
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 20.0),
              ),
            ),
            const SizedBox(width: 14.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.title,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: isPaid ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    reminder.isRecurring
                        ? 'Due Day: ${reminder.dueDay}th of month'
                        : 'Due: One-time bill',
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(reminder.amount),
                  style: AppTypography.bodyMedium(
                    color: isPaid ? AppColors.textTertiary : AppColors.textPrimary,
                  ).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4.0),
                if (!isPaid)
                  GestureDetector(
                    onTap: () => _payBill(context, ref),
                    child: Text(
                      'Pay Now',
                      style: AppTypography.micro(color: AppColors.primary).copyWith(
                        fontWeight: FontWeight.bold,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  )
                else
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12.0),
                      const SizedBox(width: 4.0),
                      Text(
                        'Paid',
                        style: AppTypography.micro(color: AppColors.success).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
