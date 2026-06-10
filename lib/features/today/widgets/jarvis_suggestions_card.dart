import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/data/providers/navigation_provider.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';

class JarvisSuggestionsCard extends ConsumerWidget {
  const JarvisSuggestionsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskProvider);
    final habitsAsync = ref.watch(habitProvider);
    final moodAsync = ref.watch(todayMoodProvider);
    final goalsAsync = ref.watch(goalProvider);

    if (tasksAsync.isLoading || habitsAsync.isLoading || moodAsync.isLoading || goalsAsync.isLoading) {
      return const SizedBox.shrink();
    }

    final tasks = tasksAsync.value ?? [];
    final habits = habitsAsync.value ?? [];
    final mood = moodAsync.value;
    final goals = goalsAsync.value ?? [];

    final suggestions = _generateSuggestions(ref, tasks, habits, mood, goals);
    if (suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0),
          child: Text(
            'Based on your activity',
            style: AppTypography.h3(color: AppColors.textPrimary),
          ),
        ),
        const SizedBox(height: 10.0),
        Column(
          children: suggestions.map((s) => _SuggestionTile(suggestion: s)).toList(),
        ),
      ],
    );
  }

  List<_SuggestionData> _generateSuggestions(
    WidgetRef ref,
    List<dynamic> tasks,
    List<dynamic> habits,
    dynamic mood,
    List<dynamic> goals,
  ) {
    final List<_SuggestionData> suggestions = [];

    // 1. Mood suggestion
    if (mood == null) {
      suggestions.add(_SuggestionData(
        emoji: '😊',
        title: 'How are you feeling?',
        subtitle: 'Log your mood today to keep your mental health tracker up to date.',
        onTap: () {
          ref.read(currentTabProvider.notifier).state = 0; // Today
        },
      ));
    }

    // 2. Overdue/incomplete tasks
    final incomplete = tasks.where((t) => !t.completed).toList();
    if (incomplete.isNotEmpty) {
      suggestions.add(_SuggestionData(
        emoji: '⚠️',
        title: 'Complete your pending items',
        subtitle: 'You have ${incomplete.length} active tasks left for today.',
        onTap: () {
          ref.read(currentTabProvider.notifier).state = 1; // Tasks
        },
      ));
    }

    // 3. Habit reminder
    final uncompletedHabits = habits.where((h) => !ref.read(habitProvider.notifier).isCompletedToday(h)).toList();
    if (uncompletedHabits.isNotEmpty) {
      final first = uncompletedHabits.first;
      suggestions.add(_SuggestionData(
        emoji: first.icon,
        title: 'Time for ${first.name}?',
        subtitle: 'Maintain your consistency and build a stronger streak.',
        onTap: () {
          ref.read(currentTabProvider.notifier).state = 1; // Focus (Habits)
        },
      ));
    }

    // 4. Financial Goal suggestion
    if (goals.isNotEmpty) {
      final incompleteGoals = goals.where((g) => g.currentAmount < g.targetAmount).toList();
      if (incompleteGoals.isNotEmpty) {
        final goal = incompleteGoals.first;
        suggestions.add(_SuggestionData(
          emoji: '💰',
          title: 'Review ${goal.name} savings',
          subtitle: 'You are currently at ${((goal.currentAmount / goal.targetAmount) * 100).toInt()}% of your goal.',
          onTap: () {
            ref.read(currentTabProvider.notifier).state = 2; // Money
          },
        ));
      }
    }

    // Default fallbacks if list is too short
    if (suggestions.length < 2) {
      suggestions.add(_SuggestionData(
        emoji: '🧘',
        title: 'Reflect on your day',
        subtitle: 'Take 5 minutes to write down three things you are grateful for.',
        onTap: () {
          ref.read(currentTabProvider.notifier).state = 3; // Memory
        },
      ));
    }

    return suggestions.take(3).toList();
  }
}

class _SuggestionData {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  _SuggestionData({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}

class _SuggestionTile extends StatelessWidget {
  final _SuggestionData suggestion;

  const _SuggestionTile({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: JarvisCard(
        padding: 16.0,
        onTap: suggestion.onTap,
        child: Row(
          children: [
            // Left Emoji
            Text(
              suggestion.emoji,
              style: const TextStyle(fontSize: 26.0),
            ),
            const SizedBox(width: 14.0),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    suggestion.title,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    suggestion.subtitle,
                    style: AppTypography.caption(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8.0),

            // Right Chevron
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20.0,
            ),
          ],
        ),
      ),
    );
  }
}
