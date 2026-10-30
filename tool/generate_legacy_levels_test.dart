import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('freeze original catalogue difficulty metadata', () {
    final levels = ArtCatalog.entries.map((e) {
      final n = ArtCatalog.design(e.id).regions.length;
      return n <= 45
          ? '0'
          : n <= 90
          ? '1'
          : '2';
    }).join();
    File('lib/coloring/legacy_levels.dart').writeAsStringSync(
      "part of 'art_catalog.dart';\n\n// Closed-region grades of the original, immutable 2,000 pages.\nconst String _legacyLevels = '$levels';\n",
    );
  });
}
