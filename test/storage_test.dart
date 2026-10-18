import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sketchora/drawing/document.dart';
import 'package:sketchora/storage/sketch_store.dart';

void main() {
  late Directory directory;
  late SketchStore store;
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('sketchora_test_');
    store = SketchStore(directory);
  });
  tearDown(() async {
    await directory.delete(recursive: true);
  });
  test(
    'queued writes retain latest revision and newest sketches sort first',
    () async {
      final first = SketchDocument.create(title: 'First');
      final writes = [
        store.save(first),
        store.save(first.copyWith(title: 'Second')),
        store.save(first.copyWith(title: 'Latest')),
      ];
      await Future.wait(writes);
      final result = await store.loadAll();
      expect(result.documents.single.title, 'Latest');
      expect(result.unreadable, 0);
    },
  );
  test('corrupt primary recovers previous valid project without deleting originals', () async {
    final doc = SketchDocument.create(title: 'Original');
    await store.save(doc);
    await store.save(doc.copyWith(title: 'New version'));
    final primary = File('${directory.path}/${doc.id}.sketch');
    await primary.writeAsString('{broken');
    final result = await store.loadAll();
    expect(result.documents.single.title, 'Original');
    expect(result.recovered, 1);
    expect(await primary.readAsString(), '{broken');
  });
  test('interrupted first save is recovered from temporary document', () async {
    final doc = SketchDocument.create();
    await store.save(doc);
    await File('${directory.path}/${doc.id}.sketch')
        .rename('${directory.path}/${doc.id}.sketch.tmp');
    final result = await store.loadAll();
    expect(result.documents.single.id, doc.id);
    expect(result.recovered, 1);
  });
  test(
    'unreadable files are reported and delete removes recovery copies',
    () async {
      final doc = SketchDocument.create();
      await store.save(doc);
      await store.save(doc);
      await File('${directory.path}/123.sketch').writeAsString('broken');
      final result = await store.loadAll();
      expect(result.unreadable, 1);
      expect(result.documents.length, 1);
      await store.delete(doc.id);
      expect((await store.loadAll()).documents, isEmpty);
      expect(
        await File('${directory.path}/${doc.id}.sketch.bak').exists(),
        false,
      );
    },
  );
}
