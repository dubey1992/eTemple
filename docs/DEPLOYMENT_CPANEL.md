# Deploying to cPanel — radhakrishnathakurwadi.com

**Target:** https://radhakrishnathakurwadi.com/ · cPanel shared hosting
**Written:** 2026-09-16 · Phase 12
**Performed:** 2026-09-06 — see *What is already deployed* below

---

## What is already deployed

Steps 1–11 below were **carried out on 2026-09-06**. The site is installed,
configured and verified on the hosting account; the only thing left is the DNS
change in *Going live*, which is at the registrar and not in cPanel.

| | |
|---|---|
| PHP | `ea-php83` — 8.3.33, with gd, zip, intl, mbstring, pdo_mysql, fileinfo, openssl, exif all loaded |
| Code | cloned to `/home/radhakrishn/thakurwadi` from the public repository |
| Composer | `install --no-dev --optimize-autoloader`, on the host |
| Database | `radhakrishn_temple`, user `radhakrishn_app`, ALL PRIVILEGES |
| Migrations | all 25, plus `RoleSeeder` — five roles |
| `.env` | from `.env.production.example`, permissions **0600** |
| Site | `build/web` extracted into `public_html`, `.htaccess` included |
| API | `api.radhakrishnathakurwadi.com` → `thakurwadi/backend_laravel/public` |
| Storage | `storage:link` run; `deploy/cpanel/storage.htaccess` installed |
| Queue worker | cron, every minute, `queue:work --stop-when-empty --max-time=50` |
| Backup | cron, 02:30 nightly, `deploy/cpanel/backup.sh` |
| First account | one Super Admin, `super.admin@thakurwadi.com`, with a temporary password to be changed at first sign-in |

**`php artisan deploy:check`: 37 passed, 0 failed.**

Verified against the hosting IP (`103.191.209.38`) with the domain resolved to
it by hand, since DNS still points elsewhere:

| Check | Result |
|---|---|
| The site loads and is named correctly | ✅ `राधा कृष्ण ठाकुरवाड़ी \| Radha Krishna Thakurwadi` |
| A deep link works on a cold load | ✅ `/gallery` → 200, so the SPA rewrite is in force |
| The API answers | ✅ `/api/health` → `database: connected`, `environment: production` |
| The whole public surface answers on an empty database | ✅ all ten endpoints → 200 |
| `.env` is not served | ✅ 444, and the same for a traversal attempt |
| The private uploads path is not served | ✅ 404 — bills are on a disk outside every document root |
| An admin endpoint without a session | ✅ 401 |
| Signing in | ✅ 200, `super-admin`, 20 permissions — and the address it replaced is refused with 401 |
| Reading the audit trail as Super Admin | ✅ 200 |
| Security headers | ✅ nosniff, DENY, Referrer-Policy, Permissions-Policy, CSP, HSTS |

### Going live

The domain still serves a **GoDaddy Website Builder** page. To point it here, at
the registrar's DNS:

| Record | Name | Value |
|---|---|---|
| A | `@` | `103.191.209.38` |
| A | `www` | `103.191.209.38` |
| A | `api` | `103.191.209.38` |

Leave MX and TXT records alone — changing the A records moves the website
without touching mail. (Changing the nameservers to the host's would move
*everything*, including mail, and is the more disruptive option.)

Then, once it has propagated: **cPanel → SSL/TLS Status → Run AutoSSL** for both
the domain and `api.`. Until the certificate is issued, browsers will warn —
AutoSSL cannot validate a domain that does not resolve to the server.

**The Super Admin's address is on a domain this account does not host.**
`super.admin@thakurwadi.com` is fine as a name to sign in with, but nothing on
this server can deliver to it, so "forgot password" has nowhere to send a link.
Either create a mailbox for it wherever that domain's mail lives, or move the
account to an address on `radhakrishnathakurwadi.com` once the DNS is here.
Until then, the password is the only way in — keep it somewhere safe.

Two things to do after the certificate is in place, both named by
`deploy:check` because PHP cannot see them from inside:

1. Open `https://api.radhakrishnathakurwadi.com/storage/accounts/attachments/`
   in a browser and confirm it is **not** served.
2. Submit the contact form from **two different networks**. If the second is
   refused as a repeat of the first, the real client IP is not reaching Laravel
   and every anti-spam limit shares one bucket.

Follow this in order. Steps 1–6 are done once; steps 7–11 are done once and then
checked; step 12 is every release afterwards.

Nothing here needs root, a shell daemon, or software the host does not already
offer — those constraints are what shaped the design (`PHASE_12_PLAN` §B).

---

## This account, as it actually is

Inspected on 2026-09-06 through the cPanel API. Everything below is a fact about
*this* hosting account, not a general assumption, and several of them change the
steps that follow.

| | |
|---|---|
| cPanel | `https://eternal.herosite.pro:2083/` · user `radhakrishn` |
| Home directory | `/home/radhakrishn` |
| Document root | `/home/radhakrishn/public_html` |
| Disk | 5 GB, **1 MB used** — the account is empty |
| PHP now | `ea-php82` (meets the `^8.2` minimum) |
| PHP available | up to `ea-php85` / `alt-php85`; **use `ea-php83`** |
| Subdomains | none yet |
| Databases | none yet |
| Cron | ✅ available |
| MySQL, File Manager | ✅ available |
| **Git Version Control** | ✅ available — and the repository is public, so it can be cloned straight onto the host |
| **SSH** | ❌ no port answers (22, 2222, 2200, 22222) |
| **cPanel Terminal** | ❌ `api_shell` is disabled on this plan |

### Two consequences worth reading before you start

**There is no shell.** Composer and `php artisan` cannot be typed anywhere. The
way to run a command on this account is to schedule it as a **cron job**, send
its output to a file, and then read that file in the File Manager. Every command
in this guide is written so it can be pasted into *Cron Jobs* as a one-off,
run once, and then deleted. Set such a one-off to a minute a few minutes ahead,
wait for it, read the log, remove the entry.

**The domain does not point here yet.** `radhakrishnathakurwadi.com` currently
serves a **GoDaddy Website Builder** page, so nothing deployed to this account is
publicly visible until the DNS is repointed at this hosting. That is a good
order to work in — the site can be built and checked in private — but it means
the last step of going live is a DNS change at the registrar, not anything in
this guide.

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

**cPanel → MultiPHP Manager** (to switch the version), then **Select PHP
Version** (for the extensions).

This account is on `ea-php82` today. Set `ea-php83` for
`radhakrishnathakurwadi.com` — 8.2 satisfies the minimum, but 8.3 is what the
application is developed and tested against. Then, on the *Extensions* tab, make
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

**cPanel → Git™ Version Control → Create.**

* Leave *Clone a Repository* **on**
* Clone URL: `https://github.com/dubey1992/eTemple.git`
* Repository Path: `thakurwadi`
* Repository Name: `thakurwadi`

The repository is public, so no key or password is needed. cPanel clones it into
`/home/radhakrishn/thakurwadi/`, giving:

```
~/thakurwadi/
   backend_laravel/
   frontend_flutter/      (source only; the build is made on your machine)
   docs/
```

`vendor/` is not in the repository, so Composer has to run on the host. With no
shell, that means a cron job.

### How to run a one-off command on this account

This is the pattern for every command in the rest of this guide, so it is worth
doing once slowly:

1. **cPanel → Cron Jobs**
2. *Common Settings*: **Once Per Minute** (`* * * * *`)
3. Command: the thing you want to run, ending with `>> ~/deploy.log 2>&1`
4. **Add New Cron Job**, wait two minutes
5. **cPanel → File Manager**, open `deploy.log`, read what happened
6. **Delete the cron job.** A one-off left in place runs every minute for ever

### Composer

```
cd ~/thakurwadi/backend_laravel && /usr/local/bin/ea-php83 -d memory_limit=-1 /usr/local/bin/composer install --no-dev --optimize-autoloader >> ~/deploy.log 2>&1
```

If `/usr/local/bin/composer` does not exist on this host, fetch it first with a
one-off cron of its own, and then use `~/composer.phar` in place of
`/usr/local/bin/composer`:

```
cd ~ && curl -sS https://getcomposer.org/installer | /usr/local/bin/ea-php83 -- --install-dir=/home/radhakrishn --filename=composer.phar >> ~/deploy.log 2>&1
```

`memory_limit=-1` matters: Composer resolving a Laravel dependency tree inside a
shared host's default limit is the most common way this step fails, and it fails
with an out-of-memory message rather than anything about packages.

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

**cPanel → File Manager**, in `thakurwadi/backend_laravel`. Turn on *Settings →
Show Hidden Files (dotfiles)* first, or none of this will be visible.

Copy `.env.production.example` to `.env` (right-click → Copy), then open `.env`
with **Edit**.

`APP_KEY` is generated by the cron in §6, so leave it empty here.

Then fill in the values marked **FILL IN**: `DB_DATABASE`, `DB_USERNAME`,
`DB_PASSWORD` (from §2) and `MAIL_PASSWORD` (from the mailbox you create in
cPanel → Email Accounts).

Everything else in that file is already set for this domain — including the two
that are easy to get wrong:

```
SESSION_DOMAIN=.radhakrishnathakurwadi.com     # the leading dot is what makes the cookie work across the subdomain
CORS_ALLOWED_ORIGINS=https://radhakrishnathakurwadi.com,https://www.radhakrishnathakurwadi.com
```

Then set its permissions to **0600** — right-click → *Change Permissions*, and
untick everything except the two owner boxes. `.env` holds the database password
and the application key, and on shared hosting "readable by anyone on the
machine" is not a theoretical concern.

---

## 6. Migrate, seed and link

One one-off cron, using the pattern from §3. All of it in a single line so it
either all runs or stops at the first failure:

```
cd ~/thakurwadi/backend_laravel && /usr/local/bin/ea-php83 artisan key:generate --force && /usr/local/bin/ea-php83 artisan migrate --force && /usr/local/bin/ea-php83 artisan db:seed --class=RoleSeeder --force && /usr/local/bin/ea-php83 artisan storage:link && /usr/local/bin/ea-php83 artisan config:cache && /usr/local/bin/ea-php83 artisan route:cache >> ~/deploy.log 2>&1
```

**Only `RoleSeeder`.** `DevelopmentContentSeeder` invents donations, ledger
entries and example villagers; it refuses to run when `APP_ENV=production`, and
that refusal is deliberate. The temple's real content is entered through the
console.

### The first account

There is no way in from outside until one exists. Put this in
`~/thakurwadi/backend_laravel/first-account.php`, with the committee chair's
real name and address in it:

```php
<?php
// Run once through a cron job, then DELETE this file.
require __DIR__.'/vendor/autoload.php';
$app = require __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();

$role = App\Models\Role::where('slug', App\Models\Role::SUPER_ADMIN)->firstOrFail();

$user = App\Models\User::create([
    'first_name' => 'नाम',
    'last_name'  => 'उपनाम',
    'email'      => 'chair@radhakrishnathakurwadi.com',
    'role_id'    => $role->id,
    'status'     => 'active',
    // Random and never disclosed: nothing can authenticate with it. The member
    // sets their own password from the link below.
    'password'   => Illuminate\Support\Str::random(64),
]);

Illuminate\Support\Facades\Password::broker()->sendResetLink(['email' => $user->email]);

echo "created {$user->email}\n";
```

```
cd ~/thakurwadi/backend_laravel && /usr/local/bin/ea-php83 first-account.php >> ~/deploy.log 2>&1
```

Then **delete `first-account.php`**. It is inside the project directory, not the
document root, so it was never web-reachable — but a script that creates a Super
Admin should not be left lying about.

If the mail is not arriving yet (step 1 of §11 will tell you), the same file can
set a password directly with `$user->password = 'chosen password';` before the
save — change it from inside the console at the first sign-in.

---

## 7. The queue worker — a cron entry, not a daemon

**cPanel → Cron Jobs.** Every minute:

```
* * * * * cd ~/thakurwadi/backend_laravel && /usr/local/bin/ea-php83 artisan queue:work --stop-when-empty --max-time=50 >> ~/queue.log 2>&1
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
30 2 * * * /home/radhakrishn/bin/thakurwadi-backup.sh >> /home/radhakrishn/backups/cron.log 2>&1
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

```
cd ~/thakurwadi/backend_laravel && /usr/local/bin/ea-php83 artisan deploy:check >> ~/deploy.log 2>&1
```

(A one-off cron again, then read `deploy.log` in the File Manager. It is the
same command a host with a shell would type.)

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
