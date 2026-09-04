# Phase 0 Completion Report — Foundation & Core Setup

**Date:** 2026-09-04 (final revision — full toolchain installed, everything executed)
**Status: COMPLETE** — every Phase 0 requirement is implemented and every
delivery-gate check is green on both stacks, including migrations verified against
the deployment database engine.

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 (NTS x64) · Composer 2.10.3 ·
Laravel 12.69.1 · Sanctum 4.3.3 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 0 requirement | Status | Where |
|---|---|---|---|
| 1 | Repository/environment setup (dev, staging, production) | ✅ | `--dart-define` config, `backend_laravel/.env.example`, CI |
| 2 | Flutter Web project, feature-first folders, Material 3 theme, responsive shell | ✅ | `frontend_flutter/lib/` |
| 3 | Laravel application and database configuration | ✅ | `backend_laravel/` |
| 4 | Environment/flavor configuration, secrets outside source control | ✅ | `AppConfig`, `.env.example`, `.gitignore` |
| 5 | Common REST response, pagination and error standards shared with Flutter | ✅ | `App\Support\ApiResponse` ↔ `core/api/api_envelope.dart` |
| 6 | Backend logging + centralized exception handling; user-safe error mapping in Flutter | ✅ | `ApiExceptionRenderer`, `config/logging.php`, `core/errors/` |
| 7 | Admin authentication foundation and protected Flutter admin routes | ✅ | `features/auth/`, `routes/api.php`, `EnsureUserIsActive` |
| 8 | Migration and seeding framework | ✅ | `database/` |
| 9 | Flutter unit/widget test framework + Laravel unit/feature tests | ✅ | 107 Flutter + 49 Laravel tests |
| 10 | Lint/static analysis and CI checks | ✅ | `analysis_options.yaml`, `pint.json`, `.github/workflows/ci.yml` |
| 11 | Basic CI/CD and deployment checklist | ✅ | `.github/workflows/ci.yml`, `docs/DEPLOYMENT_CHECKLIST.md` |
| 12 | `docs/PHASE_STATUS.md` created and updated only after validation | ✅ | `docs/PHASE_STATUS.md` |

### "START NOW — Phase 0 must establish at least"

| Item | Status |
|---|---|
| Flutter Web project and responsive app shell | ✅ verified at 360 / 768 / 1440 px |
| Material 3 theme + base typography/design tokens | ✅ `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppTheme` |
| Hindi default / English localization infrastructure | ✅ 53 keys × 2 ARBs, Hindi is the template and the default |
| `go_router` route foundation with public/admin route groups | ✅ separate shells + guard |
| Riverpod / core DI foundation | ✅ `ProviderScope`, provider-based DI throughout |
| Dio API client and standardized error mapping | ✅ `ApiClient`, `ErrorMapper`, `AppException` |
| Environment configuration without secrets | ✅ `--dart-define` only |
| Laravel app + DB configuration | ✅ boots, migrates, serves |
| Migrations / seeding / test framework | ✅ 5 migrations, 2 seeders, 2 factories, PHPUnit |
| Auth endpoints: login / logout / me / forgot-password | ✅ all covered by feature tests |
| Protected admin route foundation | ✅ `auth:sanctum` + `active` middleware, `/api/admin/ping` |
| Baseline role model and seed | ✅ 5 roles, idempotent `RoleSeeder` |
| Logging / exception standards | ✅ |
| CI / test / lint commands | ✅ |
| Green baseline Flutter tests | ✅ 107/107 |
| Green baseline Laravel tests | ✅ 49/49 |

### Explicitly not implemented (correctly deferred)

CMS pages/home/about content, site settings, navigation/footer data, per-route SEO
metadata and pre-rendering (Phase 1); user CRUD, role/permission matrix, login
history, 2FA, the password **reset** form (Phase 2); everything from Phase 3 on.

---

## 2. Database / migration changes

| Migration | Tables |
|---|---|
| `0001_01_01_000000_create_roles_table` | `roles` — `slug` (unique), `name`, `description`, `permissions` (json, null in Phase 0), `status`, timestamps |
| `0001_01_01_000001_create_users_table` | `users` — `first_name`, `last_name`, `email` (unique), `mobile`, `password`, `role_id` (FK, restrict), `status`, `last_login_at`, `remember_token`, timestamps, index on `(status, role_id)`; plus `password_reset_tokens`, `sessions` |
| `0001_01_01_000002_create_cache_table` | `cache`, `cache_locks` |
| `0001_01_01_000003_create_jobs_table` | `jobs`, `job_batches`, `failed_jobs` |
| `2026_09_04_000000_create_personal_access_tokens_table` | `personal_access_tokens` — owned by this application because **Sanctum 4 only publishes its migration** (`publishesMigrations`), it never loads it from the package |

All five verified reversible on **both SQLite and MariaDB 12.3.3**:
`migrate` → `db:seed` → `migrate:rollback` (correct reverse order, no FK
violations) → `migrate`.

Schema parity confirmed on MariaDB: `users` has all 12 columns with the specified
types, `InnoDB` engine, `utf8mb4_unicode_ci` collation (so Devanagari sorts and
compares correctly), a unique index on `email`, the compound `(status, role_id)`
index, and the `role_id` foreign key to `roles.id` with `restrict` on delete.

**Spec-field mapping.** The specification names the column `password_hash`. It is
implemented as `password` with a `hashed` cast so Laravel's guards, hashing and
password broker work without overrides; the plain value can never be persisted.
This is assumption **A1** in the phase plan, and `AuthServiceTest` asserts the
stored value is a verifiable bcrypt hash and not the plain text.

**Seeders.** `RoleSeeder` (production-safe, idempotent, five roles, no permission
keys). `DevelopmentAdminSeeder` (development-only; refuses to run in production and
refuses to invent a password). Production seeding runs `RoleSeeder` alone.

---

## 3. API endpoints created

| Method | Path | Middleware | Notes |
|---|---|---|---|
| GET | `/api/health` | `throttle:api` | Liveness + non-sensitive configuration |
| GET | `/sanctum/csrf-cookie` | — | Issued by Sanctum |
| POST | `/api/auth/login` | `throttle:auth-login` (5/min per email+IP) | Credentials checked **before** account status so the endpoint cannot enumerate accounts; session id regenerated; `last_login_at` stamped |
| POST | `/api/auth/logout` | `auth:sanctum`, `throttle:api` | Invalidates the session, rotates the CSRF token, drops resolved guards |
| GET | `/api/auth/me` | `auth:sanctum`, `active`, `throttle:api` | Session restore; 403 if deactivated mid-session |
| POST | `/api/auth/forgot-password` | `throttle:auth-forgot-password` (3/min per email+IP) | Always the same generic 200; link mailed only to active accounts |
| GET | `/api/admin/ping` | `auth:sanctum`, `active`, `throttle:api` | Proves the protected group; replaced in Phase 2 |
| GET | `/up` | — | Framework health route |
| GET | `/` (web) | — | States that this host is API-only |

**Envelope**, defined once in `App\Support\ApiResponse` and mirrored in
`lib/core/api/api_envelope.dart`:

```jsonc
{ "success": true,  "data": …, "meta": { "current_page", "per_page", "total", "last_page", "has_more" } | null }
{ "success": false, "error": { "code": "…", "message": "…", "details": { "field": ["…"] } } }
```

Error codes (`App\Support\ApiErrorCode` ↔ `lib/core/errors/error_code.dart`):
`VALIDATION_FAILED`, `UNAUTHENTICATED`, `INVALID_CREDENTIALS`, `ACCOUNT_INACTIVE`,
`ACCOUNT_BLOCKED`, `FORBIDDEN`, `NOT_FOUND`, `METHOD_NOT_ALLOWED`,
`TOO_MANY_REQUESTS`, `CSRF_TOKEN_MISMATCH`, `SERVER_ERROR`.

Documented in `docs/api/openapi.yaml`.

---

## 4. Flutter routes, screens and components

| Route | Group | Screen | Guard |
|---|---|---|---|
| `/` | public (`PublicShell`) | `FoundationHomeScreen` | none |
| `/login` | public | `LoginScreen` | redirects to `/admin` when signed in |
| `/forgot-password` | public | `ForgotPasswordScreen` | same |
| `/admin` | admin (`AdminShell`) | `AdminOverviewScreen` | authenticated **and** `status == active` |
| anything else | — | `NotFoundScreen` | — |

Path URL strategy (no hash), so `/admin` and `/login` are real, refreshable,
shareable links. The host must rewrite unknown paths to `index.html` — recorded in
the deployment checklist.

**Components created**

- `app/theme/` — `AppColors`, `AppSpacing`, `AppRadius`, `AppTypography`, `AppTheme`
- `app/localization/` — `AppLocales`, `LocaleController`, `resolveLocale`, `context.l10n`, error/validation message mapping
- `app/routing/` — `RoutePaths`, `RouteNames`, `routerProvider` with the auth guard
- `core/api/` — `ApiClient`, `ApiEndpoints`, `ApiEnvelopeParser`, `PageMeta`, conditional `BrowserSupport` (web/VM)
- `core/config/` — `AppConfig`, `AppEnvironment`
- `core/errors/` — `AppException`, `ErrorCode`, `ErrorMapper`
- `core/logging/` — `AppLogger`
- `core/utils/` — `Validators`, `ValidationError`
- `core/widgets/` — `Breakpoints`/`FormFactor`, `PageContainer`, `LanguageSwitch`, `LoadingView`, `EmptyView`, `ErrorView`, `UnauthorizedView`
- `features/auth/` — `AuthUser`, `UserRole`, `AccountStatus`, `AuthRepository` + HTTP implementation, `AuthController`, `LoginScreen`, `ForgotPasswordScreen`
- `features/shell/` — `PublicShell`, `AdminShell`, `FoundationHomeScreen`, `AdminOverviewScreen`, `NotFoundScreen`

**State handling.** Every API-driven surface renders loading, success, empty, error
and unauthorized states. `AuthController` distinguishes "session still restoring"
from "signed out", so a hard refresh on `/admin` does not bounce a signed-in user
to the sign-in screen.

---

## 5. Roles and permissions implemented

The five roles are modelled and seeded: **Super Admin, Admin, Treasurer, Content
Manager, Viewer**. Phase 0 enforces *authentication* and *account status* only —
`auth:sanctum` plus the `active` middleware on every protected route. Per-role
permission keys, the permission matrix and role-scoped endpoints are Phase 2 and
are deliberately absent.

Authorization is enforced server-side. `AdminRouteProtectionTest` asserts the
server refuses guests, inactive and blocked users, and admits an active user of
each of the five seeded roles, regardless of what the UI does.

---

## 6. Tests and command results

### Flutter — 107 tests, all passing

| File | Covers |
|---|---|
| `test/core/validators_test.dart` | e-mail/password/required rules, Devanagari input, server parity on min length |
| `test/core/api_envelope_test.dart` | success/error/paginated envelopes, defensive parsing, status fallbacks, code round-trip |
| `test/core/error_mapper_test.dart` | timeout / connection / cancel / bad-certificate / bad-response / unknown mapping |
| `test/core/app_config_test.dart` | defaults, environment parsing, API origin derivation, logging off in production |
| `test/features/auth/auth_repository_test.dart` | real `ApiClient` over a fake transport: CSRF ordering, XSRF header, trimming, 401/403/422 mapping, optional-field tolerance, signed-out vs. transport failure |
| `test/features/auth/auth_controller_test.dart` | bootstrap, restore, inactive account, sign-in/sign-out, failed sign-in leaves session untouched, refresh semantics |
| `test/features/auth/login_screen_test.dart` | Hindi and English rendering, client validation, in-flight state, error banners per code, server field errors, obscured password, responsive layout |
| `test/app/locale_controller_test.dart` | Hindi default, toggle, country variants, unsupported locale ignored |
| `test/app/localization_test.dart` | both languages delivered, placeholder interpolation, Hindi-first rendering, always-visible language switch |
| `test/app/responsive_test.dart` | breakpoint boundaries, shell layout at 3 widths, compact controls, all four shared state views |
| `test/app/router_test.dart` | guest redirected from `/admin`, active user admitted, inactive treated as guest, sign-in/sign-out re-evaluate the guard, unknown deep link |

```
$ flutter pub get                                    Got dependencies!
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  Formatted 57 files (0 changed)
$ flutter test                                       107/107 passed
$ flutter build web --release                        Built build/web
```

### Laravel — 49 tests, 170 assertions, all passing

| File | Tests | Covers |
|---|---|---|
| `tests/Feature/MigrationTest.php` | 3 | Every spec-named column on `users`/`roles`, supporting tables |
| `tests/Feature/RoleSeederTest.php` | 4 | Exactly five roles, idempotency, no Phase 2 permissions, dev seeder creates nothing without explicit credentials |
| `tests/Feature/HealthTest.php` | 2 | Success envelope shape, unknown route error envelope |
| `tests/Unit/ApiResponseTest.php` | 4 | Envelope shapes, omitted null details, pagination meta |
| `tests/Unit/AuthServiceTest.php` | 7 | Status checked only after the password verifies, blocked/inactive rejection, no login stamp on failure, password stored hashed |
| `tests/Feature/Auth/LoginTest.php` | 10 | Success, no password in the response, `last_login_at`, case-insensitive e-mail, generic failure for unknown address, blocked, inactive, validation, throttling |
| `tests/Feature/Auth/SessionTest.php` | 6 | `me` with role, unauthenticated, deactivated/blocked mid-session, logout, logout unauthenticated |
| `tests/Feature/Auth/ForgotPasswordTest.php` | 5 | Link for active users, identical answer for unknown address, nothing for blocked, validation, throttling |
| `tests/Feature/Auth/AdminRouteProtectionTest.php` | 8 | Guest 401, blocked 403, inactive 403, and one case per seeded role (data provider) |

```
$ composer install                        109 packages, package discovery clean
$ ./vendor/bin/pint --test                passed
$ php artisan test                        49 passed (170 assertions), 1.99s
$ php artisan db:show                     MariaDB 12.3.3, connection mariadb
$ php artisan migrate                     5 migrations DONE
$ php artisan db:seed --class=RoleSeeder  5 roles seeded
$ php artisan migrate:rollback            5 rolled back in reverse order, DONE
$ php artisan migrate                     DONE
```

The suite runs on in-memory SQLite (`phpunit.xml`), so `php artisan test` needs no
database server. Migration verification was run separately against **MariaDB
12.3.3**, the engine the product deploys on.

### Live server smoke check

With `php artisan serve` running against MariaDB:

| Request | Result |
|---|---|
| `GET /api/health` | 200 · `database: connected`, `timezone: Asia/Kolkata`, `locale: hi` |
| `GET /api/admin/ping` (no session) | 401 · `UNAUTHENTICATED` in the standard error envelope |
| `GET /api/auth/me` (no session) | 401 · `UNAUTHENTICATED` in the standard error envelope |

---

## 7. Defects found by actually running the code

Five real problems were found and fixed. All but the last were in code that had
been written and reviewed but never executed, which is precisely why the phase was
not claimed complete before the toolchain existed.

| # | Defect | Consequence | Fix |
|---|---|---|---|
| 1 | `Sanctum::ignoreMigrations()` called in `AppServiceProvider` | Fatal on boot — the method does not exist in Sanctum 4 | Removed. Sanctum 4 only *publishes* its migration (`publishesMigrations`), so this application legitimately owns `personal_access_tokens` and no opt-out is needed |
| 2 | The exception renderer swallowed `HttpResponseException` | **Every throttled request returned 500 instead of 429** — the login and password-reset rate limits were effectively broken. `Handler::render()` runs custom render callbacks *before* unwrapping `HttpResponseException`, and the catch-all `default` arm turned the limiter's pre-built 429 into a server error | The render callback now returns `null` for `HttpResponseException` so the framework's own handling applies |
| 3 | Expected domain failures were reported as errors | Bad credentials and blocked-account attempts wrote error reports on every occurrence | `$exceptions->dontReport([DomainException::class])`; `AuthService` already logs login attempts at info level |
| 4 | Factory-built users lacked nullable columns | `Model::shouldBeStrict()` rejected reads of `last_login_at` / `remember_token`, breaking `UserResource` and `Auth::logout()` under test | `UserFactory::configure()` force-fills both, so a factory model matches the table shape while the columns stay non-mass-assignable |
| 5 | `logout()` left a stale user on the Sanctum guard | Within the same request, `Auth::user()` still returned the signed-out user, because `RequestGuard` caches its resolved user and `setRequest()` never clears it | `Auth::forgetGuards()` after invalidating the session |

One test-design problem was also corrected: `AdminRouteProtectionTest` looped five
sign-ins through a single test. Sanctum's `RequestGuard` caches the first user it
resolves for the lifetime of the PHP process, so every iteration was answered as
user 1 — the loop was silently asserting almost nothing. It is now a data provider,
one case per role with a fresh application, which is also what a real HTTP request
gets.

---

## 8. Manual QA performed

Frontend, on the release build and in widget tests:

- Public site renders in **Hindi** with no visitor action; the English switch is
  present in the header at every breakpoint.
- Layout verified at 360 px, 768 px and 1440 px. **A real defect was found and
  fixed:** the app-bar action row overflowed by 24 px at 360 px. Both shells now
  collapse their labelled action to a tooltipped icon on phones, and the header
  text ellipsizes. Covered by a regression test.
- Sign-in form: empty, malformed-e-mail and short-password paths blocked
  client-side; in-flight state disables the button and shows a spinner.
- Failure messages verified for invalid credentials, blocked account and offline;
  the server's English text is asserted **not** to reach the visitor.
- `/admin` refuses a guest and admits an active user; sign-out closes it again.
- Unknown deep link renders the not-found screen.

Backend:

- Application boots; `php artisan --version` reports Laravel 12.69.1.
- Package discovery clean after the Sanctum fix.
- Migrations verified up → seed → rollback → up.
- Source scanned for hardcoded credentials — none. Only `.env.example` is
  committed; the generated `.env` (with a real `APP_KEY`) is git-ignored.

---

## 9. Known issues and technical debt

1. **Verified on MariaDB, not on Oracle MySQL 8.x.** The specification allows
   either. The schema uses only ordinary column types, so the risk is low, but if
   production will run MySQL 8 rather than MariaDB, re-run the migration
   verification there before deploying.
2. **Sanctum SPA topology is assumed.** Cookie/session auth requires the frontend
   and the API to be same-site with matching `FRONTEND_URL`,
   `CORS_ALLOWED_ORIGINS` and `SANCTUM_STATEFUL_DOMAINS`. No bearer-token fallback
   exists. If the committee's hosting cannot satisfy this, revisit before Phase 2.
3. **Password reset is half a feature by design.** `forgot-password` sends a link
   pointing at `/reset-password` on the frontend; that screen and the reset
   endpoint are Phase 2 scope, so the link currently lands on the not-found page.
4. **SEO/pre-rendering deferred.** `web/index.html` carries static Hindi-first
   title, description and Open Graph tags. Per-route metadata needs the pre-render
   strategy the specification calls for — Phase 1.
5. **No custom font bundled.** Devanagari uses the browser/platform font stack to
   keep the bundle small for low-bandwidth users. Worth a visual review with the
   committee on real village devices.
6. **Language choice is not persisted.** Switching to English does not survive a
   reload. Deliberate for Phase 0; a natural addition alongside Phase 1 site
   settings.
7. **CSRF validation is skipped inside the test suite** (framework behaviour in
   `ValidateCsrfToken`). CSRF handling is exercised only through the Flutter
   client's `X-XSRF-TOKEN` tests, not by a backend test. Worth an explicit
   end-to-end check during Phase 12 security smoke testing.
8. **No end-to-end test crosses the two stacks.** The Flutter tests use a fake
   transport and the Laravel tests use an in-process HTTP kernel; nothing yet
   exercises a real browser against a real API. That belongs in Phase 12.
9. **The admin chrome is briefly visible during session restore.** Deep-linking
   `/admin` while signed out renders `AdminShell` (app bar, sign-out button) for
   as long as `GET /api/auth/me` is in flight, then redirects to `/login`. No data
   is exposed and the server refuses the request regardless, but it reads as a
   flash of the wrong screen — noticed during the headless walkthrough. The
   router holds the location deliberately so a signed-in user's refresh is not
   bounced; showing a neutral loading screen instead of the admin shell while
   `session.isLoading` would keep that behaviour without the flash. Worth doing
   alongside the Phase 2 admin dashboard.
10. **`.idea/` files** were produced by `flutter create`; they are git-ignored.

---

## 10. Local toolchain installed during this phase

Recorded so the environment is reproducible:

| Tool | Version | Location | Notes |
|---|---|---|---|
| PHP | 8.3.33 NTS x64 | `C:\devtools\php83` | Portable zip from windows.php.net, SHA-256 verified. winget's `PHP.PHP.8.3` manifest is pinned to 8.3.32 and 404s, because php.net moves superseded patches to `/releases/archives/` |
| Composer | 2.10.3 | `C:\devtools\composer` | Installer verified against `composer.github.io/installer.sig` |

`php.ini` was created from `php.ini-development` with `extension_dir`, `curl`,
`fileinfo`, `intl`, `mbstring`, `openssl`, `pdo_mysql`, `pdo_sqlite` and `zip`
enabled. Both directories were appended to the **user** PATH.

---

## 11. Next phase

**Phase 1 — Public Website & Bilingual CMS.** Planned but **not started**, and it
will not be started without explicit approval.
