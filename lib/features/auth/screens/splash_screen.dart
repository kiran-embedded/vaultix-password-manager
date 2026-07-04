// lib/features/auth/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../shared/widgets/shield_hero.dart';
import '../../../shared/widgets/neon_glow.dart';
import '../../auth/providers/auth_provider.dart';
import '../../settings/providers/settings_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _bgCtrl;
  final LocalAuthentication _auth = LocalAuthentication();

  bool _scanning = false;
  bool _authenticated = false;
  /// User explicitly chose password — don't auto-re-prompt biometrics
  bool _userChosePassword = false;
  bool _usePasswordMode = false;
  bool _useRecoveryMode = false;

  /// Debounce: timestamp of last biometric attempt (prevents dialog's own
  /// resume event from immediately re-opening another dialog)
  DateTime? _lastBiometricAt;

  final _passwordCtrl = TextEditingController();
  final _recoveryCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerBiometricIfNeeded(isResumeEvent: false);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _bgCtrl.dispose();
    _passwordCtrl.dispose();
    _recoveryCtrl.dispose();
    _newPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    if (_authenticated || _scanning || _userChosePassword) return;

    // Debounce: ignore resumed events within 2s of last biometric attempt
    // (the OS fires resumed when the biometric dialog itself closes)
    if (_lastBiometricAt != null &&
        DateTime.now().difference(_lastBiometricAt!) <
            const Duration(seconds: 2)) {
      return;
    }

    _triggerBiometricIfNeeded(isResumeEvent: true);
  }

  void _triggerBiometricIfNeeded({required bool isResumeEvent}) {
    if (_authenticated || _scanning) return;
    final authState = ref.read(authStateProvider);
    final settings = ref.read(settingsProvider);

    if (authState.status != AuthStatus.locked) return;

    if (settings.biometricUnlock && !_usePasswordMode && !_useRecoveryMode) {
      final delay = isResumeEvent
          ? const Duration(milliseconds: 200)
          : const Duration(milliseconds: 700);
      Future.delayed(delay, () {
        if (mounted && !_authenticated && !_scanning && !_userChosePassword) {
          _authenticate();
        }
      });
    } else if (!settings.biometricUnlock) {
      if (mounted) setState(() => _usePasswordMode = true);
    }
  }

  Future<void> _authenticate() async {
    if (_scanning || _authenticated) return;

    try {
      final bool canBio = await _auth.canCheckBiometrics;
      final bool canAuth = canBio || await _auth.isDeviceSupported();

      if (!canAuth) {
        if (mounted) {
          setState(() {
            _usePasswordMode = true;
            _userChosePassword = true;
          });
        }
        return;
      }

      _lastBiometricAt = DateTime.now();
      if (mounted) setState(() => _scanning = true);

      final bool ok = await _auth.authenticate(
        localizedReason: 'Unlock your Vaultix secure vault',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );

      if (!mounted) return;

      if (ok) {
        _authenticated = true;
        setState(() => _scanning = false);
        await HapticHelper.success();
        ref.read(authStateProvider.notifier).unlockBiometrics();
        context.go('/home');
      } else {
        // User cancelled — show master password, don't auto-retry
        setState(() {
          _scanning = false;
          _usePasswordMode = true;
          _userChosePassword = true;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _scanning = false;
          _usePasswordMode = true;
          _userChosePassword = true;
        });
      }
    }
  }

  Future<void> _handlePasswordUnlock() async {
    final pw = _passwordCtrl.text.trim();
    if (pw.isEmpty) return;
    final success = await ref.read(authStateProvider.notifier).unlock(pw);
    if (!mounted) return;
    if (success) {
      _authenticated = true;
      await HapticHelper.success();
      context.go('/home');
    } else {
      await HapticHelper.error();
      final err = ref.read(authStateProvider).errorMessage ?? 'Incorrect password';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  Future<void> _handleRecoveryReset() async {
    final key = _recoveryCtrl.text.trim();
    final newPw = _newPasswordCtrl.text.trim();
    if (key.isEmpty || newPw.isEmpty) return;
    final success =
        await ref.read(authStateProvider.notifier).resetWithRecoveryKey(key, newPw);
    if (!mounted) return;
    if (success) {
      _authenticated = true;
      await HapticHelper.success();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vault master password reset successfully.')),
      );
      context.go('/home');
    } else {
      await HapticHelper.error();
      final err = ref.read(authStateProvider).errorMessage ?? 'Reset failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final settings = ref.watch(settingsProvider);

    final headerTextColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    ));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _bgCtrl,
            builder: (_, __) => CustomPaint(
              size: size,
              painter:
                  _BackgroundPainter(progress: _bgCtrl.value, isDark: isDark),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Brand
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: 'Vault',
                            style: AppTextStyles.brand.copyWith(
                              foreground: Paint()
                                ..shader = LinearGradient(
                                  colors: [headerTextColor, AppColors.primaryLight],
                                ).createShader(
                                    const Rect.fromLTWH(0, 0, 160, 50)),
                            ),
                          ),
                          TextSpan(
                            text: 'ix',
                            style: AppTextStyles.brand
                                .copyWith(color: AppColors.primary),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 800.ms).slideY(begin: -0.2),
                    const SizedBox(height: 8),
                    Text(
                      AppConstants.appTagline,
                      style:
                          AppTextStyles.bodyMedium.copyWith(color: subtitleColor),
                    ).animate().fadeIn(duration: 600.ms, delay: 100.ms),
                    const SizedBox(height: 48),

                    if (_useRecoveryMode) ...[
                      _RecoveryPanel(
                        recoveryCtrl: _recoveryCtrl,
                        newPasswordCtrl: _newPasswordCtrl,
                        headerTextColor: headerTextColor,
                        textMuted: textMuted,
                        onReset: _handleRecoveryReset,
                        onBack: () {
                          HapticHelper.light();
                          setState(() {
                            _useRecoveryMode = false;
                            _usePasswordMode = true;
                          });
                        },
                      ).animate().fadeIn(duration: 300.ms),
                    ] else if (_usePasswordMode) ...[
                      _PasswordPanel(
                        passwordCtrl: _passwordCtrl,
                        headerTextColor: headerTextColor,
                        textMuted: textMuted,
                        onUnlock: _handlePasswordUnlock,
                        onForgot: () {
                          HapticHelper.light();
                          setState(() => _useRecoveryMode = true);
                        },
                        // Only show biometric option if settings allow it
                        onSwitchToBiometric: settings.biometricUnlock
                            ? () {
                                HapticHelper.light();
                                setState(() {
                                  _usePasswordMode = false;
                                  _userChosePassword = false;
                                  _scanning = false;
                                });
                                _authenticate();
                              }
                            : null,
                      ).animate().fadeIn(duration: 300.ms),
                    ] else ...[
                      Column(
                        children: [
                          ShieldHero(size: 180, isAnimated: !_scanning)
                              .animate()
                              .fadeIn(duration: 800.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 48),
                          PulsingRing(
                            color: _scanning
                                ? AppColors.accentGreen
                                : AppColors.primary,
                            size: 100,
                            child: GestureDetector(
                              onTap: _scanning ? null : _authenticate,
                              child: Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: _scanning
                                        ? [
                                            AppColors.accentGreen.withAlpha(40),
                                            AppColors.accentGreen.withAlpha(20),
                                          ]
                                        : [
                                            AppColors.primary.withAlpha(40),
                                            AppColors.secondary.withAlpha(20),
                                          ],
                                  ),
                                  border: Border.all(
                                    color: _scanning
                                        ? AppColors.accentGreen.withAlpha(100)
                                        : AppColors.primary.withAlpha(80),
                                    width: 1.5,
                                  ),
                                ),
                                child: Icon(
                                  _scanning
                                      ? Icons.check_circle_rounded
                                      : Icons.fingerprint_rounded,
                                  size: 44,
                                  color: _scanning
                                      ? AppColors.accentGreen
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                          ).animate().fadeIn(duration: 600.ms, delay: 200.ms),
                          const SizedBox(height: 24),
                          Text(
                            _scanning ? 'Authenticating…' : 'Tap to Unlock',
                            style: AppTextStyles.labelLarge
                                .copyWith(color: subtitleColor),
                          ),
                          const SizedBox(height: 24),
                          TextButton(
                            onPressed: () {
                              HapticHelper.light();
                              setState(() {
                                _usePasswordMode = true;
                                _userChosePassword = true;
                              });
                            },
                            child: Text(
                              'Use Master Password instead',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Password panel ─────────────────────────────────────────────────────────────
class _PasswordPanel extends StatelessWidget {
  const _PasswordPanel({
    required this.passwordCtrl,
    required this.headerTextColor,
    required this.textMuted,
    required this.onUnlock,
    required this.onForgot,
    this.onSwitchToBiometric,
  });
  final TextEditingController passwordCtrl;
  final Color headerTextColor;
  final Color textMuted;
  final VoidCallback onUnlock;
  final VoidCallback onForgot;
  final VoidCallback? onSwitchToBiometric;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Enter Master Password',
          style: AppTextStyles.headingSmall.copyWith(
            color: headerTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: passwordCtrl,
          obscureText: true,
          autofocus: true,
          style: TextStyle(color: headerTextColor),
          onSubmitted: (_) => onUnlock(),
          decoration: InputDecoration(
            hintText: '••••••••',
            suffixIcon: IconButton(
              icon: const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.primary),
              onPressed: onUnlock,
            ),
          ),
        ),
        const SizedBox(height: 20),
        TextButton(
          onPressed: onForgot,
          child: Text(
            'Forgot Password? Use Recovery Key',
            style: TextStyle(color: textMuted),
          ),
        ),
        if (onSwitchToBiometric != null) ...[
          const SizedBox(height: 4),
          TextButton.icon(
            onPressed: onSwitchToBiometric,
            icon: const Icon(Icons.fingerprint_rounded,
                color: AppColors.primary, size: 20),
            label: const Text(
              'Use Biometric Unlock',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Recovery panel ─────────────────────────────────────────────────────────────
class _RecoveryPanel extends StatelessWidget {
  const _RecoveryPanel({
    required this.recoveryCtrl,
    required this.newPasswordCtrl,
    required this.headerTextColor,
    required this.textMuted,
    required this.onReset,
    required this.onBack,
  });
  final TextEditingController recoveryCtrl;
  final TextEditingController newPasswordCtrl;
  final Color headerTextColor;
  final Color textMuted;
  final VoidCallback onReset;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Emergency Recovery',
          style: AppTextStyles.headingSmall.copyWith(
            color: headerTextColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter your recovery key and set a new password.',
          textAlign: TextAlign.center,
          style: AppTextStyles.bodySmall.copyWith(color: textMuted),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: recoveryCtrl,
          style: TextStyle(color: headerTextColor),
          decoration: const InputDecoration(
            hintText: 'AB7X-F9LQ-K2ME-9TRD',
            labelText: 'Recovery Key',
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: newPasswordCtrl,
          obscureText: true,
          style: TextStyle(color: headerTextColor),
          decoration: const InputDecoration(
            hintText: 'Minimum 6 characters',
            labelText: 'New Master Password',
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: onReset,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Reset Master Password'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: onBack,
          child: const Text('← Back to Password Unlock'),
        ),
      ],
    );
  }
}

// ── Background painter ─────────────────────────────────────────────────────────
class _BackgroundPainter extends CustomPainter {
  _BackgroundPainter({required this.progress, required this.isDark});
  final double progress;
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final purpleGlow =
        isDark ? const Color(0x306338F6) : const Color(0x156338F6);
    final cyanGlow =
        isDark ? const Color(0x2036D7FF) : const Color(0x0A36D7FF);

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.15 + 20 * progress),
      160,
      Paint()
        ..shader = RadialGradient(
          colors: [purpleGlow, Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.2, size.height * 0.15),
          radius: 160,
        )),
    );
    canvas.drawCircle(
      Offset(size.width * 0.85, size.height * 0.75 - 20 * progress),
      120,
      Paint()
        ..shader = RadialGradient(
          colors: [cyanGlow, Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.85, size.height * 0.75),
          radius: 120,
        )),
    );
  }

  @override
  bool shouldRepaint(_BackgroundPainter old) =>
      old.progress != progress || old.isDark != isDark;
}
