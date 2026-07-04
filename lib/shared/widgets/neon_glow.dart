// lib/shared/widgets/neon_glow.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

/// Wraps any widget with a soft neon outer glow.
class NeonGlow extends StatelessWidget {
  const NeonGlow({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.blur = 24.0,
    this.spread = -4.0,
    this.opacity = 0.5,
  });

  final Widget child;
  final Color color;
  final double blur;
  final double spread;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: opacity),
            blurRadius: blur,
            spreadRadius: spread,
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Animated pulsing ring — used for the fingerprint scanner.
class PulsingRing extends StatefulWidget {
  const PulsingRing({
    super.key,
    required this.child,
    this.color = AppColors.primary,
    this.size = 100.0,
  });

  final Widget child;
  final Color color;
  final double size;

  @override
  State<PulsingRing> createState() => _PulsingRingState();
}

class _PulsingRingState extends State<PulsingRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.9, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) => Transform.scale(
        scale: _pulse.value,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: widget.color.withAlpha(80),
                blurRadius: 30 * _pulse.value,
                spreadRadius: 4 * (_pulse.value - 0.9) * 10,
              ),
            ],
          ),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Animated glowing security ring used on the Security Dashboard.
class SecurityRing extends StatefulWidget {
  const SecurityRing({
    super.key,
    required this.score,
    required this.child,
    this.size = 160.0,
  });

  final int score;
  final Widget child;
  final double size;

  @override
  State<SecurityRing> createState() => _SecurityRingState();
}

class _SecurityRingState extends State<SecurityRing>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2));
    _progress = Tween<double>(begin: 0, end: widget.score / 100.0)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _progress,
        builder: (_, child) => CustomPaint(
          painter: _RingPainter(progress: _progress.value, score: widget.score),
          child: child,
        ),
        child: Center(child: widget.child),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.progress, required this.score});
  final double progress;
  final int score;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Background track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFF1E2340)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    // Gradient arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepPaint = Paint()
      ..shader = const SweepGradient(
        startAngle: -1.5708,
        endAngle: 4.7124,
        colors: [Color(0xFF7C4DFF), Color(0xFF36D7FF), Color(0xFF7C4DFF)],
        stops: [0.0, 0.6, 1.0],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, sweepPaint);

    // Glow
    final glowPaint = Paint()
      ..color = const Color(0x607C4DFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawArc(rect, -1.5708, 6.2832 * progress, false, glowPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.progress != progress;
}
