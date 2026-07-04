// lib/features/security/widgets/security_item_row.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';

/// A single security recommendation row card.
class SecurityItemRow extends StatelessWidget {
  const SecurityItemRow({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.trailing,
    required this.trailingColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String trailing;
  final Color trailingColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final iconMutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(color: textColor),
              ),
            ),
            Text(
              trailing,
              style: AppTextStyles.headingSmall.copyWith(
                color: trailingColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: iconMutedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
