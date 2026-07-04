// lib/features/auth/screens/totp_setup_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:base32/base32.dart';
import 'package:otp/otp.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';
import '../providers/auth_provider.dart';

class TotpSetupScreen extends ConsumerStatefulWidget {
  const TotpSetupScreen({super.key});

  @override
  ConsumerState<TotpSetupScreen> createState() => _TotpSetupScreenState();
}

class _TotpSetupScreenState extends ConsumerState<TotpSetupScreen> {
  late final String _secret;
  late final String _otpAuthUri;
  final _codeCtrl = TextEditingController();
  bool _isVerifying = false;
  bool _verified = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _secret = _generateSecret();
    _otpAuthUri =
        'otpauth://totp/Vaultix?secret=$_secret&issuer=Vaultix&algorithm=SHA1&digits=6&period=30';
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  /// Generates a cryptographically-random 20-byte TOTP secret and encodes it
  /// to Base32 (RFC 4648).
  String _generateSecret() {
    final rng = Random.secure();
    final bytes = List<int>.generate(20, (_) => rng.nextInt(256));
    return base32.encode(Uint8List.fromList(bytes)).replaceAll('=', '');
  }

  Future<void> _verify() async {
    final code = _codeCtrl.text.trim();
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit code from your authenticator app.');
      await HapticHelper.error();
      return;
    }

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    // Accept current and ±1 window (30s tolerance)
    final now = DateTime.now().millisecondsSinceEpoch;
    bool ok = false;
    for (final offset in [-30000, 0, 30000]) {
      final expected = OTP.generateTOTPCodeString(
        _secret,
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
      await ref.read(authStateProvider.notifier).enableTotp(_secret);
      setState(() {
        _verified = true;
        _isVerifying = false;
      });
      await HapticHelper.success();
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.pop();
    } else {
      setState(() {
        _error = 'Invalid code. Make sure your device clock is correct.';
        _isVerifying = false;
      });
      await HapticHelper.error();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final textMuted =
        isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final textSub =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final cardBg =
        isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor =
        isDark ? AppColors.borderDark : AppColors.borderLight;

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
          'Enable 2FA',
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
              // Step 1 — header
              _StepHeader(step: 1, label: 'Scan the QR Code', color: textColor)
                  .animate()
                  .fadeIn(duration: 300.ms),
              const SizedBox(height: 6),
              Text(
                'Open Google Authenticator, Microsoft Authenticator, Authy, or 2FAS '
                'and scan the code below.',
                style: AppTextStyles.bodySmall.copyWith(color: textSub),
              ).animate().fadeIn(delay: 50.ms),
              const SizedBox(height: 24),

              // QR Code card
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: borderColor, width: 0.8),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withAlpha(18),
                        blurRadius: 24,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: _otpAuthUri,
                        version: QrVersions.auto,
                        size: 200,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF1A0A2E),
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF6338F6),
                        ),
                        padding: const EdgeInsets.all(12),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Can\'t scan?',
                        style: AppTextStyles.labelSmall.copyWith(color: textMuted),
                      ),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: _secret));
                          HapticHelper.success();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Secret key copied')),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(12),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: AppColors.primary.withAlpha(40),
                                width: 1),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _secret,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.primary,
                                  fontFamily: 'monospace',
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.copy_rounded,
                                  size: 14, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: 100.ms).scale(
                    begin: const Offset(0.9, 0.9),
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 32),

              // Step 2
              _StepHeader(step: 2, label: 'Verify the Code', color: textColor)
                  .animate()
                  .fadeIn(delay: 200.ms),
              const SizedBox(height: 6),
              Text(
                'Enter the 6-digit code shown in your authenticator app.',
                style: AppTextStyles.bodySmall.copyWith(color: textSub),
              ).animate().fadeIn(delay: 250.ms),
              const SizedBox(height: 16),

              // Code input
              TextField(
                controller: _codeCtrl,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: AppTextStyles.headingMedium.copyWith(
                  color: textColor,
                  letterSpacing: 12,
                  fontFamily: 'monospace',
                ),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                onSubmitted: (_) => _verify(),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  hintText: '000000',
                  counterText: '',
                  hintStyle: TextStyle(
                      color: textMuted, letterSpacing: 12, fontFamily: 'monospace'),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: borderColor, width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 2),
                  ),
                  errorText: _error,
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 24),

              // Verify button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: _verified
                    ? ElevatedButton.icon(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accentGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded,
                            color: Colors.white),
                        label: const Text('2FA Enabled!',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    : ElevatedButton(
                        onPressed: _isVerifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _isVerifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Verify & Enable 2FA',
                                style: AppTextStyles.labelLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                      ),
              ).animate().fadeIn(delay: 350.ms),

              const SizedBox(height: 24),

              // Supported apps
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withAlpha(30)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline_rounded,
                        color: AppColors.primary, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Compatible apps: Google Authenticator · Microsoft Authenticator · Authy · 2FAS',
                        style: AppTextStyles.bodySmall.copyWith(color: textSub),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step, required this.label, required this.color});
  final int step;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary],
            ),
          ),
          child: Center(
            child: Text(
              '$step',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTextStyles.headingSmall.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
