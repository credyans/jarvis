import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/data/providers/navigation_provider.dart';
import 'package:jarvis/data/repositories/mood_repository.dart';
import 'package:jarvis/features/today/widgets/mood_checkin_dialog.dart';

class DailySummaryCard extends ConsumerWidget {
  const DailySummaryCard({super.key});

  Widget _buildGridItem({
    required IconData icon,
    required String label,
    required String value,
    required Color iconColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: iconColor,
              size: 22.0,
            ),
            const SizedBox(height: 8.0),
            Text(
              label.toUpperCase(),
              style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                fontWeight: FontWeight.w800,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(todayTasksProvider);
    final habitsAsync = ref.watch(habitProvider);
    final moodAsync = ref.watch(todayMoodProvider);

    // Dynamic data computations
    final tasksVal = tasksAsync.when(
      data: (tasks) => '${tasks.length}',
      loading: () => '—',
      error: (_, __) => '—',
    );

    final habitsVal = habitsAsync.when(
      data: (habits) {
        final today = DateTime.now();
        final activeToday = habits.where((h) {
          if (h.frequency == 'daily') return true;
          if (h.frequency == 'weekdays') return today.weekday >= 1 && today.weekday <= 5;
          return true;
        }).length;
        final completed = habits.where((h) => ref.read(habitProvider.notifier).isCompletedToday(h)).length;
        return '$completed/$activeToday';
      },
      loading: () => '—',
      error: (_, __) => '—',
    );

    final moodVal = moodAsync.when(
      data: (mood) => mood != null
          ? '${MoodRepository.moodEmoji(mood.mood)} ${MoodRepository.moodLabel(mood.mood)}'
          : 'Tap to Log',
      loading: () => '—',
      error: (_, __) => '—',
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;

        if (isNarrow) {
          // 2x2 Grid with clean dividers
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1.0,
              ),
            ),
            child: Table(
              border: TableBorder(
                horizontalInside: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
                verticalInside: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
              ),
              children: [
                TableRow(
                  children: [
                    _buildGridItem(
                      icon: Icons.task_alt_rounded,
                      label: 'Tasks',
                      value: tasksVal,
                      iconColor: AppColors.primary,
                      onTap: () {
                        ref.read(currentTabProvider.notifier).state = 1;
                        ref.read(plannerSubTabProvider.notifier).state = 0;
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.loop_rounded,
                      label: 'Habits',
                      value: habitsVal,
                      iconColor: AppColors.secondary,
                      onTap: () {
                        ref.read(currentTabProvider.notifier).state = 1;
                        ref.read(plannerSubTabProvider.notifier).state = 1;
                      },
                    ),
                  ],
                ),
                TableRow(
                  children: [
                    _buildGridItem(
                      icon: Icons.event_note_rounded,
                      label: 'Upcoming',
                      value: '3',
                      iconColor: AppColors.warningLight,
                      onTap: () {
                        ref.read(currentTabProvider.notifier).state = 1;
                        ref.read(plannerSubTabProvider.notifier).state = 0;
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.mood_rounded,
                      label: 'Mood',
                      value: moodVal,
                      iconColor: AppColors.primary,
                      onTap: () {
                        MoodCheckinDialog.show(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        } else {
          // Horizontal Row of 4 columns divided by lines
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.01),
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.05),
                width: 1.0,
              ),
            ),
            child: Table(
              border: TableBorder(
                verticalInside: BorderSide(color: Colors.white.withOpacity(0.05), width: 1.0),
              ),
              children: [
                TableRow(
                  children: [
                    _buildGridItem(
                      icon: Icons.task_alt_rounded,
                      label: 'Tasks',
                      value: tasksVal,
                      iconColor: AppColors.primary,
                      onTap: () {
                        ref.read(currentTabProvider.notifier).state = 1;
                        ref.read(plannerSubTabProvider.notifier).state = 0;
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.loop_rounded,
                      label: 'Habits',
                      value: habitsVal,
                      iconColor: AppColors.secondary,
                      onTap: () {
                        ref.read(currentTabProvider.notifier).state = 1;
                        ref.read(plannerSubTabProvider.notifier).state = 1;
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.event_note_rounded,
                      label: 'Upcoming',
                      value: '3',
                      iconColor: AppColors.warningLight,
                      onTap: () {
                        ref.read(currentTabProvider.notifier).state = 1;
                        ref.read(plannerSubTabProvider.notifier).state = 0;
                      },
                    ),
                    _buildGridItem(
                      icon: Icons.mood_rounded,
                      label: 'Mood',
                      value: moodVal,
                      iconColor: AppColors.primary,
                      onTap: () {
                        MoodCheckinDialog.show(context);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
