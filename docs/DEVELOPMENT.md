# Local development setup

## Prerequisites

| Tool | Version | Notes |
|---|---|---|
| Flutter | stable (3.47+) with Dart 3.13+ | `flutter doctor` should be clean for the **web** target |
| PHP | 8.2 or 8.3 | with `mbstring`, `pdo_mysql`, `pdo_sqlite`, `bcmath`, `intl`, `openssl` |
| Composer | 2.x | |
| MySQL / MariaDB | MySQL 8.x or MariaDB 10.6+ | only needed to *run* the API; the test suite uses in-memory SQLite |

> **Note for this repository's current state:** PHP, Composer and MySQL were not
> installed on the machine where Phase 0 was authored, so the backend has not
> been executed. Follow the steps below on a machine that has them and report
> anything that does not come up green.

---

## 1. Backend — `backend_laravel`

```bash
cd backend_laravel

composer install
cp .env.example .env
php artisan key:generate
```

Edit `.env`:

```ini
DB_DATABASE=thakurbari
DB_USERNAME=thakurbari_app          # use a least-privilege account, not root
DB_PASSWORD=<your local password>

FRONTEND_URL=http://localhost:5000
CORS_ALLOWED_ORIGINS=http://localhost:5000
SANCTUM_STATEFUL_DOMAINS=localhost:5000

# Optional: creates a local Super Admin when you seed.
DEV_ADMIN_EMAIL=you@example.test
DEV_ADMIN_PASSWORD=<a local-only password>
```

Create the schema and reference data:

```bash
php artisan migrate
php artisan db:seed              # roles, page structure + (dev only) admin & sample content
php artisan serve                # http://localhost:8000
```

Seeders, and what is safe in production:

| Seeder | Production-safe | What it does |
|---|---|---|
| `RoleSeeder` | ✅ | The five specification roles |
| `PageStructureSeeder` | ✅ | `home` and `about` rows as **empty drafts** — structure, not content |
| `DevelopmentAdminSeeder` | ❌ dev only | A local Super Admin from `DEV_ADMIN_*` |
| `DevelopmentContentSeeder` | ❌ dev only | Sample copy, settings and menu. Its `about` page is Hindi-only on purpose, so the English fallback is visible locally |

Production seeds `RoleSeeder` and `PageStructureSeeder` only; the committee
writes and publishes the real content through the admin editor.

Verify:

```bash
curl http://localhost:8000/api/health
```

### Backend checks

```bash
php artisan test                 # in-memory SQLite, no MySQL server needed
./vendor/bin/pint --test         # code style
php artisan migrate:fresh --seed # migration verification
php artisan migrate:rollback     # rollback verification
```

---

## 2. Frontend — `frontend_flutter`

```bash
cd frontend_flutter
flutter pub get

flutter run -d chrome \
  --web-port=5000 \
  --dart-define=APP_ENV=development \
  --dart-define=API_BASE_URL=http://localhost:8000/api
```

The port matters: it must match `FRONTEND_URL`, `CORS_ALLOWED_ORIGINS` and
`SANCTUM_STATEFUL_DOMAINS` on the backend, or the session cookie will be
rejected by the browser and every protected call will return 401.

### Frontend checks

```bash
flutter analyze
flutter test
dart format --output=none --set-exit-if-changed .
flutter build web --release --dart-define=APP_ENV=staging --dart-define=API_BASE_URL=...
```

### Build-time configuration

| `--dart-define` | Default | Purpose |
|---|---|---|
| `APP_ENV` | `development` | `development` / `staging` / `production` |
| `API_BASE_URL` | `http://localhost:8000/api` | Base URL including the `/api` prefix |
| `API_CONNECT_TIMEOUT_MS` | `15000` | Connect timeout |
| `API_RECEIVE_TIMEOUT_MS` | `20000` | Receive timeout |

No secret is ever passed this way — a web bundle is public. Only non-sensitive
configuration belongs in `--dart-define`.

### Localization

Strings live in `lib/l10n/app_hi.arb` (the template, Hindi) and
`lib/l10n/app_en.arb`. After editing either:

```bash
flutter gen-l10n
```

The generated `lib/l10n/app_localizations*.dart` files are committed so a fresh
clone analyzes without a build step; CI checks they are current.

---

## Repository conventions

- One phase at a time; see `docs/PHASE_STATUS.md`.
- Plans go in `docs/phase-plans/`, reports in `docs/phase-reports/`.
- API changes update `docs/api/openapi.yaml` in the same commit.
- Never commit a populated `.env`, a key or a credential.
