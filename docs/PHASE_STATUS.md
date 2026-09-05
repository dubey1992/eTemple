# Phase Status

Updated only after a phase has been validated against its delivery gate.

Legend: `NOT STARTED` · `IN PROGRESS` · `PARTIAL` · `BLOCKED` · `COMPLETE`

| Phase | Module | Status | Notes |
|---|---|---|---|
| 0 | Foundation & Core Setup | **COMPLETE** | `phase-reports/PHASE_0_COMPLETION.md` |
| 1 | Public Website & Bilingual CMS | **COMPLETE** | `phase-reports/PHASE_1_COMPLETION.md` |
| 2 | Admin, Users & Roles | **COMPLETE** | Permission matrix, user management, login history, password reset, plus the site-settings editor carried from Phase 1. Two-factor auth (marked *optional* in the spec) deliberately deferred — `phase-reports/PHASE_2_COMPLETION.md` §7. |
| 3 | Temple Profile & Committee | **COMPLETE** | Profile, committee and the consent gate on members' personal details. The address **moved** out of `site_settings` (columns dropped) and the temple name and village were **taken over** from the ARB files — `phase-reports/PHASE_3_COMPLETION.md`. |
| 4 | Puja, Events & Calendar | **COMPLETE** | Recurring events stored as a rule and expanded on read; past/upcoming views; cancelled events kept visible and flagged. Also fixed two Phase 3 findings: admin breadcrumbs and equal-height cards — `phase-reports/PHASE_4_COMPLETION.md`. |
| 5 | Gallery & Video Darshan | **COMPLETE** | Uploads validated by their bytes, stripped of location/camera data by re-encoding, and stored as three responsive variants; albums; a deletion guard that names what still points at a file. `logo_url`, `photo_url` and `poster_url` are now filled from the library — `phase-reports/PHASE_5_COMPLETION.md`. |
| 6 | Donations & Receipts | **COMPLETE** | Money as integer paise; a receipt number issued on verification, unique by database index and immutable thereafter; no delete anywhere — reversal keeps the row, its number and a required reason. Donor detail reaches no public endpoint — `phase-reports/PHASE_6_COMPLETION.md`. |
| 7 | Devotee Contact & Enquiries | **COMPLETE** | The public contact form, protected by four layers none of which is a third-party CAPTCHA: an IP rate limit with a daily ceiling, a honeypot, a timed single-use ticket, and a server-issued question after a threshold. No public read of an enquiry at any status, and no delete — `spam` keeps the row. Also fixed two defects carried in from earlier phases — `phase-reports/PHASE_7_COMPLETION.md`. |
| 8 | Announcements & Notifications | **COMPLETE** | Publishing and sending are separate acts: saving sends nothing, publishing sends nothing, and a send needs an explicit channel choice and can happen once. The schedule is a `where` clause with no cron behind it. E-mail reaches committee accounts only. Also replaced the admin card grid with a side menu — `phase-reports/PHASE_8_COMPLETION.md`. |
| 9 | Accounts & Transparency | NOT STARTED | Keys `accounts.*` exist. |
| 10 | Reports & Analytics | NOT STARTED | Keys `reports.*` exist. |
| 11 | Security, Backup & Audit | NOT STARTED | |
| 12 | Testing, Deployment & Handover | NOT STARTED | |

## Verification log — Phase 8 (2026-09-12)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 196 files changed |
| `flutter test` | ✅ **494/494** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **544** passed (1914 assertions) |
| migrate → rollback → migrate (MariaDB) | ✅ reversible |
| Saving sends nothing; publishing sends nothing | ✅ asserted with a faked mailer, and live over HTTP |
| A send needs an explicit channel | ✅ no default; an empty list is 422 |
| A send happens once | ✅ the second attempt is 409 and queues nothing |
| A draft or archived notice cannot be sent | ✅ 409 `ANNOUNCEMENT_NOT_PUBLISHED` |
| A channel with no provider is refused with a reason | ✅ and one bad channel refuses the whole send |
| E-mail reaches committee accounts only | ✅ an enquiry address in the database is never written to; blocked accounts excluded |
| The schedule is enforced in the query | ✅ a notice dated for next week is absent from the public endpoint, with no scheduler involved |
| The public notice carries nothing private | ✅ no `sent_at`, `recipient_count`, `channels`, `status`, `created_by` or `is_showing` |
| `status`/`sent_at` cannot be set by naming them | ✅ ignored by the running server |
| No hard delete | ✅ `DELETE` is 405; archiving keeps the row and its send record |
| Bilingual fallback | ✅ Hindi served for a missing English value, `fallback_used` true |
| The menu and the dashboard cannot disagree | ✅ one catalogue, asserted by test |
| Live, through the running API | ✅ **54 checks** over two passes |
| Phase 0–7 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ still asserted, now including the three announcement routes |

## Verification log — Phase 7 (2026-09-11)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 182 files changed |
| `flutter test` | ✅ **464/464** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **504** passed |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| No public read of an enquiry | ✅ four plausible public paths 404/405 and leak no name or number |
| Reading the inbox is refused without `enquiries.manage` | ✅ Treasurer and Viewer both 403, called directly against the API |
| The address is stored hashed | ✅ 64-hex HMAC, and never serialized even to the committee |
| No hard delete | ✅ `DELETE` on an enquiry is 405; `spam` keeps the row and is one query parameter away |
| The ticket is single-use and timed | ✅ replay, forgery, staleness and instant submission all refused |
| The question escalates and cannot be side-stepped | ✅ a ticket taken before the threshold is bounced, not honoured |
| The counter window does not extend itself | ✅ a visitor who wrote twice an hour ago is not made to do arithmetic all day |
| Acknowledgement carries none of the sender's words | ✅ asserted against a rendered mail |
| Every backend error code has a client mirror | ✅ now enforced by a test across the two languages |
| Live, through the running API | ✅ **64 checks** over two passes — including waiting out the rate limit rather than configuring it away. The first pass reported five failures; all five were the checking script's own (`??` cannot tell a null value from a missing key, and it mis-modelled where the hour-long escalation counters already stood). Re-checked properly in the second pass |
| Phase 0–6 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ still asserted, now including the two enquiry routes |

## Verification log — Phase 6 (2026-09-10)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 169 files changed |
| `flutter test` | ✅ **441/441** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **450** passed (1592 assertions) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Receipt number unique | ✅ enforced by the database index, not the application; a duplicate the application asks for is refused |
| Receipt number immutable | ✅ changing an amount after receipting is 409; the number is unchanged |
| No hard delete | ✅ `DELETE` on a donation is 405; reversal keeps the row, the number and a required reason |
| Money exactness | ✅ integer paise throughout; ten ten-paise amounts sum to exactly one rupee |
| Donor privacy | ✅ four plausible public donation paths 404; the published block carries no donor, amount or receipt number |
| Live, through the running API | ✅ **44 checks** — record, correct, verify, print, reverse, and the refusals |
| Phase 0–5 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ still asserted, now including the four donation routes |

## Verification log — Phase 5 (2026-09-09)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 156 files changed |
| `flutter test` | ✅ **394/394** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **362** passed (1387 assertions) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible, including the two mutually referential tables |
| EXIF stripped, verified **through the running API** | ✅ a real EXIF block uploaded over HTTP, absent from all three stored variants |
| Upload refusals against real bytes | ✅ non-image, SVG, truncated, oversized, undersized |
| Deletion guard | ✅ refuses for the logo, a member photo, an event poster, an album cover and a page body; allows once the reference is removed, and the files leave disk |
| Phase 0–4 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ still asserted, now including the six media and album routes |

## Verification log — Phase 4 (2026-09-08)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 124 files changed |
| `flutter test` | ✅ **318/318** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **279** passed (1129 assertions) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Recurrence edge cases | ✅ month-end, years-old start, expired rules, bounded output, still-running events |
| Phase 0–3 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ asserted by `admin_breadcrumbs_test.dart` |

## Verification log — Phase 3 (2026-09-07)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 109 files changed |
| `flutter test` | ✅ **258/258** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **216** passed (939 assertions) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Address move with **real data**, both directions | ✅ carried into `temple_profiles`, columns dropped, restored intact on rollback |
| Phase 0–2 tests against the moved address | ✅ pass unchanged apart from the deliberate move edits |
| No village name left compiled into the app | ✅ asserted by `temple_name_takeover_test.dart` |

## Verification log — Phase 2 (2026-09-06)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 94 files changed |
| `flutter test` | ✅ **199/199** passed |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **164** passed (697 assertions) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Seeded matrix | ✅ super-admin 19 (computed), admin 17, treasurer 7, content-manager 7, viewer 4 |
| Phase 1 authorization tests against the new matrix | ✅ pass **unchanged** |

## Verification log — Phase 1 (2026-09-05)

`flutter analyze` clean · 167 Flutter tests · release web build · Pint clean ·
98 Laravel tests (360 assertions) · migrations reversible on MariaDB ·
live fallback and pre-render verified.

## Verification log — Phase 0 (2026-09-04)

`flutter analyze` clean · 107 Flutter tests · release web build · Pint clean ·
49 Laravel tests (170 assertions) · migrations reversible on SQLite and
MariaDB 12.3.3 · live health and 401 checks.

## Outstanding across phases

- Two-factor authentication for Super Admin (optional in the spec; Phase 2 §7).
- `web/index.html` and `manifest.json` still carry a build-time temple name;
  the pre-rendered per-route head is dynamic (Phase 3 §9.1).
- Videos are linked, not embedded: playing one inline would put a third-party
  iframe on the temple's own origin (Phase 5 §9.1).
- Media reordering is one item at a time and is disabled while a filter is on;
  drag-and-drop is wanted here, for the navigation menu and for the committee.
- `checksum` is stored and indexed for duplicate detection; nothing reads it yet.
- No online payment collection: donations are recorded after the fact, not taken
  (Phase 6 §9.1).
- No 80G/PAN fields on the receipt — the temple's registration status is not
  something this project has been told (Phase 6 §9.2).
- `donations.is_anonymous` is stored and respected by nothing yet; it exists for
  the Phase 9 transparency figures.
- No CSV/Excel export of the register — Phase 10.
- No per-occurrence overrides: one day of a recurring event cannot be cancelled
  on its own (Phase 4 §10.1).
- No calendar export (.ics); reminders are Phase 8.
- Committee ordering and the navigation menu both need reorderable editors.
- Consent changes are not audit-logged; the record exists for Phase 11.
- No retention or purge of enquiry personal data — Phase 11.
- An enquiry cannot be answered from inside the console; replies go by
  telephone or e-mail (Phase 7 §10).
- Handing an enquiry to another member needs `users.view`, which
  `enquiries.manage` does not imply; an "assignable members" endpoint would fix
  it (Phase 7 §10).
- No devotee mailing list: announcement e-mail reaches committee accounts only
  (Phase 8 §5). Opt-in, confirmation and unsubscribe are unbuilt.
- SMS and WhatsApp are refused cleanly, not implemented (Phase 8 §6).
- An announcement sent with no queue worker running records itself as sent and
  delivers nothing; it cannot be detected from inside the request (Phase 8 §10).
- The home banner's dismissal lasts the session only.
- Pre-render tool not wired into CI.
- No cross-stack end-to-end test (Phase 12).

Phase 9 must not begin without explicit approval.
