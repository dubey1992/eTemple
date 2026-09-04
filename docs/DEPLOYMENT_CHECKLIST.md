# Deployment checklist

Phase 0 scope: enough to stand up a staging environment safely. Backup/restore
rehearsal, audit logging and the full security review are Phase 11; committee
acceptance and handover are Phase 12.

---

## Before every deployment

- [ ] `flutter analyze`, `flutter test`, `flutter build web --release` green
- [ ] `php artisan test` green
- [ ] `./vendor/bin/pint --test` green
- [ ] `php artisan migrate --pretend` reviewed for the target database
- [ ] Database backup taken **before** migrations run
- [ ] Rollback plan written down (previous build artefact + `migrate:rollback` steps)

---

## Backend environment

- [ ] `APP_ENV=production`, `APP_DEBUG=false`
- [ ] `APP_KEY` generated once per environment and stored in the secret manager,
      never in the repository
- [ ] `APP_TIMEZONE=Asia/Kolkata`
- [ ] `DB_USERNAME` is a least-privilege account — not `root`, no `GRANT` rights
- [ ] `FRONTEND_URL` and `CORS_ALLOWED_ORIGINS` name the exact frontend origin
      (a wildcard cannot be combined with credentialed requests and must never
      be used here)
- [ ] `SANCTUM_STATEFUL_DOMAINS` lists that same host
- [ ] `SESSION_SECURE_COOKIE=true` (HTTPS only)
- [ ] `SESSION_DOMAIN` set to the shared parent domain when the API and the site
      are on different subdomains
- [ ] `SESSION_SAME_SITE=lax`, `SESSION_HTTP_ONLY=true`
- [ ] `MAIL_MAILER` pointed at a real SMTP service (not `log`)
- [ ] `DEV_ADMIN_EMAIL` / `DEV_ADMIN_PASSWORD` **unset**

## Backend server

- [ ] Document root is `backend_laravel/public`, never the project root
- [ ] HTTPS enforced; HTTP redirects to HTTPS
- [ ] `php artisan migrate --force`
- [ ] `php artisan db:seed --class=RoleSeeder --force` (reference data only —
      never `DatabaseSeeder`, which also calls the development seeder)
- [ ] `php artisan config:cache route:cache` after each release
- [ ] `storage/` and `bootstrap/cache/` writable by the web user only
- [ ] Scheduled database backup configured and its first run verified

## Frontend build

- [ ] Built with explicit configuration:
      ```bash
      flutter build web --release \
        --dart-define=APP_ENV=production \
        --dart-define=API_BASE_URL=https://api.<domain>/api
      ```
- [ ] **Pre-render page metadata after every build** — without this the site
      ships one generic title/description for every route to crawlers that do
      not run JavaScript:
      ```bash
      dart run tool/generate_static_meta.dart \
        --api=https://api.<domain>/api --site=https://<domain>
      ```
- [ ] Host serves `/<slug>/index.html` for `/<slug>` (so the pre-rendered head
      is used) **before** falling back to the SPA rewrite below
- [ ] `sitemap.xml` and `robots.txt` published from the build output; confirm
      `robots.txt` disallows `/admin`, `/login` and `/forgot-password`
- [ ] Host rewrites **all** unknown paths to `index.html`
      (required for `/admin`, `/login` and every deep link to survive a refresh —
      the app uses the path URL strategy, not hash routing)
- [ ] `index.html` served with `Cache-Control: no-cache`; hashed assets served
      with a long cache lifetime
- [ ] Compression (gzip/brotli) enabled — this matters on village connections
- [ ] Security headers set: `Strict-Transport-Security`, `X-Content-Type-Options: nosniff`,
      `Referrer-Policy: strict-origin-when-cross-origin`, `X-Frame-Options: DENY`

## Post-deployment verification

- [ ] `GET /api/health` returns `"database": "connected"`
- [ ] The public site loads and renders in **Hindi** by default
- [ ] The English switch works and survives navigation
- [ ] `/login` accepts a valid committee account
- [ ] `/admin` loads after signing in, and **survives a hard refresh**
- [ ] `/admin` redirects to `/login` in a fresh private window
- [ ] `curl https://api.<domain>/api/admin/ping` without a session returns 401
- [ ] A deactivated account is refused at login and loses access mid-session
- [ ] Layout checked at 360 px, 768 px and 1440 px widths
- [ ] Checked in Chrome/Edge on desktop and in a common Android mobile browser

## Handover (recorded here, executed in Phase 12)

- [ ] All seeded/temporary admin credentials changed
- [ ] Backup **and restore** rehearsed, not just configured
- [ ] Admin user guide handed to the committee
