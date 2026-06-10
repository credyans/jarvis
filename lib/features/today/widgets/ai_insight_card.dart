import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/habit_provider.dart';

class AIInsightCard extends ConsumerWidget {
  const AIInsightCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(habitProvider);

    return habitsAsync.when(
      data: (habits) {
        // Calculate dynamic win text
        final today = DateTime.now();
        final yesterday = today.subtract(const Duration(days: 1));
        final completedYesterday = habits.where((h) {
          final yesterdayStr = '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
          return h.completions.contains(yesterdayStr);
        }).length;

        final insightText = completedYesterday > 0
            ? 'You completed $completedYesterday habits yesterday. Your productivity is improving.'
            : 'Welcome back! Let\'s build positive habits and crush your goals today.';

        return Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: AppColors.primary,
                width: 3.0,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Upper tag
                    Row(
                      children: [
                        Icon(
                          Icons.bolt_rounded,
                          color: AppColors.primary,
                          size: 18.0,
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .scaleXY(begin: 0.9, end: 1.1, duration: 1.seconds),
                        const SizedBox(width: 6.0),
                        Text(
                          'AI INSIGHT',
                          style: AppTypography.micro(color: AppColors.primary).copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    // Main insight headline
                    Text(
                      insightText,
                      style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16.0),
              // Spinning concentric visualizer
              Expanded(
                flex: 2,
                child: Center(
                  child: SizedBox(
                    width: 76.0,
                    height: 76.0,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer spinner
                        Container(
                          width: 70.0,
                          height: 70.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.12),
                              width: 3.0,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                         .rotate(duration: 10.seconds),
                        // Inner spinner
                        Container(
                          width: 50.0,
                          height: 50.0,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.secondary.withOpacity(0.12),
                              width: 2.0,
                            ),
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                         .rotate(duration: 6.seconds, begin: 1.0, end: 0.0),
                        // Center active icon
                        Icon(
                          Icons.auto_awesome_rounded,
                          color: AppColors.primary,
                          size: 26.0,
                        ).animate(onPlay: (c) => c.repeat(reverse: true))
                         .scaleXY(begin: 0.85, end: 1.15, duration: 1500.ms),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
