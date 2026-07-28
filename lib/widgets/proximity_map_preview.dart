import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../config/app_theme.dart';

/// Offline-friendly map preview — no Google Maps tiles required.
class ProximityMapPreview extends StatelessWidget {
  const ProximityMapPreview({
    super.key,
    required this.recipient,
    required this.donorAreaCenter,
    required this.donorAreaRadiusMeters,
    this.showDisasterZone = false,
  });

  final LatLng recipient;
  final LatLng donorAreaCenter;
  final double donorAreaRadiusMeters;
  final bool showDisasterZone;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.skyBlue.withValues(alpha: 0.25),
            AppTheme.surfaceLight,
          ],
        ),
      ),
      child: CustomPaint(
        painter: _ProximityMapPainter(
          recipient: recipient,
          donorAreaCenter: donorAreaCenter,
          donorAreaRadiusMeters: donorAreaRadiusMeters,
          showDisasterZone: showDisasterZone,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ProximityMapPainter extends CustomPainter {
  _ProximityMapPainter({
    required this.recipient,
    required this.donorAreaCenter,
    required this.donorAreaRadiusMeters,
    required this.showDisasterZone,
  });

  final LatLng recipient;
  final LatLng donorAreaCenter;
  final double donorAreaRadiusMeters;
  final bool showDisasterZone;

  @override
  void paint(Canvas canvas, Size size) {
    final padding = 24.0;
    final plot = Rect.fromLTWH(
      padding,
      padding,
      size.width - padding * 2,
      size.height - padding * 2,
    );

    _drawGrid(canvas, plot);

    final radiusLat = donorAreaRadiusMeters / 111320;
    final radiusLng = donorAreaRadiusMeters /
        (111320 * math.cos(donorAreaCenter.latitude * math.pi / 180));

    final bounds = _Bounds.fromPoints([
      _Point(recipient.latitude, recipient.longitude),
      _Point(donorAreaCenter.latitude - radiusLat, donorAreaCenter.longitude - radiusLng),
      _Point(donorAreaCenter.latitude + radiusLat, donorAreaCenter.longitude + radiusLng),
      _Point(recipient.latitude, recipient.longitude),
    ]).expand(fraction: 0.18);

    Offset project(LatLng point) {
      final x = (point.longitude - bounds.minLng) / bounds.lngSpan;
      final y = 1 - (point.latitude - bounds.minLat) / bounds.latSpan;
      return Offset(
        plot.left + x * plot.width,
        plot.top + y * plot.height,
      );
    }

    double projectRadiusMeters(double meters, LatLng center) {
      final edge = LatLng(
        center.latitude,
        center.longitude + meters / (111320 * math.cos(center.latitude * math.pi / 180)),
      );
      final centerPx = project(center);
      final edgePx = project(edge);
      return (edgePx - centerPx).distance;
    }

    final donorPx = project(donorAreaCenter);
    final recipientPx = project(recipient);
    final privacyRadiusPx = projectRadiusMeters(donorAreaRadiusMeters, donorAreaCenter);

    if (showDisasterZone) {
      final disasterPaint = Paint()
        ..color = const Color(0xFFC62828).withValues(alpha: 0.16)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        donorPx,
        privacyRadiusPx * 1.35,
        disasterPaint,
      );
      final disasterStroke = Paint()
        ..color = const Color(0xFFB71C1C).withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(donorPx, privacyRadiusPx * 1.35, disasterStroke);
    }

    final areaFill = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(donorPx, privacyRadiusPx, areaFill);

    final areaStroke = Paint()
      ..color = AppTheme.primaryBlue.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(donorPx, privacyRadiusPx, areaStroke);

    final connector = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(recipientPx, donorPx, connector);

    _drawRecipientMarker(canvas, recipientPx);
  }

  void _drawGrid(Canvas canvas, Rect plot) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1;

    const divisions = 4;
    for (var i = 1; i < divisions; i++) {
      final t = i / divisions;
      final x = plot.left + plot.width * t;
      final y = plot.top + plot.height * t;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), gridPaint);
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }
  }

  void _drawRecipientMarker(Canvas canvas, Offset center) {
    final pinPaint = Paint()..color = Colors.red.shade600;
    canvas.drawCircle(center, 7, pinPaint);
    canvas.drawCircle(
      center,
      11,
      Paint()
        ..color = Colors.red.shade600.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _ProximityMapPainter oldDelegate) {
    return oldDelegate.recipient != recipient ||
        oldDelegate.donorAreaCenter != donorAreaCenter ||
        oldDelegate.donorAreaRadiusMeters != donorAreaRadiusMeters ||
        oldDelegate.showDisasterZone != showDisasterZone;
  }
}

class _Point {
  const _Point(this.lat, this.lng);
  final double lat;
  final double lng;
}

class _Bounds {
  const _Bounds({
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;

  double get latSpan => math.max(maxLat - minLat, 0.001);
  double get lngSpan => math.max(maxLng - minLng, 0.001);

  factory _Bounds.fromPoints(List<_Point> points) {
    var minLat = points.first.lat;
    var maxLat = points.first.lat;
    var minLng = points.first.lng;
    var maxLng = points.first.lng;

    for (final point in points) {
      minLat = math.min(minLat, point.lat);
      maxLat = math.max(maxLat, point.lat);
      minLng = math.min(minLng, point.lng);
      maxLng = math.max(maxLng, point.lng);
    }

    return _Bounds(
      minLat: minLat,
      maxLat: maxLat,
      minLng: minLng,
      maxLng: maxLng,
    );
  }

  _Bounds expand({required double fraction}) {
    final latPad = latSpan * fraction;
    final lngPad = lngSpan * fraction;
    return _Bounds(
      minLat: minLat - latPad,
      maxLat: maxLat + latPad,
      minLng: minLng - lngPad,
      maxLng: maxLng + lngPad,
    );
  }
}
