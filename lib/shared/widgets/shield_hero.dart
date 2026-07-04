// lib/shared/widgets/shield_hero.dart
//
// Vaultix premium shield widget — drawn entirely with Flutter CustomPainter.
// Matches the reference design: tilted orbital rings, gradient glass shield,
// inner lock icon, neon purple glow, floating star particles.

import 'dart:math';
import 'package:flutter/material.dart';

// ─── Public entry point ───────────────────────────────────────────────────────

/// Animated, full-detail shield hero matching the reference design.
/// Drop it anywhere: splash screen, security dashboard, etc.
class ShieldHero extends StatefulWidget {
  const ShieldHero({
    super.key,
    this.size = 260.0,
    this.isAnimated = true,
  });

  final double size;
  final bool isAnimated;

  @override
  State<ShieldHero> createState() => _ShieldHeroState();
}

class _ShieldHeroState extends State<ShieldHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    if (widget.isAnimated) _ctrl.repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => CustomPaint(
        size: Size(widget.size, widget.size),
        painter: _ShieldPainter(t: _ctrl.value),
      ),
    );
  }
}

// ─── Master Painter ───────────────────────────────────────────────────────────

class _ShieldPainter extends CustomPainter {
  _ShieldPainter({required this.t});
  final double t; // 0..1 animation progress

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // 1. Deep radial background glow
    _drawBackgroundGlow(canvas, size, cx, cy);

    // 2. Outer orbital ring (tilted ellipse, slow rotate)
    _drawOrbitalRing(
      canvas, cx, cy,
      rx: size.width * 0.47,
      ry: size.height * 0.16,
      tiltAngle: -0.35,
      rotationT: t * 2 * pi,
      color: const Color(0xFF7C4DFF),
      strokeWidth: 1.2,
      dotAngle: t * 2 * pi,
    );

    // 3. Inner orbital ring (opposite tilt, faster rotate)
    _drawOrbitalRing(
      canvas, cx, cy,
      rx: size.width * 0.38,
      ry: size.height * 0.12,
      tiltAngle: 0.28,
      rotationT: -t * 2 * pi * 1.4,
      color: const Color(0xFF36D7FF),
      strokeWidth: 0.9,
      dotAngle: -t * 2 * pi * 1.4,
    );

    // 4. Floating star particles
    _drawStars(canvas, size, t);

    // 5. Shield body (gradient fill + glow)
    _drawShield(canvas, cx, cy, size);

    // 6. Lock icon inside shield
    _drawLock(canvas, cx, cy, size);
  }

  // ── 1. Background radial glow ─────────────────────────────────────────────

  void _drawBackgroundGlow(Canvas canvas, Size size, double cx, double cy) {
    // Purple core glow
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.42,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF7C4DFF).withAlpha(90),
            const Color(0xFF5B4BFF).withAlpha(40),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(Rect.fromCircle(
          center: Offset(cx, cy),
          radius: size.width * 0.42,
        )),
    );

    // Outer subtle indigo haze
    canvas.drawCircle(
      Offset(cx, cy),
      size.width * 0.5,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF3D1D8A).withAlpha(50),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(
          center: Offset(cx, cy),
          radius: size.width * 0.5,
        )),
    );
  }

  // ── 2 & 3. Orbital ring (perspective tilted ellipse + glowing dot) ────────

  void _drawOrbitalRing(
    Canvas canvas,
    double cx,
    double cy, {
    required double rx,
    required double ry,
    required double tiltAngle,
    required double rotationT,
    required Color color,
    required double strokeWidth,
    required double dotAngle,
  }) {
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(tiltAngle);

    // Ring track
    final trackPaint = Paint()
      ..color = color.withAlpha(55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      trackPaint,
    );

    // Glowing dot on the ring
    final dotX = rx * cos(dotAngle);
    final dotY = ry * sin(dotAngle);

    // Glow halo
    canvas.drawCircle(
      Offset(dotX, dotY),
      6,
      Paint()
        ..color = color.withAlpha(60)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
    // Bright core
    canvas.drawCircle(
      Offset(dotX, dotY),
      3,
      Paint()..color = Colors.white.withAlpha(220),
    );

    canvas.restore();
  }

  // ── 4. Star particles ─────────────────────────────────────────────────────

  static final List<_Star> _stars = List.generate(18, (i) {
    final rng = Random(i * 31337);
    return _Star(
      r: 0.05 + rng.nextDouble() * 0.45,
      angle: rng.nextDouble() * 2 * pi,
      size: 0.8 + rng.nextDouble() * 1.8,
      phase: rng.nextDouble(),
      speed: 0.2 + rng.nextDouble() * 0.6,
    );
  });

  void _drawStars(Canvas canvas, Size size, double t) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    for (final s in _stars) {
      // Gentle float
      final phase = (t * s.speed + s.phase) % 1.0;
      final floatOffset = sin(phase * 2 * pi) * 4.0;

      final x = cx + s.r * size.width * 0.5 * cos(s.angle);
      final y = cy + s.r * size.height * 0.5 * sin(s.angle) + floatOffset;

      // Twinkle opacity
      final alpha = (sin((t * s.speed * 3 + s.phase) * 2 * pi) * 0.4 + 0.6);

      canvas.drawCircle(
        Offset(x, y),
        s.size,
        Paint()..color = Colors.white.withOpacity(alpha.clamp(0.2, 1.0)),
      );
    }
  }

  // ── 5. Shield body ────────────────────────────────────────────────────────

  void _drawShield(Canvas canvas, double cx, double cy, Size size) {
    final s = size.width * 0.36;
    final path = _shieldPath(cx, cy, s);

    // Outer neon glow (purple)
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF7C4DFF).withAlpha(100)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Main gradient fill — dark glass look
    final shieldRect = Rect.fromCenter(
      center: Offset(cx, cy - s * 0.05),
      width: s * 1.6,
      height: s * 1.8,
    );
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF4A1FA8),
            const Color(0xFF2D1070),
            const Color(0xFF1A0A40),
          ],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(shieldRect),
    );

    // Top-left specular highlight (glass sheen)
    final sheenPath = _shieldPath(cx, cy, s);
    canvas.drawPath(
      sheenPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.white.withAlpha(55),
            Colors.transparent,
          ],
        ).createShader(shieldRect),
    );

    // Border stroke — bright purple edge
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFF9C6FFF).withAlpha(200)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );

    // Inner thin bright edge
    final innerPath = _shieldPath(cx, cy, s * 0.92);
    canvas.drawPath(
      innerPath,
      Paint()
        ..color = const Color(0xFF7C4DFF).withAlpha(80)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );
  }

  /// Generates a shield-shaped path centred at (cx, cy) with scale [s].
  Path _shieldPath(double cx, double cy, double s) {
    // Shield is roughly 1.4 wide × 1.8 tall
    final w = s * 0.72;
    final h = s * 0.9;
    final top = cy - h;
    final bot = cy + h * 0.85;

    final path = Path();
    // Top-left rounded corner
    path.moveTo(cx - w * 0.85, top + h * 0.18);
    path.cubicTo(
      cx - w * 0.85, top,           // c1
      cx - w * 0.4,  top - h * 0.1, // c2
      cx,            top - h * 0.1, // end
    );
    // Top-right rounded corner
    path.cubicTo(
      cx + w * 0.4,  top - h * 0.1,
      cx + w * 0.85, top,
      cx + w * 0.85, top + h * 0.18,
    );
    // Right side → bottom point
    path.cubicTo(
      cx + w * 0.85, cy + h * 0.4,
      cx + w * 0.45, cy + h * 0.7,
      cx,            bot,
    );
    // Bottom point → left side
    path.cubicTo(
      cx - w * 0.45, cy + h * 0.7,
      cx - w * 0.85, cy + h * 0.4,
      cx - w * 0.85, top + h * 0.18,
    );
    path.close();
    return path;
  }

  // ── 6. Lock icon ──────────────────────────────────────────────────────────

  void _drawLock(Canvas canvas, double cx, double cy, Size size) {
    final s = size.width * 0.36;
    final lockW = s * 0.44;
    final lockH = s * 0.52;
    final lx = cx - lockW / 2;
    final ly = cy - lockH * 0.38;

    // Lock shackle (rounded arch)
    final shackleR = lockW * 0.33;
    final shacklePaint = Paint()
      ..color = Colors.white.withAlpha(220)
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.075
      ..strokeCap = StrokeCap.round;

    final shacklePath = Path();
    shacklePath.addArc(
      Rect.fromCenter(
        center: Offset(cx, ly + shackleR * 0.2),
        width: shackleR * 2,
        height: shackleR * 2,
      ),
      pi,
      -pi, // left to right arc
    );
    canvas.drawPath(shacklePath, shacklePaint);

    // Lock body (rounded rect)
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(lx, ly + shackleR * 0.55, lockW, lockH * 0.62),
      Radius.circular(lockW * 0.18),
    );

    // Body glow
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = const Color(0xFF36D7FF).withAlpha(50)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Body fill
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF5B4BFF).withAlpha(200),
            const Color(0xFF3D1FA8).withAlpha(240),
          ],
        ).createShader(bodyRect.outerRect),
    );

    // Body border
    canvas.drawRRect(
      bodyRect,
      Paint()
        ..color = Colors.white.withAlpha(100)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8,
    );

    // Keyhole circle
    final khCenter = Offset(cx, ly + shackleR * 0.55 + lockH * 0.27);
    canvas.drawCircle(
      khCenter,
      lockW * 0.13,
      Paint()..color = Colors.white.withAlpha(230),
    );

    // Keyhole stem
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, khCenter.dy + lockW * 0.14),
          width: lockW * 0.14,
          height: lockW * 0.22,
        ),
        const Radius.circular(2),
      ),
      Paint()..color = Colors.white.withAlpha(230),
    );
  }

  @override
  bool shouldRepaint(_ShieldPainter old) => old.t != t;
}

// ─── Helper ───────────────────────────────────────────────────────────────────

class _Star {
  const _Star({
    required this.r,
    required this.angle,
    required this.size,
    required this.phase,
    required this.speed,
  });
  final double r, angle, size, phase, speed;
}
