import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/constants/emoji_map.dart';
import 'package:jarvis/features/money/data/models/transaction_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_chip.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final String? initialType;
  const AddTransactionSheet({super.key, this.initialType});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  String _type = 'expense';
  String _category = 'Subscription';

  final List<String> _incomeCategories = ['Salary', 'Freelance', 'Owed to Me (Receipt)', 'Other'];
  final List<String> _expenseCategories = ['I Owe (Payment)', 'Asset EMI', 'Debt EMI', 'Subscription', 'Savings Plan', 'Other'];

  List<String> get _activeCategories => _type == 'income' ? _incomeCategories : _expenseCategories;

  @override
  void initState() {
    super.initState();
    if (widget.initialType != null) {
      _type = widget.initialType!;
    }
    _category = _activeCategories.first;
  }

  void _save() async {
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return;

    final tx = TransactionModel(
      id: IdGenerator.generate(),
      type: _type,
      amount: amount,
      category: _category,
      description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
      emoji: EmojiMap.getEmoji(_category),
      date: DateTime.now(),
      createdAt: DateTime.now(),
    );

    await ref.read(transactionProvider.notifier).addTransaction(tx);
    ref.invalidate(monthlyExpensesProvider);
    ref.invalidate(monthlyIncomeProvider);
    ref.invalidate(todaySpentProvider);
    ref.invalidate(recentTransactionsProvider);

    if (mounted) {
      Navigator.pop(context);
      ToastNotification.show(context, 'Transaction recorded!');
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
                Text('Record Transaction', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),

                Row(
                  children: [
                    Expanded(
                      child: JarvisButton(
                        text: 'Expense',
                        isOutline: _type != 'expense',
                        onPressed: () {
                          setState(() {
                            _type = 'expense';
                            _category = _expenseCategories.first;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: JarvisButton(
                        text: 'Income',
                        isOutline: _type != 'income',
                        onPressed: () {
                          setState(() {
                            _type = 'income';
                            _category = _incomeCategories.first;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                JarvisInput(
                  hintText: 'Amount (₹)',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  autofocus: true,
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'Description (optional)',
                  controller: _descController,
                ),
                const SizedBox(height: 20.0),

                Text('Category', style: AppTypography.caption(color: AppColors.textSecondary)),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _activeCategories.map((c) {
                    final isSelected = _category == c;
                    return JarvisChip(
                      label: c,
                      isSelected: isSelected,
                      emoji: EmojiMap.getEmoji(c),
                      onTap: () => setState(() => _category = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32.0),

                JarvisButton(
                  text: 'Save Record',
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
