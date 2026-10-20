import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/ads/test_ads.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/drawing/editor.dart';
import 'package:sketchora/screens/studio_screen.dart';
import 'package:sketchora/storage/sketch_store.dart';
import 'package:sketchora/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('live ad selection requires Android release and explicit opt-in', () {
    for (final release in [false, true]) {
      for (final android in [false, true]) {
        for (final enabled in [false, true]) {
          expect(
            SketlumaAdIds.useLive(
              release: release,
              android: android,
              enabled: enabled,
            ),
            release && android && enabled,
          );
        }
      }
    }
    expect(SketlumaAdIds.banner, TestAdIds.banner);
    expect(SketlumaAdIds.interstitial, TestAdIds.interstitial);
  });
  test('test ad IDs and completion frequency policy', () {
    expect(TestAdIds.banner, startsWith('ca-app-pub-3940256099942544/'));
    expect(TestAdIds.interstitial, startsWith('ca-app-pub-3940256099942544/'));
    final policy = CompletionAdPolicy(), now = DateTime(2026, 10, 19);
    expect(policy.canShow('one', now), isTrue);
    policy.recordShown('one', now);
    expect(policy.canShow('one', now.add(const Duration(days: 1))), isFalse);
    expect(
      policy.canShow('two', now.add(const Duration(seconds: 30))),
      isFalse,
    );
    expect(policy.canShow('two', now.add(const Duration(seconds: 61))), isTrue);
  });
  test('an unavailable ad never blocks completion', () async {
    await TestAds.instance
        .afterCompletion('offline')
        .timeout(const Duration(milliseconds: 200));
  });
  test('free drawings retain completion and new strokes reopen them', () {
    final editor = DrawingEditor(SketchDocument.create());
    editor.markCompleted();
    expect(SketchDocument.fromJson(editor.document.toJson()).completed, isTrue);
    editor.addStroke(
      InkStroke(
        points: const [InkPoint(Offset(50, 50))],
        color: 0xFF8050EF,
        width: 8,
        opacity: 1,
        brush: BrushKind.pen,
      ),
    );
    expect(editor.document.completed, isFalse);
    editor.dispose();
  });
  testWidgets(
    'Done saves a thumbnail, celebrates and returns Home without an ad',
    (tester) async {
      final store = _Store(Directory.current);
      final doc = SketchDocument.create(
        title: 'My painting',
        width: 2048,
        height: 2048,
        artworkId: 'art_0_0',
      ).copyWith(regionColors: {'r0': 0xFF8050EF});
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          theme: sketchoraTheme(),
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudioScreen(
                        document: doc,
                        store: store,
                        completionAudio: false,
                      ),
                    ),
                  );
                },
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Done'));
      // Alternate frames with real IO/raster time: PNG encoding spans both.
      for (var i = 0; i < 100 && store.thumbnailBytes == null; i++) {
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
      }
      await tester.pumpAndSettle();
      expect(find.text('Artwork complete!'), findsOneWidget);
      expect(store.saved?.completed, isTrue);
      expect(store.thumbnailBytes, isNotEmpty);
      await tester.ensureVisible(find.text('Back to Home'));
      await tester.tap(find.text('Back to Home'));
      await tester.pump();
      await tester.pumpAndSettle();
      expect(result, isTrue);
      expect(find.text('Home'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}

class _Store extends SketchStore {
  _Store(super.directory);
  SketchDocument? saved;
  Uint8List? thumbnailBytes;
  final thumbnailSaved = Completer<void>();
  @override
  Future<void> save(SketchDocument document) async {
    saved = document;
  }

  @override
  Future<void> saveThumbnail(String id, Uint8List bytes) async {
    thumbnailBytes = bytes;
    if (!thumbnailSaved.isCompleted) thumbnailSaved.complete();
  }
}
