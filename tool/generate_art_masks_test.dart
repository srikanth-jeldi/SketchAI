import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Original colouring masks retain every component ID', () async {
    var checked = 0;
    for (final file
        in Directory('assets/artwork').listSync().whereType<File>().where(
          (f) => f.path.endsWith('.png') && !f.path.contains('-reference-'),
        )) {
      final square = file.path.contains('-outline-');
      final codec = await ui.instantiateImageCodec(
        await file.readAsBytes(),
        targetWidth: square ? 1024 : null,
      );
      final image = (await codec.getNextFrame()).image;
      final rgba = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!
          .buffer
          .asUint8List();
      final mask = _outlineRuns((rgba, image.width, image.height, square));
      final runs = mask['runs'] as Int32List;
      final data = ByteData(8 + runs.length * 4)
        ..setUint32(0, mask['w'] as int, Endian.little)
        ..setUint32(4, mask['h'] as int, Endian.little);
      for (var i = 0; i < runs.length; i++) {
        data.setInt32(8 + i * 4, runs[i], Endian.little);
      }
      final destination = File(file.path.replaceAll('.png', '.mask'));
      if (Platform.environment['GENERATE_ART_MASKS'] == '1') {
        await destination.writeAsBytes(zlib.encode(data.buffer.asUint8List()));
      } else {
        expect(zlib.decode(await destination.readAsBytes()),
            orderedEquals(data.buffer.asUint8List()), reason: file.path);
      }
      image.dispose();
      codec.dispose();
      checked++;
    }
    expect(checked, 14);
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Map<String, Object> _outlineRuns((Uint8List, int, int, bool) input) {
  final (rgba, width, height, square) = input;
  // Half-resolution hit masks keep touch detection and retained paths bounded.
  // A dark source pixel blocks its cell, preserving fine walls conservatively.
  final w = width ~/ (square ? 2 : 4), h = height ~/ 2;
  final labels = Int32List(w * h);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      for (var dy = 0; dy < 2; dy++) {
        for (var dx = 0; dx < 2; dx++) {
          final p = ((y * 2 + dy) * width + x * 2 + dx) * 4;
          if (rgba[p] + rgba[p + 1] + rgba[p + 2] < 570) labels[y * w + x] = -1;
        }
      }
    }
  }
  var label = 0;
  final queue = Int32List(w * h);
  final counts = <int>[0];
  for (var seed = 0; seed < labels.length; seed++) {
    if (labels[seed] != 0) continue;
    label++;
    var head = 0, tail = 1;
    queue[0] = seed;
    labels[seed] = label;
    while (head < tail) {
      final p = queue[head++], x = p % w;
      for (final q in [
        if (x > 0) p - 1,
        if (x < w - 1) p + 1,
        if (p >= w) p - w,
        if (p < labels.length - w) p + w,
      ]) {
        if (labels[q] == 0) {
          labels[q] = label;
          queue[tail++] = q;
        }
      }
    }
    counts.add(tail);
  }
  // Preserve component IDs from v0.3 saves, but extend colour beneath ink.
  // Conservative source barriers otherwise leave white stripes where the
  // monochrome display suppresses pale source texture.
  var head = 0, tail = 0;
  for (var p = 0; p < labels.length; p++) {
    if (labels[p] > 0 && counts[labels[p]] >= 18) {
      queue[tail++] = p;
    } else {
      labels[p] = 0;
    }
  }
  while (head < tail) {
    final p = queue[head++], x = p % w;
    // Absorb discarded texture specks into the nearest original area. Existing
    // area seeds never change ownership; ink is drawn above this colour map.
    for (final q in [
      if (x > 0) p - 1,
      if (x < w - 1) p + 1,
      if (p >= w) p - w,
      if (p < labels.length - w) p + w,
    ]) {
      if (labels[q] == 0) {
        labels[q] = labels[p];
        queue[tail++] = q;
      }
    }
  }
  final runs = <int>[];
  for (var y = 0; y < h; y++) {
    var x = 0;
    while (x < w) {
      final id = labels[y * w + x], start = x++;
      while (x < w && labels[y * w + x] == id) {
        x++;
      }
      if (id > 0) {
        runs.addAll([id, start, y, x - start]);
      }
    }
  }
  return {'w': w, 'h': h, 'runs': Int32List.fromList(runs)};
}
