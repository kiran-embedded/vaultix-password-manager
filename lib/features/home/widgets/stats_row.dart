// lib/features/home/widgets/stats_row.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

/// Four statistic tiles — Passwords, Notes, Cards, IDs.
class StatsRow extends StatelessWidget {
  const StatsRow({
    super.key,
    required this.passwords,
    required this.notes,
    required this.cards,
    required this.ids,
  });

  final int passwords;
  final int notes;
  final int cards;
  final int ids;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _Stat(
        icon: Icons.lock_rounded,
        label: 'Passwords',
        count: passwords,
        color: const Color(0xFFC71585), // Pink/Purple badge
      ),
      _Stat(
        icon: Icons.sticky_note_2_rounded,
        label: 'Notes',
        count: notes,
        color: AppColors.accentOrange, // Orange badge
      ),
      _Stat(
        icon: Icons.credit_card_rounded,
        label: 'Cards',
        count: cards,
        color: const Color(0xFF2196F3), // Blue badge
      ),
      _Stat(
        icon: Icons.badge_rounded,
        label: 'IDs',
        count: ids,
        color: AppColors.accentGreen, // Green badge
      ),
    ];

    return Row(
      children: List.generate(stats.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < stats.length - 1 ? 10 : 0),
            child: _StatTile(stat: stats[i])
                .animate(delay: Duration(milliseconds: 80 * i))
                .fadeIn(duration: 400.ms)
                .scale(begin: const Offset(0.8, 0.8), curve: Curves.easeOutBack),
          ),
        );
      }),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});
  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final labelColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: stat.color.withAlpha(isDark ? 40 : 20),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, color: stat.color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            '${stat.count}',
            style: AppTextStyles.headingSmall.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            stat.label,
            style: AppTextStyles.labelSmall.copyWith(color: labelColor),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _Stat {
  const _Stat({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });
  final IconData icon;
  final String label;
  final int count;
  final Color color;
}
