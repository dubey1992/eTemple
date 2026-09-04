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
| 6 | Donations & Receipts | NOT STARTED | Keys `donations.*` exist. The prototype's `दान` section. |
| 7 | Devotee Contact & Enquiries | NOT STARTED | Key `enquiries.manage` exists. |
| 8 | Announcements & Notifications | NOT STARTED | Key `announcements.manage` exists. |
| 9 | Accounts & Transparency | NOT STARTED | Keys `accounts.*` exist. |
| 10 | Reports & Analytics | NOT STARTED | Keys `reports.*` exist. |
| 11 | Security, Backup & Audit | NOT STARTED | |
| 12 | Testing, Deployment & Handover | NOT STARTED | |

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
- No per-occurrence overrides: one day of a recurring event cannot be cancelled
  on its own (Phase 4 §10.1).
- No calendar export (.ics); reminders are Phase 8.
- Committee ordering and the navigation menu both need reorderable editors.
- Consent changes are not audit-logged; the record exists for Phase 11.
- Pre-render tool not wired into CI.
- No cross-stack end-to-end test (Phase 12).

Phase 6 must not begin without explicit approval.
