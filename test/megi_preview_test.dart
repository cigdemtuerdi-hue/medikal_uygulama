import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medikal_uygulama/config/app_theme.dart';
import 'package:medikal_uygulama/widgets/megi_mascot.dart';

/// Renders MeGi at the sizes it is actually used at so the artwork can be
/// eyeballed without a full web deploy. Writes build/megi_preview.png.
void main() {
  testWidgets('render MeGi preview sheet', (tester) async {
    final boundaryKey = GlobalKey();

    await tester.binding.setSurfaceSize(const Size(640, 340));
    tester.view.devicePixelRatio = 3.0;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                const MeGiMascot(size: 300),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 8),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const MeGiMascot(size: 46, showShadow: false),
                    ),
                    const SizedBox(height: 18),
                    const MeGiMascot(size: 28, showShadow: false),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryDeepBlue,
                        AppTheme.primaryBlue,
                      ],
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      MeGiMascotBadge(size: 40),
                      SizedBox(width: 10),
                      Text(
                        'MeGi',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('build/megi_preview.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
