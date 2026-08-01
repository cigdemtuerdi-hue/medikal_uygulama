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

  static const Color _blush = Color(0xFFFF8FA3);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final deep = AppTheme.primaryDeepBlue;
    final mid = AppTheme.primaryBlue;
    final light = AppTheme.lightBlue;
    final sky = AppTheme.skyBlue;
    final white = AppTheme.cleanWhite;

    final cx = w * 0.50;
    final heartCenter = Offset(cx, h * 0.40);
    // Base scale of the logo heart, stretched slightly into a plump body.
    final hs = w * 0.35;
    const stretchY = 1.24;
    final heart = _heartBody(heartCenter, hs, stretchY);

    if (showShadow) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx, h * 0.80),
          width: w * 0.44,
          height: h * 0.052,
        ),
        Paint()..color = deep.withValues(alpha: 0.13),
      );
    }

    final limbPaint = Paint()
      ..color = mid
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Stubby legs, tucked behind the body.
    for (final dir in const [-1.0, 1.0]) {
      final leg = Path()
        ..moveTo(cx + dir * w * 0.078, h * 0.585)
        ..quadraticBezierTo(
          cx + dir * w * 0.086,
          h * 0.64,
          cx + dir * w * 0.09,
          h * 0.685,
        );
      canvas.drawPath(leg, limbPaint..strokeWidth = w * 0.105);

      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dir * w * 0.10, h * 0.72),
          width: w * 0.155,
          height: w * 0.086,
        ),
        Paint()..color = deep,
      );
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dir * w * 0.092, h * 0.709),
          width: w * 0.075,
          height: w * 0.028,
        ),
        Paint()..color = light.withValues(alpha: 0.42),
      );
    }

    // Short arms held out to the sides, clearing the widest point of the body.
    for (final dir in const [-1.0, 1.0]) {
      final arm = Path()
        ..moveTo(cx + dir * w * 0.185, h * 0.435)
        ..quadraticBezierTo(
          cx + dir * w * 0.30,
          h * 0.448,
          cx + dir * w * 0.322,
          h * 0.505,
        );
      canvas.drawPath(arm, limbPaint..strokeWidth = w * 0.088);

      final hand = Offset(cx + dir * w * 0.33, h * 0.522);
      canvas.drawCircle(hand, w * 0.058, Paint()..color = sky);
      canvas.drawCircle(
        hand,
        w * 0.058,
        Paint()
          ..color = deep.withValues(alpha: 0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.012,
      );
    }

    // Heart body — logo gradient recipe.
    canvas.drawPath(
      heart,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [sky, light, mid],
          stops: const [0.0, 0.5, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: heartCenter,
            width: hs * 1.9,
            height: hs * 2.2,
          ),
        ),
    );
    canvas.drawPath(
      heart,
      Paint()
        ..color = deep.withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // Specular gleam on the upper-left lobe.
    canvas.save();
    canvas.translate(cx - w * 0.16, h * 0.275);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.095,
        height: w * 0.045,
      ),
      Paint()..color = white.withValues(alpha: 0.6),
    );
    canvas.restore();

    // Blush sits under the eyes, drawn first so eyes stay crisp.
    for (final dir in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dir * w * 0.172, h * 0.462),
          width: w * 0.092,
          height: w * 0.052,
        ),
        Paint()..color = _blush.withValues(alpha: 0.5),
      );
    }

    // Face
    for (final dir in const [-1.0, 1.0]) {
      _drawEye(
        canvas,
        center: Offset(cx + dir * w * 0.108, h * 0.385),
        radius: w * 0.077,
        deep: deep,
        white: white,
        towardCenter: -dir,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.458),
        width: w * 0.046,
        height: w * 0.034,
      ),
      Paint()..color = deep.withValues(alpha: 0.6),
    );

    final smile = Path()
      ..moveTo(cx - w * 0.062, h * 0.482)
      ..quadraticBezierTo(cx, h * 0.538, cx + w * 0.062, h * 0.482);
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
    required double towardCenter,
  }) {
    canvas.drawCircle(center, radius, Paint()..color = white);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = deep.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.11,
    );

    final pupil = Offset(
      center.dx + towardCenter * radius * 0.1,
      center.dy + radius * 0.08,
    );
    canvas.drawCircle(pupil, radius * 0.58, Paint()..color = deep);
    canvas.drawCircle(
      Offset(pupil.dx - radius * 0.2, pupil.dy - radius * 0.24),
      radius * 0.24,
      Paint()..color = white,
    );
    canvas.drawCircle(
      Offset(pupil.dx + radius * 0.22, pupil.dy + radius * 0.2),
      radius * 0.11,
      Paint()..color = white.withValues(alpha: 0.85),
    );
  }

  /// Cubic heart silhouette from [MedGiftLogo], stretched vertically by
  /// [stretchY] and with the tip rounded off so the mascot reads as a soft
  /// body instead of a spade.
  Path _heartBody(Offset center, double scale, double stretchY) {
    final path = Path();
    final cx = center.dx;
    final cy = center.dy;
    final sy = scale * stretchY;
    final r = scale * 0.19;
    final tipY = cy + sy * 0.52;
    final shoulderY = tipY - r * 0.62 * stretchY;

    path.moveTo(cx - r, shoulderY);
    path.cubicTo(
      cx - scale * 1.15,
      cy + sy * 0.08,
      cx - scale * 0.95,
      cy - sy * 0.95,
      cx,
      cy - sy * 0.38,
    );
    path.cubicTo(
      cx + scale * 0.95,
      cy - sy * 0.95,
      cx + scale * 1.15,
      cy + sy * 0.08,
      cx + r,
      shoulderY,
    );
    path.quadraticBezierTo(cx, tipY + r * 0.30 * stretchY, cx - r, shoulderY);
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
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: MeGiMascot(size: size * 0.92, showShadow: false),
    );
  }
}
