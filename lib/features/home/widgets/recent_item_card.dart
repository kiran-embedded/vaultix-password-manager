// lib/features/home/widgets/recent_item_card.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../vault/models/password_entry.dart';
import '../../../shared/widgets/brand_avatar.dart';

/// Compact password card shown in the Recent Items section.
class RecentItemCard extends StatelessWidget {
  const RecentItemCard({
    super.key,
    required this.entry,
    required this.onTap,
    required this.onFavTap,
    required this.onMoreTap,
  });

  final PasswordEntry entry;
  final VoidCallback onTap;
  final VoidCallback onFavTap;
  final VoidCallback onMoreTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final iconMutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Row(
          children: [
            BrandAvatar(entry: entry),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: AppTextStyles.labelLarge.copyWith(color: textColor),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.username,
                    style: AppTextStyles.bodySmall.copyWith(color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticHelper.light();
                onFavTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Icon(
                  entry.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: entry.isFavorite ? const Color(0xFFFFB300) : iconMutedColor,
                  size: 22,
                ),
              ),
            ),
            const SizedBox(width: 4),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                HapticHelper.medium();
                onMoreTap();
              },
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  Icons.more_vert_rounded,
                  color: iconMutedColor,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
