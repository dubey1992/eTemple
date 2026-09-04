import 'package:flutter/material.dart';

import '../../../../core/widgets/breakpoints.dart';
import '../../domain/media_item.dart';
import 'media_tile.dart';

/// The prototype's gallery block: a wide first tile spanning two rows, with
/// four smaller tiles beside it.
///
/// The approved design is a CSS grid — `2fr 1fr 1fr`, 180-pixel rows, the first
/// child spanning two rows. That is rebuilt here rather than approximated with
/// a uniform grid, because the uneven rhythm is the thing that makes the block
/// look like a gallery instead of a contact sheet.
///
/// It narrows the way the prototype's media queries do: two columns on a
/// tablet, one on a phone, and the feature tile stops spanning once there is
/// no second row beside it.
class GalleryMosaic extends StatelessWidget {
  const GalleryMosaic({
    super.key,
    required this.items,
    this.onOpen,
    this.rowHeight = 180,
  });

  /// Up to five are placed; anything beyond that belongs on the gallery page.
  final List<MediaItem> items;
  final void Function(MediaItem item)? onOpen;
  final double rowHeight;

  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const GalleryPlaceholderMosaic();

    final formFactor = Breakpoints.of(context);

    if (formFactor == FormFactor.mobile) {
      return _stacked(items.take(5).toList());
    }

    final shown = items.take(5).toList();
    final feature = shown.first;
    final rest = shown.skip(1).toList();

    if (formFactor == FormFactor.tablet) {
      // Two columns: the feature keeps its double height, the rest pair up.
      return Column(
        children: [
          SizedBox(
            height: rowHeight * 2 + _gap,
            child: _tile(feature, fontSize: 90),
          ),
          if (rest.isNotEmpty) const SizedBox(height: _gap),
          for (var i = 0; i < rest.length; i += 2) ...[
            if (i > 0) const SizedBox(height: _gap),
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(child: _tile(rest[i])),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: i + 1 < rest.length
                        ? _tile(rest[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    // Desktop: the prototype's 2fr / 1fr / 1fr with the feature spanning both
    // rows on the left.
    return SizedBox(
      height: rowHeight * 2 + _gap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: 2, child: _tile(feature, fontSize: 90)),
          const SizedBox(width: _gap),
          Expanded(child: _column(rest, 0, 2)),
          const SizedBox(width: _gap),
          Expanded(child: _column(rest, 2, 4)),
        ],
      ),
    );
  }

  Widget _column(List<MediaItem> rest, int from, int to) {
    final slots = [
      for (var i = from; i < to; i++) i < rest.length ? rest[i] : null,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < slots.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          Expanded(
            child: slots[i] == null
                ? const SizedBox.shrink()
                : _tile(slots[i]!),
          ),
        ],
      ],
    );
  }

  Widget _stacked(List<MediaItem> shown) => Column(
    children: [
      for (var i = 0; i < shown.length; i++) ...[
        if (i > 0) const SizedBox(height: _gap),
        SizedBox(height: rowHeight, child: _tile(shown[i])),
      ],
    ],
  );

  Widget _tile(MediaItem item, {double fontSize = 56}) =>
      MediaTile(item: item, onTap: onOpen == null ? null : () => onOpen!(item));
}

/// The prototype's gallery exactly as drawn: five glyph tiles on gold.
///
/// This is the empty state, and it is the approved design — the prototype's own
/// caption says photographs "will appear here". Seeding five invented
/// photographs to make a demo look full would put fabricated temple content in
/// the database, which the working agreement forbids (assumption M12).
class GalleryPlaceholderMosaic extends StatelessWidget {
  const GalleryPlaceholderMosaic({super.key, this.rowHeight = 180});

  final double rowHeight;

  /// The prototype's own glyphs, in its own order.
  static const List<String> glyphs = ['🛕', '🪔', '🦚', '🌺', '🙏'];

  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    final formFactor = Breakpoints.of(context);

    if (formFactor == FormFactor.mobile) {
      return Column(
        key: const Key('gallery-placeholder'),
        children: [
          for (var i = 0; i < glyphs.length; i++) ...[
            if (i > 0) const SizedBox(height: _gap),
            SizedBox(
              height: rowHeight,
              child: GalleryPlaceholderTile(glyph: glyphs[i]),
            ),
          ],
        ],
      );
    }

    if (formFactor == FormFactor.tablet) {
      return Column(
        key: const Key('gallery-placeholder'),
        children: [
          SizedBox(
            height: rowHeight * 2 + _gap,
            child: GalleryPlaceholderTile(glyph: glyphs.first, fontSize: 90),
          ),
          const SizedBox(height: _gap),
          for (var i = 1; i < glyphs.length; i += 2) ...[
            if (i > 1) const SizedBox(height: _gap),
            SizedBox(
              height: rowHeight,
              child: Row(
                children: [
                  Expanded(child: GalleryPlaceholderTile(glyph: glyphs[i])),
                  const SizedBox(width: _gap),
                  Expanded(
                    child: i + 1 < glyphs.length
                        ? GalleryPlaceholderTile(glyph: glyphs[i + 1])
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return SizedBox(
      key: const Key('gallery-placeholder'),
      height: rowHeight * 2 + _gap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: GalleryPlaceholderTile(glyph: glyphs[0], fontSize: 90),
          ),
          const SizedBox(width: _gap),
          Expanded(child: _pair(glyphs[1], glyphs[2])),
          const SizedBox(width: _gap),
          Expanded(child: _pair(glyphs[3], glyphs[4])),
        ],
      ),
    );
  }

  Widget _pair(String top, String bottom) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(child: GalleryPlaceholderTile(glyph: top)),
      const SizedBox(height: _gap),
      Expanded(child: GalleryPlaceholderTile(glyph: bottom)),
    ],
  );
}
