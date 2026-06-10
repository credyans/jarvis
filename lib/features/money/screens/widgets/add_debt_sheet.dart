import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/money/data/models/debt_model.dart';
import 'package:jarvis/features/money/data/models/debt_payment_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class AddDebtSheet extends ConsumerStatefulWidget {
  const AddDebtSheet({super.key});

  @override
  ConsumerState<AddDebtSheet> createState() => _AddDebtSheetState();
}

class _AddDebtSheetState extends ConsumerState<AddDebtSheet> {
  final TextEditingController _personController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '6');

  String _type = 'owedToMe'; // 'owedToMe' or 'iOwe'
  String _frequency = 'monthly'; // 'monthly' (EMI) or 'one-time'
  DateTime? _selectedRepaymentDate;

  void _save() async {
    final person = _personController.text.trim();
    final category = _categoryController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());

    if (person.isEmpty || category.isEmpty || amount == null || amount <= 0) {
      ToastNotification.show(context, 'Please fill in all fields with valid data', type: 'error');
      return;
    }

    try {
      final today = DateTime.now();
      List<DebtPaymentModel> payments = [];
      DateTime endDate = today;

      if (_frequency == 'one-time') {
        endDate = _selectedRepaymentDate ?? today.add(const Duration(days: 30));
        payments.add(
          DebtPaymentModel(
            id: IdGenerator.generate(),
            date: endDate,
            amount: amount,
            status: 'unpaid',
          ),
        );
      } else {
        final months = int.tryParse(_durationController.text.trim()) ?? 6;
        endDate = today.add(Duration(days: months * 30));
        for (int i = 1; i <= months; i++) {
          payments.add(
            DebtPaymentModel(
              id: IdGenerator.generate(),
              date: today.add(Duration(days: i * 30)),
              amount: amount, // Monthly EMI amount
              status: 'unpaid',
            ),
          );
        }
      }

      final totalAmount = _frequency == 'one-time' ? amount : (amount * payments.length);

      final debt = DebtModel(
        id: IdGenerator.generate(),
        person: person,
        category: category,
        amount: totalAmount, // Store total loan value
        frequency: _frequency,
        startDate: today,
        endDate: endDate,
        type: _type,
        payments: payments,
        createdAt: today,
      );

      await ref.read(debtProvider.notifier).addDebt(debt);

      if (mounted) {
        Navigator.pop(context);
        ToastNotification.show(
          context,
          _frequency == 'one-time' ? 'Loan registered successfully!' : 'EMI Agreement logged!',
        );
      }
    } catch (e) {
      if (mounted) {
        ToastNotification.show(context, 'Failed to log agreement: $e', type: 'error');
      }
    }
  }

  Widget _buildToggleButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required IconData icon,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
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
              const SizedBox(width: 6.0),
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

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedRepaymentDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              onPrimary: AppColors.primaryDark,
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedRepaymentDate) {
      setState(() {
        _selectedRepaymentDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final debts = ref.watch(debtProvider).value ?? [];
    final uniqueNames = debts.map((d) => d.person).toSet().toList();
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
                Text('Add EMI or Debt', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),

                // Owed To Me vs I Owe
                Container(
                  height: 48.0,
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
                      _buildToggleButton(
                        label: 'Owed To Me',
                        isSelected: _type == 'owedToMe',
                        onTap: () => setState(() => _type = 'owedToMe'),
                        icon: Icons.south_west_rounded,
                      ),
                      _buildToggleButton(
                        label: 'I Owe Someone',
                        isSelected: _type == 'iOwe',
                        onTap: () => setState(() => _type = 'iOwe'),
                        icon: Icons.north_east_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),

                // One-Time vs Monthly
                Container(
                  height: 48.0,
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
                      _buildToggleButton(
                        label: 'Monthly EMI',
                        isSelected: _frequency == 'monthly',
                        onTap: () => setState(() => _frequency = 'monthly'),
                        icon: Icons.calendar_month_rounded,
                      ),
                      _buildToggleButton(
                        label: 'One-Time Loan',
                        isSelected: _frequency == 'one-time',
                        onTap: () => setState(() => _frequency = 'one-time'),
                        icon: Icons.payment_rounded,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20.0),

                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return const Iterable<String>.empty();
                    }
                    return uniqueNames.where((String option) {
                      return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
                    });
                  },
                  onSelected: (String selection) {
                    _personController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    if (controller.text.isEmpty && _personController.text.isNotEmpty) {
                      controller.text = _personController.text;
                    }
                    controller.addListener(() {
                      _personController.text = controller.text;
                    });
                    return JarvisInput(
                      hintText: 'Person Name (e.g. Saroo)',
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        color: Colors.transparent,
                        child: Container(
                          width: MediaQuery.of(context).size.width - 48,
                          margin: const EdgeInsets.only(top: 4.0),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16.0),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10.0,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16.0),
                            child: ListView.separated(
                              padding: EdgeInsets.zero,
                              shrinkWrap: true,
                              itemCount: options.length,
                              separatorBuilder: (context, index) => const Divider(color: AppColors.border, height: 1),
                              itemBuilder: (BuildContext context, int index) {
                                final String option = options.elementAt(index);
                                return ListTile(
                                  title: Text(
                                    option,
                                    style: AppTypography.body(color: AppColors.textPrimary),
                                  ),
                                  onTap: () {
                                    onSelected(option);
                                  },
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'Category/Description (e.g. Mobile EMI)',
                  controller: _categoryController,
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: _frequency == 'one-time' ? 'Loan Amount (₹)' : 'Monthly EMI Amount (₹)',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16.0),

                if (_frequency == 'monthly')
                  JarvisInput(
                    hintText: 'Number of Months (e.g. 12)',
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                  )
                else
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceHover,
                        borderRadius: AppSpacing.inputRadius,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedRepaymentDate == null
                                ? 'Repayment Due Date'
                                : 'Repayment Date: ${DateHelpers.formatDate(_selectedRepaymentDate!)}',
                            style: AppTypography.body(
                              color: _selectedRepaymentDate == null ? AppColors.textTertiary : AppColors.textPrimary,
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20.0),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32.0),

                JarvisButton(
                  text: 'Log Agreement',
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
