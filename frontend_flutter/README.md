# Radha Krishna Thakurbari — Flutter Web

Public website and admin console. Flutter Web is the primary target; the
architecture stays Android-ready but no native app is in scope.

## Layout

```
lib/
  app/
    localization/   Locale controller (Hindi default) + message mapping
    routing/        Route paths, router and the admin auth guard
    theme/          Material 3 temple design system and design tokens
  core/
    api/            Dio client, endpoints, envelope parsing, browser bridge
    config/         Build-time configuration (--dart-define only)
    errors/         AppException, ErrorCode, ErrorMapper
    logging/        AppLogger
    utils/          Validators
    widgets/        Breakpoints, PageContainer, state views, language switch
  features/
    auth/           data / domain / presentation
    shell/          Public and admin chrome
  l10n/             ARB sources + generated localizations (committed)
```

Feature-first with a data / domain / presentation split. Widgets hold
presentation state only; business rules live in controllers and services, and
HTTP lives in repositories.

## Run

```bash
flutter pub get
flutter run -d chrome --web-port=5000 \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:8000/api
```

The web port must match the backend's `FRONTEND_URL`,
`CORS_ALLOWED_ORIGINS` and `SANCTUM_STATEFUL_DOMAINS`, or the browser will drop
the session cookie.

## Checks

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
flutter build web --release
```

## Conventions

- **No secrets.** A web bundle is public. Configuration arrives through
  `--dart-define`; nothing sensitive goes in it.
- **No token storage.** Authentication is an HttpOnly cookie the browser manages.
- **Every API-driven screen** renders loading, success, empty, error and
  unauthorized states — use `core/widgets/state_views.dart`.
- **No pixel literals in layouts.** Use `AppSpacing`, `AppRadius` and
  `Breakpoints`.
- **No colour literals in widgets.** Use `Theme.of(context).colorScheme` or
  `AppColors`.
- **Errors reaching the UI are `AppException`s.** They are rendered through
  `localizedMessage`, never as raw server text.

## Localization

`lib/l10n/app_hi.arb` is the template (Hindi is the default language);
`app_en.arb` is the English translation. Run `flutter gen-l10n` after editing
either; the generated files are committed and CI verifies they are current.
