import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/gallery_screen.dart';
import 'storage/sketch_store.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  runApp(const SketchoraApp());
}

class SketchoraApp extends StatelessWidget {
  const SketchoraApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Sketchora',
    debugShowCheckedModeBanner: false,
    theme: sketchoraTheme(),
    home: const _BootScreen(),
  );
}

class _BootScreen extends StatefulWidget {
  const _BootScreen();
  @override
  State<_BootScreen> createState() => _BootScreenState();
}

class _BootScreenState extends State<_BootScreen> {
  late Future<SketchStore> _store;
  @override
  void initState() {
    super.initState();
    _store = SketchStore.open();
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
                  'assets/branding/sketchora-full-logo-v1.png',
                  width: 340,
                  semanticLabel: 'Sketchora. Sketch and Paint.',
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
                  onPressed: () => setState(() => _store = SketchStore.open()),
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
