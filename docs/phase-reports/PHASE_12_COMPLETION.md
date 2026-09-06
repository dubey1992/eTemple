# Phase 12 — Testing, Deployment & Handover · COMPLETION

**Status:** COMPLETE
**Completed:** 2026-09-16
**Plan:** `docs/phase-plans/PHASE_12_PLAN.md`

## 1. What the specification asked for, and where it is

| Requirement | Where |
|---|---|
| Full backend suites | 749 tests, including four new cross-module journeys in `tests/Feature/EndToEnd/` |
| Flutter suites, localization and responsive regression | 595 tests, including a sweep of **every screen at every width in both languages** |
| Workflow tests: receipt, accounting, media upload | `MoneyJourneyTest`, `ContentJourneyTest` |
| Security smoke tests | `deploy:check`, proved by `DeployCheckTest` to reject a bad environment |
| Production deployment with backup + rollback plan | `docs/DEPLOYMENT_CPANEL.md` §12 |
| Admin user guide, training, backup/restore handover | `docs/ADMIN_GUIDE.md`, `docs/HANDOVER.md` |

## 2. The deployment target decided most of this phase

The committee bought **radhakrishnathakurwadi.com** and will deploy through
**cPanel**. Shared hosting is not a footnote; it rules out the standard answers.

* **The API is a subdomain**, `api.`, with its own document root at
  `backend_laravel/public`. Not a `/api` folder: the SPA rewrite that makes
  `/gallery` work would have to exclude it and every future static path, and one
  mistake there serves HTML where JSON was expected — an error that points
  nowhere near its cause.
* **Both are the same registrable domain**, so a request between them is
  *same-site* and `SESSION_DOMAIN=.radhakrishnathakurwadi.com` keeps the Sanctum
  cookie working at `SameSite=lax`. A different domain would have forced
  `SameSite=none`, a materially weaker cookie.
* **The queue worker is a cron entry**, `queue:work --stop-when-empty
  --max-time=50`, because shared hosting kills long-running processes. This
  closes the worst failure in the project: an announcement sent with no worker
  records itself as sent and delivers nothing.
* **PHP extensions come from a cPanel page**, not a package manager. `gd`, `zip`,
  `intl`, `mbstring` are hard dependencies, and `deploy:check` names each one
  with the consequence of its absence.

*The temple was written `Thakurbari` / ठाकुरबाड़ी through Phases 0–12; the
committee chose `Thakurwadi` / ठाकुरवाड़ी to match the domain, and the project
was renamed to follow. The name is CMS content everywhere, so this touched the
written word and nothing structural.*

## 3. What "end-to-end" was made to mean

`flutter drive` with chromedriver is the textbook answer and the wrong one here:
it needs a browser and a matched driver in CI, it is the slowest and flakiest
tier, and it would test *a* build rather than the deployed one.

What has actually caught defects in this project is two other things, so both
were built:

**Journeys that cross modules.** The Phase 9 defect — the console's net excluded
donations while the public page included them — was invisible to both modules'
own suites, because each was correct on its own terms. `MoneyJourneyTest` follows
one ₹2,500 donation from the register through verification, the printed receipt,
the public transparency figure, the console dashboard, the report and the audit
trail, and asserts they are all the *same* figure. Three more do the same for the
visitor, the content and the committee-member journeys.

**A check that runs on the host.** `php artisan deploy:check` answers the
questions no test on a developer's machine can: is debug off, is the cookie
secure, is `gd` loaded *for the web user*, are bills on a private disk, is a
queue worker actually running, did the demo accounts reach production. It ends by
naming the two things PHP cannot see from inside itself — that the private
uploads path is not served, and that a visitor's real IP reaches Laravel.

## 4. Three defects the phase found

### The console overflowed on every phone

The screen sweep is 44 screens × 3 widths × 2 languages, and it found **sixteen
screens overflowing at 360px** — some by 276 pixels. Every per-feature test
pumped its screen at 1024px wide, so the console had never been rendered at phone
size, and a village committee's members mostly have phones rather than desktops.

Sixteen screens, but only **five causes**:

| Cause | Screens | Fix |
|---|---|---|
| A hand-written title-and-buttons `Row` | 4 | a shared `PageHeading` that wraps the actions under the title on a phone |
| `DropdownButtonFormField` without `isExpanded` — it sizes itself to its longest menu entry | 5 | `isExpanded: true`, so it ellipsizes instead |
| The media picker's two buttons side by side | 4 | a `Wrap`, with the hint moved below |
| The report row's warning chip squeezing the title | 1 | the chip moves under the title on a phone |
| A twelve-bar chart label wrapping to two lines | 1 | one line, clipped |

### The user editor crashed instead of explaining itself

Creating an account read the last role off the roles list. With an empty list —
`.last` on nothing — it threw `Bad state: No element` and painted a red screen
with no message. It now says, in both languages, that a role must exist first.

### A whole class of privacy assertion could never fail

`json_encode` escapes non-ASCII, so a Devanagari name that leaked into a JSON
response arrives as a run of `\uXXXX` and never as the characters themselves.
Which means `assertStringNotContainsString('शर्मा', $body)` **passed whether the
name leaked or not** — and every person's name on this site is in Devanagari.

Ten such assertions were in the suite, guarding donors, payees, enquiry senders
and unpublished content. Most had an ASCII assertion beside them doing the real
work (a telephone number, a cheque number), but not all: the ledger
`description` is Devanagari-only, and nothing could have caught it leaking to the
public page.

`TestCase::assertResponseDoesNotLeak` decodes first and compares against the text
a reader would actually see. `PrivacyAssertionTest` then does the thing that
stops the fix becoming the same problem one layer up: it **proves the helper
fails** on a body that really does carry the name.

*Every one of the ten still passes.* Nothing was leaking. But now that is a fact
rather than an artefact of the encoding.

## 5. Two Phase 11 gaps closed

Committee member creation and update, and content deletions, were named in the
audit catalogue and not instrumented. Both are now recorded — and the committee
snapshot deliberately holds **whether** a detail may be shown rather than the
detail itself. A consent withdrawal that copied the telephone number into an
append-only table would have withdrawn nothing; the number would simply have
moved somewhere only the Super Admin can read, and stayed there. Asserted by
name in `AuditCoverageTest`.

## 6. Verification

| Gate | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 233 files changed |
| `flutter test` | ✅ **595 passed** (+8) |
| `flutter build web --release` | ✅ built, for the real domain |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **749 passed**, 2815 assertions (+38) |
| Migration up → rollback → up | ✅ on MariaDB |
| Every screen at 360/768/1440, Hindi and English | ✅ no overflow, no crash |
| The two ARB files agree | ✅ same keys, same placeholders, nothing untranslated |
| `deploy:check` rejects a development environment | ✅ 11 real failures on this machine, and CI asserts the non-zero exit |
| `deploy:check` passes a configured one | ✅ asserted per check |
| The app in a real browser, on a phone | ✅ sign-in, dashboard, donations, reports — in Hindi |

## 7. What this phase does not claim

* **The production deployment has not been performed.** I have no cPanel
  credentials and did not ask for them. The deliverable is a procedure precise
  enough to follow, and a command that says whether it was followed correctly.
* **Committee acceptance has not happened.** It cannot be written by me. The
  staging environment, the guide and the checklist it runs against are here.
* **A restore rehearsal with a real bill attached is still outstanding** — no
  ledger entry in the development data has one, so that pairing has never been
  exercised (Phase 11 §7). It is the reason the database and the media must be
  backed up together.
* **`deploy:check` reads the CLI's `php.ini`.** On cPanel the web server commonly
  reads a different one. The command prints which file it read and says so; the
  browser checks at the end of §11 are what covers the gap.

## 8. Known issues, still

Everything in `PHASE_STATUS.md` under *Outstanding across phases* stands, minus
the items this phase closed (the cross-stack test, the audit instrumentation,
`zip` missing from CI). The largest remaining ones are product decisions rather
than defects: no online payment collection, no donor roll without a consent
question asked at the time of the donation, no devotee mailing list, and no
80G/PAN on the receipt because the temple's registration status has never been
stated to this project. All are listed in `HANDOVER.md` §6 with the reasoning.

## 9. Next

There is no Phase 13. What remains is the committee's: fill in the four secrets,
follow `DEPLOYMENT_CPANEL.md`, run `deploy:check` until it is green, and then do
the two browser checks it names.
