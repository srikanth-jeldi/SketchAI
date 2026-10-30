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
  int _section = 0;
  int _collection = 0;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  int _available = 3094;
  @override
  void initState() {
    super.initState();
    _scroll.addListener(_loadMore);
  }

  void _loadMore() {
    if (_scroll.hasClients &&
        _scroll.position.extentAfter < 700 &&
        _visible < _available) {
      setState(() => _visible += 30);
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  String _difficulty = 'All levels';
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
    final collection = _collection == 0
        ? allVisibleEntries
        : _collection == 2
        ? ArtCatalog.entries
        : [kidsEntries, intermediateEntries, advancedEntries][_section];
    final matching = collection
        .where(
          (e) => e.searchTerms.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    final categories = matching
        .where(
          (e) => _difficulty == 'All levels' || e.difficulty == _difficulty,
        )
        .map((e) => e.category)
        .toSet()
        .toList();
    final availableLevels = matching.map((e) => e.difficulty).toSet();
    final entries = matching
        .where(
          (entry) =>
              (_difficulty == 'All levels' ||
                  entry.difficulty == _difficulty) &&
              (_category == null || entry.category == _category) &&
              entry.searchTerms.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
    _available = entries.length;
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Colour a little joy',
          style: TextStyle(fontFamily: 'DMSerif', fontSize: 27),
        ),
      ),
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3,094 offline designs · yours to colour',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final group in [0, 1, 2])
                        ChoiceChip(
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 11),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          label: Text(
                            [
                              'All designs · 3,094',
                              'Studio collection · 1,094',
                              'Original collection · 2,000',
                            ][group],
                          ),
                          selected: _collection == group,
                          onSelected: (_) => setState(() {
                            _collection = group;
                            _section = 0;
                            _category = null;
                            _difficulty = 'All levels';
                            _query = '';
                            _search.clear();
                            _visible = 30;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_collection == 1)
                    SegmentedButton<int>(
                      showSelectedIcon: false,
                      style: const ButtonStyle(
                        textStyle: WidgetStatePropertyAll(
                          TextStyle(fontSize: 11),
                        ),
                      ),
                      segments: const [
                        ButtonSegment(value: 0, label: Text('Kids')),
                        ButtonSegment(value: 1, label: Text('Intermediate')),
                        ButtonSegment(value: 2, label: Text('Advanced')),
                      ],
                      selected: {_section},
                      onSelectionChanged: (value) => setState(() {
                        _section = value.first;
                        _category = null;
                        _difficulty = 'All levels';
                        _query = '';
                        _search.clear();
                        _visible = 30;
                      }),
                    ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final level in [
                        'All levels',
                        if (availableLevels.contains('Easy')) 'Easy',
                        if (availableLevels.contains('Medium')) 'Medium',
                        if (availableLevels.contains('Detailed')) 'Detailed',
                      ])
                        ChoiceChip(
                          showCheckmark: false,
                          visualDensity: VisualDensity.compact,
                          labelStyle: const TextStyle(fontSize: 12),
                          padding: EdgeInsets.zero,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
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
                    controller: _search,
                    key: ValueKey('$_collection/$_section'),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      prefixIcon: Icon(Icons.search_rounded),
                      hintText: 'Find a favourite design…',
                    ),
                    onChanged: (value) => setState(() {
                      _query = value;
                      _category = null;
                      _difficulty = 'All levels';
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
                              label: Text(
                                '$category (${matching.where((e) => (_difficulty == "All levels" || e.difficulty == _difficulty) && e.category == category).length})',
                              ),
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
                  Text(
                    'Showing ${entries.length < _visible ? entries.length : _visible} of ${entries.length} · scroll for more',
                    style: const TextStyle(color: muted, fontSize: 11),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          if (entries.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text(
                      'No designs found. Try another category or name.',
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                        _difficulty = 'All levels';
                        _category = null;
                        _visible = 30;
                      }),
                      child: const Text('Clear filters'),
                    ),
                  ],
                ),
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
