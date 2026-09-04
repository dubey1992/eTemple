import 'package:flutter/widgets.dart';

/// The three layout classes the product is specified against.
enum FormFactor { mobile, tablet, desktop }

/// Responsive breakpoints for the whole application.
///
/// Layout decisions read [Breakpoints.of] rather than hard-coding pixel widths,
/// so every screen breaks at the same places (spec: "Responsive UI must work at
/// mobile, tablet and desktop widths. Avoid fixed pixel layouts").
class Breakpoints {
  const Breakpoints._();

  /// Below this width the layout is a single column.
  static const double tablet = 600;

  /// At or above this width the layout may use side navigation and multi-column
  /// content.
  static const double desktop = 1024;

  /// Content is never stretched wider than this, so text stays readable on very
  /// wide monitors.
  static const double maxContentWidth = 1120;

  static FormFactor forWidth(double width) {
    if (width >= desktop) return FormFactor.desktop;
    if (width >= tablet) return FormFactor.tablet;
    return FormFactor.mobile;
  }

  static FormFactor of(BuildContext context) =>
      forWidth(MediaQuery.sizeOf(context).width);
}

extension FormFactorX on FormFactor {
  bool get isMobile => this == FormFactor.mobile;

  bool get isTablet => this == FormFactor.tablet;

  bool get isDesktop => this == FormFactor.desktop;

  /// True where a compact, single-column presentation is expected.
  bool get isCompact => this == FormFactor.mobile;
}
