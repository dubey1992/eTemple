import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rkt_web/app/localization/locale_controller.dart';

void main() {
  group('AppLocales', () {
    test('supports Hindi and English, with Hindi first', () {
      expect(AppLocales.supported, [AppLocales.hindi, AppLocales.english]);
      expect(AppLocales.fallback, AppLocales.hindi);
    });

    test('recognises supported locales including country variants', () {
      expect(AppLocales.isSupported(const Locale('hi', 'IN')), isTrue);
      expect(AppLocales.isSupported(const Locale('en', 'GB')), isTrue);
      expect(AppLocales.isSupported(const Locale('bn')), isFalse);
      expect(AppLocales.isSupported(null), isFalse);
    });
  });

  group('resolveLocale', () {
    test('falls back to Hindi for an unsupported browser locale', () {
      expect(
        resolveLocale(const Locale('fr'), AppLocales.supported),
        AppLocales.hindi,
      );
      expect(resolveLocale(null, AppLocales.supported), AppLocales.hindi);
    });

    test('normalises a country variant to the supported locale', () {
      expect(
        resolveLocale(const Locale('en', 'US'), AppLocales.supported),
        AppLocales.english,
      );
    });
  });

  group('LocaleController', () {
    test('defaults to Hindi', () {
      final container = ProviderContainer.test();
      expect(container.read(localeControllerProvider), AppLocales.hindi);
    });

    test('toggles between Hindi and English', () {
      final container = ProviderContainer.test();
      final controller = container.read(localeControllerProvider.notifier);

      controller.toggle();
      expect(container.read(localeControllerProvider), AppLocales.english);

      controller.toggle();
      expect(container.read(localeControllerProvider), AppLocales.hindi);
    });

    test('ignores an unsupported locale rather than breaking the UI', () {
      final container = ProviderContainer.test();
      final controller = container.read(localeControllerProvider.notifier);

      controller.set(const Locale('bn'));

      expect(container.read(localeControllerProvider), AppLocales.hindi);
    });
  });
}
