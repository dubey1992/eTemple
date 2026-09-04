# राधा कृष्ण ठाकुरबाड़ी | Radha Krishna Thakurbari

Website and administration system for the Radha Krishna Thakurbari temple in
Amarpur Pankhoriya (Kurma Panchayat, Rasulpur Ekchari, Bhagalpur, Bihar — 813204).

A non-profit village temple project. Hindi is the default language; English is
the secondary language behind an explicit switch.

| Layer | Technology |
|---|---|
| Public site & admin console | Flutter Web (Dart 3.x), Material 3, Riverpod, go_router, Dio |
| API | Laravel REST/JSON with Sanctum cookie/session authentication |
| Database | MySQL 8.x / MariaDB |

```
frontend_flutter/   Flutter Web application
backend_laravel/    Laravel REST/JSON API
docs/               Specification-derived plans, reports and API contract
```

## Getting started

See **[docs/DEVELOPMENT.md](docs/DEVELOPMENT.md)**.

## Project state

Development is phase-gated. The current status of every phase is tracked in
**[docs/PHASE_STATUS.md](docs/PHASE_STATUS.md)**; the full checklist is in
**[docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md)**.

| Document | Purpose |
|---|---|
| [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) | Phases 0–12 mapped to the specification |
| [docs/PHASE_STATUS.md](docs/PHASE_STATUS.md) | Current status of each phase |
| [docs/phase-plans/](docs/phase-plans/) | Design written before each phase is coded |
| [docs/phase-reports/](docs/phase-reports/) | What each phase actually delivered |
| [docs/api/openapi.yaml](docs/api/openapi.yaml) | API contract |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | Local setup and check commands |
| [docs/DEPLOYMENT_CHECKLIST.md](docs/DEPLOYMENT_CHECKLIST.md) | Release checklist |

## Checks

```bash
# frontend_flutter
flutter pub get && flutter analyze && flutter test && flutter build web --release

# backend_laravel
composer install && ./vendor/bin/pint --test && php artisan test
```

## Security

No credential, key or password belongs in this repository. Environments are
configured through `.env` (backend, never committed) and `--dart-define`
(frontend, non-secret values only).
