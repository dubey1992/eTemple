# Phase 0 Plan — Foundation & Core Setup

> **Objective (spec §Phase 0):** Create a stable, secure and maintainable Flutter + Laravel technical foundation.

---

## A. Requirement review

### Features required by the specification

| # | Requirement | Where it lands |
|---|---|---|
| 1 | Repository and environment setup (development, staging, production) | `frontend_flutter` `--dart-define` env, `backend_laravel/.env.example` |
| 2 | Flutter Web app, feature-first folders, Material 3 theme, responsive shell | `lib/app`, `lib/core`, `lib/features` |
| 3 | Laravel application and database setup | `backend_laravel` |
| 4 | Environment/flavor configuration, secrets outside source control | `AppConfig` + `.env.example` + `.gitignore` |
| 5 | Common REST response, pagination and error standards shared with Flutter | `App\Support\ApiResponse` ↔ `core/api/api_envelope.dart` |
| 6 | Backend logging + centralized exception handling; user-safe error mapping in Flutter | `bootstrap/app.php` `withExceptions`, `core/errors/` |
| 7 | Admin authentication foundation and protected Flutter admin routes | `features/auth`, `routes/api.php`, `EnsureUserIsActive` |
| 8 | Migration and seeding framework | `database/migrations`, `database/seeders`, `database/factories` |
| 9 | Flutter unit/widget/integration test framework + Laravel unit/feature tests | `frontend_flutter/test`, `backend_laravel/tests` |
| 10 | Lint/static analysis and CI checks | `analysis_options.yaml`, `pint.json`, `.github/workflows/ci.yml` |
| 11 | Basic CI/CD and deployment checklist | `.github/workflows/ci.yml`, `docs/DEPLOYMENT_CHECKLIST.md` |
| 12 | `docs/PHASE_STATUS.md` created, updated only after validation | `docs/PHASE_STATUS.md` |

### Entity fields (spec §Phase 0 — user)

`id`, `first_name`, `last_name`, `email` (unique), `mobile` (nullable), `password_hash`,
`role_id`, `status` (`active`/`inactive`/`blocked`), `last_login_at`, `created_at`, `updated_at`.

### APIs (spec §Phase 0)

- `POST /api/auth/login`
- `POST /api/auth/logout`
- `GET  /api/auth/me`
- `POST /api/auth/forgot-password`

### Business / validation rules (spec §Phase 0)

- Passwords hashed with framework-approved hashing (bcrypt via `Hash::make`).
- Inactive/blocked users cannot access admin endpoints or protected Flutter routes.
- Login and password-reset requests are rate limited.
- Flutter contains no API secrets or database credentials.
- Phase ends with a runnable Flutter web shell, working Laravel health/auth foundation,
  successful migration and green baseline tests.

### Dependencies from completed phases

None — Phase 0 is the first phase.

### Ambiguities and the assumptions taken

| # | Ambiguity | Assumption (safest, reversible) |
|---|---|---|
| A1 | Spec lists `password_hash` as a field name, but Laravel/Sanctum conventions expect `password`. | Column is named **`password`** so framework hashing, guards and `Authenticatable` work without overrides. The spec's intent — "never store plain password" — is satisfied via a hashed cast. Documented here rather than fighting the framework. |
| A2 | Session-cookie vs. token auth. | **Sanctum SPA cookie/session auth** (spec: "prefer HttpOnly cookie/session-based web authentication where deployment topology allows"). No token is stored in `localStorage`. Requires frontend and API to be same-site in deployment; a bearer-token fallback is *not* implemented in Phase 0. |
| A3 | Roles carry `permissions` from Phase 2. | Phase 0 seeds the five roles with a **nullable `permissions` JSON column** left null. Permission keys, matrix and role endpoints are Phase 2 and are not implemented. |
| A4 | `forgot-password` needs a mail transport. | Endpoint implemented with Laravel's password broker; default mailer in `.env.example` is `log`. The endpoint always returns a generic success message so it cannot be used to enumerate accounts. |
| A5 | Phase 0 "responsive shell" vs. Phase 1 home page. | The public shell renders a deliberately **non-CMS foundation placeholder**, not the temple home/about content. No `pages` table, no hero/about/address sections. |
| A6 | SEO/pre-render strategy. | Deferred to Phase 1 where page metadata entities exist. Phase 0 ships only a correct `web/index.html` + manifest. |
| A7 | PHP/Composer/MySQL are absent from the build machine. | Backend is authored complete with tests targeting an **in-memory SQLite** test connection (so `php artisan test` needs no MySQL server) while dev/staging/prod use MySQL. Backend verification commands are recorded as NOT RUN. |

---

## B. Design before code

### B1. Database

**`roles`**

| Column | Type | Notes |
|---|---|---|
| `id` | big increments | |
| `slug` | string(50), unique | `super-admin`, `admin`, `treasurer`, `content-manager`, `viewer` |
| `name` | string(100) | Display name |
| `description` | string(255), nullable | Role purpose |
| `permissions` | json, nullable | Reserved for Phase 2 |
| `status` | enum(`active`,`inactive`), default `active` | |
| `created_at`/`updated_at` | timestamps | |

**`users`**

| Column | Type | Notes |
|---|---|---|
| `id` | big increments | |
| `first_name` | string(100) | |
| `last_name` | string(100), nullable | |
| `email` | string(191), unique | Login identifier |
| `mobile` | string(20), nullable | Required per role from Phase 2 |
| `password` | string | bcrypt hash (assumption A1) |
| `role_id` | FK → `roles.id`, restrict on delete | |
| `status` | enum(`active`,`inactive`,`blocked`), default `active` | |
| `last_login_at` | timestamp, nullable | |
| `remember_token` | string(100), nullable | |
| `created_at`/`updated_at` | timestamps | |

Also required by the framework: `password_reset_tokens`, `sessions`, `cache`, `jobs`.

Relationships: `User belongsTo Role`, `Role hasMany User`.
Seeders: `RoleSeeder` (production-safe, idempotent) and `DevelopmentAdminSeeder`
(clearly marked dev-only, refuses to run when `APP_ENV=production`).

### B2. API contract

Envelope, identical for every endpoint:

```jsonc
// success
{ "success": true,  "data": { }, "meta": { }|null }
// error
{ "success": false, "error": { "code": "VALIDATION_FAILED", "message": "…", "details": { "email": ["…"] } } }
```

Pagination `meta` convention (defined once, reused from Phase 1 onwards):
`{ "current_page", "per_page", "total", "last_page", "has_more" }`.

| Method | Path | Auth | Rate limit | Success | Failures |
|---|---|---|---|---|---|
| GET | `/api/health` | public | 60/min | 200 | — |
| GET | `/sanctum/csrf-cookie` | public | — | 204 | — |
| POST | `/api/auth/login` | guest | 5/min per email+IP | 200 user | 401 `INVALID_CREDENTIALS`, 403 `ACCOUNT_INACTIVE`/`ACCOUNT_BLOCKED`, 422 `VALIDATION_FAILED`, 429 `TOO_MANY_REQUESTS` |
| POST | `/api/auth/logout` | session | 60/min | 200 | 401 `UNAUTHENTICATED` |
| GET | `/api/auth/me` | session + active | 60/min | 200 user | 401, 403 |
| POST | `/api/auth/forgot-password` | guest | 3/min per email+IP | 200 generic | 422, 429 |
| GET | `/api/admin/ping` | session + active | 60/min | 200 | 401, 403 — proves the protected group works |

`UserResource` exposes: `id`, `first_name`, `last_name`, `full_name`, `email`, `mobile`,
`status`, `last_login_at`, `role {id, slug, name}`. It never exposes the password hash.

Authorization: `auth:sanctum` + `EnsureUserIsActive` middleware on every protected route
(alias `active`). Hiding UI is never the control.

### B3. Flutter design

```
lib/
  main.dart
  app/
    app.dart                     root ProviderScope + MaterialApp.router
    routing/                     route_paths, app_router (+ auth redirect guard)
    theme/                       app_colors, app_typography, app_spacing, app_theme
    localization/                locale_controller (+ generated l10n)
  core/
    config/                      app_environment, app_config (dart-define only)
    api/                         api_client (Dio), api_endpoints, api_envelope,
                                 dio_platform (conditional web/io), csrf (conditional)
    errors/                      app_exception, error_code, error_mapper
    logging/                     app_logger
    utils/                       validators
    widgets/                     breakpoints/responsive, async_view,
                                 loading/empty/error/unauthorized state widgets
  features/
    auth/
      data/                      auth_api, auth_repository_impl
      domain/                    auth_user, role, auth_repository, auth_state
      presentation/              auth_controller, login_screen, forgot_password_screen
    shell/
      presentation/              public_shell, admin_shell, foundation_home_screen,
                                 admin_overview_screen, not_found_screen
```

Routes:

| Path | Group | Guard |
|---|---|---|
| `/` | public | none |
| `/login` | public | redirects to `/admin` when already authenticated |
| `/forgot-password` | public | same |
| `/admin` | admin | authenticated **and** `status == active` |
| anything else | — | not-found screen |

State: Riverpod. `authControllerProvider` (AsyncNotifier) owns session bootstrap
(`GET /api/auth/me`), login, logout. `localeControllerProvider` owns the Hindi/English
switch, defaulting to `hi` and persisting nothing in Phase 0.

Error mapping: Dio/network/envelope failures → typed `AppException(code, message)` →
localized, user-safe message. No stack traces or server internals reach the UI.

### B4. Validation / business rules implemented in Phase 0

- Server: `LoginRequest` (`email` required/email/max, `password` required/string/min:8),
  `ForgotPasswordRequest` (`email` required/email).
- Server: `AuthService::login` rejects `inactive`/`blocked` before issuing a session,
  stamps `last_login_at`, and regenerates the session id on success.
- Server: throttles via `RateLimiter` named limiters `auth-login` (5/min) and
  `auth-forgot-password` (3/min), keyed on email + IP.
- Client: `Validators.email` / `Validators.password` mirror the server rules; server
  validation remains authoritative.

### B5. Test plan

Backend (PHPUnit, in-memory SQLite):

| Test | Asserts |
|---|---|
| `MigrationTest` | `users`/`roles` tables and required columns exist after migrating |
| `RoleSeederTest` | seeds exactly the five spec roles, idempotently |
| `AuthServiceTest` | inactive/blocked rejection, `last_login_at` stamping |
| `LoginTest` | success envelope, bad credentials 401, validation 422, blocked 403, throttle 429 |
| `MeTest` | 200 for active session, 401 unauthenticated, 403 when deactivated mid-session |
| `LogoutTest` | 200 and session invalidation, 401 unauthenticated |
| `ForgotPasswordTest` | generic 200 for known and unknown email, 422 invalid, throttle 429 |
| `AdminRouteProtectionTest` | `/api/admin/ping` 401 guest, 403 blocked, 200 active |
| `HealthTest` | 200 envelope shape |
| `ApiResponseTest` | envelope/pagination-meta shape unit test |

Flutter:

| Test | Asserts |
|---|---|
| `validators_test` | email/password/required rules incl. Hindi-safe input |
| `api_envelope_test` | success/error/paginated envelope parsing, defensive nullable handling |
| `error_mapper_test` | Dio timeout/connection/4xx/5xx → correct `ErrorCode` |
| `app_config_test` | defaults, environment resolution, no secret leakage |
| `auth_repository_test` | login/me/logout mapping over a mocked Dio |
| `auth_controller_test` | unauthenticated → authenticated → unauthenticated transitions |
| `locale_controller_test` | default is `hi`; switch to `en`; supported locales |
| `login_screen_test` | renders, validates empty fields, shows error state, shows loading |
| `localization_test` | Hindi strings by default, English after switch |
| `responsive_test` | breakpoint resolution + shell layout at mobile/tablet/desktop widths |
| `router_test` | `/admin` redirects to `/login` when unauthenticated; reaches `/admin` when active |

### B6. Acceptance criteria

1. `flutter pub get`, `flutter analyze` (0 issues), `flutter test` (all green),
   `flutter build web --release` all succeed.
2. `php artisan test` green and `migrate` + `migrate:rollback` verified — **on a machine with PHP/MySQL**.
3. `/admin` is unreachable without an active authenticated session, enforced by the server.
4. Hindi renders by default; the English switch is visible and functional on the public shell.
5. No secret, key or credential appears in either source tree.
6. Layouts behave at 375 / 768 / 1440 px widths.
7. `docs/` plan, status and completion report are written.

---

## C. Implementation order

1. Laravel migrations/models/seeders → 2. validation, authorization, `AuthService`
→ 3. API routes/controllers + backend tests → 4. Flutter config/api/errors
→ 5. auth models/repository → 6. Riverpod state → 7. theme/l10n/router/UI
→ 8. Flutter tests → 9. CI + documentation.

## D. Quality gate

Recorded in `docs/phase-reports/PHASE_0_COMPLETION.md` with actual command output.
Phase 0 is **not** declared COMPLETE unless every gate item passes.
