import 'package:flutter/material.dart';

import '../coloring/art_catalog.dart';
import '../drawing/document.dart';
import '../storage/sketch_store.dart';
import '../storage/local_diagnostics.dart';
import 'studio_screen.dart';

class ArtworkStudioGate extends StatefulWidget {
  final SketchDocument document;
  final SketchStore store;
  const ArtworkStudioGate({
    super.key,
    required this.document,
    required this.store,
  });
  @override
  State<ArtworkStudioGate> createState() => _ArtworkStudioGateState();
}

class _ArtworkStudioGateState extends State<ArtworkStudioGate> {
  late Future<void> _ready;
  @override
  void initState() {
    super.initState();
    retainArtwork(widget.document.artworkId);
    _ready = _load();
  }

  Future<void> _load() async {
    try {
      await ensureArtworkLoaded(widget.document.artworkId);
      if (!mounted) clearUnusedArtwork();
    } catch (e, st) {
      await LocalDiagnostics.record('artwork-load', e, st);
      rethrow;
    }
  }

  @override
  void dispose() {
    final id = widget.document.artworkId;
    WidgetsBinding.instance.addPostFrameCallback((_) => releaseArtwork(id));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<void>(
    future: _ready,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done &&
          !snapshot.hasError) {
        return StudioScreen(document: widget.document, store: widget.store);
      }
      return Scaffold(
        appBar: AppBar(title: const Text('Preparing your canvas')),
        body: Center(
          child: snapshot.hasError
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'This artwork could not open. Your saved work is safe.',
                    ),
                    TextButton(
                      onPressed: () => setState(() => _ready = _load()),
                      child: const Text('Try again'),
                    ),
                  ],
                )
              : const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Preparing colour areas…'),
                  ],
                ),
        ),
      );
    },
  );
}
