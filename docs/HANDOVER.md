# Handover

**Radha Krishna Thakurwadi** · https://radhakrishnathakurwadi.com/
**Written:** 2026-09-16 · Phase 12

What the committee now owns, what it has to keep doing, and what it must never
do. Read this once with whoever holds the hosting account.

---

## 1. What exists

| Thing | Where | Who holds it |
|---|---|---|
| The domain | registrar | the committee |
| The hosting | cPanel | the committee |
| The code | this repository | the committee |
| The database | cPanel MySQL | the committee |
| The uploads | `storage/app/public` (photographs) and `storage/app/private` (bills) | the committee |
| The nightly backup | `~/backups/<date>/` on the host, copied off it weekly | the committee |

**Nothing in this system depends on a third-party service the committee does not
control.** No payment gateway, no analytics, no CAPTCHA provider, no SMS vendor,
no font CDN. That was a deliberate constraint, and it is what makes this
handover a handover rather than an introduction to five other companies.

---

## 2. The four credentials, and what each one opens

Keep these somewhere two people can reach, and **not** in the same place as the
backups:

1. **The registrar login** — the domain. Losing it loses the address.
2. **The cPanel login** — the host. Everything else can be rebuilt from it.
3. **The database password** — in `~/thakurwadi/backend_laravel/.env`, and
   nowhere else. It is **not** in the backup, on purpose: a backup that carries
   the password to the database it contains is one file away from a breach.
4. **The Super Admin account** — the site itself.

`.env` also holds `APP_KEY`. If it is lost, every existing session is void and
anything encrypted with it cannot be read. **Keep one copy of `.env` somewhere a
person controls.**

---

## 3. The routine, and who does it

| How often | What | Where it is written |
|---|---|---|
| Nightly, automatic | Backup of the database and uploads | `deploy/cpanel/backup.sh`, cron |
| Every minute, automatic | The queue worker | `DEPLOYMENT_CPANEL.md` §7 |
| Monthly | Verify a backup archive without restoring it | `BACKUP_AND_RESTORE.md` §2 |
| Monthly | Check the public accounts read correctly | `ADMIN_GUIDE.md` |
| **Yearly** | **Actually restore from a backup** | `BACKUP_AND_RESTORE.md` §3 |
| Yearly | Set the opening balance for the new financial year | `ADMIN_GUIDE.md` §3 |
| After every release | `php artisan deploy:check` | `DEPLOYMENT_CPANEL.md` §11 |

The yearly restore is the one nobody wants to do and the only one that proves
the rest. A backup that has never been restored from is a hope.

---

## 4. Things that will go wrong, and what they look like

| Symptom | Almost certainly |
|---|---|
| An announcement says "sent" and nobody got it | The queue cron is not running. `php artisan deploy:check` says so |
| Every photograph is a broken image | `php artisan storage:link` was not re-run after a release |
| Uploading a photograph is refused every time | The `gd` extension was turned off — usually by changing the PHP version |
| Nobody can sign in, and the browser console says CORS | `CORS_ALLOWED_ORIGINS` or `SANCTUM_STATEFUL_DOMAINS` no longer names the site's exact origin |
| The Excel export fails and CSV works | The `zip` extension is missing |
| The contact form throttles everybody after a few messages | The real client IP is not reaching Laravel — see `DEPLOYMENT_CPANEL.md` §11.2 |
| A stack trace appears on a public page | `APP_DEBUG=true`. Fix it immediately: it prints paths and configuration |
| Nothing can be saved or deleted, and the console reports a CORS error | The host blocks PUT/PATCH/DELETE. The client tunnels them through POST; check `X-HTTP-Method-Override` is still in `config/cors.php` — see `DEPLOYMENT_CPANEL.md` |

---

## 5. Never do these

* **`php artisan migrate:fresh`, `db:wipe` or `migrate:refresh` on the live
  host.** Each destroys every donation, ledger entry and message. None is
  recoverable from anything but the backup.
* **Point the domain's document root at the project root.** That publishes
  `.env`.
* **Set `ACCOUNTS_ATTACHMENT_DISK=public`.** Bills carry a trader's name and
  telephone number; on the public disk they become permanent public URLs.
* **Turn on `ANNOUNCEMENT_SMS_ENABLED` or `..._WHATSAPP_ENABLED`** without a
  provider actually wired up. A send then appears to succeed and delivers
  nothing.
* **Run `DevelopmentContentSeeder` in production.** It invents donations and
  villagers. It refuses to run when `APP_ENV=production`, and that refusal
  should never be worked around.
* **Share a login.** Every action records who took it, and a shared account makes
  the whole audit trail a lie.

---

## 6. What was deliberately not built

None of these is an oversight. Each was decided, and the reasoning is in the
phase reports:

* **No online payment.** Donations are *recorded* after the fact, not collected.
  Taking money online needs a gateway, a merchant account and a liability the
  committee has not asked for.
* **No donor roll.** The public page carries totals and no name at all.
  Publishing a donor's name needs their consent asked at the time of the
  donation, and the current field (`is_anonymous`) defaults to false — a default
  is not consent (Phase 9 §5).
* **No devotee mailing list.** Announcement e-mail reaches committee accounts
  only. A public list needs opt-in, confirmation and unsubscribe.
* **No 80G or PAN on the receipt.** The temple's registration status was never
  stated to this project. If the temple is registered, this is the first thing
  to add.
* **No two-factor authentication.** Marked optional in the specification and
  deferred (Phase 2 §7).
* **No SMS or WhatsApp.** Refused cleanly rather than half-built.
* **Videos are linked, not embedded.** An inline player puts a third-party frame
  on the temple's own origin.

---

## 7. If somebody else takes over the code

Everything they need is in the repository:

| Document | What it answers |
|---|---|
| `README.md` | what this is, and how to run it |
| `docs/DEVELOPMENT.md` | local setup |
| `docs/IMPLEMENTATION_PLAN.md` | the whole specification, phase by phase |
| `docs/PHASE_STATUS.md` | what is done, and what is knowingly outstanding |
| `docs/phase-plans/` | **why** each phase was designed the way it was |
| `docs/phase-reports/` | what each phase actually delivered, including its defects |
| `docs/api/openapi.yaml` | the API contract |
| `docs/DESIGN_SYSTEM.md` | the visual language |

The phase plans are the ones worth reading first. Most of the surprising
decisions in this codebase — money as integer paise, no delete anywhere, the
consent gate in three layers, an audit trail that keeps only what changed — are
explained there, and each one has a test that will fail if it is undone.

Two conventions matter more than the rest:

1. **The specification's technology choices are binding.** Flutter Web and
   Laravel, not something else.
2. **A phase is not complete while a test fails.** That rule is the only reason
   the phase reports can be trusted.
