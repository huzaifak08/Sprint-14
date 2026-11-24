// Renders the brand SVGs (tool/brand + assets/images/logo.svg) into every PNG
// the app and the stores need. Run from the project root:
//
//   flutter test tool/brand/render_brand_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// Re-run after editing any SVG.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ui.Picture> _svgPicture(String path) async {
  final info = await vg.loadPicture(SvgStringLoader(File(path).readAsStringSync()), null);
  return info.picture;
}

/// Draws [layers] (1024x1024 SVGs) onto a [w]x[h] canvas, each scaled by
/// [scale] around the canvas centre, and writes a PNG to [out].
Future<void> _render(
  String out, {
  required int w,
  required int h,
  required List<String> layers,
  double scale = 1,
  Offset offset = Offset.zero,
  void Function(Canvas canvas)? background,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  background?.call(canvas);
  final size = (w < h ? w : h) * scale;
  canvas.save();
  canvas.translate((w - size) / 2 + offset.dx, (h - size) / 2 + offset.dy);
  canvas.scale(size / 1024);
  for (final layer in layers) {
    canvas.drawPicture(await _svgPicture(layer));
  }
  canvas.restore();
  final image = await recorder.endRecording().toImage(w, h);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  File(out)
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('render brand assets', (tester) async {
    await tester.runAsync(() async {
      const logo = 'assets/images/logo.svg';
      const glyph = 'tool/brand/glyph.svg';
      const mono = 'tool/brand/glyph_mono.svg';
      const bg = 'tool/brand/background.svg';

      // App icons. Rounded logo for legacy Android launchers; full square for
      // iOS and the Play Store (they apply their own mask).
      await _render('assets/icon/icon_android_legacy.png', w: 1024, h: 1024, layers: [logo]);
      await _render('assets/icon/icon_square.png', w: 1024, h: 1024, layers: [bg, glyph]);

      // Adaptive icon (Android 8+). flutter_launcher_icons wraps the
      // foreground in a 16% inset, so 0.9 here ends up ~60% of the icon:
      // inside the 66% safe zone, so round/squircle masks never clip it.
      await _render('assets/icon/adaptive_background.png', w: 1024, h: 1024, layers: [bg]);
      await _render('assets/icon/adaptive_foreground.png', w: 1024, h: 1024, layers: [glyph], scale: 0.9);
      await _render('assets/icon/adaptive_monochrome.png', w: 1024, h: 1024, layers: [mono], scale: 0.9);

      // Launch screen (Android 12+ shows the icon inside a circle).
      await _render('assets/icon/splash_logo.png', w: 1152, h: 1152, layers: [glyph], scale: 0.58);
      await _render('assets/icon/splash_logo_legacy.png', w: 512, h: 512, layers: [glyph], scale: 0.9);

      // Status-bar notification icon: white mark on transparent.
      const densities = {'mdpi': 24, 'hdpi': 36, 'xhdpi': 48, 'xxhdpi': 72, 'xxxhdpi': 96};
      for (final e in densities.entries) {
        await _render(
          'android/app/src/main/res/drawable-${e.key}/ic_stat_notification.png',
          w: e.value,
          h: e.value,
          layers: [mono],
          scale: 1.3,
        );
      }

      // Play Store graphics (text is added by tool/brand/feature_graphic.py).
      await _render('distribution/store_listing/icon_512.png', w: 512, h: 512, layers: [bg, glyph]);
      await _render(
        'distribution/store_listing/feature_graphic_base.png',
        w: 1024,
        h: 500,
        layers: [glyph],
        scale: 0.9,
        offset: const Offset(-300, 0),
        background: (canvas) {
          canvas.drawRect(
            const Rect.fromLTWH(0, 0, 1024, 500),
            Paint()
              ..shader = ui.Gradient.linear(
                Offset.zero,
                const Offset(1024, 500),
                [const Color(0xFF5A9BFF), const Color(0xFF1F56D6)],
              ),
          );
        },
      );
    });
  });
}
