// lib/shared/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/utils/haptic_helper.dart';
import '../../features/home/screens/home_screen.dart';
import '../../features/vault/screens/vault_screen.dart';
import '../../features/generator/screens/generator_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../providers/tab_provider.dart';
import '../widgets/bottom_nav_bar.dart';
import '../../core/services/secure_screen_service.dart';

class MainScreen extends StatefulHookConsumerWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    final initialTab = ref.read(tabIndexProvider);
    _pageController = PageController(initialPage: initialTab);
    SecureScreenService.setSecureMode(initialTab == 1 || initialTab == 2);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeTab = ref.watch(tabIndexProvider);

    // Sync PageView selection when activeTab state changes programmatically (bottom nav taps/drawer taps)
    ref.listen<int>(tabIndexProvider, (prev, next) {
      if (_pageController.hasClients) {
        final current = _pageController.page?.round() ?? 0;
        if (current != next) {
          _pageController.animateToPage(
            next,
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeInOutCubic,
          );
        }
      }
      
      // Index 0: Home, 1: Vault, 2: Generator, 3: Settings
      // Secure Vault and Generator screens
      if (next == 1 || next == 2) {
        SecureScreenService.setSecureMode(true);
      } else {
        SecureScreenService.setSecureMode(false);
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        
        final currentIdx = ref.read(tabIndexProvider);
        if (currentIdx != 0) {
          // Accidental back swipe: redirect to Home instead of exiting
          await HapticHelper.light();
          ref.read(tabIndexProvider.notifier).state = 0;
          return;
        }

        // Show premium confirm exit dialog
        final shouldExit = await showDialog<bool>(
          context: context,
          barrierDismissible: true,
          builder: (context) => const _ExitDialog(),
        );

        if (shouldExit == true) {
          await HapticHelper.medium();
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            if (ref.read(tabIndexProvider) != index) {
              HapticHelper.selection();
              ref.read(tabIndexProvider.notifier).state = index;
            }
          },
          children: const [
            HomeScreen(),
            VaultScreen(),
            GeneratorScreen(),
            SettingsScreen(),
          ],
        ),
        bottomNavigationBar: VaultixBottomNav(
          currentIndex: activeTab,
          onTap: (index) {
            HapticHelper.light();
            ref.read(tabIndexProvider.notifier).state = index;
          },
        ),
      ),
    );
  }
}

class _ExitDialog extends StatelessWidget {
  const _ExitDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? const Color(0xFF16151A) : Colors.white;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Dialog(
      backgroundColor: cardBgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: borderColor, width: 0.8),
      ),
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Lock Vaultix?',
              style: AppTextStyles.headingSmall.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Are you sure you want to close Vaultix and lock your credentials?',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      HapticHelper.light();
                      Navigator.of(context).pop(false);
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Lock & Exit',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
