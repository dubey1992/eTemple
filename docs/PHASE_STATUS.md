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
| 9 | Accounts & Transparency | **COMPLETE** | The ledger, and the figures the village reads. Only approved money counts in any total; donations are read from their own register and the `donation` category code is refused, so nothing is published twice; bills live on a private disk with no URL to them; no delete anywhere. The public page carries totals by heading and **no person's name** — the consent question `donations.is_anonymous` could not answer. Also fixed a defect found by screenshotting: the console's net excluded donations while the public page included them, unlabelled — `phase-reports/PHASE_9_COMPLETION.md`. |
| 10 | Reports & Analytics | **COMPLETE** | Six standard reports over donations, the ledger, events and enquiries, in three formats. The export runs the *same* report with the *same* filters as the screen — a property of the code, not a promise. Personal columns are absent unless both permitted and asked for, and asking without the permission is refused rather than quietly narrowed. Reading and downloading are separate permissions. The dashboard gained the at-a-glance figures Phase 8 promised it — `phase-reports/PHASE_10_COMPLETION.md`. |
| 11 | Security, Audit, Backup & Privacy | **COMPLETE** | An append-only audit trail over the actions somebody may later be asked about — the money lifecycle, role and account changes, settings, announcements sent, **every export of personal data and who took it**, and the one read worth recording. Only what changed is kept, and never a password or a token. Reading it is Super Admin only. Two habits became properties of the code: every admin route carries a permission, and nothing is written to browser storage. Security headers with HSTS only over HTTPS. A backup procedure that has actually been restored from — `phase-reports/PHASE_11_COMPLETION.md`. |
| 12 | Testing, Deployment & Handover | **COMPLETE** | Four cross-module journey tests — the gap no per-module suite can close; a sweep of every screen at every width in both languages, which found sixteen overflowing consoles from five causes; `deploy:check`, which answers the questions only the host can and is proved able to fail; and the cPanel procedure, the committee's guide and the handover for radhakrishnathakurwadi.com. Also found a class of privacy assertion that could never fail, and closed Phase 11's two audit gaps — `phase-reports/PHASE_12_COMPLETION.md`.

## Verification log — Phase 12 (2026-09-16)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 233 files changed |
| `flutter test` | ✅ **595/595** passed |
| `flutter build web --release` | ✅ built, for the real domain |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **749** passed (2815 assertions) |
| Migration up → rollback → up | ✅ on MariaDB |
| One rupee means the same thing everywhere | ✅ register, receipt, public page, dashboard, report, export and trail, in one test |
| A reversal leaves every total at once | ✅ and the row, its receipt number and the reason all survive |
| The whole public site answers on an empty database | ✅ ten endpoints, before the committee has written anything |
| An account: created, used, and taken away | ✅ invitation, reset, sign-in, permission boundaries, deactivation — and a live session ends too |
| A photograph: stripped, stored, published, guarded | ✅ EXIF absent from all three variants; deletion refused while a poster points at it, and the refusal names the festival |
| **Every screen at 360, 768 and 1440** | ✅ 44 screens, Hindi at all three widths and English at 360 |
| Sixteen overflowing screens found and fixed | ✅ from five shared causes; the console had never been rendered at phone width |
| The user editor no longer crashes on an empty role list | ✅ it says a role must exist first, in both languages |
| The two ARB files agree | ✅ same keys, same placeholders, nothing left in English |
| **A privacy assertion that could not fail** | ✅ found, fixed, and the fix proved able to fail |
| `deploy:check` rejects a development environment | ✅ 11 real failures here; CI asserts the non-zero exit |
| `deploy:check` catches each danger on its own | ✅ debug, wildcard CORS, public bills, no Super Admin, demo accounts, a queue with no worker, a channel with no provider |
| Committee create/update and content deletions audited | ✅ Phase 11 §10 closed |
| A consent withdrawal does not copy the number into the trail | ✅ asserted by name |
| `zip` exercised in CI | ✅ it was missing, and the .xlsx export depends on it |
| The app on a phone, in Hindi | ✅ sign-in, dashboard, donations register, reports |
| Phase 0–11 tests | ✅ pass unchanged |

**Three defects this phase found.** The console overflowed on every phone —
sixteen screens, five causes, because every per-feature test pumped at 1024px.
Creating a user with no roles on file threw `Bad state: No element` and painted a
red screen. And ten privacy assertions **could never have failed**: `json_encode`
escapes Devanagari, so a leaked name never appeared in the body as itself. All
ten still pass — but now that is a fact rather than an artefact of the encoding.

## Verification log — Phase 11 (2026-09-16)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 229 files changed |
| `flutter test` | ✅ **587/587** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **711** passed (2567 assertions) |
| Migration up → rollback → up | ✅ on MariaDB |
| An audit entry cannot be changed once written | ✅ the model throws, on every path |
| An audit entry cannot be deleted | ✅ except through `audit:prune`, which records that it ran |
| No endpoint writes to the trail | ✅ POST, PUT, PATCH and DELETE all refused |
| The trail cannot be exported | ✅ no route, at any permission |
| No entry carries a password, hash or token | ✅ stripped by key at any depth |
| An edit records only the fields that changed | ✅ and a save that changed nothing writes no row |
| An entry still names its actor after the account is deleted | ✅ the name is copied onto the row |
| **Who took a copy of the donor register** | ✅ recorded, with whether it carried personal data — the gap Phase 10 left |
| Opening an enquiry is recorded | ✅ the one read that is |
| Only Super Admin may read the trail | ✅ Admin, Treasurer, Content Manager and Viewer all 403 |
| Every `api/admin` route carries a permission | ✅ route-table sweep, with a named exemption list |
| Every `api/admin` route requires auth and an active account | ✅ same sweep |
| Security headers on every response | ✅ nosniff, DENY, Referrer-Policy, Permissions-Policy, CSP |
| HSTS only over HTTPS | ✅ absent over plain HTTP, present over TLS |
| The printable documents forbid scripts | ✅ stricter CSP on the only HTML this API emits |
| Nothing is written to browser storage | ✅ source sweep: **nothing at all** is stored |
| The session is an HttpOnly cookie | ✅ and the client reads only `XSRF-TOKEN` |
| **A backup restores** | ✅ rehearsed — dump, scratch restore, row counts, migrations, Devanagari and the published total all verified (`BACKUP_AND_RESTORE.md`) |
| The trail read in a real browser | ✅ an edit shows the two fields that moved, nothing else |
| Phase 0–10 tests | ✅ pass unchanged |

**A defect the screen found.** Verifying a donation recorded the whole record as
if every field had changed — eleven fields against an empty column. Lifecycle
events now record only what moved, and a creation is rendered without a "before"
column rather than a row of em dashes.

## Verification log — matching the approved design (2026-09-15)

Not a phase: a content audit of the public site against the committee's approved
prototype found 23 differences, and this is the work that closed them
(`PROTOTYPE_CONTENT_MATCH.md`).

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 221 files changed |
| `flutter test` | ✅ **572/572** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **675** passed (2455 assertions) |
| Migration up → rollback → up → `migrate:fresh --seed` | ✅ on MariaDB |
| The address is bilingual, and resolves per language | ✅ `अमरपुर पंखोरिया` on the Hindi page, `Amarpur Pankhoriya` on the English one |
| A half-translated address still reads as an address | ✅ each part falls back on its own |
| The retired single-language field is **refused**, not ignored | ✅ 422, rather than a 200 that saved nothing |
| The About cards are CMS content, not markup | ✅ a paragraph shaped `<emoji> <heading> — <text>`; prose with an em dash stays prose |
| The four home-page figures come from the accounts service | ✅ the same service as `/transparency` and the statement |
| Unpublished books show **nothing**, not zeros | ✅ zeros would be a false statement about somebody's finances |
| An accounts outage leaves the rest of the front page standing | ✅ the band disappears; no error box |
| No demo bank or UPI detail is seeded | ✅ asserted by name, in a test that will fail if somebody adds one |
| Live, through the running API | ✅ **39 checks** |
| In a real browser, Hindi and English | ✅ hero, notice, About cards, figures, address, map, footer |
| On a **cold browser profile** | ✅ the approved design's emoji render (see the note below) |
| Phase 0–10 tests | ✅ pass unchanged |

**A note on the emoji.** The approved design uses emoji as content — the three
About cards carry 🛕, 🤝 and 🪔. No font is bundled (`AppTypography`), and
CanvasKit fetches a Noto fallback for glyphs it cannot draw, so on a first visit
there is a short window where they show as tofu boxes before the fallback
arrives. Naming the platform emoji fonts in `fontFamilyFallback` was tried and
**does nothing** — CanvasKit does not read the system font list — so it was
reverted rather than left in place looking like a fix.

## Verification log — Phase 10 (2026-09-14)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 217 files changed |
| `flutter test` | ✅ **549/549** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **664** passed (2395 assertions) |
| The export applies exactly the on-screen filters | ✅ same query string, same parser, same runner — asserted by counting a downloaded CSV's rows against the JSON's, and again after adding a filter |
| A file is the whole filter, not the page | ✅ paging is the one thing an export does not inherit |
| Personal columns are absent unless asked for | ✅ absent from the response, not blank or masked — on the screen and in the file |
| Asking without the permission is refused | ✅ 403 `REPORT_DISCLOSURE_REFUSED`, not a quietly narrower payload |
| A file containing personal data says so on itself | ✅ in its header block, in all three formats |
| An anonymous donor is never named | ✅ at any permission; the row says `(गुप्त)` |
| The enquiry address hash reaches no report | ✅ asserted by name |
| Reading and downloading are separate permissions | ✅ a Viewer reads on screen and is refused the export |
| A Content Manager is refused the whole module | ✅ catalogue, reports, exports and overview all 403 |
| A report not in the catalogue is refused when asked for | ✅ 403, not 404 — obscurity is not a permission |
| CSV opens correctly in Excel on Windows | ✅ UTF-8 **with a BOM**, CRLF |
| No CSV cell can execute | ✅ `=`, `+`, `-`, `@`, tab and CR are neutralised |
| Money in a file is a plain decimal | ✅ so a column can be summed; the screen still formats it |
| **The workbook is real, and opens** | ✅ written by hand with `ZipArchive`, then **read back with `openpyxl`** — sheet, headings, Devanagari, numbers as numbers, bold row |
| The PDF is print-ready HTML | ✅ no PHP library shapes Devanagari; heading row repeats across pages |
| Reports are read-only | ✅ POST, PUT and DELETE are all 405 |
| The dashboard, the statement and the public page agree | ✅ one service computes all three |
| A dashboard panel this account may not see is absent, not zero | ✅ on the server and in the widget |
| The trend keeps its empty months | ✅ twelve, always |
| Live, through the running API | ✅ **79 checks** — waiting out the rate limit rather than configuring it away |
| Phase 0–9 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ still asserted, now including the two report routes |

## Verification log — Phase 9 (2026-09-13)

| Check | Result |
|---|---|
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 208 files changed |
| `flutter test` | ✅ **526/526** passed |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **609** passed (2161 assertions) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Only approved money counts | ✅ in the public totals **and** in the console's; pending and reversed appear in neither |
| Donations are counted once | ✅ read from the donation register, reported as their own line; the `donation` category code is refused on a transaction |
| An approved figure cannot be edited | ✅ 409 `TRANSACTION_LOCKED` over HTTP; only the description changes; the bill cannot be replaced either |
| No hard delete | ✅ `DELETE` on a transaction is 405; reversal keeps the row, its bill and a required reason |
| A used heading cannot be deleted or moved | ✅ 409 naming the count; the type is ignored rather than obeyed; `restrictOnDelete` says the same one layer down |
| Money exactness | ✅ integer paise throughout; ten ten-paise entries sum to exactly one rupee |
| The books are private until published | ✅ default false; an unpublished ledger returns **no summary block**, not zeros |
| The opening balance is stated, and carries across years | ✅ computed from everything before the year, never stored |
| No name reaches the public page | ✅ no donor, payee, reference, receipt number, description or author — asserted in tests and live |
| The bill is private | ✅ private disk, path never serialized, `nosniff` download, 401 without a session, not served under `/storage` |
| An upload is judged by its bytes | ✅ a PHP script named `bill.jpg` refused after a real multipart upload |
| A Content Manager cannot see financial detail | ✅ 403 on **reading**, not only on writing |
| A Viewer may read a bill | ✅ `accounts.view`, because that is what auditing is |
| Live, through the running API | ✅ **72 checks** — including waiting out the rate limit rather than configuring it away |
| Phase 0–8 tests | ✅ pass unchanged |
| Every admin route has a breadcrumb trail | ✅ still asserted, now including the five accounting routes |

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
- **No donor roll.** Phase 9 publishes no name at all, and `is_anonymous` is not
  the field that would allow one: it defaults to false, and a default is not
  consent. A board needs a publication-consent question asked when the donation
  is recorded, plus an effective-from date (Phase 9 §5).
- No per-occurrence overrides: one day of a recurring event cannot be cancelled
  on its own (Phase 4 §10.1).
- No calendar export (.ics); reminders are Phase 8.
- Committee ordering and the navigation menu both need reorderable editors.
- No retention or purge of enquiry personal data.
- An enquiry cannot be answered from inside the console; replies go by
  telephone or e-mail (Phase 7 §10).
- Handing an enquiry to another member needs `users.view`, which
  `enquiries.manage` does not imply; an "assignable members" endpoint would fix
  it (Phase 7 §10).
- No devotee mailing list: announcement e-mail reaches committee accounts only
  (Phase 8 §5). Opt-in, confirmation and unsubscribe are unbuilt.
- SMS and WhatsApp are refused cleanly, not implemented (Phase 8 §6).
- An announcement sent with no queue worker running still records itself as sent
  and delivers nothing — it cannot be detected from inside the request
  (Phase 8 §10). Phase 12 added the next best thing: `deploy:check` fails when
  jobs have been waiting more than ten minutes, and the cPanel cron entry is
  what stops it happening.
- The home banner's dismissal lasts the session only.
- No scheduled or e-mailed reports, and no report builder (Phase 10 §10).
- The export cap of 10,000 rows is not configurable.
- The events report is expanded in PHP rather than the database, because
  occurrences come from rules; a wide range over many years will be slow.
- No bank statement import or reconciliation; matching is done by eye.
- A transfer between the cash box and the bank cannot be recorded — deliberately,
  since as an income and an expense it would inflate both published figures
  (Phase 9 §12).
- Attachment storage is unbounded: nothing prunes bills or warns when the disk
  fills.
- The pre-render tool is compile-checked in CI but not run there: it needs a
  live API, so running it for real is a deploy step.
- A ledger entry's bill has still not been through a restore rehearsal, because
  no development entry has one attached (Phase 11 §7).
- `deploy:check` reads the CLI's `php.ini`; on cPanel the web server often reads
  a different one. The command says so, and the two browser checks at the end of
  `DEPLOYMENT_CPANEL.md` §11 are what cover the gap.
- **Deployed to the hosting account on 2026-09-06** and verified there
  (`DEPLOYMENT_CPANEL.md`, *What is already deployed*). Two things remain, and
  both are the committee's: pointing the domain's DNS at the host, and
  acceptance.
- Mail leaves through the host's `sendmail` rather than an authenticated
  mailbox. It works, but until DNS moves here the domain's SPF record is the old
  provider's, so a message may be filed as spam. Revisit after going live.

**All twelve phases are COMPLETE.** What remains is the committee's:
`docs/DEPLOYMENT_CPANEL.md` to put it on radhakrishnathakurwadi.com,
`docs/ADMIN_GUIDE.md` for the people who will use it, and `docs/HANDOVER.md` for
whoever holds the hosting account.

The approved-design match (2026-09-15) is recorded in
`PROTOTYPE_CONTENT_MATCH.md`. One item is deliberately not visible yet: the
donation block's wording is seeded, and stays hidden until the committee enters
a real UPI ID or bank account, because the prototype's `temple@upi` and
`Demo Bank` must never be seeded.
