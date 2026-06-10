import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/core/utils/date_helpers.dart';
import 'package:jarvis/shared/widgets/jarvis_card.dart';

class TimelineItem extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String time;
  final Color color;
  final bool isCompleted;
  final IconData? icon;
  final VoidCallback? onTap;

  final bool isInCountdown;
  final int secondsLeft;
  final VoidCallback? onUndo;

  const TimelineItem({
    super.key,
    required this.title,
    this.subtitle,
    required this.time,
    required this.color,
    this.isCompleted = false,
    this.icon,
    this.onTap,
    this.isInCountdown = false,
    this.secondsLeft = 0,
    this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    // Determine completed status (includes being in countdown)
    final displayCompleted = isCompleted || isInCountdown;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: JarvisCard(
        padding: 12.0,
        onTap: isInCountdown ? null : onTap, // Prevent tapping again during countdown
        animate: false,
        child: Row(
          children: [
            // Left Status Bubble (animated completion tick)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 36.0,
              height: 36.0,
              decoration: BoxDecoration(
                color: displayCompleted
                    ? AppColors.success.withOpacity(0.15)
                    : color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: displayCompleted
                    ? Icon(
                        Icons.check_rounded,
                        color: AppColors.success,
                        size: 18.0,
                      )
                        .animate()
                        .scale(duration: 350.ms, curve: Curves.easeOutBack)
                        .rotate(begin: -0.15, end: 0.0)
                    : Icon(
                        icon ?? Icons.circle_rounded,
                        color: color,
                        size: 16.0,
                      )
                        .animate(target: displayCompleted ? 0.0 : 1.0)
                        .scale(duration: 200.ms),
              ),
            )
              .animate(target: displayCompleted ? 1.0 : 0.0)
              .shimmer(duration: 450.ms, color: Colors.white.withOpacity(0.2)),
            
            const SizedBox(width: 14.0),

            // Content Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium(color: AppColors.textPrimary).copyWith(
                      decoration: displayCompleted ? TextDecoration.lineThrough : null,
                      fontWeight: displayCompleted ? FontWeight.normal : FontWeight.w600,
                      color: displayCompleted ? AppColors.textTertiary : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2.0),
                    Text(
                      subtitle!,
                      style: AppTypography.caption(color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12.0),

            // Right Time Label or Undo Countdown
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: isInCountdown
                  ? TextButton(
                      key: ValueKey('undo_$secondsLeft'),
                      onPressed: onUndo,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.12),
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                      ),
                      child: Text(
                        'Undo (${secondsLeft}s)',
                        style: AppTypography.caption(color: AppColors.primary).copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : Text(
                      key: const ValueKey('time'),
                      DateHelpers.formatTime(time),
                      style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
