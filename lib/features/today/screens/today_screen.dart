import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/data/providers/task_provider.dart';
import 'package:jarvis/data/providers/money_provider.dart';
import 'package:jarvis/data/providers/habit_provider.dart';
import 'package:jarvis/data/providers/navigation_provider.dart';
import 'package:jarvis/features/today/widgets/greeting_header.dart';
import 'package:jarvis/features/today/widgets/ai_insight_card.dart';
import 'package:jarvis/features/today/widgets/daily_quote_card.dart';
import 'package:jarvis/features/today/widgets/timeline_section.dart';
import 'package:jarvis/features/today/widgets/jarvis_suggestions_card.dart';
import 'package:jarvis/features/today/widgets/daily_summary_card.dart';
import 'package:jarvis/features/today/widgets/mood_checkin_dialog.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/jarvis_button.dart';

class TodayScreen extends ConsumerStatefulWidget {
  const TodayScreen({super.key});

  @override
  ConsumerState<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends ConsumerState<TodayScreen> {
  bool _hasPromptedMood = false;

  Widget _buildJarvisWelcomeCard(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80.0,
            height: 80.0,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [
                  Color(0xFFE8ECEF), // specular highlight
                  Color(0xFF6366FF), // primary theme color
                  Color(0xFF2C2F8A), // shadow shade
                ],
                center: Alignment(-0.35, -0.35),
                radius: 0.75,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366FF).withOpacity(0.5),
                  blurRadius: 24.0,
                  spreadRadius: 2.0,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8.0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                Icons.blur_on_rounded,
                size: 40.0,
                color: Colors.white.withOpacity(0.95),
                shadows: [
                  Shadow(
                    color: Colors.black.withOpacity(0.35),
                    offset: const Offset(1, 2),
                    blurRadius: 4.0,
                  ),
                ],
              ),
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .scale(end: const Offset(1.08, 1.08), duration: 1.5.seconds, curve: Curves.easeInOut),
          const SizedBox(height: 24.0),
          Text(
            "Hi, I'm Jarvis",
            style: AppTypography.h2(color: AppColors.textPrimary).copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12.0),
          Text(
            "Your Personal Life Operating System is ready to assist you. I can help you organize priorities, build habits, track budgets, and write memories.",
            textAlign: TextAlign.center,
            style: AppTypography.body(color: AppColors.textSecondary).copyWith(
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24.0),
          JarvisButton(
            text: "Talk to Jarvis",
            onPressed: () {
              ref.read(commandBarVisibleProvider.notifier).state = true;
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayMoodAsync = ref.watch(todayMoodProvider);
    final tasksAsync = ref.watch(taskProvider);
    final habitsAsync = ref.watch(habitProvider);

    // Prompt for mood check-in if not set yet today
    if (todayMoodAsync is AsyncData<MoodEntryModel?> &&
        todayMoodAsync.value == null &&
        !_hasPromptedMood) {
      _hasPromptedMood = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        MoodCheckinDialog.show(context);
      });
    }

    final tasks = tasksAsync.value ?? [];
    final habits = habitsAsync.value ?? [];
    final isNewUser = tasks.isEmpty && habits.isEmpty;

    return Scaffold(
      backgroundColor: Colors.transparent, // Let gradient background show through
      body: SafeArea(
        top: false,
        bottom: false,
        child: isNewUser
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  children: [
                    const SizedBox(height: 60.0), // top padding for header
                    const GreetingHeader()
                        .animate()
                        .fade(duration: 400.ms)
                        .slideY(begin: -0.05, end: 0.0),
                    Expanded(
                      child: Center(
                        child: _buildJarvisWelcomeCard(context)
                            .animate()
                            .fade(delay: 100.ms, duration: 400.ms)
                            .slideY(begin: 0.05, end: 0.0),
                      ),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: () async {
                  // Invalidate/reload today's providers
                  ref.invalidate(todayMoodProvider);
                  ref.invalidate(todayTasksProvider);
                  ref.invalidate(todaySpentProvider);
                  ref.invalidate(taskProvider);
                  ref.invalidate(habitProvider);
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.only(
                    left: 20.0,
                    right: 20.0,
                    bottom: 120.0, // generous bottom padding to clear floating nav bar and FAB
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Greeting Header
                      const GreetingHeader()
                          .animate()
                          .fade(duration: 400.ms)
                          .slideY(begin: -0.05, end: 0.0),
                      
                      const SizedBox(height: 12.0),

                      // 3. Today's Progress Card (now cardless stats)
                      const DailySummaryCard()
                          .animate()
                          .fade(delay: 100.ms, duration: 400.ms),
                      
                      const SizedBox(height: 24.0),

                      // 4. Next Activity (Timeline - renamed to To Do)
                      const TimelineSection()
                          .animate()
                          .fade(delay: 150.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0.0),
                      
                      const SizedBox(height: 24.0),

                      // 5. Jarvis Suggestions
                      const JarvisSuggestionsCard()
                          .animate()
                          .fade(delay: 200.ms, duration: 400.ms)
                          .slideY(begin: 0.05, end: 0.0),
                      
                      const SizedBox(height: 24.0),

                      // 6. Daily Quote (now cardless blockquote)
                      const DailyQuoteCard()
                          .animate()
                          .fade(delay: 250.ms, duration: 400.ms),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
