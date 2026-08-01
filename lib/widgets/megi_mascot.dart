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

  static const Color _blush = Color(0xFFFF7A93);

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
    // No limbs — the logo heart is the whole character, so it fills the box.
    final heartCenter = Offset(cx, h * 0.474);
    final hs = w * 0.53;
    const stretchY = 1.42;
    final heart = _heartBody(heartCenter, hs, stretchY);

    if (showShadow) {
      canvas.drawPath(
        _heartBody(heartCenter.translate(0, h * 0.022), hs, stretchY),
        Paint()
          ..color = deep.withValues(alpha: 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.03),
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
        ..strokeWidth = w * 0.022,
    );

    // Specular gleam on the upper-left lobe.
    canvas.save();
    canvas.translate(cx - w * 0.245, h * 0.265);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.15,
        height: w * 0.068,
      ),
      Paint()..color = white.withValues(alpha: 0.6),
    );
    canvas.restore();

    // Blush is drawn first so the eyes and smile stay crisp on top.
    for (final dir in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dir * w * 0.19, h * 0.632),
          width: w * 0.105,
          height: w * 0.056,
        ),
        Paint()..color = _blush.withValues(alpha: 0.7),
      );
    }

    // Face
    for (final dir in const [-1.0, 1.0]) {
      _drawEye(
        canvas,
        center: Offset(cx + dir * w * 0.165, h * 0.44),
        radius: w * 0.135,
        deep: deep,
        white: white,
        towardCenter: -dir,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.578),
        width: w * 0.062,
        height: w * 0.046,
      ),
      Paint()..color = deep.withValues(alpha: 0.55),
    );

    final smile = Path()
      ..moveTo(cx - w * 0.105, h * 0.622)
      ..quadraticBezierTo(cx, h * 0.716, cx + w * 0.105, h * 0.622);
    canvas.drawPath(
      smile,
      Paint()
        ..color = deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.042
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
  /// [stretchY] so the face has room without distorting the lobes.
  Path _heartBody(Offset center, double scale, double stretchY) {
    final path = Path();
    final cx = center.dx;
    final cy = center.dy;
    final sy = scale * stretchY;

    path.moveTo(cx, cy + sy * 0.52);
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
      cx,
      cy + sy * 0.52,
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
        color: backgroundColor ?? Colors.white,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: MeGiMascot(size: size * 0.92, showShadow: false),
    );
  }
}
