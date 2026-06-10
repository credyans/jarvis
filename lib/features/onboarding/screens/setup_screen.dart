import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/features/auth/data/models/user_model.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/data/seed_data.dart';
import 'package:jarvis/shared/widgets/gradient_background.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/jarvis_chip.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  int _currentStep = 1;
  final int _totalSteps = 4;

  // Form State
  final TextEditingController _nameController = TextEditingController(text: 'Santhosh');
  final List<String> _selectedFocusAreas = [];
  String _selectedWakeTime = '07:00 AM';

  final List<Map<String, String>> _focusAreasData = [
    {'id': 'tasks', 'name': 'Tasks', 'emoji': '✅'},
    {'id': 'habits', 'name': 'Habits', 'emoji': '🔄'},
    {'id': 'money', 'name': 'Money', 'emoji': '💰'},
    {'id': 'journaling', 'name': 'Journaling', 'emoji': '📝'},
  ];

  final List<String> _wakeTimes = [
    '05:00 AM',
    '06:00 AM',
    '07:00 AM',
    '08:00 AM',
    '09:00 AM',
    '10:00 AM',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _prevStep() {
    if (_currentStep > 1) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _completeSetup() async {
    print('[_completeSetup] Button tapped! Starting setup...');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Initializing setup and seeding database...'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    try {
      final currentUser = ref.read(userProvider).value;
      final currentUid = currentUser?.id ?? await ref.read(authRepositoryProvider).signInAnonymously();
      
      final user = UserModel(
        id: currentUid,
        name: _nameController.text.trim().isEmpty ? (currentUser?.name ?? 'Santhosh') : _nameController.text.trim(),
        joinDate: currentUser?.joinDate ?? DateTime.now(),
        currency: currentUser?.currency ?? '₹',
        onboardingComplete: true,
        wakeTime: _selectedWakeTime,
        focusAreas: _selectedFocusAreas,
      );

      // Save user profile
      await ref.read(userProvider.notifier).saveUser(user);

      // Seed mock data
      await SeedData.seed(currentUid, force: true);

      if (mounted) {
        context.go('/');
      }
    } catch (e, stack) {
      print('[_completeSetup] ONBOARDING ERROR: $e');
      print(stack.toString());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing setup: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Widget _buildStepName() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What should Jarvis call you?',
          style: AppTypography.display(color: AppColors.textPrimary).copyWith(
            fontSize: 26.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'This will customize your greeting and AI recommendations.',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40.0),
        JarvisInput(
          hintText: 'Your name',
          controller: _nameController,
          autofocus: true,
          label: 'Name',
        ),
      ],
    );
  }

  Widget _buildStepFocus() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What matters most to you?',
          style: AppTypography.display(color: AppColors.textPrimary).copyWith(
            fontSize: 26.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'Select the key modules you want Jarvis to prioritize in your personal workspace (multiple select allowed).',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32.0),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 1.2,
          ),
          itemCount: _focusAreasData.length,
          itemBuilder: (context, index) {
            final area = _focusAreasData[index];
            final isSelected = _selectedFocusAreas.contains(area['id']!);

            return GestureDetector(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    _selectedFocusAreas.remove(area['id']!);
                  } else {
                    _selectedFocusAreas.add(area['id']!);
                  }
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : AppColors.surface,
                  borderRadius: AppSpacing.cardRadius,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10.0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      area['emoji']!,
                      style: const TextStyle(fontSize: 32.0),
                    ),
                    const SizedBox(height: 12.0),
                    Text(
                      area['name']!,
                      style: AppTypography.bodyMedium(
                        color: isSelected ? AppColors.background : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStepWakeTime() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'When does your day usually start?',
          style: AppTypography.display(color: AppColors.textPrimary).copyWith(
            fontSize: 26.0,
          ),
        ),
        const SizedBox(height: 12.0),
        Text(
          'Jarvis uses this to organize your timeline and send timely recommendations.',
          style: AppTypography.body(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 32.0),
        Wrap(
          spacing: 12.0,
          runSpacing: 16.0,
          children: _wakeTimes.map((time) {
            final isSelected = _selectedWakeTime == time;
            return JarvisChip(
              label: time,
              isSelected: isSelected,
              emoji: '⏰',
              onTap: () {
                setState(() {
                  _selectedWakeTime = time;
                });
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildStepReady() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 24.0),
        Container(
          width: 90.0,
          height: 90.0,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.successLight,
            border: Border.all(color: AppColors.success.withOpacity(0.3), width: 1.5),
          ),
          child: const Center(
            child: Text(
              '🎉',
              style: TextStyle(fontSize: 48.0),
            ),
          ),
        )
        .animate()
        .scaleXY(begin: 0.5, end: 1.0, duration: 600.ms, curve: Curves.easeOutBack),
        
        const SizedBox(height: 32.0),
        
        Text(
          'All set!',
          style: AppTypography.display(color: AppColors.textPrimary).copyWith(
            fontSize: 28.0,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16.0),
        
        Text(
          'Jarvis is now fully integrated and ready to organize your day, tasks, money, habits, and memories.',
          style: AppTypography.body(color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        )
        .animate()
        .fade(delay: 200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _getStepContent() {
    switch (_currentStep) {
      case 1:
        return _buildStepName();
      case 2:
        return _buildStepFocus();
      case 3:
        return _buildStepWakeTime();
      case 4:
      default:
        return _buildStepReady();
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    
    return Scaffold(
      body: GradientBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Step Progress Indicator
                if (_currentStep < _totalSteps) ...[
                  Row(
                    children: [
                      if (_currentStep > 1)
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20.0),
                          color: AppColors.textPrimary,
                          onPressed: _prevStep,
                        )
                      else
                        const SizedBox(width: 48.0),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4.0),
                          child: LinearProgressIndicator(
                            value: _currentStep / (_totalSteps - 1),
                            color: AppColors.primary,
                            backgroundColor: AppColors.border,
                            minHeight: 6.0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16.0),
                      Text(
                        '$_currentStep of ${_totalSteps - 1}',
                        style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32.0),
                ],

                // Step Page Content
                Expanded(
                  child: SingleChildScrollView(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: Container(
                        key: ValueKey<int>(_currentStep),
                        child: _getStepContent(),
                      ),
                    ),
                  ),
                ),

                // Keyboard Buffer Spacer
                if (!keyboardOpen) const SizedBox(height: 24.0),

                // Next/Submit Button
                if (_currentStep < _totalSteps)
                  JarvisButton(
                    text: 'Continue',
                    isFullWidth: true,
                    onPressed: () {
                      if (_currentStep == 1 && _nameController.text.trim().isEmpty) {
                        return; // enforce name selection
                      }
                      _nextStep();
                    },
                  )
                else
                  JarvisButton(
                    text: "Let's Go",
                    isFullWidth: true,
                    onPressed: _completeSetup,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
