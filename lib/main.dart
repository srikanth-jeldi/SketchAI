import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:async';

import 'storage/local_diagnostics.dart';

import 'screens/gallery_screen.dart';
import 'storage/sketch_store.dart';
import 'theme.dart';
import 'coloring/art_catalog.dart';
import 'ads/test_ads.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PaintingBinding.instance.imageCache.maximumSizeBytes = 24 * 1024 * 1024;
  PaintingBinding.instance.imageCache.maximumSize = 60;
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      LocalDiagnostics.record(
        'flutter-error',
        details.exception,
        details.stack ?? StackTrace.current,
      ),
    );
  };
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SketchoraApp());
  unawaited(TestAds.instance.initialize());
}

class SketchoraApp extends StatelessWidget {
  final Future<SketchStore> Function()? storeLoader;
  const SketchoraApp({super.key, this.storeLoader});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sketluma',
    debugShowCheckedModeBanner: false,
    theme: sketchoraTheme(),
    home: _BootScreen(storeLoader: storeLoader),
  );
}

class _BootScreen extends StatefulWidget {
  final Future<SketchStore> Function()? storeLoader;
  const _BootScreen({this.storeLoader});
  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> with WidgetsBindingObserver {
  late Future<SketchStore> _store;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _store = _open();
  }

  Future<SketchStore> _open() async {
    unawaited(LocalDiagnostics.previousExit());
    return widget.storeLoader?.call() ?? SketchStore.open();
  }

  @override
  void didHaveMemoryPressure() {
    PaintingBinding.instance.imageCache.clear();
    clearUnusedArtwork();
    unawaited(
      LocalDiagnostics.record(
        'memory-pressure',
        'OS requested cache release',
        StackTrace.current,
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      PaintingBinding.instance.imageCache.clear();
      clearUnusedArtwork();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<SketchStore>(
    future: _store,
    builder: (context, snapshot) {
      if (snapshot.hasData) return GalleryScreen(store: snapshot.data!);
      return Scaffold(
        backgroundColor: plum,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Image.asset(
                  'assets/branding/sketluma-full-logo-v1.png',
                  width: 340,
                  semanticLabel: 'Sketluma. Sketch and Paint.',
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'A quiet space for bold ideas.',
                style: TextStyle(color: Color(0xFFCFBFD7)),
              ),
              const SizedBox(height: 28),
              if (snapshot.hasError) ...[
                const Text(
                  'Could not open local storage.',
                  style: TextStyle(color: Colors.white),
                ),
                TextButton(
                  onPressed: () => setState(() => _store = _open()),
                  child: const Text('Try again'),
                ),
              ] else
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
        ),
      );
    },
  );
}
