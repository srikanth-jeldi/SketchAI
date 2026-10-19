import 'package:flutter/material.dart';

import '../drawing/document.dart';
import '../screens/artwork_studio_gate.dart';
import '../storage/sketch_store.dart';
import '../theme.dart';
import 'art_catalog.dart';
import 'artwork_view.dart';

class ArtLibraryScreen extends StatefulWidget {
  final SketchStore store;
  final VoidCallback? onCompleted;
  const ArtLibraryScreen({super.key, required this.store, this.onCompleted});
  @override
  State<ArtLibraryScreen> createState() => _ArtLibraryState();
}

class _ArtLibraryState extends State<ArtLibraryScreen> {
  String? _category;
  bool _kids = true;
  String _difficulty = 'Easy';
  String _query = '';
  int _visible = 30;
  bool _opening = false;
  Future<void> _open(ArtEntry entry) async {
    if (_opening) return;
    final start = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.title,
                  style: const TextStyle(fontFamily: 'DMSerif', fontSize: 28),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 230,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: ArtworkView(entry.id),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'A little inspiration. Make the colours your own.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tap closed areas to fill, or paint with a brush. The small colour guide can be opened any time.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: muted),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: GradientButton(
                    label: 'Start colouring',
                    icon: Icons.palette_outlined,
                    onTap: () => Navigator.pop(context, true),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (start != true || !mounted) return;
    setState(() => _opening = true);
    try {
      final doc = SketchDocument.create(
        title: entry.title,
        width: 2048,
        height: 2048,
        artworkId: entry.id,
      );
      await widget.store.save(doc);
      if (mounted) {
        final completed = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ArtworkStudioGate(document: doc, store: widget.store),
          ),
        );
        if (completed == true && mounted) {
          if (widget.onCompleted != null) {
            widget.onCompleted!();
          } else if (Navigator.canPop(context)) {
            Navigator.pop(context, true);
          }
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Could not open this design. Check storage and try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final collection = _kids ? kidsEntries : adultEntries;
    final categories = collection.map((e) => e.category).toSet().toList();
    final entries = collection
        .where(
          (entry) =>
              entry.difficulty == _difficulty &&
              (_category == null || entry.category == _category) &&
              '${entry.title} ${entry.category}'.toLowerCase().contains(
                _query.toLowerCase(),
              ),
        )
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Colour a little joy',
          style: TextStyle(fontFamily: 'DMSerif', fontSize: 27),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _kids
                        ? 'Big shapes, happy colours. Start with something easy.'
                        : 'A little calm. Beautiful designs at your own pace.',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SegmentedButton<bool>(
                    segments: const [
                      ButtonSegment(
                        value: true,
                        label: Text('Kids'),
                        icon: Icon(Icons.child_care),
                      ),
                      ButtonSegment(
                        value: false,
                        label: Text('Adults'),
                        icon: Icon(Icons.spa_outlined),
                      ),
                    ],
                    selected: {_kids},
                    onSelectionChanged: (value) => setState(() {
                      _kids = value.first;
                      _category = null;
                      _difficulty = 'Easy';
                      _visible = 30;
                    }),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final level in ['Easy', 'Medium', 'Detailed'])
                        ChoiceChip(
                          label: Text(level),
                          selected: _difficulty == level,
                          onSelected: (_) => setState(() {
                            _difficulty = level;
                            _category = null;
                            _visible = 30;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Find a favourite design…',
                    ),
                    onChanged: (value) => setState(() {
                      _query = value;
                      _visible = 30;
                    }),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 46,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: const Text('All'),
                            selected: _category == null,
                            onSelected: (_) => setState(() {
                              _category = null;
                              _visible = 30;
                            }),
                          ),
                        ),
                        for (final category in categories)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(category),
                              selected: _category == category,
                              onSelected: (_) => setState(() {
                                _category = category;
                                _visible = 30;
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${entries.length} designs · choose your favourite',
                    style: const TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No designs found. Try another category or name.'),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverLayoutBuilder(
              builder: (context, constraints) => SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: constraints.crossAxisExtent > 800
                      ? 4
                      : constraints.crossAxisExtent > 550
                      ? 3
                      : 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: .80,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final entry = entries[index];
                    return Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: _opening ? null : () => _open(entry),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: SizedBox.expand(
                                  child: ArtworkView(entry.id),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${entry.category} · ${entry.difficulty}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: muted,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: entries.length < _visible
                      ? entries.length
                      : _visible,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: entries.length > _visible
                  ? OutlinedButton(
                      onPressed: () => setState(() => _visible += 30),
                      child: const Text('Discover more designs'),
                    )
                  : const Center(
                      child: Text(
                        'Your colours. Your imagination.',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
