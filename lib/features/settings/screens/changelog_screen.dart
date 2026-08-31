import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';

class ChangelogScreen extends StatelessWidget {
  const ChangelogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            HapticHelper.light();
            context.pop();
          },
        ),
        title: Text(
          'What\'s New',
          style: AppTextStyles.headingSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
        children: [
          // Version Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.new_releases_rounded,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Vaultix v1.0.0+2',
                  style: AppTextStyles.headingMedium.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Bug fixes, security tweaks, and UI improvements',
                  style: AppTextStyles.bodyMedium.copyWith(color: subColor),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 32),

          // Updates list
          _UpdateCard(
            version: 'v1.0.0+2',
            date: 'August 2026',
            features: const [
              {
                'title': 'Advanced Hardware Security',
                'desc': 'Added strict root detection, anti-spoofing, and tamper checks permanently backed by hardware attestation for maximum vault safety.',
                'icon': Icons.security_rounded,
                'color': AppColors.accentGreen,
              },
              {
                'title': 'In-App Updater',
                'desc': 'Added an animated update checker in Settings that pulls the latest release directly from GitHub.',
                'icon': Icons.system_update_rounded,
                'color': AppColors.primary,
              },
              {
                'title': 'Bug Fixes & UI Tweaks',
                'desc': 'Fixed the app getting stuck on the splash screen. Fixed a delay when toggling dark mode. Locked system font scaling so the layout doesn\'t break.',
                'icon': Icons.bug_report_rounded,
                'color': AppColors.accentOrange,
              },
            ],
            cardBg: cardBg,
            borderCol: borderCol,
            textColor: textColor,
            subColor: subColor,
          ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.05),

          const SizedBox(height: 24),
          
          _UpdateCard(
            version: 'v1.0.0',
            date: 'July 2026',
            features: const [
              {
                'title': 'Initial Release',
                'desc': 'Welcome to Vaultix! Featuring AES-256 encryption, Biometric Unlock, and offline-first architecture.',
                'icon': Icons.rocket_launch_rounded,
                'color': AppColors.primary,
              },
            ],
            cardBg: cardBg,
            borderCol: borderCol,
            textColor: textColor,
            subColor: subColor,
          ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.05),
        ],
      ),
    );
  }
}

class _UpdateCard extends StatelessWidget {
  const _UpdateCard({
    required this.version,
    required this.date,
    required this.features,
    required this.cardBg,
    required this.borderCol,
    required this.textColor,
    required this.subColor,
  });

  final String version;
  final String date;
  final List<Map<String, dynamic>> features;
  final Color cardBg;
  final Color borderCol;
  final Color textColor;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol, width: 0.8),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                version,
                style: AppTextStyles.labelLarge.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                date,
                style: AppTextStyles.labelSmall.copyWith(
                  color: subColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(color: borderCol, height: 1),
          const SizedBox(height: 16),
          ...features.map((feature) {
            final isLast = features.last == feature;
            return Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: (feature['color'] as Color).withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      feature['icon'] as IconData,
                      size: 16,
                      color: feature['color'] as Color,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          feature['title'] as String,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          feature['desc'] as String,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: subColor,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
