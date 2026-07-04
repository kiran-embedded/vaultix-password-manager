// lib/features/auth/screens/setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../core/services/google_auth_service.dart';
import '../../../core/services/unified_backup_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../vault/providers/vault_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../../../core/services/local_backup_service.dart';

class SetupScreen extends HookConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordCtrl = useTextEditingController();
    final confirmCtrl = useTextEditingController();
    final acceptedKey = useState(false);
    final showPassword = useState(false);
    final isRestoreMode = useState(false);
    final isLocalRestoreMode = useState(false);
    final hasLocalBackupState = useState(false);

    useEffect(() {
      LocalBackupService.instance.hasLocalBackup().then((val) {
        hasLocalBackupState.value = val;
      });
      return null;
    }, []);

    final auth = ref.watch(authStateProvider);
    final notifier = ref.read(authStateProvider.notifier);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    Future<void> handleSetup() async {
      final pw = passwordCtrl.text.trim();
      final confirm = confirmCtrl.text.trim();

      if (pw.isEmpty || pw.length < 6) {
        await HapticHelper.error();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password must be at least 6 characters.')),
          );
        }
        return;
      }
      if (pw != confirm) {
        await HapticHelper.error();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Passwords do not match.')),
          );
        }
        return;
      }

      await HapticHelper.success();
      final success = await notifier.setupMasterPassword(pw, auth.recoveryKey ?? '');
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vault secure enclave initialized successfully.')),
        );
      }
    }

    // ── Restore from Google Drive flow ────────────────────────────────────────
    if (isRestoreMode.value) {
      return _RestoreFromDriveScreen(
        onBack: () => isRestoreMode.value = false,
        onRestored: (password) async {
          isRestoreMode.value = false;
          await ref.read(vaultProvider.notifier).init();
          await ref.read(authStateProvider.notifier).initializeWithRestoredPassword(password);
          UnifiedBackupService.instance.performBackup();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vault restored from Google Drive!')),
            );
          }
        },
      );
    }

    // ── Restore from Local Backup flow ───────────────────────────────────────
    if (isLocalRestoreMode.value) {
      return _RestoreFromLocalScreen(
        onBack: () => isLocalRestoreMode.value = false,
        onRestored: (password) async {
          isLocalRestoreMode.value = false;
          await ref.read(vaultProvider.notifier).init();
          await ref.read(authStateProvider.notifier).initializeWithRestoredPassword(password);
          UnifiedBackupService.instance.performBackup();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Vault restored successfully from local backup!')),
            );
          }
        },
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // ── Header ─────────────────────────────────────────────────────
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: 'Secure ',
                      style: AppTextStyles.headingLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const TextSpan(
                      text: 'Enclave',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 8),
              Text(
                'Set up your Master Password to protect your digital vault.',
                style: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 32),

              // ── "Local Backup Found" card ──────────────────────────────────
              if (hasLocalBackupState.value) ...[
                GestureDetector(
                  onTap: () async {
                    await HapticHelper.medium();
                    isLocalRestoreMode.value = true;
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accentGreen.withAlpha(20),
                          AppColors.primary.withAlpha(10),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.accentGreen.withAlpha(60), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.sd_storage_rounded,
                              color: AppColors.accentGreen, size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    'Local Backup Found',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGreen.withAlpha(20),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'AUTO',
                                      style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.accentGreen,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Highly encrypted local file detected on device',
                                style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_rounded,
                            color: AppColors.accentGreen, size: 20),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1),
                const SizedBox(height: 16),
              ],

              // ── "Already a User?" card ──────────────────────────────────────
              GestureDetector(
                onTap: () async {
                  await HapticHelper.medium();
                  isRestoreMode.value = true;
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withAlpha(20),
                        AppColors.secondary.withAlpha(10),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withAlpha(60), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.cloud_download_rounded,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Already a Vaultix user?',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: textColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Restore your vault from Google Drive backup',
                              style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.primary, size: 22),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

              const SizedBox(height: 28),

              // ── New user password setup ─────────────────────────────────────
              Text(
                'Create New Vault',
                style: AppTextStyles.labelMedium.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 16),

              Text(
                'Master Password',
                style: AppTextStyles.labelMedium.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: !showPassword.value,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Minimum 6 characters',
                  suffixIcon: IconButton(
                    icon: Icon(
                      showPassword.value
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: textMuted,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticHelper.light();
                      showPassword.value = !showPassword.value;
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'Confirm Password',
                style: AppTextStyles.labelMedium.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmCtrl,
                obscureText: !showPassword.value,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(hintText: 'Re-enter your password'),
              ),
              const SizedBox(height: 32),

              // ── Recovery Key Banner ─────────────────────────────────────────
              Text(
                '🔑 Emergency Recovery Key',
                style: AppTextStyles.labelMedium.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Store this key offline. It\'s your only way back if you forget your master password.',
                style: AppTextStyles.bodySmall.copyWith(color: textMuted),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 0.8),
                ),
                child: Column(
                  children: [
                    Text(
                      auth.recoveryKey ?? '---- ---- ---- ----',
                      style: AppTextStyles.headingMedium.copyWith(
                        color: AppColors.primary,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        HapticHelper.success();
                        Clipboard.setData(ClipboardData(text: auth.recoveryKey ?? ''));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Recovery key copied to clipboard.')),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary.withAlpha(20),
                        foregroundColor: AppColors.primary,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy Key'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              GestureDetector(
                onTap: () {
                  HapticHelper.light();
                  acceptedKey.value = !acceptedKey.value;
                },
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: acceptedKey.value,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        HapticHelper.light();
                        acceptedKey.value = val ?? false;
                      },
                    ),
                    Expanded(
                      child: Text(
                        'I have saved my emergency recovery key safely.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: acceptedKey.value ? textColor : textMuted,
                          fontWeight:
                              acceptedKey.value ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: acceptedKey.value ? handleSetup : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Initialize Secure Vault',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Restore from Google Drive screen ─────────────────────────────────────────
class _RestoreFromDriveScreen extends ConsumerStatefulWidget {
  const _RestoreFromDriveScreen({
    required this.onBack,
    required this.onRestored,
  });
  final VoidCallback onBack;
  final void Function(String password) onRestored;

  @override
  ConsumerState<_RestoreFromDriveScreen> createState() =>
      _RestoreFromDriveScreenState();
}

class _RestoreFromDriveScreenState extends ConsumerState<_RestoreFromDriveScreen> {
  final _passwordCtrl = TextEditingController();
  bool _isLoading = false;
  bool _isConnected = false;
  String? _displayName;
  String? _email;
  String? _photoUrl;
  String? _backupPayload;

  @override
  void initState() {
    super.initState();
    _loadExistingProfile();
  }

  Future<void> _loadExistingProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final connected = prefs.getBool('gdrive_connected') ?? false;
    if (connected) {
      final cached = prefs.getString('gdrive_backup_payload');
      final remote = await UnifiedBackupService.instance.fetchGdriveBackupString();
      if (!mounted) return;
      setState(() {
        _isConnected = true;
        _displayName = prefs.getString('gdrive_connected_name');
        _email = prefs.getString('gdrive_connected_email');
        _photoUrl = prefs.getString('gdrive_connected_photo');
        _backupPayload = remote ?? cached;
      });
    }
  }

  Future<void> _connect() async {
    setState(() => _isLoading = true);
    await HapticHelper.medium();

    try {
      final profile = await GoogleAuthService.instance.signIn();

      if (profile == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      await ref.read(settingsProvider.notifier).updateGoogleProfile(
            profile.name, profile.email, profile.photoUrl);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('gdrive_connected', true);
      await prefs.setString('gdrive_connected_name', profile.name);
      await prefs.setString('gdrive_connected_email', profile.email);
      await prefs.setString('gdrive_connected_photo', profile.photoUrl);
      final payload = await UnifiedBackupService.instance.fetchGdriveBackupString();

      if (!mounted) return;
      await HapticHelper.success();
      setState(() {
        _isConnected = true;
        _displayName = profile.name;
        _email = profile.email;
        _photoUrl = profile.photoUrl;
        _backupPayload = payload;
        _isLoading = false;
      });
    } on GoogleSignInException catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google sign-in failed: $e')),
        );
      }
    }
  }


  Future<void> _restore() async {
    if (_passwordCtrl.text.trim().isEmpty) {
      await HapticHelper.error();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your master password to decrypt the backup.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final password = _passwordCtrl.text.trim();
      var backupString = _backupPayload;
      backupString ??= await UnifiedBackupService.instance.fetchGdriveBackupString();

      if (backupString == null || backupString.isEmpty) {
        await HapticHelper.error();
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No backup found on this account. Try a different account.'),
            ),
          );
        }
        return;
      }

      final payload = UnifiedBackupService.instance.decryptBackup(backupString, password);
      await UnifiedBackupService.instance.applyRestoredPayload(payload, password);
      await HapticHelper.success();
      if (mounted) widget.onRestored(password);
    } catch (_) {
      await HapticHelper.error();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Decryption failed. Check your master password.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cardBg = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () {
            HapticHelper.light();
            widget.onBack();
          },
        ),
        title: Text(
          'Restore from Drive',
          style: AppTextStyles.headingSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Google Drive branding card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: borderColor, width: 0.8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.cloud_done_rounded,
                                color: AppColors.primary, size: 26),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Google Drive Restore',
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Recover all your saved passwords',
                                  style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    if (!_isConnected) ...[
                      // ── Single Google Sign-In button ─────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _connect,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          icon: const Icon(Icons.account_circle_rounded,
                              size: 22, color: Colors.white),
                          label: const Text(
                            'Sign in with Google',
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          'Choose your Google account to find your backup',
                          style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    ] else ...[
                      // ── Connected state ─────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.accentGreen.withAlpha(60), width: 1),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundColor: AppColors.primary.withAlpha(20),
                              backgroundImage: _photoUrl != null
                                  ? NetworkImage(_photoUrl!)
                                  : null,
                              child: _photoUrl == null
                                  ? const Icon(Icons.person_rounded,
                                      color: AppColors.primary)
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _displayName ?? 'Google User',
                                    style: AppTextStyles.labelMedium.copyWith(
                                      color: textColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    _email ?? '',
                                    style:
                                        AppTextStyles.bodySmall.copyWith(color: textMuted),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.check_circle_rounded,
                                color: AppColors.accentGreen, size: 22),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      if (_backupPayload != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: AppColors.accentGreen.withAlpha(40), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.backup_rounded,
                                  color: AppColors.accentGreen, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Backup found on Google Drive ✓',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.accentGreen,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Master Password',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: true,
                          style: TextStyle(color: textColor),
                          decoration: InputDecoration(
                            hintText: 'Enter the password you used to encrypt the backup',
                            prefixIcon: const Icon(Icons.lock_outline_rounded),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.arrow_forward_rounded,
                                  color: AppColors.primary),
                              onPressed: _restore,
                            ),
                          ),
                          onSubmitted: (_) => _restore(),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _restore,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.settings_backup_restore_rounded),
                            label: const Text(
                              'Decrypt & Restore Vault',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.orange.withAlpha(15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.withAlpha(40), width: 1),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'No backup found on this account.',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: Colors.orange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            HapticHelper.light();
                            setState(() {
                              _isConnected = false;
                              _displayName = null;
                              _email = null;
                              _photoUrl = null;
                            });
                          },
                          child: const Text('Try a different account'),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ── Restore from Local Encrypted Backup Screen ──────────────────────────────
class _RestoreFromLocalScreen extends HookConsumerWidget {
  const _RestoreFromLocalScreen({
    required this.onBack,
    required this.onRestored,
  });

  final VoidCallback onBack;
  final Function(String) onRestored;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final passwordCtrl = useTextEditingController();
    final errorMessage = useState<String?>(null);
    final isLoading = useState(false);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSecondary = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    Future<void> handleRestore() async {
      final pw = passwordCtrl.text.trim();
      if (pw.isEmpty) {
        errorMessage.value = 'Please enter your master password.';
        await HapticHelper.error();
        return;
      }

      isLoading.value = true;
      errorMessage.value = null;
      await HapticHelper.medium();

      // Attempt to decrypt and restore from local backup
      final success = await LocalBackupService.instance.restoreFromLocalBackup(pw);
      isLoading.value = false;

      if (success) {
        await HapticHelper.success();
        onRestored(pw);
      } else {
        await HapticHelper.error();
        errorMessage.value = 'Failed to restore. Please verify your master password.';
      }
    }

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
            onBack();
          },
        ),
        title: Text(
          'Restore Local Backup',
          style: AppTextStyles.headingSmall.copyWith(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.accentGreen.withAlpha(12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.accentGreen.withAlpha(40), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sd_storage_rounded, color: AppColors.accentGreen, size: 24),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Encrypted Backup Detected',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Enter the password that was used to encrypt this vault. Decryption happens entirely offline.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 350.ms),
              const SizedBox(height: 28),
              Text(
                'Master Password',
                style: AppTextStyles.labelMedium.copyWith(
                  color: textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: passwordCtrl,
                obscureText: true,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Enter your master password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: isLoading.value
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                        )
                      : IconButton(
                          icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                          onPressed: handleRestore,
                        ),
                ),
                onSubmitted: (_) => handleRestore(),
              ).animate().fadeIn(delay: 100.ms),
              if (errorMessage.value != null) ...[
                const SizedBox(height: 12),
                Text(
                  errorMessage.value!,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentRed),
                ).animate().shake(duration: 300.ms),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: isLoading.value ? null : handleRestore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.settings_backup_restore_rounded),
                  label: Text(
                    isLoading.value ? 'Restoring...' : 'Decrypt & Restore',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}
