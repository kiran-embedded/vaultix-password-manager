// lib/features/vault/widgets/category_chips.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';
import '../models/password_entry.dart';

/// Horizontally scrollable category filter chips.
class CategoryChips extends StatelessWidget {
  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onSelect,
  });

  final EntryCategory? selectedCategory;
  final ValueChanged<EntryCategory?> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          // "All" chip
          _Chip(
            label: 'All',
            isSelected: selectedCategory == null,
            onTap: () => onSelect(null),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(width: 8),
          // Category chips
          ...EntryCategory.values.map((cat) {
            final i = cat.index + 1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Chip(
                label: cat.label,
                isSelected: selectedCategory == cat,
                onTap: () => onSelect(cat),
              ).animate(delay: Duration(milliseconds: 40 * i)).fadeIn(
                    duration: 300.ms,
                  ),
            );
          }),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    const activeBgColor = AppColors.primary;
    const activeTextColor = Colors.white;

    const inactiveBgColor = Colors.transparent;
    final inactiveBorderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final inactiveTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticHelper.light();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? activeBgColor : inactiveBgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeBgColor : inactiveBorderColor,
            width: 1.0,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? activeTextColor : inactiveTextColor,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
