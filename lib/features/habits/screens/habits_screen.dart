import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/features/habits/data/models/habit_model.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';
import 'package:jarvis/shared/widgets/jarvis_input.dart';
import 'package:jarvis/shared/widgets/empty_state.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class HabitsScreen extends ConsumerWidget {
  const HabitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        top: false,
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(habitProvider);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // 1. Header
              SliverPadding(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 20.0,
                  left: 20.0,
                  right: 20.0,
                  bottom: 12.0,
                ),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habit Tracker',
                        style: AppTypography.h1(color: AppColors.textPrimary).copyWith(
                          fontSize: 26.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2.0),
                      Text(
                        'Small daily victories lead to massive changes.',
                        style: AppTypography.caption(color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. Dynamic Streak Dashboard & Insights
              habitsAsync.when(
                data: (habits) {
                  if (habits.isEmpty) return const SliverToBoxAdapter(child: SizedBox.shrink());

                  // Calculate aggregate stats
                  final notifier = ref.read(habitProvider.notifier);
                  int totalStreak = 0;
                  for (final h in habits) {
                    final str = notifier.getCurrentStreak(h);
                    if (str > totalStreak) totalStreak = str;
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Aggregated Fire Streak Card
                        _StreakCard(totalStreak: totalStreak),
                        const SizedBox(height: 16.0),

                        // Jarvis Insight Box
                        const _HabitInsightBox(),
                        const SizedBox(height: 24.0),
                      ]),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(child: SizedBox.shrink()),
                error: (_, __) => const SliverToBoxAdapter(child: SizedBox.shrink()),
              ),

              // 3. Habits Checklist
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                sliver: habitsAsync.when(
                  data: (habits) {
                    if (habits.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48.0),
                            EmptyState(
                              emoji: '🔄',
                              title: 'No habits tracked yet',
                              subtitle: 'Start small. Tapping below lets Jarvis guide your atomic habits.',
                              actionLabel: 'Create Habit',
                              onActionPressed: () => _showAddHabitSheet(context),
                            ),
                          ],
                        ),
                      );
                    }

                    return SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final habit = habits[index];
                          final notifier = ref.read(habitProvider.notifier);
                          final isCompletedToday = notifier.isCompletedToday(habit);
                          final currentStreak = notifier.getCurrentStreak(habit);

                          return _HabitCard(
                            habit: habit,
                            isCompletedToday: isCompletedToday,
                            currentStreak: currentStreak,
                            onToggleComplete: () async {
                              await notifier.toggleCompletion(habit.id, DateTime.now());
                              if (context.mounted && !isCompletedToday) {
                                ToastNotification.show(
                                  context,
                                  'Atomic victory! Streak increased! 🚀',
                                );
                              }
                            },
                            onDelete: () async {
                              await notifier.deleteHabit(habit.id);
                              if (context.mounted) {
                                ToastNotification.show(context, 'Habit removed successfully.');
                              }
                            },
                          );
                        },
                        childCount: habits.length,
                      ),
                    );
                  },
                  loading: () => const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => SliverFillRemaining(
                    child: Center(child: Text('Error loading habits: $err')),
                  ),
                ),
              ),

              // Bottom Buffer
              const SliverToBoxAdapter(
                child: SizedBox(height: 180.0),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 96.0, right: 8.0),
        child: FloatingActionButton(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 4.0,
          shape: const CircleBorder(),
          onPressed: () => _showAddHabitSheet(context),
          child: const Icon(Icons.add_rounded, size: 28.0),
        ),
      ),
    );
  }

  void _showAddHabitSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddHabitSheet(),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final int totalStreak;

  const _StreakCard({required this.totalStreak});

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      color: AppColors.primaryLight.withOpacity(0.5),
      child: Row(
        children: [
          // Pulse Fire
          Container(
            padding: const EdgeInsets.all(12.0),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Text(
              '🔥',
              style: TextStyle(fontSize: 28.0),
            ),
          )
          .animate(onPlay: (controller) => controller.repeat(reverse: true))
          .scaleXY(begin: 1.0, end: 1.08, duration: 1.seconds, curve: Curves.easeInOut),

          const SizedBox(width: 16.0),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Best Vibe Streak',
                  style: AppTypography.caption(color: AppColors.primaryDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  totalStreak > 0 ? '$totalStreak Days Strong' : 'Starting Fresh Today',
                  style: AppTypography.h2(color: AppColors.textPrimary).copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitInsightBox extends StatelessWidget {
  const _HabitInsightBox();

  @override
  Widget build(BuildContext context) {
    return JarvisCard(
      color: AppColors.secondaryLight.withOpacity(0.5),
      padding: 16.0,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🧠', style: TextStyle(fontSize: 20.0)),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Jarvis Insight',
                  style: AppTypography.caption(color: AppColors.primaryDark).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2.0),
                Text(
                  'You tend to complete "Morning Workout" 40% more often on weekdays compared to weekends. Suggest snoozing weekend notifications?',
                  style: AppTypography.caption(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HabitCard extends StatelessWidget {
  final HabitModel habit;
  final bool isCompletedToday;
  final int currentStreak;
  final VoidCallback onToggleComplete;
  final VoidCallback onDelete;

  const _HabitCard({
    required this.habit,
    required this.isCompletedToday,
    required this.currentStreak,
    required this.onToggleComplete,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
      child: Dismissible(
        key: Key(habit.id),
        direction: DismissDirection.endToStart,
        background: Container(
          padding: const EdgeInsets.only(right: 20.0),
          alignment: Alignment.centerRight,
          decoration: BoxDecoration(
            color: AppColors.errorLight,
            borderRadius: AppSpacing.cardRadius,
          ),
          child: const Icon(
            Icons.delete_forever_rounded,
            color: AppColors.error,
            size: 28.0,
          ),
        ),
        onDismissed: (_) => onDelete(),
        child: JarvisCard(
          padding: 16.0,
          child: Column(
            children: [
              Row(
                children: [
                  // Emoji Icon
                  Container(
                    width: 44.0,
                    height: 44.0,
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      habit.icon,
                      style: const TextStyle(fontSize: 22.0),
                    ),
                  ),
                  const SizedBox(width: 14.0),

                  // Habit Title
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          habit.name,
                          style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2.0),
                        Row(
                          children: [
                            Text(
                              '🔥 $currentStreak Day Streak',
                              style: AppTypography.caption(color: AppColors.primary).copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8.0),
                            Text(
                              '• ${habit.frequency}',
                              style: AppTypography.caption(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8.0),

                  // Completion Check Bubble
                  GestureDetector(
                    onTap: onToggleComplete,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      width: 32.0,
                      height: 32.0,
                      decoration: BoxDecoration(
                        color: isCompletedToday ? AppColors.success : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompletedToday ? AppColors.success : AppColors.border,
                          width: 2.0,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: isCompletedToday
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 18.0,
                            )
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Weekly Dot Grid
              _WeeklyDotGrid(completions: habit.completions, startDate: habit.startDate),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyDotGrid extends StatelessWidget {
  final List<String> completions;
  final DateTime startDate;

  const _WeeklyDotGrid({required this.completions, required this.startDate});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final weekDays = DateHelpers.daysInWeek(today);
    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(7, (index) {
        final day = weekDays[index];
        final dayStr = DateHelpers.dateKey(day);
        final isCompleted = completions.contains(dayStr);
        final isFuture = day.isAfter(today);
        final isToday = DateHelpers.isToday(day);
        final isBeforeStart = day.isBefore(startDate);

        Color dotColor;
        Border? border;

        if (isFuture || isBeforeStart) {
          dotColor = Colors.transparent;
          border = Border.all(color: AppColors.border.withOpacity(0.5), width: 1.0);
        } else if (isCompleted) {
          dotColor = AppColors.success;
        } else {
          dotColor = Colors.transparent;
          border = Border.all(
            color: isToday ? AppColors.primary : AppColors.border,
            width: isToday ? 2.0 : 1.0,
          );
        }

        return Column(
          children: [
            Text(
              dayLabels[index],
              style: AppTypography.micro(
                color: isToday ? AppColors.primary : AppColors.textTertiary,
              ).copyWith(
                fontWeight: isToday ? FontWeight.w800 : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 6.0),
            Container(
              width: 24.0,
              height: 24.0,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                border: border,
              ),
              alignment: Alignment.center,
              child: isCompleted
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 12.0)
                  : null,
            ),
          ],
        );
      }),
    );
  }
}

class _AddHabitSheet extends ConsumerStatefulWidget {
  const _AddHabitSheet();

  @override
  ConsumerState<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends ConsumerState<_AddHabitSheet> {
  final TextEditingController _nameController = TextEditingController();
  String _emoji = '🔄';
  String _frequency = 'daily';
  final int _target = 1;
  String? _reminderTime = '07:30';

  final List<String> _emojis = ['🔄', '🏋️', '🧘', '📚', '💧', '🥗', '🚶', '😴', '🧠', '✏️'];

  void _saveHabit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final habit = HabitModel(
      id: IdGenerator.generate(),
      name: name,
      icon: _emoji,
      frequency: _frequency,
      target: _target,
      reminderTime: _reminderTime,
      startDate: DateTime.now(),
      completions: [],
    );

    await ref.read(habitProvider.notifier).addHabit(habit);

    if (mounted) {
      Navigator.pop(context);
      ToastNotification.show(context, 'Habit added: $name');
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.0),
          topRight: Radius.circular(32.0),
        ),
      ),
      padding: EdgeInsets.only(
        left: 24.0,
        right: 24.0,
        top: 24.0,
        bottom: bottomInset + 32.0,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start New Habit',
                  style: AppTypography.h2(color: AppColors.textPrimary),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(4.0),
                    decoration: BoxDecoration(
                      color: AppColors.border.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded, size: 20.0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24.0),

            // Emoji Picker
            Text(
              'Select Icon',
              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
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
                        color: isSelected ? AppColors.successLight : AppColors.border.withOpacity(0.2),
                        borderRadius: AppSpacing.buttonRadius,
                        border: Border.all(
                          color: isSelected ? AppColors.success : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        em,
                        style: const TextStyle(fontSize: 22.0),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20.0),

            // Habit Name
            JarvisInput(
              hintText: 'E.g., Drink 3L Water',
              controller: _nameController,
              autofocus: true,
              label: 'Habit Name',
            ),
            const SizedBox(height: 20.0),

            // Frequency Selection
            Text(
              'Frequency',
              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                _buildFreqChip('daily', 'Everyday'),
                const SizedBox(width: 8.0),
                _buildFreqChip('weekdays', 'Weekdays'),
                const SizedBox(width: 8.0),
                _buildFreqChip('custom', 'Custom'),
              ],
            ),
            const SizedBox(height: 24.0),

            // Reminder Time Picker Row
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.notifications_active_rounded, color: AppColors.success),
              title: Text(
                _reminderTime == null ? 'Set Daily Reminder' : 'Remind at ${DateHelpers.formatTime(_reminderTime!)}',
                style: AppTypography.body(color: AppColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final selected = await showTimePicker(
                  context: context,
                  initialTime: const TimeOfDay(hour: 7, minute: 30),
                );
                if (selected != null) {
                  setState(() {
                    _reminderTime = '${selected.hour.toString().padLeft(2, '0')}:${selected.minute.toString().padLeft(2, '0')}';
                  });
                }
              },
            ),
            const SizedBox(height: 32.0),

            // Save Button
            JarvisButton(
              text: 'Save Habit',
              isFullWidth: true,
              onPressed: _saveHabit,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFreqChip(String freq, String label) {
    final isSelected = _frequency == freq;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _frequency = freq;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.success : Colors.white,
            borderRadius: AppSpacing.buttonRadius,
            border: Border.all(
              color: isSelected ? AppColors.success : AppColors.border,
              width: 1.0,
            ),
          ),
          child: Text(
            label,
            style: AppTypography.caption(
              color: isSelected ? Colors.white : AppColors.textPrimary,
            ).copyWith(
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
