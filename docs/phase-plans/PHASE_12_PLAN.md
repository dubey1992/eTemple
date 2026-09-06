# Phase 12 — Testing, Deployment & Handover

**Status:** complete — see `docs/phase-reports/PHASE_12_COMPLETION.md`
**Started:** 2026-09-16
**Depends on:** Phases 0–11, all COMPLETE

## A. What the specification asks for

> - Full backend unit/feature/API/authorization suites
> - Flutter unit/widget/integration suites, localization and responsive regression
> - Donation receipt, accounting and media upload workflow tests; security smoke tests
> - Staging acceptance by committee, production deployment with backup + rollback plan
> - Admin user guide, training, backup/restore handover checklist
> - `flutter analyze`, `flutter test`, `flutter build web --release`, `php artisan test` green

Most of the first three lines already exist — 711 backend tests and 587 Flutter
tests, written phase by phase. Restating them as a Phase 12 deliverable would be
a phase that ships nothing. What is genuinely missing is named in
`PHASE_STATUS.md`: **no cross-stack end-to-end test**, and nothing at all for
the last two lines.

## B. The deployment target, which reshapes the phase

The committee has bought **https://radhakrishnathakurwadi.com/** and will deploy
through **cPanel**. That is not a footnote; it decides most of this phase.

*(The temple was written `Thakurbari` / राधा कृष्ण ठाकुरबाड़ी up to this point;
the committee chose `Thakurwadi` / ठाकुरवाड़ी to match the domain, and the
project follows. Nothing structural moved — the name is CMS content everywhere,
asserted by `temple_name_takeover_test.dart` — so this was a rename of the word
alone.)*

### T1. Where the two halves live

| | cPanel object | Serves |
|---|---|---|
| Public site | `public_html` | the Flutter `build/web` output |
| API | subdomain `api.radhakrishnathakurwadi.com` | `backend_laravel/public` |

**Why not put the API in a `/api` subfolder of the same origin.** It is
tempting — same origin means no CORS at all — but the SPA fallback rewrite that
makes `/gallery` work has to exclude `/api`, and every future static path with
it. One mistake there serves `index.html` where JSON was expected, and the
client reports a parse error that points nowhere near the cause. A subdomain is
one cPanel screen, and the boundary is unambiguous.

### T2. The session still works across the two, and that is not luck

`radhakrishnathakurwadi.com` and `api.radhakrishnathakurwadi.com` share a
registrable domain, so a request between them is **same-site**. With
`SESSION_DOMAIN=.radhakrishnathakurwadi.com` the Sanctum cookie is sent with
`SameSite=lax` unchanged.

Had the API been put on a different domain, the only way to keep the session
would have been `SameSite=none`, which is a materially weaker cookie and one
browsers are steadily restricting. The subdomain choice is what avoids that.

### T3. The queue worker is a cron entry, not a daemon

Shared hosting has no supervisor and kills long-running processes. So:

```
* * * * * cd ~/thakurbari/backend_laravel && php artisan queue:work --stop-when-empty --max-time=50
```

This closes the worst failure recorded anywhere in this project: **an
announcement sent with no worker running records itself as sent and delivers
nothing** (Phase 8 §10). The committee believes the village was told, and it
was not.

### T4. No root, so the PHP extensions are a cPanel screen

`gd` (EXIF stripping by re-encode — without it every upload is refused),
`zip` (the .xlsx writer is hand-built on `ZipArchive`), `exif`, `intl`,
`mbstring`, `pdo_mysql`, `fileinfo`, `openssl`. `memory_limit ≥ 128M` for a
ten-thousand-row export. All of it from *Select PHP Version*, verified **as the
web user** rather than on the CLI, because cPanel commonly gives the two
different `php.ini` files.

## C. Design decisions

### 1. What "end-to-end" is going to mean here

The textbook answer is `flutter drive` with chromedriver against a running API.
It is the wrong answer for this project: it needs a browser binary and a
matched driver in CI, it is the slowest and flakiest tier by a wide margin, and
it would test *a* build on a developer's machine — never the deployed one.

What has actually caught defects here, repeatedly, is two other things:

* **journeys that cross module boundaries.** The Phase 9 defect — the console's
  net excluded donations while the public page included them — was invisible to
  both modules' own suites, because each was correct on its own terms. No
  per-module test can catch two modules that disagree.
* **looking at the running site.** Phase 11's audit defect was found by
  rendering a screen, not by a test.

So Phase 12 builds journey tests that cross modules in one test, a smoke command
that interrogates the *deployed* host, and ends with a browser pass by hand.

### 2. `php artisan deploy:check` — the questions only the host can answer

Is `APP_DEBUG` off? Is the session cookie secure? Is `storage/app/private`
reachable over the web? Is a queue worker actually running? Did the dev seed
data reach production? Is `gd` loaded *for the web user*?

Not one of those can be answered by a test on my machine, and every one of them
is a real way this deployment fails silently. The command runs on the host, over
the deployed URL, and prints a pass/fail line per check.

**It must be able to fail.** A check that passes everywhere proves nothing, so
its own tests assert that a development environment is *rejected* — debug on,
insecure cookie, wildcard CORS, dev seed rows present — and that a
correctly-configured one passes.

### 3. Rollback a committee member can perform at 9pm

`migrate:rollback` is right for a schema mistake and wrong for a data one. Both
are written down, with the distinction stated, and the release keeps the
previous `public_html` as a dated sibling so the site can be put back by
renaming two directories in the cPanel file manager — no shell, no build.

### 4. The admin guide is task-shaped and Hindi-first

Not a feature list. The committee's questions are "दान की रसीद कैसे निकालें",
"नई तस्वीरें कैसे डालें", "खाते कब सार्वजनिक होंगे". Each is a numbered
procedure with what to expect at the end, and the guide says plainly what the
system will **refuse** to do — no delete, no editing an approved figure, no
second receipt — because a member who thinks the software is broken will ask for
a workaround, and there is no workaround by design.

### 5. Two Phase 11 gaps close here, not in the handover notes

Committee member create/update and content deletions are named in the audit
catalogue and not instrumented. Handing over a list of things I said I would do
is not a handover, and both are call-site changes of a few lines.

### 6. What this phase will not claim

* **No committee acceptance sign-off**, because that is theirs to give and
  cannot be written by me. The phase delivers the staging environment, the
  guide and the checklist that acceptance runs against.
* **No production deployment performed.** I have no cPanel credentials and will
  not ask for them; the deliverable is a procedure precise enough to follow.
* **A restore rehearsal with a real bill attached** stays open until a ledger
  entry has one (Phase 11 §7).

## D. Implementation order

1. Close the two audit instrumentation gaps carried from Phase 11.
2. Backend journey tests — the money journey, the visitor journey, the content
   journey, the committee journey.
3. Flutter sweeps — every route at three widths without overflow; ARB parity
   between the two languages; the admin route table against the permission
   catalogue.
4. `deploy:check`, with tests that prove it rejects a bad environment.
5. `.env.production.example` and the two `.htaccess` artefacts, for the real
   domain.
6. `docs/DEPLOYMENT_CPANEL.md` — the step-by-step, cPanel screen by cPanel
   screen.
7. `docs/ADMIN_GUIDE.md` and `docs/HANDOVER.md`.
8. CI: add the `zip` extension it is missing, and run the journey tests.
9. Gates, a browser pass, the completion report, PHASE_STATUS.

## E. Quality gate

The standard commands, and beyond them:

- [ ] Journey tests cross at least three modules each and pass
- [ ] `deploy:check` **fails** a development environment and passes a
      correctly-configured one — asserted by test
- [ ] Every public and admin route renders at 360, 768 and 1440 with no overflow
- [ ] The two ARB files have identical key sets and identical placeholders
- [ ] Every admin route's permission exists in the catalogue
- [ ] `zip` and `gd` are exercised in CI, not assumed
- [ ] The deployment guide's build commands have been run for the real domain
      and the artefact inspected
- [ ] The app opened in a real browser, Hindi and English
