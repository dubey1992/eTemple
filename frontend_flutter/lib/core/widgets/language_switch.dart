import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/localization/locale_controller.dart';

/// The Hindi/English switch.
///
/// Always visible on the public site (spec: "English switch is always visible on
/// the public site"). Labelled for screen readers and reachable by keyboard,
/// which matters on the admin screens.
class LanguageSwitch extends ConsumerWidget {
  const LanguageSwitch({super.key, this.compact = false});

  /// Renders a single toggle button instead of the two-option control, for
  /// narrow app bars.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final controller = ref.read(localeControllerProvider.notifier);
    final l10n = context.l10n;
    final isHindi = locale.languageCode == AppLocales.hindi.languageCode;

    if (compact) {
      return TextButton.icon(
        onPressed: controller.toggle,
        icon: const Icon(Icons.translate, size: 18),
        label: Text(isHindi ? l10n.languageEnglish : l10n.languageHindi),
        // Announces the action, not just the label, to assistive technology.
        style: TextButton.styleFrom(
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
      );
    }

    return Semantics(
      label: l10n.languageLabel,
      child: SegmentedButton<String>(
        showSelectedIcon: false,
        segments: [
          ButtonSegment(
            value: AppLocales.hindi.languageCode,
            label: Text(l10n.languageHindi),
            tooltip: l10n.switchToHindi,
          ),
          ButtonSegment(
            value: AppLocales.english.languageCode,
            label: Text(l10n.languageEnglish),
            tooltip: l10n.switchToEnglish,
          ),
        ],
        selected: {locale.languageCode},
        onSelectionChanged: (selection) =>
            controller.set(Locale(selection.first)),
      ),
    );
  }
}
