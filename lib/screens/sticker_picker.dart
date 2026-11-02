import 'package:flutter/material.dart';

import '../drawing/decoration.dart';
import '../drawing/sticker_library.dart';

class StickerPicker extends StatefulWidget {
  final Color initialColor;
  final void Function(int, Color) onSelect;
  final VoidCallback onMyStickers;
  const StickerPicker({
    super.key,
    required this.initialColor,
    required this.onSelect,
    required this.onMyStickers,
  });
  @override
  State<StickerPicker> createState() => _StickerPickerState();
}

class _StickerPickerState extends State<StickerPicker> {
  final _search = TextEditingController();
  final _scroll = ScrollController();
  String _topic = 'All';
  String _edition = 'All styles';
  late Color _color = widget.initialColor;
  static const _colors = [
    Color(0xFF8050EF),
    Color(0xFFFF786B),
    Color(0xFF279C84),
    Color(0xFF4F8BC9),
    Color(0xFFE5A747),
    Color(0xFF292034),
  ];
  @override
  void dispose() {
    _search.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _update(VoidCallback change) {
    setState(change);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final matches = stickerBrowseOrder
        .where(
          (i) =>
              (_topic == 'All' || stickerTopic(i) == _topic) &&
              (_edition == 'All styles' ||
                  (i >= 24 && stickerEditions[(i - 24) % 18] == _edition)) &&
              query
                  .split(RegExp(r'\s+'))
                  .every(
                    (word) => '${stickerNames[i]} ${stickerTopic(i)}'
                        .toLowerCase()
                        .contains(word),
                  ),
        )
        .toList();
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Make it yours',
                    style: TextStyle(fontFamily: 'DMSerif', fontSize: 28),
                  ),
                ),
                IconButton(
                  tooltip: 'Close stickers',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${stickerNames.length} stickers · offline & recolourable',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                TextButton(
                  onPressed: widget.onMyStickers,
                  child: const Text('My stickers'),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _search,
              onChanged: (_) => _update(() {}),
              decoration: InputDecoration(
                hintText: 'Search fox, flowers, space…',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear sticker search',
                        onPressed: () => _update(_search.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final topic in ['All', 'Essentials', ...stickerTopics])
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 6,
                    ),
                    child: ChoiceChip(
                      label: Text(topic),
                      selected: _topic == topic,
                      onSelected: (_) => _update(() {
                        _topic = topic;
                        _edition = 'All styles';
                      }),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _edition,
                    items: [
                      for (final style in ['All styles', ...stickerEditions])
                        DropdownMenuItem(
                          value: style,
                          child: Text(style, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => _update(() {
                      _edition = v!;
                      if (_topic == 'Essentials' && v != 'All styles') {
                        _topic = 'All';
                      }
                    }),
                  ),
                ),
                const SizedBox(width: 12),
                Text('${matches.length} results'),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final color in _colors)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Semantics(
                      label: 'Sticker colour ${_colors.indexOf(color) + 1}',
                      selected: _color == color,
                      button: true,
                      child: InkResponse(
                        onTap: () => setState(() => _color = color),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _color == color
                                  ? Theme.of(context).colorScheme.onSurface
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: _color == color
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 17,
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: matches.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('No matching stickers'),
                        TextButton(
                          onPressed: () => _update(() {
                            _search.clear();
                            _topic = 'All';
                            _edition = 'All styles';
                          }),
                          child: const Text('Clear filters'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 150,
                          childAspectRatio: .86,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                        ),
                    itemCount: matches.length,
                    itemBuilder: (_, position) {
                      final id = matches[position];
                      return RepaintBoundary(
                        child: Material(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerLow,
                          borderRadius: BorderRadius.circular(18),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            onTap: () => widget.onSelect(id, _color),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                children: [
                                  Expanded(
                                    child: CustomPaint(
                                      painter: StickerPreview(
                                        CanvasDecoration(
                                          id: 'preview-$id',
                                          sticker: id,
                                          center: Offset.zero,
                                          color: _color.toARGB32(),
                                        ),
                                      ),
                                      child: const SizedBox.expand(),
                                    ),
                                  ),
                                  Text(
                                    stickerNames[id],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              '60 motifs × 18 compositions + 24 essentials',
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}
