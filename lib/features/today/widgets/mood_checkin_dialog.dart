import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/id_generator.dart';
import 'package:jarvis/features/mood/data/models/mood_entry_model.dart';
import 'package:jarvis/data/providers/mood_provider.dart';
import 'package:jarvis/features/today/widgets/mood_arc_selector.dart';
import 'package:jarvis/shared/widgets/toast_notification.dart';

class MoodCheckinDialog extends ConsumerWidget {
  const MoodCheckinDialog({super.key});

  static Future<void> show(BuildContext context) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (context) => const MoodCheckinDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayMoodAsync = ref.watch(todayMoodProvider);

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28.0)),
          border: Border.all(
            color: Colors.white.withOpacity(0.08),
            width: 1.0,
          ),
        ),
        padding: EdgeInsets.only(
          top: 12.0,
          left: 20.0,
          right: 20.0,
          bottom: MediaQuery.of(context).padding.bottom + 24.0,
        ),
        child: todayMoodAsync.when(
          data: (moodEntry) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Notch line
                Center(
                  child: Container(
                    width: 40.0,
                    height: 4.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
                const SizedBox(height: 20.0),
                
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 24.0), // Spacer to offset close button
                    Expanded(
                      child: Text(
                        'How has your day been so far?',
                        style: AppTypography.h2(color: AppColors.textPrimary).copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22.0),
                      color: AppColors.textSecondary,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16.0),

                // Mood selector
                MoodArcSelector(
                  selectedMood: moodEntry?.mood,
                  onMoodSelected: (mood) async {
                    try {
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
                        Navigator.pop(context);
                        ToastNotification.show(
                          context,
                          'Mood logged successfully! Keep radiating positive energy.',
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ToastNotification.show(
                          context,
                          'Failed to save mood: $e',
                          type: 'error',
                        );
                      }
                    }
                  },
                ),
                const SizedBox(height: 24.0),

                // Supportive message
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.08),
                    borderRadius: AppSpacing.buttonRadius,
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.15),
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('✨', style: TextStyle(fontSize: 18.0)),
                      const SizedBox(width: 10.0),
                      Expanded(
                        child: Text(
                          'Prioritize your mental health and embrace self-care.',
                          style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 200.0,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => const SizedBox(
            height: 100.0,
            child: Center(child: Text('Error loading mood data')),
          ),
        ),
      ),
    );
  }
}
