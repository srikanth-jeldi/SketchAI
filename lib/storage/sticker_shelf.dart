import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import '../drawing/decoration.dart';
import '../drawing/document.dart' show newSketchId;

class StickerShelf {
  final Directory directory;
  StickerShelf(Directory sketches)
    : directory = Directory('${sketches.path}/stickers');
  Future<List<CanvasDecoration>> load() async {
    if (!await directory.exists()) return [];
    final result = <CanvasDecoration>[];
    await for (final file in directory.list()) {
      if (file is! File ||
          !file.path.endsWith('.sticker') ||
          await file.length() > 2300000) {
        continue;
      }
      try {
        result.add(
          CanvasDecoration.fromJson(
            jsonDecode(await file.readAsString()) as Map<String, dynamic>,
          ),
        );
      } catch (_) {
        /* Ignore an unreadable shelf item, without losing saved artwork. */
      }
      if (result.length == 40) break;
    }
    return result;
  }

  Future<void> save(CanvasDecoration item) async {
    await directory.create(recursive: true);
    if ((await load()).length >= 40) {
      throw StateError('Your sticker shelf is full (40 stickers).');
    }
    final copy = item.copyWith(
      id: newSketchId(),
      center: const Offset(0, 0),
      behindInk: false,
    );
    final file = File('${directory.path}/${copy.id}.sticker');
    final temp = File('${file.path}.tmp');
    await temp.writeAsString(jsonEncode(copy.toJson()), flush: true);
    await temp.rename(file.path);
  }

  Future<void> delete(String id) async {
    if (!RegExp(r'^\d+$').hasMatch(id)) return;
    final file = File('${directory.path}/$id.sticker');
    if (await file.exists()) await file.delete();
  }
}
