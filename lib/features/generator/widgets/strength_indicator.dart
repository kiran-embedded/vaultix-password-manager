// lib/features/generator/widgets/strength_indicator.dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/password_utils.dart';

/// Segmented password strength indicator matching mockup UI.
class StrengthIndicator extends StatelessWidget {
  const StrengthIndicator({super.key, required this.strength});
  final PasswordStrength strength;

  Color get _color => switch (strength) {
        PasswordStrength.veryStrong => AppColors.accentGreen,
        PasswordStrength.strong => AppColors.accentGreen,
        PasswordStrength.medium => AppColors.accentOrange,
        PasswordStrength.weak => AppColors.accentRed,
        PasswordStrength.veryWeak => AppColors.accentRed,
        PasswordStrength.none => Colors.grey,
      };

  int get _segments => switch (strength) {
        PasswordStrength.veryStrong => 4,
        PasswordStrength.strong => 3,
        PasswordStrength.medium => 2,
        PasswordStrength.weak => 1,
        PasswordStrength.veryWeak => 1,
        PasswordStrength.none => 0,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final inactiveColor = isDark ? const Color(0xFF35343A) : const Color(0xFFE0E0E0);

    return Row(
      children: [
        // 4 Segments
        ...List.generate(4, (i) {
          final filled = i < _segments;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 8 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 8,
                decoration: BoxDecoration(
                  color: filled ? _color : inactiveColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 16),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: Text(
            strength.label,
            key: ValueKey(strength),
            style: AppTextStyles.labelMedium.copyWith(
              color: _color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
