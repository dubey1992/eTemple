import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_spacing.dart';
import 'page_container.dart';

/// A full-width horizontal band with its own ground colour.
///
/// The prototype alternates the page between cream and a slightly warmer cream
/// so each section reads as its own block on a long scroll. The colour has to
/// run edge to edge while the content stays within the reading measure, so the
/// band is full width and the [PageContainer] inside it does the constraining.
class SectionBand extends StatelessWidget {
  const SectionBand({
    super.key,
    required this.child,
    this.background,
    this.gradient,
    this.maxWidth,
    this.verticalPadding = AppSpacing.xxl,
  });

  /// A band on the alternate ground, one shade warmer than the page.
  const SectionBand.alternate({
    super.key,
    required this.child,
    this.maxWidth,
    this.verticalPadding = AppSpacing.xxl,
  }) : background = AppColors.creamBand,
       gradient = null;

  final Widget child;
  final Color? background;
  final Gradient? gradient;
  final double? maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final container = PageContainer(
      maxWidth: maxWidth ?? 1120,
      verticalPadding: verticalPadding,
      child: child,
    );

    if (background == null && gradient == null) return container;

    return DecoratedBox(
      decoration: BoxDecoration(color: background, gradient: gradient),
      child: container,
    );
  }
}
