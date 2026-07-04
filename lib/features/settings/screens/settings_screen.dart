// lib/features/settings/screens/settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../core/services/google_auth_service.dart';
import '../../settings/providers/settings_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vault/providers/vault_provider.dart';
import '../../../core/services/unified_backup_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor   = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg          = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor     = isDark ? AppColors.borderDark : AppColors.borderLight;
    final dividerColor    = isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: AnimationLimiter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: AnimationConfiguration.toStaggeredList(
                duration: const Duration(milliseconds: 280),
                childAnimationBuilder: (w) => SlideAnimation(
                  verticalOffset: 18,
                  child: FadeInAnimation(child: w),
                ),
                children: [
                  // ── Header ──────────────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 4),
                    child: Text(
                      'Settings',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: headerTextColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ),

                  // ── Google Profile Card ──────────────────────────────────
                  _GoogleProfileCard(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: headerTextColor,
                    subColor: subtitleColor,
                  ),
                  const SizedBox(height: 14),
                  _BackupCard(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    textColor: headerTextColor,
                    subColor: subtitleColor,
                  ),
                  const SizedBox(height: 28),

                  // ── Security ────────────────────────────────────────────
                  _SectionLabel('Security', subtitleColor),
                  const SizedBox(height: 10),
                  _Group(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    children: [
                      _SwitchRow(
                        icon: Icons.fingerprint_rounded,
                        iconColor: AppColors.primary,
                        label: 'Biometric Unlock',
                        subtitle: 'Fingerprint or Face ID',
                        value: settings.biometricUnlock,
                        onChanged: notifier.setBiometricUnlock,
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                      ),
                      _Divider(dividerColor),
                      _NavRow(
                        icon: Icons.security_rounded,
                        iconColor: AppColors.accentGreen,
                        label: 'Security Dashboard',
                        subtitle: 'Password health & score',
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                        onTap: () => context.push('/security'),
                      ),
                      _Divider(dividerColor),
                      _TwoFactorRow(
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── Appearance ──────────────────────────────────────────
                  _SectionLabel('Appearance', subtitleColor),
                  const SizedBox(height: 10),
                  _Group(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    children: [
                      _SwitchRow(
                        icon: Icons.dark_mode_rounded,
                        iconColor: const Color(0xFF3F51B5),
                        label: 'Dark Mode',
                        subtitle: 'Switch between light and dark',
                        value: settings.darkMode,
                        onChanged: notifier.setDarkMode,
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),

                  // ── About & Support ─────────────────────────────────────
                  _SectionLabel('About & Support', subtitleColor),
                  const SizedBox(height: 10),
                  _Group(
                    cardBg: cardBg,
                    borderColor: borderColor,
                    children: [
                      _NavRow(
                        icon: Icons.help_outline_rounded,
                        iconColor: const Color(0xFF2196F3),
                        label: 'Help Centre',
                        subtitle: 'FAQ, contact & privacy policy',
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                        onTap: () => context.push('/help'),
                      ),
                      _Divider(dividerColor),
                      _NavRow(
                        icon: Icons.code_rounded,
                        iconColor: Colors.deepPurpleAccent,
                        label: 'Developer',
                        subtitle: 'github.com/kiran-embedded',
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                        onTap: () async {
                          final url = Uri.parse('https://github.com/kiran-embedded');
                          if (await canLaunchUrl(url)) {
                            await launchUrl(url, mode: LaunchMode.externalApplication);
                          }
                        },
                      ),
                      _Divider(dividerColor),
                      _NavRow(
                        icon: Icons.info_outline_rounded,
                        iconColor: Colors.grey,
                        label: 'Version',
                        subtitle: '1.0.0+1 — Vaultix',
                        textColor: headerTextColor,
                        subColor: subtitleColor,
                        onTap: () {},
                        showChevron: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // ── Log Out ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        await HapticHelper.medium();
                        ref.read(authStateProvider.notifier).lock();
                        if (context.mounted) context.go('/');
                      },
                      icon: const Icon(Icons.logout_rounded, color: AppColors.accentRed, size: 20),
                      label: Text(
                        'Log Out',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.accentRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppColors.accentRed.withAlpha(120), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        backgroundColor: AppColors.accentRed.withAlpha(10),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Reset All Data ──────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await HapticHelper.heavy();
                        _showResetWarningDialog(context, ref);
                      },
                      icon: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 20),
                      label: Text(
                        'Factory Reset',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showResetWarningDialog(BuildContext context, WidgetRef ref) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    bool isResetting = false;
    int countdown = 5;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            if (countdown > 0 && !isResetting) {
              Future.delayed(const Duration(seconds: 1), () {
                if (ctx.mounted) {
                  setState(() => countdown--);
                }
              });
            }
            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF16151A) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.accentRed),
                  const SizedBox(width: 8),
                  Text('Reset All Data', style: AppTextStyles.headingMedium.copyWith(color: AppColors.accentRed, fontWeight: FontWeight.bold)),
                ],
              ),
              content: Text(
                'This will permanently delete all your passwords locally and in Google Drive, and sign you out. This action cannot be undone.',
                style: AppTextStyles.bodyMedium.copyWith(color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
              actions: [
                if (!isResetting)
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: AppTextStyles.bodyMedium.copyWith(color: Colors.grey)),
                  ),
                ElevatedButton(
                  onPressed: (countdown > 0 || isResetting) ? null : () async {
                    setState(() => isResetting = true);
                    await HapticHelper.heavy();
                    
                    await ref.read(settingsProvider.notifier).resetAllSettings();
                    await ref.read(vaultProvider.notifier).clearAll();
                    ref.read(authStateProvider.notifier).lock();
                    
                    if (ctx.mounted) {
                      Navigator.pop(ctx);
                      context.go('/');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentRed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isResetting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(countdown > 0 ? 'Wait $countdown...' : 'Confirm Reset'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

// ── Backup Status Card ────────────────────────────────────────────────────────
class _BackupCard extends ConsumerStatefulWidget {
  const _BackupCard({
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
  });

  final Color cardBg, borderColor, textColor, subColor;

  @override
  ConsumerState<_BackupCard> createState() => _BackupCardState();
}

class _BackupCardState extends ConsumerState<_BackupCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(settingsProvider.notifier).refreshBackupMetadata();
    });
  }

  String _formatLastBackup(DateTime? at) {
    if (at == null) return 'Never';
    return DateFormat('d MMM yyyy, h:mm a').format(at.toLocal());
  }

  Future<void> _backupNow() async {
    await HapticHelper.medium();
    final result = await ref.read(settingsProvider.notifier).performBackupNow();
    if (!mounted) return;

    await HapticHelper.success();
    final message = switch ((result.localSuccess, result.gdriveSuccess)) {
      (true, true) => 'Backup saved to device & Google Drive.',
      (true, false) => 'Saved locally. Google Drive backup unavailable.',
      (false, true) => 'Saved to Google Drive. Local storage unavailable.',
      _ => result.error ?? 'Backup failed. Ensure permissions are granted.',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final totpFuture = ref.read(authStateProvider.notifier).isTotpEnabled();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.backup_rounded, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Vault Backup',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: widget.textColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              FutureBuilder<bool>(
                future: totpFuture,
                builder: (context, snap) {
                  final on = snap.data ?? false;
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: (on ? AppColors.accentGreen : AppColors.textMutedDark).withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      on ? '2FA ON' : '2FA OFF',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: on ? AppColors.accentGreen : widget.subColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          _BackupInfoRow(
            icon: Icons.schedule_rounded,
            label: 'Last backup',
            value: _formatLastBackup(settings.lastBackupAt),
            subColor: widget.subColor,
            textColor: widget.textColor,
          ),
          const SizedBox(height: 8),
          _BackupInfoRow(
            icon: Icons.sd_storage_rounded,
            label: 'Local backup',
            value: settings.localBackupFileExists ? 'Available' : 'Not found',
            subColor: widget.subColor,
            textColor: widget.textColor,
            valueColor: settings.localBackupFileExists ? AppColors.accentGreen : widget.subColor,
          ),
          const SizedBox(height: 8),
          _BackupInfoRow(
            icon: Icons.cloud_done_rounded,
            label: 'Google Drive',
            value: settings.hasGdriveBackup ? 'Synced' : 'Not synced',
            subColor: widget.subColor,
            textColor: widget.textColor,
            valueColor: settings.hasGdriveBackup ? AppColors.accentGreen : widget.subColor,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: settings.isBackingUp ? null : _backupNow,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: settings.isBackingUp
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.cloud_upload_rounded, size: 20),
              label: Text(
                settings.isBackingUp ? 'Backing up…' : 'Backup Now',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Includes passwords, recovery key & 2FA settings. Encrypted with your master password.',
            style: AppTextStyles.bodySmall.copyWith(color: widget.subColor, height: 1.35),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 80.ms).slideY(begin: 0.04);
  }
}

class _BackupInfoRow extends StatelessWidget {
  const _BackupInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.subColor,
    required this.textColor,
    this.valueColor,
  });

  final IconData icon;
  final String label, value;
  final Color subColor, textColor;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: subColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall.copyWith(color: subColor),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodySmall.copyWith(
              color: valueColor ?? textColor,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Google Profile Card ───────────────────────────────────────────────────────
class _GoogleProfileCard extends ConsumerStatefulWidget {
  const _GoogleProfileCard({
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subColor,
  });
  final Color cardBg, borderColor, textColor, subColor;

  @override
  ConsumerState<_GoogleProfileCard> createState() => _GoogleProfileCardState();
}

class _GoogleProfileCardState extends ConsumerState<_GoogleProfileCard> {
  bool _loading = false;
  String? _name;
  String? _email;
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadCached();
  }

  Future<void> _loadCached() async {
    final prefs = await SharedPreferences.getInstance();
    final connected = prefs.getBool('gdrive_connected') ?? false;
    if (connected && mounted) {
      setState(() {
        _name     = prefs.getString('gdrive_connected_name');
        _email    = prefs.getString('gdrive_connected_email');
        _photoUrl = prefs.getString('gdrive_connected_photo');
      });
    }
  }

  bool get _isSignedIn => _email != null;

  Future<void> _signIn() async {
    setState(() => _loading = true);
    await HapticHelper.medium();
    try {
      final profile = await GoogleAuthService.instance.signIn();
      if (!mounted) return;

      if (profile != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('gdrive_connected', true);
        await prefs.setString('gdrive_connected_name', profile.name);
        await prefs.setString('gdrive_connected_email', profile.email);
        await prefs.setString('gdrive_connected_photo', profile.photoUrl);
        await ref.read(settingsProvider.notifier)
            .updateGoogleProfile(profile.name, profile.email, profile.photoUrl);
        await ref.read(settingsProvider.notifier).refreshBackupMetadata();
        await HapticHelper.success();
        setState(() {
          _name     = profile.name;
          _email    = profile.email;
          _photoUrl = profile.photoUrl;
          _loading  = false;
        });
      } else {
        if (mounted) setState(() => _loading = false);
      }
    } on GoogleSignInException catch (e) {
      if (mounted) setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await HapticHelper.medium();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Sign out of Google?'),
        content: const Text('Your local vault data will remain safe.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentRed),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await GoogleAuthService.instance.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('gdrive_connected', false);
    await ref.read(settingsProvider.notifier).updateGoogleProfile(null, null, null);
    if (mounted) {
      setState(() { _name = null; _email = null; _photoUrl = null; });
      await HapticHelper.success();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Container(
        height: 88,
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: widget.borderColor, width: 0.8),
        ),
        child: const Center(child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2)),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _isSignedIn
              ? AppColors.accentGreen.withAlpha(60)
              : widget.borderColor,
          width: _isSignedIn ? 1.2 : 0.8,
        ),
        gradient: _isSignedIn
            ? LinearGradient(colors: [
                AppColors.accentGreen.withAlpha(8),
                AppColors.primary.withAlpha(6),
              ])
            : null,
      ),
      child: _isSignedIn ? _SignedInContent(
        name: _name!,
        email: _email!,
        photoUrl: _photoUrl,
        textColor: widget.textColor,
        subColor: widget.subColor,
        onSignOut: _signOut,
      ) : _SignInPrompt(
        textColor: widget.textColor,
        subColor: widget.subColor,
        onSignIn: _signIn,
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }
}

class _SignedInContent extends StatelessWidget {
  const _SignedInContent({
    required this.name,
    required this.email,
    required this.photoUrl,
    required this.textColor,
    required this.subColor,
    required this.onSignOut,
  });
  final String name, email;
  final String? photoUrl;
  final Color textColor, subColor;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(' ').map((w) => w.isEmpty ? '' : w[0].toUpperCase()).take(2).join();

    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: photoUrl == null
                ? const LinearGradient(colors: [AppColors.primary, AppColors.secondary])
                : null,
            border: Border.all(color: AppColors.accentGreen.withAlpha(80), width: 2),
          ),
          child: ClipOval(
            child: photoUrl != null
                ? Image.network(photoUrl!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _initials(initials))
                : _initials(initials),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(name,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accentGreen.withAlpha(60)),
                  ),
                  child: const Icon(Icons.verified_rounded, color: AppColors.accentGreen, size: 11),
                ),
              ]),
              const SizedBox(height: 2),
              Text(email, style: AppTextStyles.bodySmall.copyWith(color: subColor),
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        TextButton(
          onPressed: onSignOut,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.accentRed,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          ),
          child: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ),
      ],
    );
  }

  Widget _initials(String text) => Container(
    color: AppColors.primary.withAlpha(30),
    child: Center(child: Text(text.isEmpty ? 'V' : text,
        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20))),
  );
}

class _SignInPrompt extends StatelessWidget {
  const _SignInPrompt({required this.textColor, required this.subColor, required this.onSignIn});
  final Color textColor, subColor;
  final VoidCallback onSignIn;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onSignIn,
      borderRadius: BorderRadius.circular(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withAlpha(15),
              border: Border.all(color: AppColors.primary.withAlpha(40), width: 1.5),
            ),
            child: const Icon(Icons.account_circle_rounded, color: AppColors.primary, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sign in with Google',
                    style: AppTextStyles.labelMedium.copyWith(
                        color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text('Sync & back up your vault securely',
                    style: AppTextStyles.bodySmall.copyWith(color: subColor)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 16),
          ),
        ],
      ),
    );
  }
}

// ── Shared Primitives ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title, this.color);
  final String title;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Text(
          title.toUpperCase(),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 11,
          ),
        ),
      );
}

class _Group extends StatelessWidget {
  const _Group({required this.cardBg, required this.borderColor, required this.children});
  final Color cardBg, borderColor;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: borderColor, width: 0.8),
        ),
        child: Column(children: children),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.textColor,
    required this.subColor,
  });
  final IconData icon;
  final Color iconColor, textColor, subColor;
  final String label, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            _Badge(icon, iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTextStyles.labelLarge.copyWith(
                          color: textColor, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTextStyles.bodySmall.copyWith(color: subColor)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (v) {
                HapticHelper.medium();
                onChanged(v);
              },
              activeThumbColor: Colors.white,
              activeTrackColor: AppColors.primary,
              inactiveThumbColor: Colors.white,
              inactiveTrackColor: subColor.withAlpha(50),
              trackOutlineColor: WidgetStateProperty.resolveWith(
                (states) => states.contains(WidgetState.selected)
                    ? AppColors.primary.withAlpha(90)
                    : subColor.withAlpha(60),
              ),
              trackOutlineWidth: WidgetStateProperty.all(1.2),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      );
}

class _NavRow extends StatelessWidget {
  const _NavRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.textColor,
    required this.subColor,
    required this.onTap,
    this.showChevron = true,
    this.trailingWidget,
  });
  final IconData icon;
  final Color iconColor, textColor, subColor;
  final String label, subtitle;
  final VoidCallback onTap;
  final bool showChevron;
  final Widget? trailingWidget;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () {
          HapticHelper.light();
          onTap();
        },
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              _Badge(icon, iconColor),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: AppTextStyles.labelLarge.copyWith(
                            color: textColor, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: AppTextStyles.bodySmall.copyWith(color: subColor)),
                  ],
                ),
              ),
              if (trailingWidget != null) trailingWidget!,
              if (showChevron && trailingWidget == null)
                Icon(Icons.chevron_right_rounded, color: subColor, size: 20),
            ],
          ),
        ),
      );
}

class _Badge extends StatelessWidget {
  const _Badge(this.icon, this.color);
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(color: color.withAlpha(20), shape: BoxShape.circle),
        child: Icon(icon, color: color, size: 18),
      );
}

class _Divider extends StatelessWidget {
  const _Divider(this.color);
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 68),
        child: Divider(color: color, height: 1, thickness: 0.7),
      );
}

// ── 2FA Row ───────────────────────────────────────────────────────────────────
class _TwoFactorRow extends ConsumerWidget {
  const _TwoFactorRow({required this.textColor, required this.subColor});
  final Color textColor, subColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider);
    final enabled = auth.hasTotpEnabled;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: [
          const _Badge(Icons.phonelink_lock_rounded, AppColors.accentOrange),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Two-Factor Auth',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  enabled
                      ? 'Authenticator verification is active'
                      : 'Turn on instant login protection',
                  style: AppTextStyles.bodySmall.copyWith(color: subColor),
                ),
              ],
            ),
          ),
          Switch(
            value: enabled,
            onChanged: (value) async {
              if (value) {
                await HapticHelper.medium();
                if (context.mounted) {
                  context.push('/totp-setup');
                }
                return;
              }

              await ref.read(authStateProvider.notifier).disableTotp();
              await HapticHelper.success();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('2FA turned off')),
                );
              }
            },
            activeThumbColor: Colors.white,
            activeTrackColor: AppColors.accentGreen,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: subColor.withAlpha(50),
            trackOutlineColor: WidgetStateProperty.resolveWith(
              (states) => states.contains(WidgetState.selected)
                  ? AppColors.accentGreen.withAlpha(80)
                  : subColor.withAlpha(60),
            ),
            trackOutlineWidth: WidgetStateProperty.all(1.2),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}
