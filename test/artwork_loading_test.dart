import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/coloring/art_catalog.dart';
import 'package:sketchora/main.dart';
import 'package:sketchora/screens/gallery_screen.dart';
import 'package:sketchora/storage/sketch_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'raster loads deduplicate, protect active art, release and reload',
    (tester) async {
      await tester.runAsync(() async {
        clearUnusedArtwork();
        expect(premiumDesigns, isEmpty);
        retainArtwork('premium_0');
        final a = ensureArtworkLoaded('premium_0');
        expect(identical(a, ensureArtworkLoaded('premium_0')), isTrue);
        await a;
        final before = ArtCatalog.design('premium_0').regions
            .map((e) => e.id)
            .toList();
        clearUnusedArtwork();
        expect(premiumDesigns.keys, ['premium_0']);
        releaseArtwork('premium_0');
        expect(premiumDesigns, isEmpty);
        await ensureArtworkLoaded('premium_0');
        expect(
          ArtCatalog.design('premium_0').regions.map((e) => e.id).toList(),
          before,
        );
        clearUnusedArtwork();
      });
    },
  );
  testWidgets(
    'home boots without decoding masks and survives simulated idle and memory pressure',
    (tester) async {
      final directory = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('sketchora-idle-'),
      ))!;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            (call) async => directory.path,
          );
      clearUnusedArtwork();
      await tester.pumpWidget(
        SketchoraApp(storeLoader: () async => _IdleStore(directory)),
      );
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pump();
      await tester.runAsync(() async {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(premiumDesigns, isEmpty);
      await tester.pump(const Duration(hours: 1));
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      tester.binding.handleMemoryPressure();
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(find.byType(GalleryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => directory.delete(recursive: true));
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/path_provider'),
            null,
          );
    },
  );
}

class _IdleStore extends SketchStore {
  _IdleStore(super.directory);
  @override
  Future<SketchLoadResult> loadAll() async => const SketchLoadResult([], 0, 0);
}
