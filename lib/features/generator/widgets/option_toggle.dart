// lib/features/generator/widgets/option_toggle.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

/// A labeled toggle row for generator character set options.
class OptionToggle extends StatelessWidget {
  const OptionToggle({
    super.key,
    required this.prefixLabel,
    required this.label,
    required this.value,
    required this.onChanged,
    this.delay = 0,
  });

  final String prefixLabel;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final int delay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    // Badge styling matches the Google design mockup (soft purple badge)
    final badgeBgColor = isDark ? const Color(0xFF201B3D) : const Color(0xFFF1EEFF);
    final badgeTextColor = isDark ? const Color(0xFF9F83FF) : AppColors.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cardBgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value ? AppColors.primary.withAlpha(80) : borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Prefix badge (e.g., A-Z, a-z)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeBgColor,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              prefixLabel,
              style: AppTextStyles.labelSmall.copyWith(
                color: badgeTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: AppColors.primary,
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: delay))
        .fadeIn(duration: 300.ms)
        .slideX(begin: 0.05);
  }
}
