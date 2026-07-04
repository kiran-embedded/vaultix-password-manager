// lib/features/vault/widgets/password_card.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/haptic_helper.dart';
import '../../../shared/widgets/brand_avatar.dart';
import '../models/password_entry.dart';

/// Swipeable, expandable password card with copy and delete actions.
class PasswordCard extends StatefulWidget {
  const PasswordCard({
    super.key,
    required this.entry,
    required this.onFavTap,
    required this.onDelete,
  });

  final PasswordEntry entry;
  final VoidCallback onFavTap;
  final VoidCallback onDelete;

  @override
  State<PasswordCard> createState() => _PasswordCardState();
}

class _PasswordCardState extends State<PasswordCard>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;
  bool _passwordVisible = false;
  bool _justCopied = false;
  Timer? _clipboardTimer;

  @override
  void dispose() {
    _clipboardTimer?.cancel();
    super.dispose();
  }

  Future<void> _copyPassword() async {
    await Clipboard.setData(ClipboardData(text: widget.entry.password));
    await HapticHelper.success();
    setState(() => _justCopied = true);

    _clipboardTimer?.cancel();
    _clipboardTimer = Timer(const Duration(seconds: 30), () async {
      try {
        final currentData = await Clipboard.getData(Clipboard.kTextPlain);
        if (currentData?.text == widget.entry.password) {
          await Clipboard.setData(const ClipboardData(text: ''));
        }
      } catch (_) {}
    });

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _justCopied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final cardBgColor = isDark ? AppColors.surfaceCardDark : AppColors.surfaceCardLight;
    final borderColor = isDark ? AppColors.borderDark : AppColors.borderLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final iconMutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;

    return Dismissible(
      key: ValueKey(widget.entry.id),
      direction: DismissDirection.endToStart,
      background: _DeleteBackground(),
      confirmDismiss: (_) async {
        await HapticHelper.medium();
        if (!context.mounted) return false;
        return await showDialog<bool>(
          context: context,
          builder: (_) => _DeleteDialog(title: widget.entry.title),
        );
      },
      onDismissed: (_) => widget.onDelete(),
      child: AnimatedContainer(
        duration: AppConstants.durationNormal,
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: cardBgColor,
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          border: Border.all(
            color: _expanded ? AppColors.primary.withAlpha(120) : borderColor,
            width: _expanded ? 1.2 : 0.8,
          ),
          boxShadow: _expanded
              ? [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Column(
          children: [
            // ── Main row ────────────────────────────────────────
            InkWell(
              onTap: () {
                HapticHelper.light();
                setState(() => _expanded = !_expanded);
              },
              borderRadius: BorderRadius.circular(AppConstants.radiusMd),
              splashColor: AppColors.primary.withAlpha(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    BrandAvatar(entry: widget.entry),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entry.title,
                            style: AppTextStyles.labelLarge.copyWith(color: textColor),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.entry.username,
                            style: AppTextStyles.bodySmall.copyWith(color: subtitleColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        HapticHelper.light();
                        widget.onFavTap();
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          widget.entry.isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                          color: widget.entry.isFavorite
                              ? const Color(0xFFFFB300)
                              : iconMutedColor,
                          size: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppConstants.durationNormal,
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: iconMutedColor,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded details ─────────────────────────────────
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: _ExpandedDetails(
                entry: widget.entry,
                passwordVisible: _passwordVisible,
                justCopied: _justCopied,
                onToggleVisibility: () {
                  HapticHelper.light();
                  setState(() => _passwordVisible = !_passwordVisible);
                },
                onCopy: _copyPassword,
              ),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppConstants.durationNormal,
              sizeCurve: Curves.easeOutCubic,
            ),
          ],
        ),
      ),
    );
  }
}

class _ExpandedDetails extends StatelessWidget {
  const _ExpandedDetails({
    required this.entry,
    required this.passwordVisible,
    required this.justCopied,
    required this.onToggleVisibility,
    required this.onCopy,
  });

  final PasswordEntry entry;
  final bool passwordVisible;
  final bool justCopied;
  final VoidCallback onToggleVisibility;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final iconMutedColor = isDark ? AppColors.textMutedDark : AppColors.textMutedLight;
    final dividerColor = isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final textColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final subtitleColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        children: [
          Divider(color: dividerColor, height: 16),

          // Password row
          Row(
            children: [
              Icon(
                entry.category == EntryCategory.card
                    ? Icons.credit_card_rounded
                    : entry.category == EntryCategory.wifi
                        ? Icons.wifi_password_rounded
                        : Icons.lock_rounded,
                color: iconMutedColor,
                size: 14,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  passwordVisible
                      ? entry.password
                      : '•' * entry.password.length.clamp(0, 18),
                  style: AppTextStyles.bodySmall.copyWith(
                    letterSpacing: passwordVisible ? 0.5 : 2,
                    color: textColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Eye toggle
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onToggleVisibility,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    passwordVisible
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: iconMutedColor,
                    size: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Copy button
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onCopy,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: justCopied
                        ? AppColors.accentGreen.withAlpha(30)
                        : AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: justCopied
                          ? AppColors.accentGreen.withAlpha(80)
                          : AppColors.primary.withAlpha(50),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    justCopied ? 'Copied!' : 'Copy',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: justCopied ? AppColors.accentGreen : AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),

          if (entry.website != null && entry.website!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  entry.category == EntryCategory.card
                      ? Icons.date_range_rounded
                      : entry.category == EntryCategory.wifi
                          ? Icons.security_rounded
                          : Icons.language_rounded,
                  color: iconMutedColor,
                  size: 14,
                ),
                const SizedBox(width: 8),
                Text(
                  entry.website!,
                  style: AppTextStyles.bodySmall.copyWith(color: subtitleColor),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

class _DeleteBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withAlpha(30),
        borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        border: Border.all(
          color: AppColors.accentRed.withAlpha(60),
          width: 0.8,
        ),
      ),
      child: const Icon(Icons.delete_rounded, color: AppColors.accentRed, size: 24),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  const _DeleteDialog({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dialogBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final titleStyle = AppTextStyles.headingSmall.copyWith(
      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    );
    final contentStyle = AppTextStyles.bodyMedium.copyWith(
      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    );

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.radiusXl),
      ),
      title: Text('Delete $title?', style: titleStyle),
      content: Text(
        'This entry will be permanently removed from your vault.',
        style: contentStyle,
      ),
      actions: [
        TextButton(
          onPressed: () {
            HapticHelper.light();
            Navigator.pop(context, false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            HapticHelper.medium();
            Navigator.pop(context, true);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.accentRed),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}
