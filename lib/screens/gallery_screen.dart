import 'package:flutter/material.dart';

import '../drawing/document.dart';
import '../drawing/renderer.dart';
import '../storage/sketch_store.dart';
import '../theme.dart';
import 'artwork_studio_gate.dart';
import '../coloring/library_screen.dart';
import '../storage/local_diagnostics.dart';

import 'package:share_plus/share_plus.dart';

import '../ads/test_ads.dart';

class GalleryScreen extends StatefulWidget {
  final SketchStore store;
  const GalleryScreen({super.key, required this.store});
  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<SketchDocument> _documents = [];
  bool _loading = true, _creating = false;
  bool _galleryOnly = false;
  String? _error, _notice;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final result = await widget.store.loadAll();
      if (!mounted) return;
      setState(() {
        _documents = result.documents;
        _loading = false;
        _error = null;
        _notice = result.unreadable > 0
            ? '${result.unreadable} sketch file(s) could not be opened. Original files are preserved.'
            : result.recovered > 0
            ? 'Recovered ${result.recovered} sketch(es) from a local recovery copy.'
            : null;
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Could not load your sketches. Please try again.';
        });
      }
    }
  }

  Future<void> _open(SketchDocument doc) async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => ArtworkStudioGate(document: doc, store: widget.store),
      ),
    );
    if (completed == true && mounted) setState(() => _galleryOnly = false);
    await _load();
  }

  void _returnHome() {
    if (!mounted) return;
    setState(() => _galleryOnly = false);
    _load();
  }

  Future<void> _create() async {
    if (_creating) return;
    final preset = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'A fresh start',
                style: Theme.of(context).textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your canvas. Make it yours.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 16),
              for (final item in [
                (0, Icons.crop_portrait_rounded, 'Portrait', '1200 × 1600'),
                (1, Icons.crop_square_rounded, 'Square', '1400 × 1400'),
                (2, Icons.crop_landscape_rounded, 'Landscape', '1600 × 1200'),
              ])
                ListTile(
                  leading: Icon(item.$2, color: violet),
                  title: Text(item.$3),
                  subtitle: Text(item.$4),
                  trailing: const Icon(Icons.arrow_forward_rounded, size: 20),
                  onTap: () => Navigator.pop(context, item.$1),
                ),
            ],
          ),
        ),
      ),
    );
    if (preset == null || !mounted) return;
    setState(() => _creating = true);
    try {
      final doc = SketchDocument.create(
        title: 'Untitled ${_documents.length + 1}',
        width: preset == 1
            ? 1400
            : preset == 2
            ? 1600
            : 1200,
        height: preset == 1
            ? 1400
            : preset == 2
            ? 1200
            : 1600,
      );
      await widget.store.save(doc);
      if (mounted) await _open(doc);
    } catch (_) {
      if (mounted) {
        _snack(
          'Could not create the sketch. Check available storage and try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _colourDesign() async {
    final completed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ArtLibraryScreen(store: widget.store)),
    );
    if (completed == true) _returnHome();
    await _load();
  }

  void _snack(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
  Future<void> _shareDiagnostics() async {
    try {
      final file = await LocalDiagnostics.exportFile();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Sketchora local diagnostics. Shared manually by the user.',
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) _snack('Could not prepare diagnostics. Please try again.');
    }
  }

  Future<void> _action(SketchDocument doc, String action) async {
    try {
      if (action == 'rename') {
        final name = await requestName(context, doc.title);
        if (name != null) await widget.store.save(doc.copyWith(title: name));
      } else if (action == 'duplicate') {
        final fresh = SketchDocument.create(
          title: '${doc.title} copy',
          width: doc.width,
          height: doc.height,
        );
        final copy = SketchDocument(
          id: fresh.id,
          title: fresh.title,
          width: doc.width,
          height: doc.height,
          activeLayerId: doc.activeLayerId,
          modified: DateTime.now(),
          layers: doc.layers,
          artworkId: doc.artworkId,
          regionColors: doc.regionColors,
          completed: doc.completed,
        );
        await widget.store.save(copy);
        await widget.store.saveThumbnail(
          copy.id,
          await renderPng(copy, maxSide: 420),
        );
      } else {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete sketch?'),
            content: Text('“${doc.title}” will be removed from this device.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Keep sketch'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        );
        if (confirmed == true) await widget.store.delete(doc.id);
      }
      await _load();
    } catch (_) {
      if (mounted) _snack('Could not update the sketch. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const HomeTestBanner(),
        NavigationBar(
          selectedIndex: _galleryOnly ? 1 : 0,
          onDestinationSelected: (index) {
            setState(() => _galleryOnly = index == 1);
            if (index == 0) _load();
          },
          height: 68,
          backgroundColor: paper,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.photo_library_outlined),
              selectedIcon: Icon(Icons.photo_library_rounded),
              label: 'Gallery',
            ),
          ],
        ),
      ],
    ),
    body: _galleryOnly
        ? ArtLibraryScreen(store: widget.store, onCompleted: _returnHome)
        : SafeArea(
            child: RefreshIndicator(
              onRefresh: _load,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 1120),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const BrandMark(),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Sketchora',
                                          style: TextStyle(
                                            fontSize: 30,
                                            fontFamily: 'DMSerif',
                                            letterSpacing: -.8,
                                          ),
                                        ),
                                        Text(
                                          'Sketch & Paint',
                                          style: TextStyle(
                                            fontSize: 12,
                                            letterSpacing: .2,
                                            color: muted,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'About Sketchora',
                                    onPressed: () => showAboutDialog(
                                      context: context,
                                      applicationName: 'Sketchora',
                                      applicationVersion:
                                          '0.6.0 · Completion & test ads',
                                      applicationIcon: const BrandMark(
                                        size: 56,
                                      ),
                                      children: [
                                        const Text(
                                          'Your ideas. Your canvas.\nSketches stay on this device. No account required.\n\nExport important work before uninstalling the app.',
                                        ),
                                        TextButton(
                                          onPressed: _shareDiagnostics,
                                          child: const Text(
                                            'Share local diagnostics',
                                          ),
                                        ),
                                      ],
                                    ),
                                    icon: const Icon(
                                      Icons.info_outline_rounded,
                                      color: muted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 30),
                              if (!_galleryOnly) ...[
                                const Text(
                                  'Make something\nbeautiful.',
                                  style: TextStyle(
                                    fontFamily: 'DMSerif',
                                    fontSize: 38,
                                    height: 1.06,
                                    letterSpacing: -1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Your ideas deserve a little room to grow.',
                                  style: TextStyle(color: muted, fontSize: 13),
                                ),
                                const SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  child: GradientButton(
                                    label: _creating
                                        ? 'Creating…'
                                        : 'Free draw · blank canvas',
                                    icon: Icons.add_rounded,
                                    onTap: _creating ? null : _create,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                SizedBox(
                                  width: double.infinity,
                                  child: OutlinedButton.icon(
                                    onPressed: _colourDesign,
                                    icon: const Icon(Icons.palette_outlined),
                                    label: const Text(
                                      'Explore colouring · Kids & Adults',
                                    ),
                                    style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(48, 52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                if (_documents.isNotEmpty) ...[
                                  const Text(
                                    'Continue creating',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  _ContinueCard(
                                    document: _documents.first,
                                    store: widget.store,
                                    onTap: () => _open(_documents.first),
                                  ),
                                ] else
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0E7FD),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.gesture_rounded,
                                          size: 34,
                                          color: violet,
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Every artist starts with a line.',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Your first sketch belongs here.',
                                                style: TextStyle(
                                                  color: muted,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                              const SizedBox(height: 30),
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      'Your sketches',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: -.5,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${_documents.length} ${_documents.length == 1 ? 'sketch' : 'sketches'}',
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Pick up where inspiration left off.',
                                style: TextStyle(color: muted, fontSize: 13),
                              ),
                              if (_notice != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Text(
                                    _notice!,
                                    style: const TextStyle(color: muted),
                                  ),
                                ),
                              if (_error != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 16),
                                  child: Row(
                                    children: [
                                      Expanded(child: Text(_error!)),
                                      TextButton(
                                        onPressed: _load,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                ),
                              const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  if (_loading)
                    const SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(30),
                          child: CircularProgressIndicator(),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      sliver: SliverLayoutBuilder(
                        builder: (context, constraints) {
                          final width = constraints.crossAxisExtent;
                          final columns = width > 1000
                              ? 4
                              : width > 650
                              ? 3
                              : width > 340
                              ? 2
                              : 1;
                          return SliverGrid(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              if (index == 0) {
                                return _NewCard(
                                  onTap: _creating ? null : _create,
                                );
                              }
                              final doc = _documents[index - 1];
                              return _SketchCard(
                                document: doc,
                                store: widget.store,
                                onTap: () => _open(doc),
                                onAction: (action) => _action(doc, action),
                              );
                            }, childCount: _documents.length + 1),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: .80,
                                ),
                          );
                        },
                      ),
                    ),
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.offline_pin_outlined,
                            size: 15,
                            color: muted,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Made for your flow. Saved on your device.',
                            style: TextStyle(color: muted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
  );
}

class _NewCard extends StatelessWidget {
  final VoidCallback? onTap;
  const _NewCard({this.onTap});
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF0EAFB),
    borderRadius: BorderRadius.circular(22),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: violet, size: 28),
          ),
          const SizedBox(height: 16),
          const Text(
            'Start something',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 5),
          const Text('beautiful', style: TextStyle(color: muted, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _SketchCard extends StatelessWidget {
  final SketchDocument document;
  final SketchStore store;
  final VoidCallback onTap;
  final ValueChanged<String> onAction;
  const _SketchCard({
    required this.document,
    required this.store,
    required this.onTap,
    required this.onAction,
  });
  @override
  Widget build(BuildContext context) {
    final file = store.thumbnail(document.id);
    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F0F6),
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(12),
                child: Image.file(
                  file,
                  key: ValueKey('${document.id}_${document.modified}'),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) => const Center(
                    child: Icon(
                      Icons.draw_outlined,
                      color: Color(0xFFC6BBD2),
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 3, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          document.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${document.width} × ${document.height}',
                          style: const TextStyle(fontSize: 10, color: muted),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Sketch options',
                    onSelected: onAction,
                    icon: const Icon(
                      Icons.more_vert_rounded,
                      color: muted,
                      size: 20,
                    ),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'rename',
                        child: Text('Rename'),
                      ),
                      const PopupMenuItem(
                        value: 'duplicate',
                        child: Text('Duplicate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueCard extends StatelessWidget {
  final SketchDocument document;
  final SketchStore store;
  final VoidCallback onTap;
  const _ContinueCard({
    required this.document,
    required this.store,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF2EBE1),
    borderRadius: BorderRadius.circular(20),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 132,
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Image.file(
                  store.thumbnail(document.id),
                  fit: BoxFit.contain,
                  errorBuilder: (_, _, _) =>
                      const Icon(Icons.draw_outlined, color: violet, size: 40),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${document.width} × ${document.height}',
                      style: const TextStyle(color: muted, fontSize: 11),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Keep creating →',
                      style: TextStyle(
                        color: violet,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
