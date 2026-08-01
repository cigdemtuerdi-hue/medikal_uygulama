import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:medikal_uygulama/config/app_theme.dart';
import 'package:medikal_uygulama/widgets/medgift_logo.dart';

/// Exports the MedGift mark to the raster files the web build needs.
///
/// The logo only exists as Dart `CustomPaint`, so the shipped favicon and PWA
/// icons were still Flutter's default logo. Rendering the real widget here
/// keeps the exported art identical to what the app draws — redrawing it by
/// hand in an image editor would drift the moment the painter changes.
///
/// Run with: flutter test test/generate_brand_icons_test.dart
void main() {
  /// `flutter test` ships only the blank Ahem font, which would render the
  /// share card's copy as solid boxes. The exported PNG has to be legible, so
  /// pull a real face off the host machine.
  Future<String?> loadHostFont() async {
    const faces = <String, String>{
      'BrandSans': '/System/Library/Fonts/Supplemental/Arial.ttf',
      'BrandSansBold': '/System/Library/Fonts/Supplemental/Arial Bold.ttf',
    };
    for (final entry in faces.entries) {
      final file = File(entry.value);
      if (!file.existsSync()) return null;
      final loader = FontLoader(entry.key)
        ..addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      await loader.load();
    }
    return 'BrandSans';
  }

  /// `maskable` and `ios` icons must keep their art inside the area the OS
  /// leaves visible after masking, so the mark is inset and the padding is
  /// filled with brand blue instead of transparency.
  Future<void> exportIcon(
    WidgetTester tester, {
    required String path,
    required int pixels,
    bool maskable = false,
    bool ios = false,
  }) async {
    final boundaryKey = GlobalKey();
    const logical = 256.0;
    final ratio = pixels / logical;
    final inset = maskable ? 0.64 : (ios ? 0.78 : 1.0);

    await tester.binding.setSurfaceSize(const Size(logical, logical));
    tester.view.devicePixelRatio = ratio;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          key: boundaryKey,
          child: Container(
            width: logical,
            height: logical,
            color: inset == 1.0 ? AppTheme.cleanWhite : AppTheme.primaryDeepBlue,
            alignment: Alignment.center,
            child: MedGiftLogo(size: logical * inset),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File(path);
      out.parent.createSync(recursive: true);
      // App Store Connect rejects icons that carry an alpha channel at all,
      // even a fully opaque one, so iOS assets are re-encoded without it.
      out.writeAsBytesSync(
        ios
            ? img.encodePng(
                img.decodePng(bytes!.buffer.asUint8List())!
                    .convert(numChannels: 3),
              )
            : bytes!.buffer.asUint8List(),
      );
    });
  }

  testWidgets('export favicon and PWA icons', (tester) async {
    await exportIcon(tester, path: 'web/favicon.png', pixels: 64);
    await exportIcon(tester, path: 'web/icons/Icon-192.png', pixels: 192);
    await exportIcon(tester, path: 'web/icons/Icon-512.png', pixels: 512);
    await exportIcon(
      tester,
      path: 'web/icons/Icon-maskable-192.png',
      pixels: 192,
      maskable: true,
    );
    await exportIcon(
      tester,
      path: 'web/icons/Icon-maskable-512.png',
      pixels: 512,
      maskable: true,
    );
  });

  testWidgets('export iOS app icons', (tester) async {
    const appIcon = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
    const sizes = <String, int>{
      'Icon-App-20x20@1x': 20,
      'Icon-App-20x20@2x': 40,
      'Icon-App-20x20@3x': 60,
      'Icon-App-29x29@1x': 29,
      'Icon-App-29x29@2x': 58,
      'Icon-App-29x29@3x': 87,
      'Icon-App-40x40@1x': 40,
      'Icon-App-40x40@2x': 80,
      'Icon-App-40x40@3x': 120,
      'Icon-App-60x60@2x': 120,
      'Icon-App-60x60@3x': 180,
      'Icon-App-76x76@1x': 76,
      'Icon-App-76x76@2x': 152,
      'Icon-App-83.5x83.5@2x': 167,
      'Icon-App-1024x1024@1x': 1024,
    };

    for (final entry in sizes.entries) {
      await exportIcon(
        tester,
        path: '$appIcon/${entry.key}.png',
        pixels: entry.value,
        ios: true,
      );
    }
  });

  testWidgets('export social share card', (tester) async {
    // 1200x630 is the size Facebook, LinkedIn and X expect for link previews.
    final boundaryKey = GlobalKey();
    String? fontFamily;
    await tester.runAsync(() async {
      fontFamily = await loadHostFont();
    });
    const width = 600.0;
    const height = 315.0;
    const ratio = 2.0;

    await tester.binding.setSurfaceSize(const Size(width, height));
    tester.view.devicePixelRatio = ratio;

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        // Without a Material ancestor Flutter paints the debug yellow
        // underline under every Text, which would bake into the PNG.
        home: Material(
          type: MaterialType.transparency,
          child: RepaintBoundary(
            key: boundaryKey,
            child: Container(
              width: width,
              height: height,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primaryDeepBlue, AppTheme.primaryBlue],
                ),
              ),
              padding: const EdgeInsets.all(40),
              child: Row(
                children: [
                  const MedGiftLogo(size: 132),
                  const SizedBox(width: 32),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MedGift US',
                          style: TextStyle(
                            fontFamily:
                                fontFamily == null ? null : 'BrandSansBold',
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Donate and receive durable medical equipment '
                          'across the United States.',
                          style: TextStyle(
                            fontFamily: fontFamily,
                            color: Colors.white.withValues(alpha: 0.92),
                            fontSize: 18,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'medgift.us',
                          style: TextStyle(
                            fontFamily:
                                fontFamily == null ? null : 'BrandSansBold',
                            color: AppTheme.skyBlue.withValues(alpha: 0.95),
                            fontSize: 17,
                            letterSpacing: 0.5,
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
      ),
    );
    await tester.pumpAndSettle();

    final boundary =
        boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;

    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: ratio);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final out = File('web/icons/social-card.png');
      out.parent.createSync(recursive: true);
      out.writeAsBytesSync(bytes!.buffer.asUint8List());
    });
  });
}
