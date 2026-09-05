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
- [ ] `MEDIA_DISK` names a disk that exists on this host (`public`, or `s3`
      with its credentials set); `MEDIA_MAX_UPLOAD_KB` is not larger than PHP's
      own `upload_max_filesize` **and** `post_max_size`, which are the second
      wall and silently truncate a request that exceeds them
- [ ] **The contact form's real client IP reaches Laravel.** Every anti-spam
      limit in Phase 7 — the rate limit, the daily ceiling and the question
      after the threshold — is keyed on `$request->ip()`. Behind a proxy or a
      CDN that is the *proxy's* address unless `TrustProxies` is configured, in
      which case every visitor in the country shares one bucket: the first few
      messages of the day would exhaust it and everybody else would be
      throttled. Verify by submitting from two different networks and checking
      that the second is not counted against the first
- [ ] `ENQUIRY_ACKNOWLEDGEMENT_ENABLED` is left `false` unless the committee
      has asked for it. When it is on, the address is supplied by whoever filled
      an anonymous form and need not be theirs — the mail is rate limited per
      address and carries none of the sender's words, and it should still be a
      deliberate decision
- [ ] `QUEUE_CONNECTION` has a worker running if the acknowledgement is enabled;
      it is queued so a slow SMTP server cannot hold a public request open, and
      with no worker the mail is never sent

## Backend server

- [ ] Document root is `backend_laravel/public`, never the project root
- [ ] HTTPS enforced; HTTP redirects to HTTPS
- [ ] **The `gd` PHP extension is installed.** It is a hard dependency from
      Phase 5: uploaded photographs are stripped of location and camera data by
      being re-encoded through it, and without it `MediaService` refuses every
      upload rather than storing an unstripped original. `exif` is optional and
      only affects auto-rotation of portrait photographs; install it too.
      Verify with `php -r "var_dump(extension_loaded('gd'));"` **as the web
      user**, not just on the CLI — the two often load different `php.ini`
      files
- [ ] `php artisan storage:link` (once per environment, when `MEDIA_DISK=public`)
      — without it every uploaded photograph 404s while the database insists it
      exists
- [ ] The uploads directory (`storage/app/public/media`) is included in the
      backup, and **excluded from the deployment artefact** so a release never
      overwrites or removes the committee's photographs
- [ ] **`Access-Control-Allow-Origin` is set on `/storage/`** when the site and
      the API are on different origins, which they are by default here. Uploads
      are static files: the web server answers them without running Laravel, so
      `config/cors.php` cannot do this. In nginx:
      ```nginx
      location /storage/ {
          add_header Access-Control-Allow-Origin "https://<site-domain>" always;
          add_header Cross-Origin-Resource-Policy "cross-origin" always;
      }
      ```
      Without it the client falls back to plain `<img>` elements — the gallery
      still renders, but the bounded decode that keeps a phone alive is lost
- [ ] `php artisan migrate --force`
- [ ] `php artisan db:seed --class=RoleSeeder --force` (reference data only —
      never `DatabaseSeeder`, which also calls the development seeder)
- [ ] `php artisan config:cache route:cache` after each release
- [ ] `storage/` and `bootstrap/cache/` writable by the web user only
- [ ] Scheduled database backup configured and its first run verified
- [ ] The web server does **not** execute anything under the uploads directory.
      Files are re-encoded images with server-generated names, so nothing
      executable can be stored there — but a misconfigured host that runs `.php`
      from a writable directory is one mistake away from a shell, and the
      cheapest place to close that is here

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
