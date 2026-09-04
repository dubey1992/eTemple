import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';

/// The languages the product supports.
///
/// Hindi is first and is the default: the site is for a village community in
/// Bihar, and English is the secondary language behind an explicit switch.
class AppLocales {
  const AppLocales._();

  static const Locale hindi = Locale('hi');
  static const Locale english = Locale('en');

  static const List<Locale> supported = [hindi, english];

  static const Locale fallback = hindi;

  static bool isSupported(Locale? locale) =>
      locale != null &&
      supported.any((l) => l.languageCode == locale.languageCode);
}

/// Holds the active locale.
///
/// Phase 0 keeps the choice in memory only. The visitor's explicit choice is
/// never overridden by the browser locale — Hindi stays the initial language
/// until they switch (spec: "Hindi remains the initial language unless the
/// visitor explicitly switches language").
class LocaleController extends Notifier<Locale> {
  @override
  Locale build() => AppLocales.fallback;

  void set(Locale locale) {
    if (!AppLocales.isSupported(locale)) return;
    state = locale;
  }

  void toggle() {
    state = state.languageCode == AppLocales.hindi.languageCode
        ? AppLocales.english
        : AppLocales.hindi;
  }

  bool get isHindi => state.languageCode == AppLocales.hindi.languageCode;
}

final localeControllerProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

/// Resolution callback for `MaterialApp.localeResolutionCallback`.
///
/// Always answers with a supported locale, defaulting to Hindi.
Locale resolveLocale(Locale? preferred, Iterable<Locale> supported) {
  if (AppLocales.isSupported(preferred)) {
    return AppLocales.supported.firstWhere(
      (l) => l.languageCode == preferred!.languageCode,
    );
  }
  return AppLocales.fallback;
}

/// Convenience accessor so screens read `context.l10n.appTitle`.
extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
