import 'dart:io';

import 'package:flutter/services.dart';

import 'package:path_provider/path_provider.dart';

/// Bounded device-local diagnostics. Never uploaded and no artwork content.
class LocalDiagnostics {
  static Future<void> previousExit() async {
    try {
      final exit = await const MethodChannel('sketchora/diagnostics')
          .invokeMethod<Object?>('previousExit');
      if (exit != null) {
        await record('previous-android-exit', exit, StackTrace.current);
      }
    } catch (_) {
      /* Older Android/iOS and test platforms need no channel. */
    }
  }

  static Future<File> exportFile() async {
    final root = await getApplicationSupportDirectory();
    final source = File('${root.path}/sketchora-diagnostics.txt');
    final temp = await getTemporaryDirectory();
    final export = File('${temp.path}/sketchora-diagnostics.txt');
    await _queue;
    await export.writeAsString(
      await source.exists() ? await source.readAsString() : 'No local error records. Native exit history requires Android 11 or newer.',
    );
    return export;
  }

  static Future<void> _queue = Future.value();
  static Future<void> record(String event, Object error, StackTrace stack) {
    final next = _queue.then((_) async {
      try {
        final root = await getApplicationSupportDirectory();
        final file = File('${root.path}/sketchora-diagnostics.txt');
        if (await file.exists() && await file.length() > 65536) {
          await file.writeAsString('Older diagnostics rotated.\n');
        }
        final detail = '$error';
        await file.writeAsString(
          '${DateTime.now().toUtc().toIso8601String()} $event\n${detail.length > 1000 ? detail.substring(0, 1000) : detail}\n${stack.toString().split('\n').take(12).join('\n')}\n',
          mode: FileMode.append,
        );
      } catch (_) {
        /* Diagnostics must never break painting. */
      }
    });
    _queue = next;
    return next;
  }
}
