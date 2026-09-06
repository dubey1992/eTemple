# Radha Krishna Thakurwadi — API

Laravel REST/JSON API for the Flutter Web public site and admin console.

## Layout

```
app/
  Exceptions/       DomainException + the central API exception renderer
  Http/
    Controllers/    Thin controllers only
    Middleware/     EnsureUserIsActive (the "active account" gate)
    Requests/       Form Requests — all write validation lives here
    Resources/      Response shaping; never exposes password hashes
  Models/           User, Role
  Providers/        Rate limiters, password-reset URL, model strictness
  Services/         Business rules (AuthService)
  Support/          ApiResponse envelope, ApiErrorCode
database/
  migrations/ seeders/ factories/
routes/api.php      Public, auth and protected admin route groups
```

## Conventions

**Envelope.** Every endpoint answers with the same shape, defined once in
`App\Support\ApiResponse`:

```jsonc
{ "success": true,  "data": …, "meta": … }
{ "success": false, "error": { "code": "…", "message": "…", "details": … } }
```

`ApiErrorCode` holds the stable codes. They are mirrored by the Flutter client
in `lib/core/errors/error_code.dart` — change both in the same release.

**Pagination.** `ApiResponse::paginated()` produces
`{current_page, per_page, total, last_page, has_more}`. Reuse it; do not invent a
second convention.

**Authorization.** Admin routes carry `auth:sanctum` plus the `active` alias.
Hiding a control in the Flutter UI is never the access control.

**Errors.** Throw a `DomainException` subclass for anything a caller is allowed
to see. Everything else becomes a logged `SERVER_ERROR` with no internal detail
in the response.

## Commands

```bash
composer install
cp .env.example .env && php artisan key:generate
php artisan migrate
php artisan db:seed                       # roles + dev admin (local only)
php artisan serve

php artisan test                          # in-memory SQLite; no MySQL needed
./vendor/bin/pint --test                  # code style
```

## Authentication

Sanctum stateful (cookie/session) authentication. The session cookie is HttpOnly
and never readable by script; the client echoes the readable `XSRF-TOKEN` cookie
back in the `X-XSRF-TOKEN` header on unsafe requests.

For this to work the API and the Flutter app must agree on three settings:
`FRONTEND_URL`, `CORS_ALLOWED_ORIGINS` and `SANCTUM_STATEFUL_DOMAINS`.

## Seed data

- `RoleSeeder` — the five specification roles. Production-safe and idempotent.
- `DevelopmentAdminSeeder` — **development only**. Refuses to run in production
  and refuses to invent a password; set `DEV_ADMIN_EMAIL` and
  `DEV_ADMIN_PASSWORD` locally to use it.

Production seeding runs `RoleSeeder` alone.
