import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// Blue heart sitting in a wheelchair — bold filled silhouette for small sizes.
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
        color: AppTheme.skyBlue.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(size * 0.24),
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
    final chair = Paint()..color = AppTheme.primaryDeepBlue;

    // Rear wheel (filled ring)
    final rearCenter = Offset(w * 0.33, h * 0.70);
    final rearR = w * 0.24;
    canvas.drawCircle(rearCenter, rearR, chair);
    canvas.drawCircle(
      rearCenter,
      rearR * 0.52,
      Paint()..color = AppTheme.cleanWhite,
    );

    // Front wheel
    final frontCenter = Offset(w * 0.80, h * 0.78);
    final frontR = w * 0.11;
    canvas.drawCircle(frontCenter, frontR, chair);
    canvas.drawCircle(
      frontCenter,
      frontR * 0.45,
      Paint()..color = AppTheme.cleanWhite,
    );

    // Seat bar
    final seatRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.50, h * 0.56),
        width: w * 0.50,
        height: h * 0.09,
      ),
      Radius.circular(h * 0.045),
    );
    canvas.drawRRect(seatRect, chair);

    // Backrest
    final backRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w * 0.33, h * 0.44),
        width: w * 0.09,
        height: h * 0.28,
      ),
      Radius.circular(w * 0.04),
    );
    canvas.drawRRect(backRect, chair);

    // Leg rest to front wheel
    final legPath = Path()
      ..moveTo(w * 0.72, h * 0.58)
      ..lineTo(frontCenter.dx, frontCenter.dy - frontR * 0.5);
    canvas.drawPath(
      legPath,
      Paint()
        ..color = AppTheme.primaryDeepBlue
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.08
        ..strokeCap = StrokeCap.round,
    );

    // Blue heart — the person sitting in the chair
    final heartCenter = Offset(w * 0.50, h * 0.30);
    final heart = _heartPath(heartCenter, w * 0.21);
    canvas.drawPath(heart, Paint()..color = AppTheme.primaryBlue);

    // Small white gleam on heart for depth
    canvas.drawCircle(
      Offset(heartCenter.dx - w * 0.04, heartCenter.dy - h * 0.04),
      w * 0.025,
      Paint()..color = AppTheme.cleanWhite.withValues(alpha: 0.55),
    );
  }

  Path _heartPath(Offset center, double scale) {
    final path = Path();
    final cx = center.dx;
    final cy = center.dy;

    path.moveTo(cx, cy + scale * 0.45);
    path.cubicTo(
      cx - scale * 1.05, cy,
      cx - scale * 0.55, cy - scale * 1.05,
      cx, cy - scale * 0.42,
    );
    path.cubicTo(
      cx + scale * 0.55, cy - scale * 1.05,
      cx + scale * 1.05, cy,
      cx, cy + scale * 0.45,
    );
    path.close();

    return path;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
