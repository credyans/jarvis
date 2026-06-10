import 'package:flutter/material.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_spacing.dart';
import 'package:jarvis/core/theme/app_typography.dart';

class JarvisChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final String? emoji;
  final VoidCallback? onTap;

  const JarvisChip({
    super.key,
    required this.label,
    this.isSelected = false,
    this.emoji,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: AppSpacing.chipRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.white.withOpacity(0.08),
            width: 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.2),
                    blurRadius: 8.0,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji!,
                style: const TextStyle(fontSize: 14.0),
              ),
              const SizedBox(width: 6.0),
            ],
            Text(
              label,
              style: AppTypography.caption(
                color: isSelected ? AppColors.background : AppColors.textPrimary,
              ).copyWith(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
