import 'package:flutter/material.dart';

import '../../app/theme/app_spacing.dart';
import 'breakpoints.dart';

/// Constrains and pads page content responsively.
///
/// Every screen wraps its body in this so the reading measure stays comfortable
/// on a desktop monitor and the gutters stay tight on a phone.
class PageContainer extends StatelessWidget {
  const PageContainer({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.maxContentWidth,
    this.verticalPadding = AppSpacing.lg,
  });

  final Widget child;
  final double maxWidth;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    final horizontal = switch (Breakpoints.of(context)) {
      FormFactor.mobile => AppSpacing.pagePaddingMobile,
      FormFactor.tablet => AppSpacing.pagePaddingTablet,
      FormFactor.desktop => AppSpacing.pagePaddingDesktop,
    };

    return Align(
      alignment: Alignment.topCenter,
      // Shrink-wraps vertically. Without this the Align expands to whatever
      // height it is offered, which is correct inside a scroll view but makes
      // the widget swallow the whole screen anywhere the height is merely
      // loose — a footer in `bottomNavigationBar`, for instance, then covers
      // the page and eats every tap.
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: horizontal,
            vertical: verticalPadding,
          ),
          child: child,
        ),
      ),
    );
  }
}
