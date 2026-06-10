import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/features/money/data/models/bill_reminder_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_chip.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class AddBillReminderSheet extends ConsumerStatefulWidget {
  const AddBillReminderSheet({super.key});

  @override
  ConsumerState<AddBillReminderSheet> createState() => _AddBillReminderSheetState();
}

class _AddBillReminderSheetState extends ConsumerState<AddBillReminderSheet> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dueDayController = TextEditingController(text: '5');
  
  bool _isRecurring = true;
  String _category = 'Subscription';
  DateTime? _selectedDate;

  final List<String> _categories = [
    'House Rent',
    'Food Mess',
    'Credit Card Bill',
    'Subscription',
    'Utilities',
    'Other'
  ];

  void _save() async {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (title.isEmpty || amount == null || amount <= 0) return;

    int dueDay = 1;
    if (_isRecurring) {
      dueDay = int.tryParse(_dueDayController.text.trim()) ?? 1;
      if (dueDay < 1 || dueDay > 31) dueDay = 1;
    }

    final reminder = BillReminderModel(
      id: IdGenerator.generate(),
      title: title,
      amount: amount,
      dueDay: dueDay,
      dueDate: _isRecurring ? null : (_selectedDate ?? DateTime.now().add(const Duration(days: 30))),
      category: _category,
      isRecurring: _isRecurring,
      isPaid: false,
      createdAt: DateTime.now(),
    );

    await ref.read(billReminderProvider.notifier).addBillReminder(reminder);

    if (mounted) {
      Navigator.pop(context);
      ToastNotification.show(context, 'Bill Reminder added: $title');
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 30)),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
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
                Text('Add Bill Reminder', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),

                Row(
                  children: [
                    Expanded(
                      child: JarvisButton(
                        text: 'Monthly Bill',
                        isOutline: !_isRecurring,
                        onPressed: () => setState(() => _isRecurring = true),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: JarvisButton(
                        text: 'One-Time Bill',
                        isOutline: _isRecurring,
                        onPressed: () => setState(() => _isRecurring = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                JarvisInput(
                  hintText: 'Bill Title (e.g. House Rent)',
                  controller: _titleController,
                  autofocus: true,
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'Amount (₹)',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16.0),

                if (_isRecurring)
                  JarvisInput(
                    hintText: 'Due Day of Month (1 - 31)',
                    controller: _dueDayController,
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
                            _selectedDate == null
                                ? 'Select Payment Due Date'
                                : 'Due Date: ${DateHelpers.formatDate(_selectedDate!)}',
                            style: AppTypography.body(
                              color: _selectedDate == null ? AppColors.textTertiary : AppColors.textPrimary,
                            ),
                          ),
                          const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 20.0),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 20.0),

                Text('Category', style: AppTypography.caption(color: AppColors.textSecondary)),
                const SizedBox(height: 8.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: _categories.map((c) {
                    final isSelected = _category == c;
                    return JarvisChip(
                      label: c,
                      isSelected: isSelected,
                      emoji: c == 'House Rent'
                          ? '🏠'
                          : c == 'Food Mess'
                              ? '🍲'
                              : c == 'Credit Card Bill'
                                  ? '💳'
                                  : c == 'Subscription'
                                      ? '🧾'
                                      : c == 'Utilities'
                                          ? '🔌'
                                          : '➕',
                      onTap: () => setState(() => _category = c),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 32.0),

                JarvisButton(
                  text: 'Save Bill Reminder',
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
