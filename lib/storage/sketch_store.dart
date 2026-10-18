import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import '../drawing/document.dart';

class SketchLoadResult {
  final List<SketchDocument> documents;
  final int unreadable;
  final int recovered;
  const SketchLoadResult(this.documents, this.unreadable, this.recovered);
}

class SketchStore {
  final Directory directory;
  Future<void> _queue = Future.value();
  SketchStore(this.directory);
  static Future<SketchStore> open() async {
    final root = await getApplicationSupportDirectory();
    final directory = Directory('${root.path}/sketches');
    await directory.create(recursive: true);
    return SketchStore(directory);
  }

  File _file(String id, String suffix) {
    if (!RegExp(r'^\d+$').hasMatch(id)) {
      throw const FormatException('Invalid sketch ID');
    }
    return File('${directory.path}/$id$suffix');
  }

  Future<SketchLoadResult> loadAll() async {
    await _queue;
    final ids = <String>{};
    await for (final file in directory.list()) {
      final name = file.uri.pathSegments.last;
      final match = RegExp(r'^(\d+)\.sketch(?:\.bak|\.tmp)?$').firstMatch(name);
      if (match != null) ids.add(match[1]!);
    }
    final documents = <SketchDocument>[];
    var unreadable = 0, recovered = 0;
    for (final id in ids) {
      SketchDocument? doc;
      for (final suffix in ['.sketch', '.sketch.tmp', '.sketch.bak']) {
        try {
          doc = SketchDocument.fromJson(
            jsonDecode(await _file(id, suffix).readAsString())
                as Map<String, dynamic>,
          );
          if (doc.id != id) throw const FormatException('Mismatched sketch ID');
          if (suffix != '.sketch') recovered++;
          break;
        } catch (_) {
          doc = null;
        }
      }
      if (doc == null) {
        unreadable++;
      } else {
        documents.add(doc);
      }
    }
    documents.sort((a, b) => b.modified.compareTo(a.modified));
    return SketchLoadResult(documents, unreadable, recovered);
  }

  Future<void> _enqueue(Future<void> Function() action) {
    final next = _queue.then((_) => action());
    // A failed save is surfaced to its caller, but does not poison later retries.
    _queue = next.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    return next;
  }

  Future<void> save(SketchDocument document) => _enqueue(() async {
    final target = _file(document.id, '.sketch');
    final temp = _file(document.id, '.sketch.tmp');
    final backup = _file(document.id, '.sketch.bak');
    await temp.writeAsString(jsonEncode(document.toJson()), flush: true);
    if (await target.exists()) {
      // Validate before replacing the recovery copy with the previous version.
      try {
        SketchDocument.fromJson(
          jsonDecode(await target.readAsString()) as Map<String, dynamic>,
        );
        await target.copy(backup.path);
      } on FormatException {
        /* Preserve the known-good backup. */
      }
    }
    await temp.rename(target.path);
  });
  File thumbnail(String id) => _file(id, '.png');
  Future<void> saveThumbnail(String id, Uint8List bytes) => _enqueue(() async {
    final temp = _file(id, '.png.tmp');
    await temp.writeAsBytes(bytes, flush: true);
    await temp.rename(thumbnail(id).path);
  });
  Future<void> delete(String id) => _enqueue(() async {
    for (final suffix in [
      '.sketch',
      '.sketch.bak',
      '.sketch.tmp',
      '.png',
      '.png.tmp',
    ]) {
      final file = _file(id, suffix);
      if (await file.exists()) await file.delete();
    }
  });
}
