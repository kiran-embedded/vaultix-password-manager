// lib/features/home/widgets/security_score_card.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/neon_glow.dart';

/// Animated arc-based security score card for the home dashboard.
class SecurityScoreCard extends StatelessWidget {
  const SecurityScoreCard({
    super.key,
    required this.score,
    required this.onArrowTap,
  });

  final int score;
  final VoidCallback onArrowTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.spaceMd),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.bottomLeft,
          end: Alignment.topRight,
          colors: [
            Color(0xFF6338F6), // Vibrant Purple
            Color(0xFF421E94), // Deep Purple
          ],
        ),
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6338F6).withAlpha(40),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Animated ring score
          SecurityRing(
            score: score,
            size: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$score',
                  style: AppTextStyles.headingLarge.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: Colors.white,
                  ),
                ),
                Text(
                  '/100',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white.withAlpha(160),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 600.ms).scale(
                begin: const Offset(0.7, 0.7),
                curve: Curves.easeOutBack,
              ),

          const SizedBox(width: 16),

          // Score label + description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  score < 40 ? 'Your vault needs help!' : score < 70 ? 'Your vault is okay.' : 'Your vault is strong!',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.2),
                const SizedBox(height: 6),
                Text(
                  score < 40
                      ? 'You have many weak or reused passwords.'
                      : score < 70
                          ? 'Consider updating some weak passwords.'
                          : 'Keep it up! You have good security habits.',
                  style: AppTextStyles.bodySmall.copyWith(
                    height: 1.4,
                    color: Colors.white.withAlpha(200),
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Arrow button
          GestureDetector(
            onTap: onArrowTap,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(50),
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ).animate().fadeIn(delay: 500.ms).scale(
                begin: const Offset(0.5, 0.5),
                curve: Curves.easeOutBack,
              ),
        ],
      ),
    );
  }
}
