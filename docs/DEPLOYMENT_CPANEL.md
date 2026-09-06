# Deploying to cPanel — radhakrishnathakurwadi.com

**Target:** https://radhakrishnathakurwadi.com/ · cPanel shared hosting
**Written:** 2026-09-16 · Phase 12

Follow this in order. Steps 1–6 are done once; steps 7–11 are done once and then
checked; step 12 is every release afterwards.

Nothing here needs root, a shell daemon, or software the host does not already
offer — those constraints are what shaped the design (`PHASE_12_PLAN` §B).

---

## What goes where

| | cPanel object | Document root | Holds |
|---|---|---|---|
| The public site | the main domain | `public_html` | the Flutter build |
| The API | a **subdomain**, `api.` | `thakurwadi/backend_laravel/public` | Laravel |
| The code | — | `~/thakurwadi/` | both projects, outside any document root |

The API is a subdomain rather than a `/api` folder because the rewrite that
makes `/gallery` work has to exclude every API path, and one mistake there
serves the HTML shell where JSON was expected — a parse error that points
nowhere near its cause.

Both are the same registrable domain, so a request from the site to the API is
**same-site**: the session cookie works with `SameSite=lax` and no weakening is
needed.

---

## 1. PHP

**cPanel → Select PHP Version.**

Choose **PHP 8.3** (8.2 is the minimum). Then, on the *Extensions* tab, make
sure these are ticked:

| Extension | Without it |
|---|---|
| `gd` | **every photograph upload is refused.** Uploads are stripped of location and camera data by being re-encoded through GD; there is no fallback that stores the original |
| `zip` | the Excel export cannot be written — it is built by hand with `ZipArchive` |
| `intl` | dates and numbers format wrongly |
| `mbstring` | Devanagari is cut mid-character |
| `pdo_mysql`, `openssl`, `fileinfo`, `curl`, `xml` | nothing works |
| `exif` | *optional* — without it a portrait photograph may appear on its side |

**cPanel → MultiPHP INI Editor** (Editor mode), for the API subdomain:

```ini
memory_limit = 256M
upload_max_filesize = 10M
post_max_size = 12M
max_execution_time = 120
```

`memory_limit` is the one place this application can fail on hardware rather
than on logic: an export of ten thousand rows is built in memory, and a shared
host's 64M default is not enough.

> The CLI and the web server often read **different** `php.ini` files on cPanel.
> `php artisan deploy:check` prints which one it is reading; if the two disagree,
> the web server's is the one that decides.

---

## 2. The database

**cPanel → MySQL Databases.**

1. Create a database — cPanel prefixes it, e.g. `thakur_site`.
2. Create a user, e.g. `thakur_app`, with a long generated password.
3. Add the user to the database with **ALL PRIVILEGES**.

Laravel needs full rights on its own schema for migrations to run. It does
**not** need `CREATE DATABASE`, and it should not have it — which also means a
restore rehearsal needs a credential the application itself does not have
(`BACKUP_AND_RESTORE.md` §4).

---

## 3. The code

**cPanel → Git Version Control**, or upload a zip and extract it.

```
~/thakurwadi/
   backend_laravel/
   frontend_flutter/      (source only; the build is made on your machine)
   docs/
```

Then, in **cPanel → Terminal**:

```bash
cd ~/thakurwadi/backend_laravel
composer install --no-dev --optimize-autoloader
```

If the plan has no Terminal, run Composer through **cPanel → Setup PHP
Application**, or upload a `vendor/` built locally with the same PHP version.

---

## 4. The subdomain for the API

**cPanel → Domains → Create A New Domain.**

* Domain: `api.radhakrishnathakurwadi.com`
* Uncheck *"Share document root"*
* Document root: `thakurwadi/backend_laravel/public`

The document root is `public`, never the project root. Pointing it one level up
publishes `.env` — the database password and the application key — as a file
anybody can fetch.

---

## 5. The environment file

```bash
cd ~/thakurwadi/backend_laravel
cp .env.production.example .env
php artisan key:generate
```

Then edit `.env` and fill in the four values marked **FILL IN**: `APP_KEY` (done
by the command above), `DB_DATABASE`, `DB_USERNAME`, `DB_PASSWORD`, and
`MAIL_PASSWORD`.

Everything else in that file is already set for this domain — including the two
that are easy to get wrong:

```
SESSION_DOMAIN=.radhakrishnathakurwadi.com     # the leading dot is what makes the cookie work across the subdomain
CORS_ALLOWED_ORIGINS=https://radhakrishnathakurwadi.com,https://www.radhakrishnathakurwadi.com
```

Set permissions so the file is not world-readable:

```bash
chmod 600 .env
```

---

## 6. Migrate, seed and link

```bash
cd ~/thakurwadi/backend_laravel
php artisan migrate --force
php artisan db:seed --class=RoleSeeder --force
php artisan storage:link
php artisan config:cache && php artisan route:cache
```

**Only `RoleSeeder`.** `DevelopmentContentSeeder` invents donations, ledger
entries and example villagers; it refuses to run when `APP_ENV=production`, and
that refusal is deliberate. The temple's real content is entered through the
console.

Then create the first account — there is no way in from outside without it:

```bash
php artisan tinker
>>> $role = App\Models\Role::where('slug', 'super-admin')->first();
>>> $u = App\Models\User::create(['first_name'=>'…','last_name'=>'…','email'=>'…','role_id'=>$role->id,'status'=>'active','password'=>Str::random(64)]);
>>> Password::broker()->sendResetLink(['email' => $u->email]);
```

The password is random and never disclosed; the member sets their own from the
mail. If mail is not working yet, use `php artisan tinker` to set one directly —
and change it from inside the console on the first sign-in.

---

## 7. The queue worker — a cron entry, not a daemon

**cPanel → Cron Jobs.** Every minute:

```
* * * * * cd ~/thakurwadi/backend_laravel && /usr/local/bin/php artisan queue:work --stop-when-empty --max-time=50 >> ~/queue.log 2>&1
```

`--stop-when-empty` and `--max-time=50` are what make this safe on shared
hosting: the process finishes on its own rather than being killed, and the next
minute's run picks up anything new.

**This is not optional.** With `QUEUE_CONNECTION=database` and no worker, an
announcement is written to the jobs table, the console reports it as *sent*, and
the village is never told. That is the worst failure in this system, and this
cron entry is the whole of its cure. (`deploy:check` looks for jobs older than
ten minutes and fails when it finds them.)

If the host forbids cron entirely, set `QUEUE_CONNECTION=sync` instead: sending
inline is slower, but a failure then *says* it failed.

---

## 8. The nightly backup

Upload `deploy/cpanel/backup.sh` to `~/bin/thakurwadi-backup.sh`, then:

```bash
chmod 700 ~/bin/thakurwadi-backup.sh
mkdir -p ~/backups
```

**cPanel → Cron Jobs**, once a night, out of hours:

```
30 2 * * * /home/<account>/bin/thakurwadi-backup.sh >> /home/<account>/backups/cron.log 2>&1
```

Read `docs/BACKUP_AND_RESTORE.md` before trusting it. The important parts: the
database and the uploads are taken **together**, `utf8mb4` is not optional, and
a backup that has never been restored from is a hope rather than a procedure.

---

## 9. The site

On your own machine:

```bash
cd frontend_flutter
flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.radhakrishnathakurwadi.com/api

# Per-page titles and descriptions for crawlers that do not run JavaScript,
# plus sitemap.xml and robots.txt. Needs the API to be live.
dart run tool/generate_static_meta.dart \
  --api=https://api.radhakrishnathakurwadi.com/api \
  --site=https://radhakrishnathakurwadi.com
```

Upload **the contents of `build/web/`** into `public_html` — the contents, not
the folder. `build/web/.htaccess` travels with it and is what makes `/gallery`
work on a reload; if your upload tool hides dotfiles, turn that off, or upload it
by hand.

Keep the previous `public_html` as a dated sibling before replacing it (see
§12).

---

## 10. HTTPS and the uploads directory

**cPanel → SSL/TLS Status.** Run AutoSSL for both the domain and the `api.`
subdomain. The site's own `.htaccess` already redirects plain HTTP; leave that
alone once the certificate is issued.

Then install the uploads rules:

```bash
cp ~/thakurwadi/deploy/cpanel/storage.htaccess \
   ~/thakurwadi/backend_laravel/public/storage/.htaccess
```

Uploaded photographs are static files: the web server answers them without ever
running Laravel, so the CORS header and `nosniff` have to be set there rather
than in `config/cors.php`.

---

## 11. Check it, then look at it

```bash
cd ~/thakurwadi/backend_laravel
php artisan deploy:check
```

Fix everything it marks `XX` and run it again. It ends by naming the two things
PHP cannot see from inside itself — do both by hand:

1. Open `https://api.radhakrishnathakurwadi.com/storage/accounts/attachments/`
   in a browser. It must **not** be served. Those are shop bills carrying a
   trader's name and telephone number.
2. Submit the contact form from **two different networks** — a phone on mobile
   data and a laptop on wi-fi. If the second is refused as a repeat of the
   first, the real client IP is not reaching Laravel, and every anti-spam limit
   in the system is keyed on one shared bucket. Behind a proxy or CDN this needs
   `TrustProxies` configured.

Then open the site and look at it, in Hindi and in English, on a phone. Sign in.
Record one donation and print its receipt. Send one announcement to yourself and
**confirm it arrives** — that is the only proof the queue worker is running.

---

## 12. Every release after the first

```bash
# 1. On your machine: the gates must be green before anything is uploaded.
cd frontend_flutter && flutter analyze && flutter test && flutter build web --release \
  --dart-define=APP_ENV=production \
  --dart-define=API_BASE_URL=https://api.radhakrishnathakurwadi.com/api
cd ../backend_laravel && ./vendor/bin/pint --test && php artisan test

# 2. On the host: take a backup FIRST, before any migration runs.
~/bin/thakurwadi-backup.sh

# 3. Keep the current site, then replace it.
mv ~/public_html ~/public_html-$(date +%Y-%m-%d) && mkdir ~/public_html
#    ... upload the new build/web contents into public_html ...

# 4. The API.
cd ~/thakurwadi && git pull
cd backend_laravel
composer install --no-dev --optimize-autoloader
php artisan migrate --force
php artisan config:cache && php artisan route:cache && php artisan view:clear

# 5. Prove it.
php artisan deploy:check
```

**Never** run `migrate:fresh`, `db:wipe` or `migrate:refresh` on this host. Each
of them destroys the temple's records, and none of them is recoverable from
anything but the backup taken in step 2.

### Going back

Two different failures, two different answers — and telling them apart is the
whole skill:

| What went wrong | What to do |
|---|---|
| The new build is broken; the data is fine | `rm -rf ~/public_html && mv ~/public_html-<date> ~/public_html`. Two renames in the cPanel file manager, no shell and no rebuild. If a migration ran, `php artisan migrate:rollback --step=1` too |
| The data is wrong — something was deleted or overwritten | **Restore from the backup**, not `migrate:rollback`. A rollback undoes a *schema* change; it cannot bring back a row. Follow `BACKUP_AND_RESTORE.md` §3, and take a fresh dump of the damaged state first: whatever went wrong, the current state is still evidence |

Put the site into maintenance mode first when the API is involved:

```bash
php artisan down
# ... restore or roll back ...
php artisan up
```
