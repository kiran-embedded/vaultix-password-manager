// lib/features/auth/screens/totp_verify_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:otp/otp.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';
import '../providers/auth_provider.dart';

class TotpVerifyScreen extends ConsumerStatefulWidget {
  const TotpVerifyScreen({super.key});

  @override
  ConsumerState<TotpVerifyScreen> createState() => _TotpVerifyScreenState();
}

class _TotpVerifyScreenState extends ConsumerState<TotpVerifyScreen>
    with TickerProviderStateMixin {
  final _codeCtrl = TextEditingController();
  late final AnimationController _shakeCtrl;
  bool _isVerifying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      _shake();
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      await HapticHelper.error();
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    final secret = await ref.read(authStateProvider.notifier).getTotpSecret();
    if (secret == null) {
      // No 2FA secret found — just complete the 2FA step
      ref.read(authStateProvider.notifier).complete2FA();
      if (mounted) context.go('/home');
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    bool ok = false;
    for (final offset in [-30000, 0, 30000]) {
      final expected = OTP.generateTOTPCodeString(
        secret,
        now + offset,
        algorithm: Algorithm.SHA1,
        isGoogle: true,
      );
      if (expected == code) {
        ok = true;
        break;
      }
    }

    if (ok) {
      await HapticHelper.success();
      ref.read(authStateProvider.notifier).complete2FA();
      if (mounted) context.go('/home');
    } else {
      _codeCtrl.clear();
      await HapticHelper.error();
      _shake();
      if (mounted) {
        setState(() {
          _error = 'Incorrect code. Try again.';
          _isVerifying = false;
        });
      }
    }
  }

  void _shake() {
    _shakeCtrl.forward(from: 0).then((_) => _shakeCtrl.reset());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textSub =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Subtle animated background
          Positioned.fill(
            child: CustomPaint(
              painter: _BgPainter(isDark: isDark),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: size.height * 0.9),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withAlpha(60),
                              blurRadius: 30,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.phonelink_lock_rounded,
                          color: Colors.white,
                          size: 42,
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(
                            begin: const Offset(0.8, 0.8),
                            curve: Curves.easeOutBack,
                          ),
                      const SizedBox(height: 28),

                      Text(
                        'Two-Factor Auth',
                        style: AppTextStyles.headingLarge.copyWith(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        'Enter the 6-digit code from\nyour authenticator app.',
                        textAlign: TextAlign.center,
                        style:
                            AppTextStyles.bodyMedium.copyWith(color: textSub),
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 40),

                      // Shake wrapper
                      AnimatedBuilder(
                        animation: _shakeCtrl,
                        builder: (_, child) {
                          final dx = 8 *
                              (_shakeCtrl.value < 0.5
                                  ? _shakeCtrl.value * 2
                                  : (1 - _shakeCtrl.value) * 2) *
                              (_shakeCtrl.value < 0.25
                                  ? 1.0
                                  : _shakeCtrl.value < 0.5
                                      ? -1.0
                                      : _shakeCtrl.value < 0.75
                                          ? 1.0
                                          : -1.0);
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: child,
                          );
                        },
                        child: TextField(
                          controller: _codeCtrl,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          textAlign: TextAlign.center,
                          autofocus: true,
                          style: AppTextStyles.headingLarge.copyWith(
                            color: textColor,
                            letterSpacing: 16,
                            fontFamily: 'monospace',
                            fontSize: 32,
                          ),
                          onSubmitted: (_) => _verify(),
                          onChanged: (v) {
                            if (_error != null) setState(() => _error = null);
                            if (v.length == 6) _verify();
                          },
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          decoration: InputDecoration(
                            hintText: '● ● ● ● ● ●',
                            counterText: '',
                            hintStyle: TextStyle(
                              color: textMuted,
                              letterSpacing: 8,
                              fontSize: 18,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 20, horizontal: 16),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide:
                                  BorderSide(color: AppColors.primary.withAlpha(60), width: 1.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2.5),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: AppColors.accentRed, width: 2),
                            ),
                            focusedErrorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(18),
                              borderSide: const BorderSide(
                                  color: AppColors.accentRed, width: 2.5),
                            ),
                            errorText: _error,
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 28),

                      // Verify button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isVerifying ? null : _verify,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                          ),
                          child: _isVerifying
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2.5),
                                )
                              : Text(
                                  'Verify',
                                  style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ).animate().fadeIn(delay: 250.ms),

                      const SizedBox(height: 20),
                      Text(
                        'Code resets every 30 seconds',
                        style: AppTextStyles.bodySmall.copyWith(color: textMuted),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BgPainter extends CustomPainter {
  _BgPainter({required this.isDark});
  final bool isDark;

  @override
  void paint(Canvas canvas, Size size) {
    final purpleGlow =
        isDark ? const Color(0x206338F6) : const Color(0x0F6338F6);
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.2),
      140,
      Paint()
        ..shader = RadialGradient(
          colors: [purpleGlow, Colors.transparent],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.8, size.height * 0.2),
          radius: 140,
        )),
    );
    canvas.drawCircle(
      Offset(size.width * 0.1, size.height * 0.85),
      100,
      Paint()
        ..shader = RadialGradient(
          colors: [
            isDark ? const Color(0x1836D7FF) : const Color(0x0836D7FF),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(size.width * 0.1, size.height * 0.85),
          radius: 100,
        )),
    );
  }

  @override
  bool shouldRepaint(_BgPainter old) => false;
}
