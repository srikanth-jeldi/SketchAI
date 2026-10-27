import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets('freeze Atelier visibility from 2K masks', (tester) async {
    await tester.runAsync(() async {
      final rows = <String>[];
      for (var i = 0; i < atelierCount; i++) {
        final art = ArtCatalog.design('atelier_$i');
        final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
        canvas.scale(2.048);
        for (final region in art.regions) {
          final n = int.parse(region.id.substring(1)) + 1;
          canvas.drawPath(
            region.path,
            Paint()
              ..isAntiAlias = false
              ..color = Color(0xFF000000 | n),
          );
        }
        final picture = recorder.endRecording();
        final image = await picture.toImage(2048, 2048);
        final bytes = (await image.toByteData())!.buffer.asUint8List();
        final visible = <int>{};
        for (var p = 0; p < bytes.length; p += 4) {
          if (bytes[p + 3] != 0) {
            visible.add(
              (bytes[p] << 16 | bytes[p + 1] << 8 | bytes[p + 2]) - 1,
            );
          }
        }
        final last = int.parse(art.regions.last.id.substring(1));
        final hidden = [
          for (var n = 0; n <= last; n++)
            if (!visible.contains(n)) '$n',
        ];
        rows.add("  '${hidden.join(',')}',");
        image.dispose();
        picture.dispose();
        if (i % 60 == 0) debugPrint('Prepared $i / $atelierCount');
      }
      File('lib/coloring/atelier_visibility.dart').writeAsStringSync(
        "part of 'art_catalog.dart';\n\n// Generated from 2K region masks. Preserve with catalogue v1.\nconst List<String> _atelierHiddenRegions = [\n${rows.join('\n')}\n];\n",
      );
    });
  }, timeout: const Timeout(Duration(minutes: 20)));
}
