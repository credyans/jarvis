import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/features/today/widgets/mood_arc_selector.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class MoodCheckinCard extends ConsumerWidget {
  const MoodCheckinCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMoodAsync = ref.watch(todayMoodProvider);

    return todayMoodAsync.when(
      data: (moodEntry) {
        return JarvisCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'How has your day been so far?',
                style: AppTypography.h3(color: AppColors.textPrimary).copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16.0),
              
              // Custom mood arch selector
              MoodArcSelector(
                selectedMood: moodEntry?.mood,
                onMoodSelected: (mood) async {
                  final newMood = MoodEntryModel(
                    id: IdGenerator.generate(),
                    date: DateTime.now(),
                    mood: mood,
                    note: moodEntry?.note,
                    createdAt: DateTime.now(),
                  );
                  
                  await ref.read(moodProvider.notifier).saveMood(newMood);
                  ref.invalidate(todayMoodProvider);
                  
                  if (context.mounted) {
                    ToastNotification.show(
                      context,
                      'Mood logged successfully! Keep radiating positive energy.',
                    );
                  }
                },
              ),
              
              const SizedBox(height: 20.0),
              
              // Supportive Message
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.4),
                  borderRadius: AppSpacing.buttonRadius,
                ),
                child: Row(
                  children: [
                    const Text('✨', style: TextStyle(fontSize: 16.0)),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        'Prioritize your mental health and embrace self-care.',
                        style: AppTypography.caption(color: AppColors.primaryDark).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(
        height: 220.0,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => const SizedBox.shrink(),
    );
  }
}
