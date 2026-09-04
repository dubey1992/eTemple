/// Spacing, radius and elevation tokens.
///
/// A single 4-pixel scale keeps rhythm consistent across screens and makes
/// responsive adjustments predictable.
class AppSpacing {
  const AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  /// Horizontal page padding per form factor.
  static const double pagePaddingMobile = md;
  static const double pagePaddingTablet = lg;
  static const double pagePaddingDesktop = xl;
}

class AppRadius {
  const AppRadius._();

  static const double sm = 8;
  static const double md = 12;
  static const double lg = 20;
}
