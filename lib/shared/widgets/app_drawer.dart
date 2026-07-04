// lib/shared/widgets/app_drawer.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/haptic_helper.dart';
import '../../features/settings/providers/settings_provider.dart';
import '../providers/tab_provider.dart';

class VaultixDrawer extends ConsumerWidget {
  const VaultixDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTab = ref.watch(tabIndexProvider);
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    void selectTab(int index) {
      HapticHelper.light();
      ref.read(tabIndexProvider.notifier).state = index;
      Navigator.of(context).pop(); // Close drawer
    }

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          children: [
            // ── Drawer Header ─────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.secondary],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.shield_rounded,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: 'Vault',
                                style: AppTextStyles.brand.copyWith(
                                  fontSize: 20,
                                  color: textColor,
                                ),
                              ),
                              TextSpan(
                                text: 'ix',
                                style: AppTextStyles.brand.copyWith(
                                  fontSize: 20,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'PREMIUM MEMBER',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Drawer Links ──────────────────────────────────
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: [
                  _DrawerItem(
                    icon: Icons.home_rounded,
                    label: 'Home',
                    isSelected: activeTab == 0,
                    onTap: () => selectTab(0),
                    textColor: textColor,
                  ),
                  _DrawerItem(
                    icon: Icons.lock_rounded,
                    label: 'Vault Credentials',
                    isSelected: activeTab == 1,
                    onTap: () => selectTab(1),
                    textColor: textColor,
                  ),
                  _DrawerItem(
                    icon: Icons.auto_awesome_rounded,
                    label: 'Password Generator',
                    isSelected: activeTab == 2,
                    onTap: () => selectTab(2),
                    textColor: textColor,
                  ),
                  _DrawerItem(
                    icon: Icons.security_rounded,
                    label: 'Security Dashboard',
                    isSelected: false,
                    onTap: () {
                      HapticHelper.light();
                      Navigator.of(context).pop();
                      context.push('/security');
                    },
                    textColor: textColor,
                  ),
                  _DrawerItem(
                    icon: Icons.settings_rounded,
                    label: 'Settings',
                    isSelected: activeTab == 3,
                    onTap: () => selectTab(3),
                    textColor: textColor,
                  ),

                  const SizedBox(height: 16),
                  Divider(color: borderColor, height: 1),
                  const SizedBox(height: 16),

                  // ── Quick Dark Mode Toggle ────────────────────────
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: cardBgColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 0.8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(
                              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                              color: isDark ? const Color(0xFF9F83FF) : Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Dark Mode',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: settings.darkMode,
                          onChanged: (val) {
                            HapticHelper.medium();
                            settingsNotifier.setDarkMode(val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Footer ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                'v1.0.0 • Secured with AES-256',
                style: AppTextStyles.bodySmall.copyWith(color: textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.textColor,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withAlpha(20) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? AppColors.primary : textColor.withAlpha(160),
          size: 22,
        ),
        title: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: isSelected ? AppColors.primary : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: onTap,
      ),
    );
  }
}
