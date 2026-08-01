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

  static const Color _blush = Color(0xFFFF7EA8);

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
    // A stretch below 1.0 of its own width keeps the silhouette chubby.
    final heartCenter = Offset(cx, h * 0.508);
    final hs = w * 0.52;
    const stretchY = 1.12;
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
    canvas.translate(cx - w * 0.235, h * 0.325);
    canvas.rotate(-0.6);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset.zero,
        width: w * 0.145,
        height: w * 0.062,
      ),
      Paint()..color = white.withValues(alpha: 0.6),
    );
    canvas.restore();

    // Blush is drawn first so the eyes and smile stay crisp on top.
    for (final dir in const [-1.0, 1.0]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(cx + dir * w * 0.215, h * 0.60),
          width: w * 0.128,
          height: w * 0.07,
        ),
        Paint()..color = _blush.withValues(alpha: 0.8),
      );
    }

    // Face
    for (final dir in const [-1.0, 1.0]) {
      _drawEye(
        canvas,
        center: Offset(cx + dir * w * 0.155, h * 0.47),
        rx: w * 0.085,
        ry: w * 0.10,
        deep: deep,
        white: white,
      );
    }

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.588),
        width: w * 0.045,
        height: w * 0.032,
      ),
      Paint()..color = deep.withValues(alpha: 0.4),
    );

    final smile = Path()
      ..moveTo(cx - w * 0.082, h * 0.618)
      ..quadraticBezierTo(cx, h * 0.688, cx + w * 0.082, h * 0.618);
    canvas.drawPath(
      smile,
      Paint()
        ..color = deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.036
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Solid plush-toy eye. A white sclera around a dark pupil reads as
  /// bug-eyed at this scale, so the eye is one filled oval plus sparkles.
  void _drawEye(
    Canvas canvas, {
    required Offset center,
    required double rx,
    required double ry,
    required Color deep,
    required Color white,
  }) {
    canvas.drawOval(
      Rect.fromCenter(center: center, width: rx * 2, height: ry * 2),
      Paint()..color = deep,
    );
    canvas.drawCircle(
      Offset(center.dx - rx * 0.30, center.dy - ry * 0.34),
      rx * 0.44,
      Paint()..color = white,
    );
    canvas.drawCircle(
      Offset(center.dx + rx * 0.33, center.dy + ry * 0.33),
      rx * 0.20,
      Paint()..color = white.withValues(alpha: 0.9),
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
