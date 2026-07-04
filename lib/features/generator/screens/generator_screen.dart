// lib/features/generator/screens/generator_screen.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haptic_helper.dart';
import '../providers/generator_provider.dart';
import '../widgets/option_toggle.dart';
import '../widgets/strength_indicator.dart';
import '../widgets/shuffling_text.dart';

class GeneratorScreen extends ConsumerWidget {
  const GeneratorScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => const _GeneratorBody();
}

class _GeneratorBody extends ConsumerStatefulWidget {
  const _GeneratorBody();
  @override
  ConsumerState<_GeneratorBody> createState() => _GeneratorBodyState();
}

class _GeneratorBodyState extends ConsumerState<_GeneratorBody>
    with TickerProviderStateMixin {
  late final AnimationController _shimmerCtrl;
  late final AnimationController _burstCtrl;
  late final AnimationController _btnCtrl;
  bool _generating = false;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _burstCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _btnCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    _burstCtrl.dispose();
    _btnCtrl.dispose();
    super.dispose();
  }

  Future<void> _generate() async {
    setState(() => _generating = true);
    await HapticHelper.medium();
    ref.read(generatorProvider.notifier).generate();
    _shimmerCtrl.forward(from: 0).then((_) => _shimmerCtrl.reset());
    _btnCtrl
        .forward()
        .then((_) => _btnCtrl.reverse())
        .then((_) => setState(() => _generating = false));
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    await HapticHelper.success();
    ref.read(generatorProvider.notifier).markCopied();
    _burstCtrl.forward(from: 0).then((_) => _burstCtrl.reset());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(generatorProvider);
    final notifier = ref.read(generatorProvider.notifier);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final headerTextColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final fillDisplayColor = isDark ? const Color(0xFF1E1D24) : const Color(0xFFF1F3FA);
    final borderDisplayColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final subColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Generator',
            style: TextStyle(color: headerTextColor, fontWeight: FontWeight.bold, fontSize: 22)),
        actions: [
          AnimatedBuilder(
            animation: _btnCtrl,
            builder: (_, child) => Transform.rotate(
              angle: _btnCtrl.value * 2 * pi,
              child: child,
            ),
            child: GestureDetector(
              onTap: _generate,
              child: const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Icon(Icons.refresh_rounded, color: AppColors.primary, size: 26),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Animated password display ──────────────────────────
              _ShimmerPasswordDisplay(
                password: state.generated,
                justCopied: state.justCopied,
                backgroundColor: fillDisplayColor,
                borderColor: borderDisplayColor,
                textColor: headerTextColor,
                shimmerCtrl: _shimmerCtrl,
                burstCtrl: _burstCtrl,
                onCopy: () => _copy(state.generated),
              ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.15),
  
              const SizedBox(height: 10),
  
              // ── Strength indicator ─────────────────────────────────
              StrengthIndicator(strength: state.strength)
                  .animate()
                  .fadeIn(delay: 80.ms),
  
              const SizedBox(height: 16),
  
              // ── Length slider ──────────────────────────────────────
              _LengthSlider(
                length: state.length,
                onChanged: notifier.setLength,
                isDark: isDark,
                textColor: headerTextColor,
                subColor: subColor,
              ).animate().fadeIn(delay: 140.ms).slideY(begin: 0.15),
  
              const SizedBox(height: 16),
  
              // ── Character set toggles (Compact Wrap) ───────────
              Text('Character Set',
                  style: AppTextStyles.labelLarge.copyWith(
                      color: headerTextColor, fontWeight: FontWeight.bold))
                  .animate()
                  .fadeIn(delay: 180.ms),
              const SizedBox(height: 16),
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _CharChip(label: 'A-Z (Upper)', value: state.useUpper, onChanged: (v) { notifier.toggleUpper(v); HapticHelper.light(); }, isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _CharChip(label: 'a-z (Lower)', value: state.useLower, onChanged: (v) { notifier.toggleLower(v); HapticHelper.light(); }, isDark: isDark)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(child: _CharChip(label: '0-9 (Digits)', value: state.useDigits, onChanged: (v) { notifier.toggleDigits(v); HapticHelper.light(); }, isDark: isDark)),
                      const SizedBox(width: 12),
                      Expanded(child: _CharChip(label: '!@# (Symbols)', value: state.useSymbols, onChanged: (v) { notifier.toggleSymbols(v); HapticHelper.light(); }, isDark: isDark)),
                    ],
                  ),
                ],
              ).animate().fadeIn(delay: 200.ms),
  
              const Spacer(),
  
              // ── Generate CTA ───────────────────────────────────────
              AnimatedBuilder(
                animation: _btnCtrl,
                builder: (_, child) => Transform.scale(
                  scale: 1.0 - (_btnCtrl.value * 0.05),
                  child: child,
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _generate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                      if (_generating)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      else
                        const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                      const SizedBox(width: 10),
                      Text(
                        _generating ? 'Generating...' : 'Generate Password',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(delay: 340.ms),

            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
}
}

// ── Shimmer Password Display ──────────────────────────────────────────────────
class _ShimmerPasswordDisplay extends StatelessWidget {
  const _ShimmerPasswordDisplay({
    required this.password,
    required this.justCopied,
    required this.backgroundColor,
    required this.borderColor,
    required this.textColor,
    required this.shimmerCtrl,
    required this.burstCtrl,
    required this.onCopy,
  });

  final String password;
  final bool justCopied;
  final Color backgroundColor, borderColor, textColor;
  final AnimationController shimmerCtrl;
  final AnimationController burstCtrl;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shimmerCtrl,
      builder: (_, child) {
        final shimmerOffset = Alignment(
          -2 + shimmerCtrl.value * 4,
          0,
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.fromLTRB(20, 18, 14, 18),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: justCopied
                  ? AppColors.accentGreen.withAlpha(120)
                  : shimmerCtrl.value > 0
                      ? AppColors.primary.withAlpha(120)
                      : borderColor,
              width: 1.2,
            ),
          ),
          child: Stack(
            children: [
              // Shimmer overlay
              if (shimmerCtrl.value > 0)
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: ShaderMask(
                      blendMode: BlendMode.srcATop,
                      shaderCallback: (bounds) => LinearGradient(
                        begin: shimmerOffset,
                        end: Alignment(shimmerOffset.x + 1.5, 0),
                        colors: [
                          Colors.transparent,
                          AppColors.primary.withAlpha(25),
                          Colors.transparent,
                        ],
                      ).createShader(bounds),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: ShufflingText(
                      text: password,
                      style: AppTextStyles.monospace.copyWith(
                        fontSize: 16,
                        letterSpacing: 1.2,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  _CopyButton(
                    justCopied: justCopied,
                    burstCtrl: burstCtrl,
                    onCopy: onCopy,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Animated Copy Button with particle burst ─────────────────────────────────
class _CopyButton extends StatelessWidget {
  const _CopyButton({
    required this.justCopied,
    required this.burstCtrl,
    required this.onCopy,
  });
  final bool justCopied;
  final AnimationController burstCtrl;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: burstCtrl,
      builder: (_, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Burst rings
            if (burstCtrl.value > 0) ...[
              for (var i = 0; i < 3; i++)
                Transform.scale(
                  scale: 1 + burstCtrl.value * (1.2 + i * 0.4),
                  child: Opacity(
                    opacity: (1 - burstCtrl.value).clamp(0.0, 1.0),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.accentGreen.withAlpha(60),
                          width: 1.5 - i * 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
            GestureDetector(
              onTap: onCopy,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: justCopied
                      ? AppColors.accentGreen.withAlpha(25)
                      : AppColors.primary.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  justCopied ? Icons.check_rounded : Icons.copy_rounded,
                  color: justCopied ? AppColors.accentGreen : AppColors.primary,
                  size: 20,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ── Length Slider ─────────────────────────────────────────────────────────────
class _LengthSlider extends StatelessWidget {
  const _LengthSlider({
    required this.length,
    required this.onChanged,
    required this.isDark,
    required this.textColor,
    required this.subColor,
  });
  final int length;
  final ValueChanged<int> onChanged;
  final bool isDark;
  final Color textColor, subColor;

  String get _strengthLabel {
    if (length < 8) return 'Very Short';
    if (length < 12) return 'Short';
    if (length < 16) return 'Good';
    if (length < 24) return 'Strong';
    return 'Very Strong';
  }

  Color get _strengthColor {
    if (length < 8) return AppColors.accentRed;
    if (length < 12) return AppColors.accentOrange;
    if (length < 16) return Colors.amber;
    if (length < 24) return AppColors.accentGreen;
    return const Color(0xFF00E5FF);
  }

  @override
  Widget build(BuildContext context) {
    final bubbleBgColor = isDark ? const Color(0xFF201B3D) : const Color(0xFFF1EEFF);
    final bubbleTextColor = isDark ? const Color(0xFF9F83FF) : AppColors.primary;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Password Length',
                style: AppTextStyles.labelLarge.copyWith(
                    color: textColor, fontWeight: FontWeight.bold)),
            Row(
              children: [
                Text(_strengthLabel,
                    style: AppTextStyles.labelSmall.copyWith(
                        color: _strengthColor, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: bubbleBgColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('$length',
                      style: AppTextStyles.labelMedium.copyWith(
                          color: bubbleTextColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 14),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 22),
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: isDark
                ? AppColors.primary.withAlpha(25)
                : AppColors.primary.withAlpha(20),
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withAlpha(25),
          ),
          child: Slider(
            value: length.toDouble(),
            min: 4,
            max: 64,
            divisions: 60,
            onChanged: (v) {
              final val = v.round();
              if (val != length) {
                onChanged(val);
                HapticHelper.selection();
              }
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('4', style: AppTextStyles.labelSmall.copyWith(color: subColor)),
            Text('Recommended: 16–20',
                style: AppTextStyles.labelSmall.copyWith(color: subColor)),
            Text('64', style: AppTextStyles.labelSmall.copyWith(color: subColor)),
          ],
        ),
      ],
    );
  }
}

// ── Char Chip ─────────────────────────────────────────────────────────────────
class _CharChip extends StatelessWidget {
  const _CharChip({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1E1D24) : const Color(0xFFF1F3FA);
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;

    return GestureDetector(
      onTap: () => onChanged(!value),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 34),
        decoration: BoxDecoration(
          color: value ? AppColors.primary.withAlpha(20) : bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: value ? AppColors.primary : borderColor,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                value ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                key: ValueKey(value),
                color: value ? AppColors.primary : (isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                size: 24,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: value ? AppColors.primary : textColor,
                  fontWeight: value ? FontWeight.bold : FontWeight.normal,
                  fontSize: 15,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
