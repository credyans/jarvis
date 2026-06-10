import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/data/providers/user_provider.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/data/repositories/mood_repository.dart';
import 'package:jarvis/features/today/widgets/mood_checkin_dialog.dart';

class GreetingHeader extends ConsumerWidget {
  const GreetingHeader({super.key});



  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(userProvider);
    final todayMoodAsync = ref.watch(todayMoodProvider);
    final greeting = DateHelpers.greeting();

    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16.0,
        bottom: 16.0,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: userAsync.when(
              data: (user) {
                final userName = user?.name ?? 'Santhosh';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting,',
                      style: AppTypography.body(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        Text(
                          '$userName ',
                          style: AppTypography.h1(color: AppColors.textPrimary).copyWith(
                            fontSize: 26.0,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => MoodCheckinDialog.show(context),
                          behavior: HitTestBehavior.opaque,
                          child: todayMoodAsync.when(
                            data: (moodEntry) => Text(
                              moodEntry != null
                                  ? MoodRepository.moodEmoji(moodEntry.mood)
                                  : '🎭',
                              style: const TextStyle(fontSize: 26.0),
                            ),
                            loading: () => const SizedBox(
                              width: 20.0,
                              height: 20.0,
                              child: CircularProgressIndicator(strokeWidth: 2.0),
                            ),
                            error: (_, __) => const Text(
                              '🎭',
                              style: TextStyle(fontSize: 26.0),
                            ),
                          ).animate(key: ValueKey(todayMoodAsync.value?.mood)).scale(duration: 350.ms, curve: Curves.easeOutBack),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      'Jarvis has prepared your day.',
                      style: AppTypography.caption(color: AppColors.textTertiary),
                    ),
                  ],
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (err, _) => Row(
                children: [
                  Text(
                    'Welcome ',
                    style: AppTypography.h1(color: AppColors.textPrimary),
                  ),
                  GestureDetector(
                    onTap: () => MoodCheckinDialog.show(context),
                    behavior: HitTestBehavior.opaque,
                    child: todayMoodAsync.when(
                      data: (moodEntry) => Text(
                        moodEntry != null
                            ? MoodRepository.moodEmoji(moodEntry.mood)
                            : '🎭',
                        style: const TextStyle(fontSize: 26.0),
                      ),
                      loading: () => const SizedBox(
                        width: 20.0,
                        height: 20.0,
                        child: CircularProgressIndicator(strokeWidth: 2.0),
                      ),
                      error: (_, __) => const Text(
                        '🎭',
                        style: TextStyle(fontSize: 26.0),
                      ),
                    ).animate(key: ValueKey(todayMoodAsync.value?.mood)).scale(duration: 350.ms, curve: Curves.easeOutBack),
                  ),
                ],
              ),
            ),
          ),
          
          // Action Buttons
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 24.0),
                color: AppColors.textPrimary,
                onPressed: () {
                  // Notification click placeholder
                },
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined, size: 24.0),
                color: AppColors.textPrimary,
                onPressed: () => context.push('/profile'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
