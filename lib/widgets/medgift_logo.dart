import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Blue heart sitting in a wheelchair — detailed mark that stays readable at small sizes.
class MedGiftLogo extends StatelessWidget {
  const MedGiftLogo({
    super.key,
    this.size = 48,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.skyBlue.withValues(alpha: 0.55),
            AppTheme.cleanWhite,
            AppTheme.lightBlue.withValues(alpha: 0.28),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.24),
        border: Border.all(
          color: AppTheme.primaryBlue.withValues(alpha: 0.18),
          width: math.max(1.0, size * 0.02),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDeepBlue.withValues(alpha: 0.12),
            blurRadius: size * 0.12,
            offset: Offset(0, size * 0.04),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _HeartInWheelchairPainter(),
      ),
    );
  }
}

class MedGiftBrand extends StatelessWidget {
  const MedGiftBrand({
    super.key,
    this.compact = false,
    this.showLabel = true,
    this.logoSize = 48,
  });

  final bool compact;
  final bool showLabel;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    if (compact || !showLabel) {
      return MedGiftLogo(size: logoSize);
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        MedGiftLogo(size: logoSize),
        const SizedBox(width: 12),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'MedGift',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDeepBlue,
                      letterSpacing: -0.3,
                      height: 1.1,
                    ),
              ),
              Text(
                'US',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: AppTheme.primaryBlue,
                      letterSpacing: 1.2,
                      height: 1.1,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeartInWheelchairPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final deep = AppTheme.primaryDeepBlue;
    final mid = AppTheme.primaryBlue;
    final light = AppTheme.lightBlue;
    final white = AppTheme.cleanWhite;

    final rearCenter = Offset(w * 0.36, h * 0.72);
    final rearR = w * 0.255;
    final frontCenter = Offset(w * 0.78, h * 0.80);
    final frontR = w * 0.095;

    // Soft ground shadow under the chair
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.52, h * 0.90),
        width: w * 0.62,
        height: h * 0.08,
      ),
      Paint()..color = deep.withValues(alpha: 0.10),
    );

    // --- Frame tubes ---
    final frameStroke = Paint()
      ..color = deep
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.055
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final frameFill = Paint()..color = deep;

    // Seat cushion (slightly rounded for realism)
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.34, h * 0.52, w * 0.72, h * 0.62),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(
      seatRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [mid, deep],
        ).createShader(seatRect.outerRect),
    );
    // Seat highlight strip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(w * 0.36, h * 0.53, w * 0.70, h * 0.56),
        Radius.circular(w * 0.03),
      ),
      Paint()..color = light.withValues(alpha: 0.45),
    );

    // Backrest
    final backRect = RRect.fromRectAndRadius(
      Rect.fromLTRB(w * 0.28, h * 0.28, w * 0.40, h * 0.58),
      Radius.circular(w * 0.045),
    );
    canvas.drawRRect(
      backRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [deep, mid],
        ).createShader(backRect.outerRect),
    );

    // Armrest
    canvas.drawLine(
      Offset(w * 0.40, h * 0.46),
      Offset(w * 0.66, h * 0.46),
      Paint()
        ..color = deep
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );

    // Seat-to-front axle / footrest frame
    final chassis = Path()
      ..moveTo(w * 0.48, h * 0.60)
      ..lineTo(w * 0.62, h * 0.68)
      ..lineTo(frontCenter.dx, frontCenter.dy - frontR * 0.15)
      ..lineTo(w * 0.70, h * 0.72)
      ..lineTo(w * 0.58, h * 0.62);
    canvas.drawPath(
      chassis,
      Paint()
        ..color = deep
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.048
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Footplate
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(w * 0.74, h * 0.74),
          width: w * 0.12,
          height: h * 0.035,
        ),
        Radius.circular(w * 0.02),
      ),
      frameFill,
    );

    // Rear hub → seat brace
    canvas.drawLine(
      rearCenter,
      Offset(w * 0.48, h * 0.58),
      frameStroke,
    );

    // --- Rear drive wheel (detailed) ---
    _drawDriveWheel(
      canvas,
      center: rearCenter,
      radius: rearR,
      tire: deep,
      rim: mid,
      hub: light,
      white: white,
    );

    // --- Front caster ---
    _drawCasterWheel(
      canvas,
      center: frontCenter,
      radius: frontR,
      tire: deep,
      rim: mid,
      white: white,
    );

    // --- Heart seated on the chair ---
    final heartCenter = Offset(w * 0.52, h * 0.30);
    final heartScale = w * 0.35;
    final heart = _heartPath(heartCenter, heartScale);
    final sky = AppTheme.skyBlue;

    // Soft drop shadow under heart (reads as “sitting”)
    canvas.save();
    canvas.translate(w * 0.012, h * 0.018);
    canvas.drawPath(
      heart,
      Paint()..color = mid.withValues(alpha: 0.20),
    );
    canvas.restore();

    canvas.drawPath(
      heart,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            sky,
            light,
            mid,
          ],
          stops: const [0.0, 0.50, 1.0],
        ).createShader(
          Rect.fromCenter(
            center: heartCenter,
            width: heartScale * 2.2,
            height: heartScale * 2.0,
          ),
        ),
    );

    // Inner contour for definition
    canvas.drawPath(
      _heartPath(heartCenter, heartScale * 0.72),
      Paint()
        ..color = white.withValues(alpha: 0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.018,
    );

    // Specular gleam
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
          heartCenter.dx - heartScale * 0.28,
          heartCenter.dy - heartScale * 0.22,
        ),
        width: heartScale * 0.28,
        height: heartScale * 0.18,
      ),
      Paint()..color = white.withValues(alpha: 0.70),
    );
    canvas.drawCircle(
      Offset(
        heartCenter.dx + heartScale * 0.18,
        heartCenter.dy - heartScale * 0.08,
      ),
      heartScale * 0.06,
      Paint()..color = white.withValues(alpha: 0.35),
    );
  }

  void _drawDriveWheel(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color tire,
    required Color rim,
    required Color hub,
    required Color white,
  }) {
    // Tire
    canvas.drawCircle(center, radius, Paint()..color = tire);

    // Sidewall / rim band
    canvas.drawCircle(
      center,
      radius * 0.82,
      Paint()..color = rim,
    );

    // Inner disc (sky cutout feel)
    canvas.drawCircle(
      center,
      radius * 0.68,
      Paint()..color = white,
    );

    // Handrim
    canvas.drawCircle(
      center,
      radius * 0.92,
      Paint()
        ..color = tire
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.10,
    );

    // Spokes
    final spokePaint = Paint()
      ..color = rim
      ..strokeWidth = radius * 0.08
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 8; i++) {
      final angle = (i / 8) * math.pi * 2;
      final inner = Offset(
        center.dx + math.cos(angle) * radius * 0.18,
        center.dy + math.sin(angle) * radius * 0.18,
      );
      final outer = Offset(
        center.dx + math.cos(angle) * radius * 0.62,
        center.dy + math.sin(angle) * radius * 0.62,
      );
      canvas.drawLine(inner, outer, spokePaint);
    }

    // Hub
    canvas.drawCircle(center, radius * 0.18, Paint()..color = tire);
    canvas.drawCircle(center, radius * 0.10, Paint()..color = hub);

    // Tire highlight arc
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.94),
      -math.pi * 0.85,
      math.pi * 0.45,
      false,
      Paint()
        ..color = white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.08
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawCasterWheel(
    Canvas canvas, {
    required Offset center,
    required double radius,
    required Color tire,
    required Color rim,
    required Color white,
  }) {
    canvas.drawCircle(center, radius, Paint()..color = tire);
    canvas.drawCircle(center, radius * 0.58, Paint()..color = white);
    canvas.drawCircle(center, radius * 0.22, Paint()..color = rim);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius * 0.88),
      -math.pi * 0.9,
      math.pi * 0.5,
      false,
      Paint()
        ..color = white.withValues(alpha: 0.30)
        ..style = PaintingStyle.stroke
        ..strokeWidth = radius * 0.12
        ..strokeCap = StrokeCap.round,
    );
  }

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
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
