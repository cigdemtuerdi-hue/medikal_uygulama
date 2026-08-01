import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// MeGi — cute blue-heart mascot using MedGift logo blues.
class MeGiMascot extends StatelessWidget {
  const MeGiMascot({
    super.key,
    this.size = 48,
    this.showShadow = true,
  });

  final double size;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'MeGi',
      image: true,
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _MeGiMascotPainter(showShadow: showShadow),
        ),
      ),
    );
  }
}

class _MeGiMascotPainter extends CustomPainter {
  _MeGiMascotPainter({required this.showShadow});

  final bool showShadow;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final deep = AppTheme.primaryDeepBlue;
    final mid = AppTheme.primaryBlue;
    final light = AppTheme.lightBlue;
    final sky = AppTheme.skyBlue;
    final white = AppTheme.cleanWhite;

    // Heart sits a bit high so legs have room.
    final heartCenter = Offset(w * 0.50, h * 0.42);
    final heartScale = w * 0.34;
    final heart = _heartPath(heartCenter, heartScale);

    if (showShadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(w * 0.50, h * 0.92),
          width: w * 0.42,
          height: h * 0.07,
        ),
        Paint()..color = deep.withValues(alpha: 0.12),
      );
    }

    // Arms (behind heart slightly via draw order after limbs under body tip)
    _drawArm(
      canvas,
      shoulder: Offset(w * 0.22, h * 0.48),
      hand: Offset(w * 0.08, h * 0.58),
      mid: mid,
      deep: deep,
      light: light,
      thickness: w * 0.075,
    );
    _drawArm(
      canvas,
      shoulder: Offset(w * 0.78, h * 0.48),
      hand: Offset(w * 0.92, h * 0.58),
      mid: mid,
      deep: deep,
      light: light,
      thickness: w * 0.075,
    );

    // Legs
    _drawLeg(
      canvas,
      hip: Offset(w * 0.40, h * 0.68),
      foot: Offset(w * 0.36, h * 0.88),
      mid: mid,
      deep: deep,
      light: light,
      thickness: w * 0.08,
    );
    _drawLeg(
      canvas,
      hip: Offset(w * 0.60, h * 0.68),
      foot: Offset(w * 0.64, h * 0.88),
      mid: mid,
      deep: deep,
      light: light,
      thickness: w * 0.08,
    );

    // Soft drop under heart
    canvas.save();
    canvas.translate(w * 0.01, h * 0.015);
    canvas.drawPath(heart, Paint()..color = mid.withValues(alpha: 0.18));
    canvas.restore();

    // Heart body — same gradient recipe as MedGift logo heart
    canvas.drawPath(
      heart,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sky, light, mid],
          stops: const [0.0, 0.45, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: heartCenter,
            width: heartScale * 2.2,
            height: heartScale * 2.0,
          ),
        ),
    );

    // Inner contour
    canvas.drawPath(
      _heartPath(heartCenter, heartScale * 0.72),
      Paint()
        ..color = white.withValues(alpha: 0.14)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.016,
    );

    // Specular gleam (logo-style)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          heartCenter.dx - heartScale * 0.28,
          heartCenter.dy - heartScale * 0.22,
        ),
        width: heartScale * 0.26,
        height: heartScale * 0.16,
      ),
      Paint()..color = white.withValues(alpha: 0.72),
    );

    // Face
    final faceY = heartCenter.dy + heartScale * 0.02;
    final eyeY = faceY - heartScale * 0.06;
    final eyeDx = heartScale * 0.22;
    final eyeR = heartScale * 0.13;

    _drawEye(
      canvas,
      center: Offset(heartCenter.dx - eyeDx, eyeY),
      radius: eyeR,
      deep: deep,
      white: white,
      lookRight: false,
    );
    _drawEye(
      canvas,
      center: Offset(heartCenter.dx + eyeDx, eyeY),
      radius: eyeR,
      deep: deep,
      white: white,
      lookRight: true,
    );

    // Tiny nose
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(heartCenter.dx, faceY + heartScale * 0.08),
        width: heartScale * 0.10,
        height: heartScale * 0.08,
      ),
      Paint()..color = deep.withValues(alpha: 0.55),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          heartCenter.dx - heartScale * 0.015,
          faceY + heartScale * 0.07,
        ),
        width: heartScale * 0.04,
        height: heartScale * 0.03,
      ),
      Paint()..color = white.withValues(alpha: 0.45),
    );

    // Soft blush
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(heartCenter.dx - eyeDx * 1.35, faceY + heartScale * 0.12),
        width: heartScale * 0.16,
        height: heartScale * 0.09,
      ),
      Paint()..color = const Color(0xFFFF8A9A).withValues(alpha: 0.35),
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(heartCenter.dx + eyeDx * 1.35, faceY + heartScale * 0.12),
        width: heartScale * 0.16,
        height: heartScale * 0.09,
      ),
      Paint()..color = const Color(0xFFFF8A9A).withValues(alpha: 0.35),
    );

    // Smile
    final smile = Path()
      ..moveTo(heartCenter.dx - heartScale * 0.16, faceY + heartScale * 0.18)
      ..quadraticBezierTo(
        heartCenter.dx,
        faceY + heartScale * 0.30,
        heartCenter.dx + heartScale * 0.16,
        faceY + heartScale * 0.18,
      );
    canvas.drawPath(
      smile,
      Paint()
        ..color = deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.028
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color deep,
    required Color white,
    required bool lookRight,
  }) {
    canvas.drawCircle(center, radius, Paint()..color = white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = deep.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12,
    );
    final pupil = Offset(
      center.dx + (lookRight ? radius * 0.08 : -radius * 0.08),
      center.dy + radius * 0.06,
    );
    canvas.drawCircle(pupil, radius * 0.55, Paint()..color = deep);
    canvas.drawCircle(
      Offset(pupil.dx - radius * 0.18, pupil.dy - radius * 0.18),
      radius * 0.18,
      Paint()..color = white.withValues(alpha: 0.95),
    );
  }

  void _drawArm(
    Canvas canvas, {
    required Offset shoulder,
    required Offset hand,
    required Color mid,
    required Color deep,
    required Color light,
    required double thickness,
  }) {
    canvas.drawLine(
      shoulder,
      hand,
      Paint()
        ..color = mid
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(hand, thickness * 0.72, Paint()..color = light);
    canvas.drawCircle(
      hand,
      thickness * 0.72,
      Paint()
        ..color = deep.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = thickness * 0.12,
    );
  }

  void _drawLeg(
    Canvas canvas, {
    required Offset hip,
    required Offset foot,
    required Color mid,
    required Color deep,
    required Color light,
    required double thickness,
  }) {
    canvas.drawLine(
      hip,
      foot,
      Paint()
        ..color = mid
        ..strokeWidth = thickness
        ..strokeCap = StrokeCap.round,
    );
    // Cute little foot
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(foot.dx, foot.dy + thickness * 0.15),
        width: thickness * 1.55,
        height: thickness * 0.95,
      ),
      Paint()..color = deep,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(foot.dx - thickness * 0.1, foot.dy),
        width: thickness * 0.9,
        height: thickness * 0.55,
      ),
      Paint()..color = light.withValues(alpha: 0.55),
    );
  }

  /// Same cubic heart silhouette used in [MedGiftLogo].
  Path _heartPath(Offset center, double scale) {
    final path = Path();
    final cx = center.dx;
    final cy = center.dy;

    path.moveTo(cx, cy + scale * 0.52);
    path.cubicTo(
      cx - scale * 1.15,
      cy + scale * 0.08,
      cx - scale * 0.95,
      cy - scale * 0.95,
      cx,
      cy - scale * 0.38,
    );
    path.cubicTo(
      cx + scale * 0.95,
      cy - scale * 0.95,
      cx + scale * 1.15,
      cy + scale * 0.08,
      cx,
      cy + scale * 0.52,
    );
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _MeGiMascotPainter oldDelegate) =>
      oldDelegate.showShadow != showShadow;
}

/// Circular badge wrapper for chat header / FAB.
class MeGiMascotBadge extends StatelessWidget {
  const MeGiMascotBadge({
    super.key,
    this.size = 40,
    this.backgroundColor,
  });

  final double size;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white.withValues(alpha: 0.18),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: MeGiMascot(size: size * 0.88, showShadow: false),
    );
  }
}
