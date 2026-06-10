import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/repositories/mood_repository.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';

class MoodArcSelector extends StatelessWidget {
  final String? selectedMood;
  final ValueChanged<String> onMoodSelected;

  const MoodArcSelector({
    super.key,
    this.selectedMood,
    required this.onMoodSelected,
  });

  // Emojis and moods ordered to match Stitch mockup
  static const List<String> _moods = ['great', 'good', 'okay', 'low', 'burnedOut'];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        child: Row(
          children: _moods.map((mood) {
            final isSelected = selectedMood == mood;
            final emoji = MoodRepository.moodEmoji(mood);
            final label = MoodRepository.moodLabel(mood);

            return Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: SizedBox(
                width: 80.0,
                height: 90.0,
                child: JarvisCard(
                  padding: 8.0,
                  animate: false,
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.15)
                      : Colors.white.withOpacity(0.04),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : Colors.white.withOpacity(0.08),
                    width: 1.2,
                  ),
                  onTap: () => onMoodSelected(mood),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        emoji,
                        style: const TextStyle(fontSize: 26.0),
                      ),
                      const SizedBox(height: 6.0),
                      Text(
                        label,
                        style: AppTypography.micro(
                          color: isSelected ? AppColors.primary : AppColors.textSecondary,
                        ).copyWith(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
