import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/section_header.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';
import 'package:jarvis/shared/widgets/empty_state.dart';
import 'package:jarvis/features/money/screens/widgets/add_savings_plan_sheet.dart';

class SavingsPlansSection extends ConsumerWidget {
  const SavingsPlansSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(savingsPlanProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: SectionHeader(
            title: 'Savings Plans',
            onActionTap: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => const AddSavingsPlanSheet(),
              );
            },
            actionLabel: '+ Add Plan',
          ),
        ),
        const SizedBox(height: 10.0),
        plansAsync.when(
          data: (plans) {
            if (plans.isEmpty) {
              return EmptyState(
                emoji: '🐷',
                title: 'No savings plans configured',
                subtitle: 'Set up recurring savings plans to automate your savings contributions and link them to your goals.',
                actionLabel: 'Add Plan',
                onActionPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddSavingsPlanSheet(),
                  );
                },
              );
            }

            return Column(
              children: plans.map((p) => _SavingsPlanCard(plan: p)).toList(),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _SavingsPlanCard extends ConsumerWidget {
  final SavingsPlanModel plan;

  const _SavingsPlanCard({required this.plan});

  void _payMonth(BuildContext context, WidgetRef ref) async {
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7); // 'yyyy-MM'
    if (plan.paidMonths.contains(currentMonth)) {
      ToastNotification.show(context, 'Already contributed for this month!', type: 'info');
      return;
    }

    // 1. Log transaction
    final tx = TransactionModel(
      id: IdGenerator.generate(),
      type: 'expense', // savings are recorded as outflow from liquidity
      amount: plan.monthlyAmount,
      category: 'Savings Plan',
      description: 'Savings Plan: ${plan.name} Contribution',
      emoji: '🐷',
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await ref.read(transactionProvider.notifier).addTransaction(tx);

    // 2. Increment linked Goal
    if (plan.linkedGoalId != null) {
      final goals = ref.read(goalProvider).value ?? [];
      final goalIndex = goals.indexWhere((g) => g.id == plan.linkedGoalId);
      if (goalIndex != -1) {
        final goal = goals[goalIndex];
        final updatedGoal = goal.copyWith(
          currentAmount: goal.currentAmount + plan.monthlyAmount,
        );
        await ref.read(goalProvider.notifier).updateGoal(updatedGoal);
      }
    }

    // 3. Update savings plan ledger
    final updatedPaid = [...plan.paidMonths, currentMonth];
    final updatedPlan = plan.copyWith(paidMonths: updatedPaid);
    await ref.read(savingsPlanProvider.notifier).updateSavingsPlan(updatedPlan);

    ref.invalidate(monthlyExpensesProvider);
    ref.invalidate(todaySpentProvider);
    ref.invalidate(recentTransactionsProvider);

    if (context.mounted) {
      ToastNotification.show(
        context,
        'Saved: ₹${plan.monthlyAmount} in ${plan.name}!',
      );
    }
  }

  void _unlinkGoal(BuildContext context, WidgetRef ref) async {
    if (plan.linkedGoalId == null) return;

    final goalId = plan.linkedGoalId!;
    final goals = ref.read(goalProvider).value ?? [];
    final goalIndex = goals.indexWhere((g) => g.id == goalId);

    // Sync Option A logic: Subtract contributed savings from the goal progress
    if (goalIndex != -1) {
      final goal = goals[goalIndex];
      final totalPlanContribution = plan.monthlyAmount * plan.paidMonths.length;
      final updatedGoal = goal.copyWith(
        currentAmount: (goal.currentAmount - totalPlanContribution).clamp(0.0, double.infinity),
      );
      await ref.read(goalProvider.notifier).updateGoal(updatedGoal);
    }

    final updatedPlan = plan.copyWith(
      linkedGoalId: () => null,
    );
    await ref.read(savingsPlanProvider.notifier).updateSavingsPlan(updatedPlan);

    if (context.mounted) {
      ToastNotification.show(context, 'Unlinked goal. Goal progress decreased.', type: 'info');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMonth = DateTime.now().toIso8601String().substring(0, 7);
    final contributedThisMonth = plan.paidMonths.contains(currentMonth);
    
    // Find linked goal name safely
    final goals = ref.watch(goalProvider).value ?? [];
    final hasGoal = plan.linkedGoalId != null;
    final linkedGoal = hasGoal
        ? (goals.any((g) => g.id == plan.linkedGoalId)
            ? goals.firstWhere((g) => g.id == plan.linkedGoalId)
            : null)
        : null;

    final progressText = plan.durationMonths != null
        ? 'Month ${plan.paidMonths.length}/${plan.durationMonths}'
        : 'Active Months: ${plan.paidMonths.length}';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: JarvisCard(
        padding: 16.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 44.0,
                  height: 44.0,
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Text('🐷', style: TextStyle(fontSize: 20.0)),
                ),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        plan.name,
                        style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '$progressText • EMI: ${CurrencyFormatter.format(plan.monthlyAmount)}',
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyFormatter.format(plan.totalSaved),
                      style: AppTypography.bodyMedium(color: AppColors.secondary).copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      'Total Saved',
                      style: AppTypography.micro(color: AppColors.textTertiary),
                    ),
                  ],
                ),
              ],
            ),
            if (hasGoal && linkedGoal != null) ...[
              const SizedBox(height: 12.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceHover,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.link_rounded, color: AppColors.primary, size: 14.0),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        'Linked to goal: ${linkedGoal.icon} ${linkedGoal.name}',
                        style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _unlinkGoal(context, ref),
                      child: Text(
                        'Unlink',
                        style: AppTypography.micro(color: AppColors.error).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: JarvisButton(
                    text: contributedThisMonth ? '✓ Saved This Month' : 'Save Monthly',
                    isOutline: contributedThisMonth,
                    onPressed: contributedThisMonth ? null : () => _payMonth(context, ref),
                  ),
                ),
                const SizedBox(width: 8.0),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () async {
                    await ref.read(savingsPlanProvider.notifier).deleteSavingsPlan(plan.id);
                    if (context.mounted) {
                      ToastNotification.show(context, 'Savings Plan deleted.');
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
