import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/currency_formatter.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/features/money/data/models/financial_goal_model.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/debt_payment_model.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/features/tasks/data/models/task_model.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/section_header.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';
import 'package:jarvis/shared/widgets/empty_state.dart';

// Modular Widgets & Sheets
import 'package:jarvis/features/money/screens/widgets/add_transaction_sheet.dart';
import 'package:jarvis/features/money/screens/widgets/add_bill_reminder_sheet.dart';
import 'package:jarvis/features/money/screens/widgets/add_savings_plan_sheet.dart';
import 'package:jarvis/features/money/screens/widgets/add_debt_sheet.dart';
import 'package:jarvis/features/money/screens/widgets/bill_reminders_section.dart';
import 'package:jarvis/features/money/screens/widgets/savings_plans_section.dart';

class MoneyScreen extends ConsumerStatefulWidget {
  const MoneyScreen({super.key});

  @override
  ConsumerState<MoneyScreen> createState() => _MoneyScreenState();
}

class _MoneyScreenState extends ConsumerState<MoneyScreen> {
  int _activeTabIndex = 0; // 0: Overview, 1: Savings, 2: Bills, 3: Debts

  void _showAddOptionsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const _AddOptionsSheet(),
    );
  }

  void _showAddTransactionSheet(BuildContext context, {String? initialType}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTransactionSheet(initialType: initialType),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddGoalSheet(),
    );
  }

  void _showAddBillReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddBillReminderSheet(),
    );
  }

  void _showAddSavingsPlanSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddSavingsPlanSheet(),
    );
  }

  void _showAddDebtSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddDebtSheet(),
    );
  }

  Widget _buildTabSelector() {
    return Container(
      height: 48.0,
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      padding: const EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24.0),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
        ),
      ),
      child: Row(
        children: [
          _buildTabButton(0, 'Overview', Icons.dashboard_outlined),
          _buildTabButton(1, 'Savings', Icons.savings_outlined),
          _buildTabButton(2, 'Bills', Icons.receipt_long_outlined),
          _buildTabButton(3, 'Debts', Icons.people_outline_rounded),
        ],
      ),
    );
  }

  Widget _buildTabButton(int index, String label, IconData icon) {
    final isSelected = _activeTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _activeTabIndex = index;
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20.0),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15.0,
                color: isSelected ? AppColors.background : AppColors.textSecondary,
              ),
              const SizedBox(width: 4.0),
              Text(
                label,
                style: AppTypography.micro(
                  color: isSelected ? AppColors.background : AppColors.textSecondary,
                ).copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, double amount, Color color, String emoji, {VoidCallback? onTap}) {
    return Expanded(
      child: JarvisCard(
        padding: 12.0,
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18.0)),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Text(
              title,
              style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              CurrencyFormatter.format(amount),
              style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                fontWeight: FontWeight.w800,
                fontSize: 14.0,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final goalsAsync = ref.watch(goalProvider);
    final debtsAsync = ref.watch(debtProvider);
    final savingsPlansAsync = ref.watch(savingsPlanProvider);
    final billsAsync = ref.watch(billReminderProvider);

    // Calculate Summary Metrics
    final goals = goalsAsync.value ?? [];
    final savingsPlans = savingsPlansAsync.value ?? [];
    final debts = debtsAsync.value ?? [];
    final monthlyIncomeAsync = ref.watch(monthlyIncomeProvider);
    final double salaryAmount = monthlyIncomeAsync.value ?? 0.0;

    double totalSaved = 0.0;
    for (final goal in goals) {
      totalSaved += goal.currentAmount;
    }
    for (final plan in savingsPlans) {
      totalSaved += plan.totalSaved;
    }

    double totalOwedToMe = 0.0;
    double totalIOwe = 0.0;
    for (final debt in debts) {
      double remaining = 0.0;
      for (final p in debt.payments) {
        if (p.status != 'paid') {
          remaining += p.amount;
        }
      }
      if (debt.type == 'owedToMe') {
        totalOwedToMe += remaining;
      } else {
        totalIOwe += remaining;
      }
    }

    final txs = transactionsAsync.value ?? [];
    final reminders = billsAsync.value ?? [];

    final activeTabEmpty = (_activeTabIndex == 0 && txs.isEmpty) ||
                           (_activeTabIndex == 1 && goals.isEmpty && savingsPlans.isEmpty) ||
                           (_activeTabIndex == 2 && reminders.isEmpty) ||
                           (_activeTabIndex == 3 && debts.isEmpty);
    final scrollPhysics = activeTabEmpty ? const NeverScrollableScrollPhysics() : const AlwaysScrollableScrollPhysics();

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0, right: 8.0),
        child: FloatingActionButton(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.primaryDark,
          elevation: 6.0,
          shape: const CircleBorder(),
          onPressed: () => _showAddOptionsSheet(context),
          child: const Icon(Icons.add_rounded, size: 28.0),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(transactionProvider);
            ref.invalidate(goalProvider);
            ref.invalidate(debtProvider);
            ref.invalidate(savingsPlanProvider);
            ref.invalidate(billReminderProvider);
            ref.invalidate(monthlyIncomeProvider);
            ref.invalidate(monthlyExpensesProvider);
            ref.invalidate(todaySpentProvider);
            ref.invalidate(recentTransactionsProvider);
          },
          child: CustomScrollView(
            physics: scrollPhysics,
            slivers: [
              // ALWAYS SHOWN: 1. Operating Liquidity Header
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 8.0,
                ),
                sliver: const SliverToBoxAdapter(
                  child: _OperatingLiquidityHeader(),
                ),
              ),

              // ALWAYS SHOWN: 2. Tab Selector Row
              SliverToBoxAdapter(
                child: _buildTabSelector(),
              ),

              // TAB CONTENTS
              if (_activeTabIndex == 0) ...[
                // Overview Tab
                if (txs.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        emoji: '📊',
                        title: 'Financial Overview',
                        subtitle: 'Tracks daily transaction history and cash flow dynamics.',
                        actionLabel: '+ Add Record',
                        onActionPressed: () => _showAddTransactionSheet(context),
                      ),
                    ),
                  )
                else ...[
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: _FlowDynamicsCard(),
                    ),
                  ),
                  
                  // 2x2 Summary Grid Row
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Row(
                            children: [
                              _buildSummaryCard(
                                'Salary',
                                salaryAmount,
                                AppColors.secondary,
                                '💼',
                                onTap: () => _showAddTransactionSheet(context, initialType: 'income'),
                              ),
                              const SizedBox(width: 12.0),
                              _buildSummaryCard(
                                'Total Saved',
                                totalSaved,
                                AppColors.primary,
                                '🐷',
                                onTap: () => setState(() => _activeTabIndex = 1),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            children: [
                              _buildSummaryCard(
                                'Owed to Me',
                                totalOwedToMe,
                                AppColors.success,
                                '📈',
                                onTap: () => setState(() => _activeTabIndex = 3),
                              ),
                              const SizedBox(width: 12.0),
                              _buildSummaryCard(
                                'I Owe',
                                totalIOwe,
                                AppColors.error,
                                '📉',
                                onTap: () => setState(() => _activeTabIndex = 3),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Recent Transactions',
                            onActionTap: () => _showAddTransactionSheet(context),
                            actionLabel: '+ Add Record',
                          ),
                          const SizedBox(height: 10.0),
                          transactionsAsync.when(
                            data: (txs) => _RecentTransactionsList(txs: txs),
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ] else if (_activeTabIndex == 1) ...[
                // Savings Tab
                if (goals.isEmpty && savingsPlans.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('🐷', style: TextStyle(fontSize: 64.0)),
                          const SizedBox(height: 16.0),
                          Text('Savings & Goals', style: AppTypography.h3(color: AppColors.textPrimary)),
                          const SizedBox(height: 8.0),
                          Text(
                            'Grow wealth by creating savings plans or tracking goals.',
                            style: AppTypography.body(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24.0),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Row(
                              children: [
                                Expanded(
                                  child: JarvisButton(
                                    text: 'Add Savings Plan',
                                    onPressed: () => _showAddSavingsPlanSheet(context),
                                  ),
                                ),
                                const SizedBox(width: 16.0),
                                Expanded(
                                  child: JarvisButton(
                                    text: 'Add Goal',
                                    isOutline: true,
                                    onPressed: () => _showAddGoalSheet(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else ...[
                  SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                          child: SectionHeader(
                            title: 'Savings Goals',
                            onActionTap: () => _showAddGoalSheet(context),
                            actionLabel: '+ Add Goal',
                          ),
                        ),
                        const SizedBox(height: 6.0),
                        goalsAsync.when(
                          data: (goalsList) => _GoalsList(
                            goals: goalsList,
                            onAddAmount: (goalId, amt) async {
                              if (goalId == 'freedom_fund_seed') {
                                ToastNotification.show(context, 'Seed savings updated (Simulator)!');
                                return;
                              }
                              final goal = goalsList.firstWhere((g) => g.id == goalId);
                              final updated = goal.copyWith(currentAmount: goal.currentAmount + amt);
                              await ref.read(goalProvider.notifier).updateGoal(updated);
                              if (context.mounted) {
                                ToastNotification.show(context, 'Goal savings updated!');
                              }
                            },
                          ),
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),

                  const SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    sliver: SliverToBoxAdapter(
                      child: SavingsPlansSection(),
                    ),
                  ),
                ],
              ] else if (_activeTabIndex == 2) ...[
                // Bills Tab
                if (reminders.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
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
                    ),
                  )
                else
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: BillRemindersSection(),
                    ),
                  ),
              ] else if (_activeTabIndex == 3) ...[
                // Debts Tab
                if (debts.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Center(
                      child: EmptyState(
                        emoji: '🤝',
                        title: 'Track Peer Agreements',
                        subtitle: 'Track peer-to-peer agreements and monthly borrowing EMIs.',
                        actionLabel: '+ Add Agreement',
                        onActionPressed: () => _showAddDebtSheet(context),
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SectionHeader(
                            title: 'Debt & EMI Agreements',
                            onActionTap: () => _showAddDebtSheet(context),
                            actionLabel: '+ Add Agreement',
                          ),
                          const SizedBox(height: 10.0),
                          debtsAsync.when(
                            data: (debtList) {
                              return Column(
                                children: debtList.map((debt) {
                                  return _DebtCard(
                                    debt: debt,
                                    onCollectEMI: (paymentId) async {
                                      final updatedPayments = debt.payments.map((p) {
                                        if (p.id == paymentId) {
                                          return p.copyWith(status: 'paid', paidAt: () => DateTime.now());
                                        }
                                        return p;
                                      }).toList();
                                      final updatedDebt = debt.copyWith(payments: updatedPayments);
                                      await ref.read(debtProvider.notifier).updateDebt(updatedDebt);
                                      
                                      final tx = TransactionModel(
                                        id: IdGenerator.generate(),
                                        type: debt.type == 'owedToMe' ? 'income' : 'expense',
                                        amount: debt.payments.firstWhere((p) => p.id == paymentId).amount,
                                        category: debt.type == 'owedToMe' ? 'Owed to Me (Receipt)' : 'I Owe (Payment)',
                                        description: '${debt.person} — ${debt.category} EMI',
                                        emoji: debt.type == 'owedToMe' ? '📈' : '📉',
                                        date: DateTime.now(),
                                        createdAt: DateTime.now(),
                                      );
                                      await ref.read(transactionProvider.notifier).addTransaction(tx);
                                      
                                      if (context.mounted) {
                                        ToastNotification.show(context, 'EMI marked as Paid/Collected!');
                                      }
                                    },
                                  );
                                }).toList(),
                              );
                            },
                            loading: () => const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],

              // Bottom Buffer
              const SliverToBoxAdapter(
                child: SizedBox(height: 180.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── SUB-WIDGETS ──

class _OperatingLiquidityHeader extends ConsumerWidget {
  const _OperatingLiquidityHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final income = ref.watch(monthlyIncomeProvider).value ?? 0.0;
    final expense = ref.watch(monthlyExpensesProvider).value ?? 0.0;
    final safeToSpend = (income - expense).clamp(0.0, double.infinity);
    final displayBalance = safeToSpend;

    // Calculate dynamic savings rate
    final double changePercentage = income > 0 ? (safeToSpend / income) * 100 : 0.0;
    final String percentageText = '${changePercentage > 0 ? '+' : ''}${changePercentage.toStringAsFixed(1)}%';
    final Color percentageColor = changePercentage > 0 ? AppColors.success : AppColors.textSecondary;
    final IconData percentageIcon = changePercentage > 0 ? Icons.trending_up_rounded : Icons.trending_flat_rounded;
    final Color percentageBgColor = changePercentage > 0 ? AppColors.success.withOpacity(0.15) : AppColors.textSecondary.withOpacity(0.1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Operating Liquidity',
              style: AppTypography.micro(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 4.0),
            Tooltip(
              message: "Operating Liquidity is your 'Safe-to-Spend' amount (Income minus Expenses). The percentage indicates your current monthly Net Savings Rate.",
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: true,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              textStyle: AppTypography.caption(color: AppColors.textPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Icon(
                Icons.info_outline_rounded,
                size: 14.0,
                color: AppColors.textSecondary.withOpacity(0.6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6.0),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              CurrencyFormatter.format(displayBalance),
              style: AppTypography.display(color: AppColors.textPrimary).copyWith(
                fontSize: 36.0,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 12.0),
            Tooltip(
              message: "Your current Net Savings Rate: $percentageText of monthly income kept after expenses.",
              triggerMode: TooltipTriggerMode.tap,
              preferBelow: true,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10.0,
                  ),
                ],
              ),
              textStyle: AppTypography.caption(color: AppColors.textPrimary),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: percentageBgColor,
                  borderRadius: BorderRadius.circular(6.0),
                ),
                child: Row(
                  children: [
                    Icon(percentageIcon, color: percentageColor, size: 14.0),
                    const SizedBox(width: 4.0),
                    Text(
                      percentageText,
                      style: AppTypography.micro(color: percentageColor).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FlowDynamicsCard extends ConsumerWidget {
  const _FlowDynamicsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incomeVal = ref.watch(monthlyIncomeProvider).value ?? 0.0;
    final expenseVal = ref.watch(monthlyExpensesProvider).value ?? 0.0;

    final income = incomeVal;
    final expense = expenseVal;

    final ratio = income > 0 ? (expense / income).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
          bottom: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Flow Dynamics',
                style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Income vs Expenditure',
                style: AppTypography.micro(color: AppColors.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 18.0),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Income',
                      style: AppTypography.micro(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      CurrencyFormatter.format(income),
                      style: AppTypography.bodyMedium(color: AppColors.success).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: Container(
                        height: 6.0,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expenditure',
                      style: AppTypography.micro(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      CurrencyFormatter.format(expense),
                      style: AppTypography.bodyMedium(color: AppColors.error).copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4.0),
                      child: FractionallySizedBox(
                        widthFactor: ratio == 0.0 ? 0.65 : ratio,
                        alignment: Alignment.centerLeft,
                        child: Container(
                          height: 6.0,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddOptionsSheet extends StatelessWidget {
  const _AddOptionsSheet();

  Widget _buildOption(
    BuildContext context, {
    required String emoji,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: JarvisCard(
        padding: 16.0,
        onTap: () {
          Navigator.pop(context); // Close option selector sheet first!
          onTap();
        },
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26.0)),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 20.0),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Log & Remind', style: AppTypography.h2(color: AppColors.textPrimary)),
              const SizedBox(height: 20.0),
              _buildOption(
                context,
                emoji: '📝',
                title: 'Record Transaction',
                subtitle: 'Log income or a simple one-off expense',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddTransactionSheet(),
                  );
                },
              ),
              _buildOption(
                context,
                emoji: '🧾',
                title: 'Add Bill Reminder',
                subtitle: 'Rent, food mess, CC bills, subscriptions',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddBillReminderSheet(),
                  );
                },
              ),
              _buildOption(
                context,
                emoji: '🐷',
                title: 'Start Savings / Chitu Plan',
                subtitle: 'Log recurring savings linked to financial goals',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddSavingsPlanSheet(),
                  );
                },
              ),
              _buildOption(
                context,
                emoji: '🤝',
                title: 'Log Debt / EMI Agreement',
                subtitle: 'Track peer lending, borrowing, and product EMIs',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => const AddDebtSheet(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DebtDetailsSheet extends ConsumerWidget {
  final DebtModel debt;
  const _DebtDetailsSheet({required this.debt});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
            ),
          ),
          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: bottom + 32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(debt.type == 'owedToMe' ? '📈' : '📉', style: const TextStyle(fontSize: 32.0)),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(debt.person, style: AppTypography.h2(color: AppColors.textPrimary)),
                          Text(
                            debt.category,
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                JarvisCard(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Loan Value', style: AppTypography.caption(color: AppColors.textSecondary)),
                          Text(
                            CurrencyFormatter.format(debt.amount),
                            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.border, height: 20.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Frequency', style: AppTypography.caption(color: AppColors.textSecondary)),
                          Text(
                            debt.frequency == 'monthly' ? 'Monthly EMI' : 'One-time repayment',
                            style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                Text(
                  'PAYMENT INSTALLMENTS',
                  style: AppTypography.micro(color: AppColors.textSecondary).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                if (debt.payments.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No installments registered.',
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Column(
                    children: debt.payments.map((p) {
                      final isPaid = p.status == 'paid';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Installment: ${CurrencyFormatter.format(p.amount)}',
                                  style: AppTypography.caption(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  isPaid && p.paidAt != null
                                      ? 'Settled on ${DateHelpers.formatDate(p.paidAt!)}'
                                      : 'Due: ${DateHelpers.formatDate(p.date)}',
                                  style: AppTypography.micro(color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: isPaid ? AppColors.success.withOpacity(0.12) : AppColors.warning.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6.0),
                              ),
                              child: Text(
                                isPaid ? 'SETTLED' : 'PENDING',
                                style: AppTypography.micro(
                                  color: isPaid ? AppColors.success : AppColors.warning,
                                ).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  final List<FinancialGoalModel> goals;
  final Function(String goalId, double amount) onAddAmount;

  const _GoalsList({required this.goals, required this.onAddAmount});

  @override
  Widget build(BuildContext context) {
    final list = [...goals];
    
    if (list.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: Text(
          'No savings goals created yet.',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 145.0,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        itemCount: list.length,
        itemBuilder: (context, index) {
          final goal = list[index];
          final progress = goal.progress;

          return Container(
            width: 190.0,
            margin: const EdgeInsets.only(right: 12.0),
            child: JarvisCard(
              padding: 12.0,
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => _GoalDetailsSheet(goal: goal),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(goal.icon, style: const TextStyle(fontSize: 24.0)),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: AppTypography.caption(color: AppColors.primary).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    goal.name,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6.0),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3.0),
                    child: LinearProgressIndicator(
                      value: progress,
                      color: AppColors.primary,
                      backgroundColor: AppColors.border,
                      minHeight: 5.0,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    '${CurrencyFormatter.format(goal.currentAmount)} / ${CurrencyFormatter.format(goal.targetAmount)}',
                    style: AppTypography.micro(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddSavingsDialog(BuildContext context, FinancialGoalModel goal) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Savings to ${goal.name}', style: AppTypography.h2(color: AppColors.textPrimary)),
        content: JarvisInput(
          hintText: '₹ Amount to add',
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final amt = double.tryParse(controller.text.trim());
              if (amt != null && amt > 0) {
                onAddAmount(goal.id, amt);
                Navigator.pop(context);
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _DebtCard extends ConsumerWidget {
  final DebtModel debt;
  final Function(String paymentId) onCollectEMI;

  const _DebtCard({required this.debt, required this.onCollectEMI});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextPayment = debt.payments.firstWhere(
      (p) => p.status != 'paid',
      orElse: () => DebtPaymentModel(id: '', date: DateTime(2000), amount: 0.0, status: 'paid'),
    );

    final showAction = nextPayment.id.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: JarvisCard(
        padding: 16.0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  decoration: BoxDecoration(
                    color: debt.type == 'owedToMe' ? AppColors.primaryLight : AppColors.border.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    debt.type == 'owedToMe' ? '📈' : '📉',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${debt.person} — ${debt.category}',
                        style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        debt.frequency == 'monthly'
                            ? 'Total: ${CurrencyFormatter.format(debt.amount)} • ${CurrencyFormatter.format(debt.payments.isNotEmpty ? debt.payments.first.amount : 0.0)}/mo'
                            : 'Total: ${CurrencyFormatter.format(debt.amount)}',
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showAction) ...[
              const SizedBox(height: 16.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Next Due: ${DateHelpers.formatDate(nextPayment.date)}',
                          style: AppTypography.caption(color: AppColors.textPrimary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Amount: ${CurrencyFormatter.format(nextPayment.amount)}',
                          style: AppTypography.caption(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  JarvisButton(
                    text: debt.type == 'owedToMe' ? 'Collected?' : 'Paid?',
                    onPressed: () => onCollectEMI(nextPayment.id),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12.0),
              Text(
                '✅ All EMIs for this loan are fully settled!',
                style: AppTypography.caption(color: AppColors.success).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 12.0),
            const Divider(color: AppColors.border, height: 1.0),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: AppColors.primary, size: 20.0),
                  tooltip: 'View Installments',
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _DebtDetailsSheet(debt: debt),
                    );
                  },
                ),
                const SizedBox(width: 8.0),
                if (showAction) ...[
                  IconButton(
                    icon: const Icon(Icons.add_task_rounded, color: AppColors.secondary, size: 20.0),
                    tooltip: 'Add to Priorities',
                    onPressed: () async {
                      final task = TaskModel(
                        id: IdGenerator.generate(),
                        title: 'Settle EMI: ${debt.person} — ${debt.category}',
                        description: 'EMI payment: ${CurrencyFormatter.format(nextPayment.amount)} due on ${DateHelpers.formatDate(nextPayment.date)}',
                        priority: 2, // Medium priority
                        completed: false,
                        emoji: '🤝',
                        createdAt: DateTime.now(),
                      );
                      await ref.read(taskProvider.notifier).addTask(task);
                      if (context.mounted) {
                        ToastNotification.show(context, 'Added to priorities checklist!');
                      }
                    },
                  ),
                  const SizedBox(width: 8.0),
                  TextButton.icon(
                    icon: const Icon(Icons.handshake_rounded, size: 16.0),
                    label: const Text('Settle All', style: TextStyle(fontSize: 12.0, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.success,
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    ),
                    onPressed: () async {
                      final updatedPayments = debt.payments.map((p) => p.copyWith(status: 'paid', paidAt: () => DateTime.now())).toList();
                      final updatedDebt = debt.copyWith(payments: updatedPayments);
                      await ref.read(debtProvider.notifier).updateDebt(updatedDebt);
                      
                      double remainingAmount = 0.0;
                      for (final p in debt.payments) {
                        if (p.status != 'paid') {
                          remainingAmount += p.amount;
                        }
                      }
                      if (remainingAmount > 0) {
                        final tx = TransactionModel(
                          id: IdGenerator.generate(),
                          type: debt.type == 'owedToMe' ? 'income' : 'expense',
                          amount: remainingAmount,
                          category: debt.type == 'owedToMe' ? 'Owed to Me (Receipt)' : 'I Owe (Payment)',
                          description: 'Full Settlement: ${debt.person} — ${debt.category}',
                          emoji: debt.type == 'owedToMe' ? '📈' : '📉',
                          date: DateTime.now(),
                          createdAt: DateTime.now(),
                        );
                        await ref.read(transactionProvider.notifier).addTransaction(tx);
                      }

                      if (context.mounted) {
                        ToastNotification.show(context, 'Agreement fully settled!');
                      }
                    },
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  final List<TransactionModel> txs;

  const _RecentTransactionsList({required this.txs});

  @override
  Widget build(BuildContext context) {
    if (txs.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Text(
          'No transaction logs saved.',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
      );
    }

    return Column(
      children: txs.take(6).map((tx) {
        final isIncome = tx.type == 'income';
        final color = isIncome ? AppColors.success : AppColors.error;
        final sign = isIncome ? '+' : '-';

        return Container(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: JarvisCard(
            padding: 12.0,
            child: Row(
              children: [
                Text(tx.emoji, style: const TextStyle(fontSize: 22.0)),
                const SizedBox(width: 14.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tx.description ?? tx.category,
                        style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        '${tx.category} • ${DateHelpers.formatDate(tx.date)}',
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8.0),
                Text(
                  '$sign${CurrencyFormatter.format(tx.amount)}',
                  style: AppTypography.bodyMedium(color: color).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _AddGoalSheet extends ConsumerStatefulWidget {
  const _AddGoalSheet();

  @override
  ConsumerState<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends ConsumerState<_AddGoalSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();
  String _emoji = '🎯';

  final List<String> _emojis = ['🎯', '🚨', '💻', '🚗', '🏠', '✈️', '🎁', '🎓'];

  void _save() async {
    final name = _nameController.text.trim();
    final target = double.tryParse(_targetController.text.trim());
    if (name.isEmpty || target == null || target <= 0) return;

    final goal = FinancialGoalModel(
      id: IdGenerator.generate(),
      name: name,
      icon: _emoji,
      targetAmount: target,
      currentAmount: 0.0,
      createdAt: DateTime.now(),
    );

    await ref.read(goalProvider.notifier).addGoal(goal);

    if (mounted) {
      Navigator.pop(context);
      ToastNotification.show(context, 'Savings goal created: $name');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
            ),
          ),
          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: bottom + 32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Create Savings Goal', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),
                SizedBox(
                  height: 48.0,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _emojis.length,
                    itemBuilder: (context, index) {
                      final em = _emojis[index];
                      final isSelected = _emoji == em;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = em),
                        child: Container(
                          width: 44.0,
                          height: 44.0,
                          margin: const EdgeInsets.only(right: 8.0),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : AppColors.border.withOpacity(0.2),
                            borderRadius: AppSpacing.buttonRadius,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(em, style: const TextStyle(fontSize: 22.0)),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20.0),
                JarvisInput(
                  hintText: 'Goal Name (e.g. Vacation fund)',
                  controller: _nameController,
                  autofocus: true,
                ),
                const SizedBox(height: 16.0),
                JarvisInput(
                  hintText: 'Target Amount (₹)',
                  controller: _targetController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 32.0),
                JarvisButton(
                  text: 'Create Goal',
                  isFullWidth: true,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GoalDetailsSheet extends ConsumerStatefulWidget {
  final FinancialGoalModel goal;
  const _GoalDetailsSheet({required this.goal});

  @override
  ConsumerState<_GoalDetailsSheet> createState() => _GoalDetailsSheetState();
}

class _GoalDetailsSheetState extends ConsumerState<_GoalDetailsSheet> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _addSavings(double targetGoalAmount) async {
    final amountText = _amountController.text.trim();
    final noteText = _noteController.text.trim();
    final amount = double.tryParse(amountText);
    
    if (amount == null || amount <= 0) {
      ToastNotification.show(context, 'Please enter a valid amount', type: 'error');
      return;
    }

    // 1. Update the Goal amount
    final updatedGoal = widget.goal.copyWith(
      currentAmount: widget.goal.currentAmount + amount,
    );
    await ref.read(goalProvider.notifier).updateGoal(updatedGoal);

    // 2. Log transaction history
    final tx = TransactionModel(
      id: IdGenerator.generate(),
      type: 'expense', // savings are recorded as outflow from liquidity
      amount: amount,
      category: 'Savings Goal (${widget.goal.name})',
      description: 'Goal: ${widget.goal.name}${noteText.isEmpty ? "" : " — " + noteText}',
      emoji: widget.goal.icon,
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    await ref.read(transactionProvider.notifier).addTransaction(tx);

    // 3. Clear inputs & show toast
    _amountController.clear();
    _noteController.clear();
    
    ref.invalidate(monthlyExpensesProvider);
    ref.invalidate(todaySpentProvider);
    ref.invalidate(recentTransactionsProvider);

    if (mounted) {
      ToastNotification.show(context, 'Added ₹$amount to ${widget.goal.name}!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final transactions = ref.watch(transactionProvider).value ?? [];
    final savingsPlans = ref.watch(savingsPlanProvider).value ?? [];

    // Filter transactions logged for this goal
    final goalHistory = transactions.where((tx) =>
      tx.category == 'Savings Goal (${widget.goal.name})' ||
      (tx.description != null && tx.description!.contains('Goal: ${widget.goal.name}'))
    ).toList();

    // Calculate Linked Amount
    final linkedPlans = savingsPlans.where((p) => p.linkedGoalId == widget.goal.id).toList();
    double totalLinkedContribution = 0.0;
    for (final plan in linkedPlans) {
      totalLinkedContribution += plan.monthlyAmount * plan.paidMonths.length;
    }

    final progress = widget.goal.progress;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20.0, sigmaY: 20.0),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.92),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32.0)),
            border: Border(
              top: BorderSide(
                color: Colors.white.withOpacity(0.08),
                width: 1.0,
              ),
            ),
          ),
          padding: EdgeInsets.only(left: 24.0, right: 24.0, top: 24.0, bottom: bottom + 32.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Details
                Row(
                  children: [
                    Text(widget.goal.icon, style: const TextStyle(fontSize: 32.0)),
                    const SizedBox(width: 16.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.goal.name, style: AppTypography.h2(color: AppColors.textPrimary)),
                          Text(
                            'Target: ${CurrencyFormatter.format(widget.goal.targetAmount)}',
                            style: AppTypography.caption(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Progress Card
                JarvisCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${(progress * 100).toInt()}% Achieved',
                            style: AppTypography.bodyMedium(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${CurrencyFormatter.format(widget.goal.currentAmount)} saved',
                            style: AppTypography.caption(color: AppColors.textPrimary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10.0),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.0),
                        child: LinearProgressIndicator(
                          value: progress,
                          color: AppColors.primary,
                          backgroundColor: AppColors.border,
                          minHeight: 8.0,
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Direct Manual', style: AppTypography.micro(color: AppColors.textSecondary)),
                                Text(
                                  CurrencyFormatter.format((widget.goal.currentAmount - totalLinkedContribution).clamp(0.0, double.infinity)),
                                  style: AppTypography.caption(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Linked Savings Plans', style: AppTypography.micro(color: AppColors.textSecondary)),
                                Text(
                                  CurrencyFormatter.format(totalLinkedContribution),
                                  style: AppTypography.caption(color: AppColors.secondary).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                // Add Savings Form
                Text('ADD SAVINGS CONTRIBUTION', style: AppTypography.micro(color: AppColors.textSecondary).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8.0),
                JarvisInput(
                  hintText: 'Amount (₹)',
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10.0),
                JarvisInput(
                  hintText: 'Note (e.g. Birthday gift, monthly bonus) - Optional',
                  controller: _noteController,
                ),
                const SizedBox(height: 12.0),
                JarvisButton(
                  text: 'Add to Goal',
                  isFullWidth: true,
                  onPressed: () => _addSavings(widget.goal.targetAmount),
                ),
                const SizedBox(height: 24.0),

                // History Section
                Text('CONTRIBUTION HISTORY', style: AppTypography.micro(color: AppColors.textSecondary).copyWith(letterSpacing: 1.2, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10.0),
                if (goalHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(
                      child: Text(
                        'No direct contributions recorded.',
                        style: AppTypography.caption(color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  Column(
                    children: goalHistory.map((tx) {
                      // Extract note if present in description: "Goal: Name — Note"
                      String note = '';
                      if (tx.description != null && tx.description!.contains(' — ')) {
                        note = tx.description!.split(' — ')[1];
                      }

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8.0),
                        padding: const EdgeInsets.all(12.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHover,
                          borderRadius: BorderRadius.circular(16.0),
                          border: Border.all(color: Colors.white.withOpacity(0.03)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    note.isNotEmpty ? note : 'Direct Contribution',
                                    style: AppTypography.caption(color: AppColors.textPrimary).copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2.0),
                                  Text(
                                    DateHelpers.formatDate(tx.date),
                                    style: AppTypography.micro(color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '+${CurrencyFormatter.format(tx.amount)}',
                              style: AppTypography.caption(color: AppColors.success).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
