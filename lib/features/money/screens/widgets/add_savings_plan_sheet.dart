import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/features/money/data/models/savings_plan_model.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class AddSavingsPlanSheet extends ConsumerStatefulWidget {
  const AddSavingsPlanSheet({super.key});

  @override
  ConsumerState<AddSavingsPlanSheet> createState() => _AddSavingsPlanSheetState();
}

class _AddSavingsPlanSheetState extends ConsumerState<AddSavingsPlanSheet> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _durationController = TextEditingController(text: '30');
  
  bool _hasDurationLimit = true;
  String? _selectedGoalId;

  void _save() async {
    final name = _nameController.text.trim();
    final amount = double.tryParse(_amountController.text.trim());
    if (name.isEmpty || amount == null || amount <= 0) return;

    int? durationMonths;
    if (_hasDurationLimit) {
      durationMonths = int.tryParse(_durationController.text.trim());
      if (durationMonths != null && durationMonths <= 0) durationMonths = null;
    }

    final plan = SavingsPlanModel(
      id: IdGenerator.generate(),
      name: name,
      monthlyAmount: amount,
      durationMonths: durationMonths,
      linkedGoalId: _selectedGoalId,
      paidMonths: const [],
      skippedMonths: const [],
      createdAt: DateTime.now(),
      isActive: true,
    );

    await ref.read(savingsPlanProvider.notifier).addSavingsPlan(plan);

    if (mounted) {
      Navigator.pop(context);
      ToastNotification.show(context, 'Savings Plan "$name" created successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    final goalsAsync = ref.watch(goalProvider);
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
                Text('Start Savings Plan', style: AppTypography.h2(color: AppColors.textPrimary)),
                const SizedBox(height: 20.0),

                Row(
                  children: [
                    Expanded(
                      child: JarvisButton(
                        text: 'Fixed Months',
                        isOutline: !_hasDurationLimit,
                        onPressed: () => setState(() => _hasDurationLimit = true),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: JarvisButton(
                        text: 'Unlimited SIP',
                        isOutline: _hasDurationLimit,
                        onPressed: () => setState(() => _hasDurationLimit = false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                JarvisInput(
                  hintText: 'Plan Name (e.g. Goal SIP)',
                  controller: _nameController,
                  autofocus: true,
                ),
                const SizedBox(height: 16.0),

                JarvisInput(
                  hintText: 'Monthly Contribution (₹)',
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 16.0),

                if (_hasDurationLimit) ...[
                  JarvisInput(
                    hintText: 'Duration (months, e.g. 30)',
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16.0),
                ],

                // Goal Selector Dropdown
                Text(
                  'Link to Financial Goal (Optional)',
                  style: AppTypography.caption(color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8.0),
                goalsAsync.when(
                  data: (goals) {
                    if (goals.isEmpty) {
                      return Text(
                        'No savings goals created yet. Create a goal first to link it.',
                        style: AppTypography.caption(color: AppColors.textTertiary),
                      );
                    }
                    return Container(
                      height: 52.0,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        border: Border.all(color: AppColors.border),
                        borderRadius: AppSpacing.inputRadius,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGoalId,
                          hint: Text('Select Goal', style: AppTypography.body(color: AppColors.textTertiary)),
                          isExpanded: true,
                          dropdownColor: AppColors.surface,
                          onChanged: (val) {
                            setState(() => _selectedGoalId = val);
                          },
                          items: [
                            DropdownMenuItem<String>(
                              value: null,
                              child: Text('Do Not Link', style: AppTypography.body(color: AppColors.textPrimary)),
                            ),
                            ...goals.map((g) {
                              return DropdownMenuItem<String>(
                                value: g.id,
                                child: Text('${g.icon} ${g.name}', style: AppTypography.body(color: AppColors.textPrimary)),
                              );
                            })
                          ],
                        ),
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 32.0),

                JarvisButton(
                  text: 'Create Plan',
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
