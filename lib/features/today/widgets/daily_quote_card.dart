import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jarvis/core/theme/app_colors.dart';
import 'package:jarvis/core/theme/app_typography.dart';
import 'package:jarvis/data/providers/quote_provider.dart';

class DailyQuoteCard extends ConsumerWidget {
  const DailyQuoteCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final quote = ref.watch(quoteOfTheDayProvider);
    final text = quote['quote'] ?? 'Concentrate all your thoughts upon the work at hand.';
    final author = quote['author'] ?? 'Alexander Graham Bell';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.01),
        border: Border(
          left: BorderSide(
            color: AppColors.secondary,
            width: 3.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                '💡',
                style: TextStyle(fontSize: 16.0),
              ),
              const SizedBox(width: 8.0),
              Text(
                'WISDOM FOR TODAY',
                style: AppTypography.micro(color: AppColors.textTertiary).copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            '"$text"',
            style: AppTypography.body(color: AppColors.textPrimary).copyWith(
              fontStyle: FontStyle.italic,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 6.0),
          Align(
            alignment: Alignment.bottomRight,
            child: Text(
              '— $author',
              style: AppTypography.caption(color: AppColors.textSecondary).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
