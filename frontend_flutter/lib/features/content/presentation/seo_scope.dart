import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/seo/seo_metadata_service.dart';
import '../data/content_providers.dart';

/// Publishes a route's metadata to the document head while it is on screen.
///
/// Flutter Web paints to a canvas, so a crawler or a link preview sees only the
/// document head — never the widget tree. Wrapping a screen in this is what
/// makes its title, description and canonical URL real.
///
/// Metadata is applied after the frame so it reflects the data the screen
/// actually rendered, and re-applied whenever that data or the language changes.
class SeoScope extends ConsumerStatefulWidget {
  const SeoScope({
    super.key,
    required this.title,
    required this.child,
    this.description,
    this.canonicalPath,
  });

  final String title;
  final String? description;
  final String? canonicalPath;
  final Widget child;

  @override
  ConsumerState<SeoScope> createState() => _SeoScopeState();
}

class _SeoScopeState extends ConsumerState<SeoScope> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _apply());
  }

  @override
  void didUpdateWidget(SeoScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.title != widget.title ||
        oldWidget.description != widget.description ||
        oldWidget.canonicalPath != widget.canonicalPath) {
      _apply();
    }
  }

  void _apply() {
    if (!mounted) return;

    ref
        .read(seoMetadataServiceProvider)
        .apply(
          PageMetadata(
            title: widget.title,
            language: ref.read(contentLanguageProvider),
            description: widget.description,
            canonicalPath: widget.canonicalPath,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    // Re-apply when the visitor switches language, so <html lang> and the
    // social preview follow the content actually being shown.
    ref.listen<String>(contentLanguageProvider, (_, _) => _apply());

    return widget.child;
  }
}
