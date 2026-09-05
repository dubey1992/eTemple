# Phase 11 — Security, Audit, Backup & Privacy

**Status:** in progress
**Started:** 2026-09-15
**Depends on:** Phases 0–10, all COMPLETE

## A. What the specification asks for

> - `audit_logs` (`user_id`, `action`, `entity_type`, `entity_id`, `before_data`,
>   `after_data`, `ip_address`)
> - Append-only audit behaviour; permission enforcement on every admin endpoint
> - Database + media backup schedule and rehearsed restore procedure
> - Secure headers, HTTPS-only, CSRF, session timeout, login rate limits
> - No sensitive tokens in insecure browser storage

and, from the global rules:

> Audit sensitive create/update/delete/reversal/export actions as required by
> Phase 11.

Three of these five are partly done already, and this phase must not pretend
otherwise:

| Already in place | Since | What is still missing |
|---|---|---|
| CSRF, stateful cookie session, HttpOnly | Phase 0 | HTTPS-only production settings, secure-cookie verification |
| Login rate limits, login history | Phase 2 | nothing — but it must be re-verified, not assumed |
| Permission middleware on admin routes | Phases 2–10 | proof that **every** route has one, as a test rather than a habit |

## B. Design decisions

### 1. What is audited — a named list, not "every write"

Auditing every `save()` produces a table nobody reads and a disk nobody has.
This is a village temple on shared hosting; the log has to stay small enough to
be searched by a treasurer answering a question at an annual meeting.

So the audit log records **the actions somebody may later be asked about**:

| Module | Recorded |
|---|---|
| Donations | recorded, verified, reversed, receipt printed |
| Accounts | entry recorded, approved, reversed; opening balance changed; books published or unpublished |
| Reports | **every export of personal data**, and who took it |
| Users & roles | account created, role changed, status changed, password reset sent; role permissions changed |
| Committee | a member's personal detail published or unpublished; consent recorded or withdrawn |
| Enquiries | read, assigned, resolved, marked spam — the register of who saw a villager's message |
| Content | page, event, media, announcement deleted; announcement sent |
| Temple | profile, site settings and donation details changed |

**Assumption S1.** Reads are not audited, with one exception: opening an
enquiry, because that is the only place where reading *is* the sensitive act —
somebody's telephone number and complaint. Auditing every read of every list
would bury the log.

**Assumption S2.** An export of personal data is audited even though it is a
`GET`. Phase 10 left "who took a copy of the donor register, and when" with no
answer, and that is precisely what an audit log exists for.

### 2. Append-only, and enforced rather than promised

* No controller, service or route can update or delete an audit row.
* The model refuses: `updating` and `deleting` events throw.
* `AuditLog` has no `update`, no `delete` and no mass-assignable route to one.
* The API exposes read and filter only. There is no DELETE, at any permission.

**Assumption S3.** Append-only is enforced in the application, not by a database
trigger or a revoked `DELETE` grant. A trigger would be the stronger guarantee,
but the deployment target is shared hosting where the application's database
user routinely has full rights and migrations must run — a guarantee that only
holds when somebody remembers to configure it is worse than one the code
enforces on every path. The deployment checklist records the stronger option for
a host that can offer it.

**Assumption S4.** Pruning is the one exception, and it is a separate,
deliberate act: `php artisan audit:prune --older-than=` deletes rows past a
retention the committee chooses. It is not scheduled by default, it refuses to
run without an explicit age, and it writes an audit row saying what it removed.
A log that grows forever fills a shared host's disk and takes the site down with
it; that is not more secure than a log with a stated retention.

### 3. What a row may contain — and what it must never

`before_data` and `after_data` hold **only the fields that changed**, and pass
through a redaction list first:

* `password`, `remember_token`, `*_token`, `token` — never stored, in any form.
* `submitted_ip_hash` and anything already hashed — pointless to duplicate.

Personal details of donors, enquirers and committee members **are** stored when
they are what changed: "the amount on Rampasad's donation was edited" is the
question the log exists to answer, and a redacted log answers nothing.

**Assumption S5.** That makes the audit log itself a store of personal data.
Two consequences, both designed for here: reading it needs its own permission
(`audit.view`), held by **Super Admin only** by default; and there is **no
export** of the audit log in this phase — an audit trail that can be downloaded
as a spreadsheet is a personal-data leak with an official-sounding name.

**Assumption S6.** The actor's IP address is stored raw, unlike an enquirer's,
which is hashed. The difference is consent and purpose: a committee member is a
known, named account-holder acting in an administrative capacity, and "which
machine approved this payment" is a question the temple may legitimately need to
answer. An anonymous villager filling in a contact form is not.

### 4. Permission enforcement, as a test rather than a habit

A test walks Laravel's route table and asserts that **every** route under
`api/admin` carries an authorization middleware, with an explicitly named and
justified exemption list. Adding an admin route without a permission then fails
the build rather than shipping.

**Assumption S7.** This is a route-table sweep, not a request-by-request audit.
It proves a control is attached, not that the right one is — the per-module
authorization tests from Phases 2–10 already prove that, and they stay.

### 5. Secure headers

One middleware on every response:

* `X-Content-Type-Options: nosniff`
* `X-Frame-Options: DENY` and `Content-Security-Policy: frame-ancestors 'none'`
* `Referrer-Policy: strict-origin-when-cross-origin`
* `Permissions-Policy` denying camera, microphone and geolocation
* `Strict-Transport-Security` **only when the request arrived over HTTPS**, so a
  local development site never poisons a browser into refusing plain HTTP.

**Assumption S8.** The print-ready documents (receipt, bill, report export) get
a stricter `Content-Security-Policy` of their own: they are HTML the server
composes from stored content, and they are the only HTML this API emits.

### 6. Nothing sensitive in browser storage

The session is an HttpOnly cookie and always has been — no token ever reaches
JavaScript. This phase proves it stays that way with a source sweep, the same
technique that pinned the `LinkOpener` fix: a test that fails if any Dart file
writes a token, password or session value into `localStorage` or
`sessionStorage`.

**Assumption S9.** The two existing uses of browser storage — the chosen
language and the dismissed-announcement list — are per-visitor conveniences with
no security value and stay. The sweep names them, so the test says what is
allowed rather than merely what is not.

### 7. Backup and restore

A documented, **rehearsed** procedure (`docs/BACKUP_AND_RESTORE.md`) covering the
database and the uploaded media, with the restore actually performed against a
scratch database as part of this phase's verification — a backup procedure
nobody has restored from is a hope, not a procedure.

**Assumption S10.** No backup scheduler ships in the application. On shared
hosting the reliable mechanism is cron plus `mysqldump`, which the host provides
and the committee's provider configures; an in-application scheduler would need
a worker this deployment does not run, and would write backups to the same disk
that is being backed up.

## C. Implementation order

1. `audit_logs` migration, model, append-only guard
2. `AuditLogger` service and the action catalogue
3. Recording at the named call sites, module by module
4. `audit.view` permission, list/detail endpoints, filters
5. Route-table permission sweep test
6. Security headers middleware
7. Browser-storage source sweep test
8. Flutter: audit log screen, filters, detail
9. Backup and restore documentation, and a rehearsed restore
10. Docs: OpenAPI, PHASE_STATUS, deployment checklist, completion report

## D. Quality gate

The usual: `flutter analyze`, `dart format --set-exit-if-changed`,
`flutter test`, `flutter build web --release`, `pint --test`, `php artisan test`,
migration up → rollback → up → `migrate:fresh --seed` on MariaDB, live checks
through the running API, and the app read in a real browser.

Additionally, and specific to this phase:

* an audit row cannot be updated or deleted through any code path
* no audit row contains a password, hash or token
* a role without `audit.view` is refused the log entirely
* every `api/admin` route carries an authorization middleware
* the security headers are present on a real response, and HSTS only over HTTPS
* a restore from backup produces a working site
