// lib/features/security/screens/security_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/password_utils.dart';
import '../../../core/services/secure_screen_service.dart';
import '../../../shared/widgets/shield_hero.dart';
import '../../vault/providers/vault_provider.dart';
import '../../vault/models/password_entry.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/security_item_row.dart';
import '../../home/widgets/recent_item_card.dart';
import '../../../shared/providers/tab_provider.dart';

/// Security Dashboard — animated shield, circular score, recommendations.
class SecurityScreen extends HookConsumerWidget {
  const SecurityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    useEffect(() {
      SecureScreenService.setSecureMode(true);
      return () {
        final currentTab = ref.read(tabIndexProvider);
        SecureScreenService.setSecureMode(currentTab == 1 || currentTab == 2);
      };
    }, const []);

    final headerTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    final vault = ref.watch(vaultProvider);
    final settings = ref.watch(settingsProvider);
    final loginEntries = vault.entries.where((e) => e.category == EntryCategory.login).toList();
    
    final passwordCounts = <String, int>{};
    for (final e in loginEntries) {
      passwordCounts[e.password] = (passwordCounts[e.password] ?? 0) + 1;
    }

    final weakEntries = <PasswordEntry>[];
    final strongEntries = <PasswordEntry>[];
    final reusedEntries = <PasswordEntry>[];

    for (final e in loginEntries) {
      final strength = PasswordUtils.analyzeStrength(e.password);
      if (strength == PasswordStrength.veryWeak || strength == PasswordStrength.weak) {
        weakEntries.add(e);
      } else if (strength == PasswordStrength.strong || strength == PasswordStrength.veryStrong) {
        strongEntries.add(e);
      }
      if ((passwordCounts[e.password] ?? 0) > 1) {
        reusedEntries.add(e);
      }
    }
    
    int weakCount = weakEntries.length;
    int strongCount = strongEntries.length;
    int reusedCount = reusedEntries.length;
    const compromisedCount = 0;

    int total = loginEntries.isEmpty ? 1 : loginEntries.length;
    int score = ((strongCount / total) * 100).round();
    if (loginEntries.isEmpty) {
      score = 100;
    } else {
      if (weakCount > 0) score -= (weakCount * 15);
      if (reusedCount > 0) score -= (reusedCount * 10);
      score = score.clamp(0, 100);
    }
    
    String statusText = 'Excellent';
    String statusSub = 'Your vault is in excellent shape!';
    if (score < 50) {
      statusText = 'Needs Work';
      statusSub = 'Many passwords need your attention.';
    } else if (score < 80) {
      statusText = 'Good';
      statusSub = 'Your vault is fairly secure.';
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Soft radial bg glow
          Positioned(
            top: -100,
            left: -80,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withAlpha(isDark ? 30 : 15),
                    Colors.transparent
                  ],
                ),
              ),
            ),
          ),

          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App Bar ─────────────────────────────────────
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                backgroundColor: Colors.transparent,
                leading: GestureDetector(
                  onTap: () => context.pop(),
                  child: Icon(Icons.arrow_back_rounded, color: headerTextColor),
                ),
                title: Text(
                  'Security Dashboard',
                  style: TextStyle(color: headerTextColor, fontWeight: FontWeight.bold),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 48),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // ── Glowing Shield + Score ────────────────
                    Center(
                      child: Column(
                        children: [
                          const ShieldHero(size: 220)
                              .animate()
                              .fadeIn(duration: 700.ms)
                              .scale(
                                begin: const Offset(0.6, 0.6),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 16),
                          Text(
                            statusText,
                            style: AppTextStyles.headingMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            statusSub,
                            style: AppTextStyles.bodyMedium.copyWith(color: subtitleColor),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppConstants.spaceXl),

                    // ── Security items ────────────────────────
                    AnimationLimiter(
                      child: Column(
                        children: AnimationConfiguration.toStaggeredList(
                          duration: const Duration(milliseconds: 400),
                          childAnimationBuilder: (w) => SlideAnimation(
                            verticalOffset: 20,
                            child: FadeInAnimation(child: w),
                          ),
                          children: [
                            SecurityItemRow(
                              icon: Icons.check_circle_rounded,
                              iconColor: AppColors.accentGreen,
                              label: 'Strong Passwords',
                              trailing: '$strongCount',
                              trailingColor: AppColors.accentGreen,
                              onTap: () => _showCategoryEntries(context, 'Strong Passwords', strongEntries),
                            ),
                            const SizedBox(height: 10),
                            SecurityItemRow(
                              icon: Icons.warning_rounded,
                              iconColor: AppColors.accentOrange,
                              label: 'Weak Passwords',
                              trailing: '$weakCount',
                              trailingColor: AppColors.accentOrange,
                              onTap: () => _showCategoryEntries(context, 'Weak Passwords', weakEntries),
                            ),
                            const SizedBox(height: 10),
                            SecurityItemRow(
                              icon: Icons.copy_rounded,
                              iconColor: AppColors.accentRed,
                              label: 'Reused Passwords',
                              trailing: '$reusedCount',
                              trailingColor: AppColors.accentRed,
                              onTap: () => _showCategoryEntries(context, 'Reused Passwords', reusedEntries),
                            ),
                            const SizedBox(height: 10),
                            SecurityItemRow(
                              icon: Icons.shield_rounded,
                              iconColor: AppColors.accentGreen,
                              label: 'Compromised',
                              trailing: '$compromisedCount',
                              trailingColor: AppColors.accentGreen,
                              onTap: () {},
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spaceXl),

                    _TwoFACard(
                      isEnabled: settings.biometricUnlock,
                      cardBg: cardBgColor,
                        borderColor: borderColor,
                        textCol: headerTextColor,
                        subCol: subtitleColor,
                      )
                          .animate(delay: 500.ms)
                          .fadeIn(duration: 400.ms)
                          .slideY(begin: 0.2),
                  ]),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryEntries(BuildContext context, String title, List<PasswordEntry> entries) {
    if (entries.isEmpty) return;
    
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF16151A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return Column(
              children: [
                // Drag Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.headingMedium.copyWith(
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(isDark ? 50 : 30),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${entries.length}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: entries.length,
                    itemBuilder: (ctx, i) {
                      final entry = entries[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: RecentItemCard(
                          entry: entry,
                          onTap: () {
                            // Close sheet and jump to vault tab
                            Navigator.pop(ctx);
                          },
                          onFavTap: () {},
                          onMoreTap: () {},
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _TwoFACard extends StatelessWidget {
  const _TwoFACard({
    required this.isEnabled,
    required this.cardBg,
    required this.borderColor,
    required this.textCol,
    required this.subCol,
  });

  final bool isEnabled;

  final Color cardBg;
  final Color borderColor;
  final Color textCol;
  final Color subCol;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEnabled ? 'Two-Factor Auth Enabled' : 'Enable Two-Factor Authentication',
                  style: AppTextStyles.labelLarge.copyWith(color: textCol, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  isEnabled ? 'Your vault is protected' : 'Add an extra layer of security',
                  style: AppTextStyles.bodySmall.copyWith(color: subCol),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEnabled ? AppColors.accentGreen.withAlpha(30) : AppColors.primary,
            ),
            child: Icon(
              isEnabled ? Icons.check_circle_rounded : Icons.lock_rounded, 
              color: isEnabled ? AppColors.accentGreen : Colors.white, 
              size: 20
            ),
          ),
        ],
      ),
    );
  }
}
