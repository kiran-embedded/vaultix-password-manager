// lib/features/home/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../core/utils/password_utils.dart';
import '../../../shared/providers/tab_provider.dart';
import '../../vault/providers/vault_provider.dart';
import '../../vault/models/password_entry.dart';
import '../../settings/providers/settings_provider.dart';
import '../widgets/security_score_card.dart';
import '../widgets/stats_row.dart';
import '../widgets/recent_item_card.dart';

/// Home screen — security overview, stats, and recent password items.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vault = ref.watch(vaultProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final recentEntries = ([...vault.entries]
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)))
      .take(3)
      .toList();

    final passwords = vault.entries.where((e) => e.category == EntryCategory.login).map((e) => e.password).toList();
    
    // AI-like logic for password strength
    int weakCount = 0;
    int strongCount = 0;
    for (final p in passwords) {
      final strength = PasswordUtils.analyzeStrength(p);
      if (strength == PasswordStrength.veryWeak || strength == PasswordStrength.weak) {
        weakCount++;
      } else if (strength == PasswordStrength.strong || strength == PasswordStrength.veryStrong) {
        strongCount++;
      }
    }

    final passwordCounts = <String, int>{};
    for (final p in passwords) {
      passwordCounts[p] = (passwordCounts[p] ?? 0) + 1;
    }
    final reusedCount = passwords.where((p) => (passwordCounts[p] ?? 0) > 1).length;
    final hasAlerts = (weakCount > 0 || reusedCount > 0) &&
        (settings.notificationsViewedAt == null ||
            vault.entries.any((e) => e.updatedAt.isAfter(settings.notificationsViewedAt!)));
    
    int total = passwords.isEmpty ? 1 : passwords.length;
    int score = ((strongCount / total) * 100).round();
    if (passwords.isEmpty) {
      score = 100;
    } else {
      if (weakCount > 0) score -= (weakCount * 15);
      if (reusedCount > 0) score -= (reusedCount * 10);
      score = score.clamp(0, 100);
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 40,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded, color: headerTextColor, size: 24),
            onPressed: () {
              HapticHelper.light();
              ref.read(tabIndexProvider.notifier).state = 1; // Slide to Vault tab
              ref.read(searchFocusProvider.notifier).state = true;
            },
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.notifications_none_rounded, color: headerTextColor, size: 24),
                onPressed: () {
                  HapticHelper.light();
                  ref.read(settingsProvider.notifier).markNotificationsViewed();
                  _showNotificationsSheet(context, weakCount, reusedCount, settings.lastBackupAt);
                },
              ),
              if (hasAlerts)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.accentRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── User Greeting ─────────────────────────────
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome back,',
                        style: AppTextStyles.bodyMedium.copyWith(color: subtitleColor, fontSize: 20),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Flexible(
                            child: ShaderMask(
                              shaderCallback: (bounds) => LinearGradient(
                                colors: [AppColors.primary, AppColors.secondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ).createShader(bounds),
                              child: Text(
                                settings.userName,
                                style: AppTextStyles.headingMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 42,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: const Text('👋', style: TextStyle(fontSize: 36, color: Colors.white)),
                          ),
                        ],
                      ),
                    ],
                  ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppConstants.spaceMd),

                  // ── Security Score Card ───────────────────────
                  SecurityScoreCard(
                    score: score,
                    onArrowTap: () {
                      HapticHelper.light();
                      context.push('/security');
                    },
                  ).animate().fadeIn(delay: 100.ms).scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutCubic),

                  const SizedBox(height: AppConstants.spaceLg),

                  // ── Statistics Row ────────────────────────────
                  StatsRow(
                    passwords: vault.entries.where((e) => e.category == EntryCategory.login).length,
                    notes: vault.entries.where((e) => e.category == EntryCategory.note).length,
                    cards: vault.entries.where((e) => e.category == EntryCategory.card).length,
                    ids: vault.entries.where((e) => e.category == EntryCategory.identity).length,
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                  const SizedBox(height: AppConstants.spaceXl),

                  // ── Recent Section Header ─────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recently Added',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: headerTextColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          HapticHelper.light();
                          ref.read(tabIndexProvider.notifier).state = 1; // Go to Vault tab
                        },
                        child: Text(
                          'View All',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms),

                  const SizedBox(height: AppConstants.spaceMd),
                ],
              ),
            ),
            
            // ── Recent Items List ─────────────────────────
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: recentEntries.isEmpty
                    ? Center(
                        child: Text(
                          'No credentials added yet.',
                          style: AppTextStyles.bodyMedium.copyWith(color: subtitleColor),
                        ),
                      )
                    : AnimationLimiter(
                        child: ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          itemCount: recentEntries.length,
                          itemBuilder: (context, index) {
                            final entry = recentEntries[index];
                            return AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: RecentItemCard(
                                      entry: entry,
                                      onTap: () {
                                        HapticHelper.selection();
                                        ref.read(tabIndexProvider.notifier).state = 1;
                                      },
                                      onFavTap: () {
                                        HapticHelper.selection();
                                        ref.read(vaultProvider.notifier).toggleFavorite(entry.id);
                                      },
                                      onMoreTap: () => _showRecentEntryActions(context, ref, entry),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotificationsSheet(BuildContext context, int weakCount, int reusedCount, DateTime? lastBackupAt) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final sheetBg = isDark ? const Color(0xFF16151A) : Colors.white;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Security Alerts',
                    style: AppTextStyles.headingSmall.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textMuted),
                    onPressed: () {
                      HapticHelper.light();
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (lastBackupAt != null) ...[
                _NotificationItem(
                  title: 'Vault Backup Completed',
                  subtitle: 'All credentials are encrypted and stored locally.',
                  time: _formatTimeAgo(lastBackupAt),
                  icon: Icons.cloud_done_rounded,
                  iconColor: AppColors.accentGreen,
                ),
                const Divider(height: 24, thickness: 0.8),
              ],
              if (weakCount > 0) ...[
                _NotificationItem(
                  title: 'Weak Passwords Detected',
                  subtitle: '$weakCount credentials use weak patterns. We suggest updating them.',
                  time: 'Just now',
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.accentOrange,
                ),
                const Divider(height: 24, thickness: 0.8),
              ],
              if (reusedCount > 0) ...[
                _NotificationItem(
                  title: 'Reused Passwords Detected',
                  subtitle: '$reusedCount passwords are used across multiple accounts.',
                  time: 'Just now',
                  icon: Icons.copy_rounded,
                  iconColor: AppColors.accentRed,
                ),
                const Divider(height: 24, thickness: 0.8),
              ],
              _NotificationItem(
                title: 'Monitored Breach Report',
                subtitle: 'No security breaches found in your saved email addresses.',
                time: 'Recently',
                icon: Icons.shield_rounded,
                iconColor: AppColors.primary,
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inDays < 1) return '${diff.inHours} hours ago';
    if (diff.inDays < 30) return '${diff.inDays} days ago';
    return '${diff.inDays ~/ 30} months ago';
  }

  Future<void> _showRecentEntryActions(
    BuildContext context,
    WidgetRef ref,
    PasswordEntry entry,
  ) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.folder_open_rounded),
                title: const Text('Open in Vault'),
                onTap: () => Navigator.pop(sheetContext, 'open'),
              ),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('Copy Username'),
                onTap: () => Navigator.pop(sheetContext, 'copyUsername'),
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text('Copy Password'),
                onTap: () => Navigator.pop(sheetContext, 'copyPassword'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.accentRed),
                title: const Text('Delete Entry'),
                textColor: AppColors.accentRed,
                iconColor: AppColors.accentRed,
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
            ],
          ),
        ),
      ),
    );

    if (!context.mounted || selected == null) return;

    switch (selected) {
      case 'open':
        await HapticHelper.medium();
        ref.read(tabIndexProvider.notifier).state = 1;
        break;
      case 'copyUsername':
        await Clipboard.setData(ClipboardData(text: entry.username));
        await HapticHelper.success();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Username copied')),
          );
        }
        break;
      case 'copyPassword':
        await Clipboard.setData(ClipboardData(text: entry.password));
        await HapticHelper.success();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password copied')),
          );
        }
        break;
      case 'delete':
        await HapticHelper.heavy();
        ref.read(vaultProvider.notifier).deleteEntry(entry.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${entry.title} deleted')),
          );
        }
        break;
    }
  }
}

class _NotificationItem extends StatelessWidget {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final String subtitle;
  final String time;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withAlpha(20),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    time,
                    style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: AppTextStyles.bodyMedium.copyWith(color: textMuted),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
