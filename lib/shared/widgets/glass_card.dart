// lib/shared/widgets/glass_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_constants.dart';

/// Glassmorphism card used throughout Vaultix.
/// Supports optional neon border glow and gradient overlay.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.radiusXl,
    this.padding = const EdgeInsets.all(AppConstants.spaceMd),
    this.margin = EdgeInsets.zero,
    this.blur = AppConstants.glassBlur,
    this.glowColor,
    this.borderColor,
    this.gradient,
    this.height,
    this.width,
    this.onTap,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final double blur;
  final Color? glowColor;
  final Color? borderColor;
  final Gradient? gradient;
  final double? height;
  final double? width;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = borderColor ?? AppColors.border;
    final effectiveGlow = glowColor;

    Widget card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: gradient ??
                LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withAlpha(10),
                    Colors.white.withAlpha(4),
                  ],
                ),
            border: Border.all(
              color: effectiveBorder.withAlpha(40),
              width: AppConstants.glassBorderWidth,
            ),
          ),
          padding: padding,
          child: child,
        ),
      ),
    );

    // Neon outer glow
    if (effectiveGlow != null) {
      card = Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: effectiveGlow.withAlpha(60),
              blurRadius: 20,
              spreadRadius: -4,
            ),
          ],
        ),
        child: card,
      );
    } else {
      card = Padding(padding: margin, child: card);
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }
}

/// A simple surface card without blur — lighter weight for lists.
class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    super.key,
    required this.child,
    this.borderRadius = AppConstants.radiusLg,
    this.padding = const EdgeInsets.all(AppConstants.spaceMd),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.color,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Material(
        color: color ?? AppColors.surfaceCard,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.glowPurple,
          highlightColor: Colors.transparent,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: AppColors.border,
                width: 0.8,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
