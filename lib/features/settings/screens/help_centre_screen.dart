// lib/features/settings/screens/help_centre_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/utils/haptic_helper.dart';

class HelpCentreScreen extends StatefulWidget {
  const HelpCentreScreen({super.key});
  @override
  State<HelpCentreScreen> createState() => _HelpCentreScreenState();
}

class _HelpCentreScreenState extends State<HelpCentreScreen> {
  int? _openFaq;

  void _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subColor  = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final mutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final cardBg    = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderCol = isDark ? AppColors.borderDark : AppColors.borderLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: textColor),
          onPressed: () { HapticHelper.light(); context.pop(); },
        ),
        title: Text('Help Centre',
            style: AppTextStyles.headingSmall.copyWith(
                color: textColor, fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          // ── Hero banner ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(bottom: 28),
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('We\'re here to help',
                          style: AppTextStyles.headingSmall.copyWith(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Browse FAQs or reach out directly',
                          style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withAlpha(200))),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),

          // ── FAQ Section ──────────────────────────────────────────────────
          _SectionHeader('Frequently Asked Questions', textColor)
              .animate().fadeIn(delay: 80.ms),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Column(
              children: [
                ..._faqs.asMap().entries.map((e) {
                  final idx = e.key;
                  final faq = e.value;
                  final isOpen = _openFaq == idx;
                  final isLast = idx == _faqs.length - 1;

                  return Column(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.vertical(
                          top: idx == 0 ? const Radius.circular(18) : Radius.zero,
                          bottom: isLast && !isOpen ? const Radius.circular(18) : Radius.zero,
                        ),
                        onTap: () {
                          HapticHelper.light();
                          setState(() => _openFaq = isOpen ? null : idx);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withAlpha(15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isOpen ? Icons.remove_rounded : Icons.add_rounded,
                                  color: AppColors.primary,
                                  size: 16,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  faq['q']!,
                                  style: AppTextStyles.labelMedium.copyWith(
                                    color: textColor,
                                    fontWeight: isOpen ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstChild: const SizedBox.shrink(),
                        secondChild: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(62, 0, 18, 16),
                          child: Text(
                            faq['a']!,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: subColor,
                              height: 1.6,
                            ),
                          ),
                        ),
                        crossFadeState: isOpen
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 220),
                      ),
                      if (!isLast)
                        Padding(
                          padding: const EdgeInsets.only(left: 62),
                          child: Divider(
                              color: borderCol, height: 1, thickness: 0.6),
                        ),
                    ],
                  );
                }),
              ],
            ),
          ).animate().fadeIn(delay: 120.ms),

          const SizedBox(height: 28),

          // ── Contact Section ──────────────────────────────────────────────
          _SectionHeader('Contact & Support', textColor).animate().fadeIn(delay: 180.ms),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Column(
              children: [
                _ContactRow(
                  icon: Icons.email_rounded,
                  iconColor: const Color(0xFFEA4335),
                  label: 'Email Support',
                  subtitle: 'kiran.cybergrid@gmail.com',
                  onTap: () => _launch('mailto:kiran.cybergrid@gmail.com'),
                  textColor: textColor,
                  subColor: subColor,
                  borderColor: borderCol,
                  showDivider: true,
                ),
                _ContactRow(
                  icon: Icons.chat_rounded,
                  iconColor: const Color(0xFF25D366),
                  label: 'WhatsApp',
                  subtitle: '+91 95264 80039',
                  onTap: () => _launch('https://wa.me/919526480039'),
                  textColor: textColor,
                  subColor: subColor,
                  borderColor: borderCol,
                  showDivider: true,
                ),
                _ContactRow(
                  icon: Icons.code_rounded,
                  iconColor: isDark ? Colors.white : const Color(0xFF24292E),
                  label: 'GitHub',
                  subtitle: 'View source & report issues',
                  onTap: () => _launch('https://github.com/kiran-embedded'),
                  textColor: textColor,
                  subColor: subColor,
                  borderColor: borderCol,
                  showDivider: false,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 220.ms),

          const SizedBox(height: 28),

          // ── Privacy Policy ───────────────────────────────────────────────
          _SectionHeader('Privacy Policy', textColor).animate().fadeIn(delay: 280.ms),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderCol, width: 0.8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrivacySection(
                  icon: Icons.lock_rounded,
                  iconColor: AppColors.primary,
                  title: 'Your Data Stays on Your Device',
                  body: 'Vaultix stores all passwords and vault data exclusively on your device using encrypted secure storage. We do not operate servers, collect telemetry, or have any access to your data.',
                  textColor: textColor,
                  subColor: subColor,
                ),
                _PrivacySection(
                  icon: Icons.fingerprint_rounded,
                  iconColor: AppColors.accentGreen,
                  title: 'Biometric & Master Password',
                  body: 'Your master password is hashed using SHA-256 and never stored in plain text. Biometric authentication uses the device\'s secure enclave and is never transmitted.',
                  textColor: textColor,
                  subColor: subColor,
                ),
                _PrivacySection(
                  icon: Icons.cloud_off_rounded,
                  iconColor: AppColors.accentOrange,
                  title: 'Optional Google Backup',
                  body: 'If you choose to connect Google Drive, your vault data is AES-256 encrypted on-device before upload. Only you, with your master password, can decrypt it.',
                  textColor: textColor,
                  subColor: subColor,
                ),
                _PrivacySection(
                  icon: Icons.visibility_off_rounded,
                  iconColor: AppColors.accentRed,
                  title: 'No Tracking, No Ads',
                  body: 'Vaultix contains zero analytics SDKs, no advertising, and no third-party tracking. Your usage patterns are entirely private.',
                  textColor: textColor,
                  subColor: subColor,
                  isLast: true,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(8),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.primary.withAlpha(25)),
                  ),
                  child: Text(
                    'Last updated: July 2026 · For questions contact kiran.cybergrid@gmail.com',
                    style: AppTextStyles.bodySmall.copyWith(
                        color: mutedColor, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 300.ms),

          const SizedBox(height: 24),

          // ── Footer ───────────────────────────────────────────────────────
          Center(
            child: Column(
              children: [
                Text('Made with ❤️ by Kiran',
                    style: AppTextStyles.bodySmall.copyWith(color: mutedColor)),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _launch('https://github.com/kiran-embedded'),
                  child: Text('github.com/kiran-embedded',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline)),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}

// ── FAQ Data ─────────────────────────────────────────────────────────────────
const _faqs = [
  {
    'q': 'Is my data encrypted?',
    'a': 'Yes. All vault data is encrypted with AES-256 using your master password as the key. Even if someone gets your device, they cannot read your passwords without the master password.',
  },
  {
    'q': 'What if I forget my master password?',
    'a': 'Use the Emergency Recovery Key that was shown to you during setup. Go to the lock screen, tap "Forgot Password? Use Recovery Key", enter your key, and set a new password.',
  },
  {
    'q': 'How does biometric unlock work?',
    'a': 'Biometric unlock uses your device\'s secure enclave to authenticate. Your fingerprint or face data never leaves your device and is never sent to any server.',
  },
  {
    'q': 'What is Two-Factor Auth (2FA/TOTP)?',
    'a': 'TOTP adds a time-based 6-digit code requirement after your password. Scan the QR code in Settings → Two-Factor Auth with Google Authenticator, Authy, or any TOTP app.',
  },
  {
    'q': 'How do I back up my vault?',
    'a': 'Sign in with Google in Settings and your vault will be encrypted and uploaded to your personal Google Drive. Only you can decrypt it using your master password.',
  },
  {
    'q': 'Can I use Vaultix offline?',
    'a': 'Absolutely. Vaultix works entirely offline. Google sign-in and backup are optional features. All core password management functions work without an internet connection.',
  },
  {
    'q': 'How do I generate a strong password?',
    'a': 'Go to the Generator tab. Choose your desired length (16+ recommended), enable Uppercase, Lowercase, Digits, and Symbols, then tap "Generate Password". Copy and save it directly.',
  },
];

// ── Widgets ──────────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title, this.color);
  final String title;
  final Color color;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(title.toUpperCase(),
        style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
            fontSize: 11)),
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.subtitle,
    required this.onTap,
    required this.textColor,
    required this.subColor,
    required this.borderColor,
    required this.showDivider,
  });
  final IconData icon;
  final Color iconColor, textColor, subColor, borderColor;
  final String label, subtitle;
  final VoidCallback onTap;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () { HapticHelper.light(); onTap(); },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withAlpha(18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(label,
                          style: AppTextStyles.labelMedium.copyWith(
                              color: textColor, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTextStyles.bodySmall.copyWith(color: subColor)),
                    ],
                  ),
                ),
                Icon(Icons.open_in_new_rounded, color: subColor, size: 16),
              ],
            ),
          ),
        ),
        if (showDivider)
          Padding(
            padding: const EdgeInsets.only(left: 70),
            child: Divider(color: borderColor, height: 1, thickness: 0.6),
          ),
      ],
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
    required this.textColor,
    required this.subColor,
    this.isLast = false,
  });
  final IconData icon;
  final Color iconColor, textColor, subColor;
  final String title, body;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 16 : 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: iconColor.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTextStyles.labelMedium.copyWith(
                        color: textColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(body,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: subColor, height: 1.55)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
