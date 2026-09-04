# Phase 3 Completion Report — Temple Profile & Committee Management

**Date:** 2026-09-07
**Status: COMPLETE.** Every specified requirement is delivered, and both
obligations carried in from earlier phases are closed.

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 · Composer 2.10.3 ·
Laravel 12.69.1 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 3 requirement | Status | Where |
|---|---|---|---|
| 1 | `temple_profile` — bilingual name/address/history/mission, `logo_url`, `map_url` | ✅ | `temple_profiles` table, `TempleProfileService`, `AdminTempleProfileScreen` |
| 2 | `committee_members` — designation, tenure dates, public/private visibility | ✅ | `committee_members` table, `CommitteeService`, `AdminCommitteeScreen` |
| 3 | `GET /api/public/temple-profile`, `PUT /api/admin/temple-profile` | ✅ | `TempleController`, `TempleProfileController` |
| 4 | `GET /api/public/committee`, `POST /api/admin/committee-members` | ✅ | plus show/update/delete — see §3 |
| 5 | Consent-gated publication of member personal details | ✅ | Three enforced layers — §4 |

### Carried obligations, both closed

| # | Obligation | Result |
|---|---|---|
| 6 | **Move** the address out of `site_settings` — do not duplicate it | ✅ The nine address columns and `map_url` were carried across and then **dropped**. `MigrationTest` now asserts they are *gone*, so a re-introduction fails the build |
| 7 | **Take over** the temple name from the ARB files | ✅ The header, hero, footer, page titles, sign-in page and pre-rendered `<title>` all read the profile. `appSubtitle` — the hardcoded village line — is **deleted** |

---

## 2. Database changes

| Migration | Effect |
|---|---|
| `2026_09_07_000000_create_temple_profiles_table` | Singleton row: bilingual name/history/mission, the address, `logo_url`, `map_url`, `established_year`, `updated_by` |
| `2026_09_07_000001_create_committee_members_table` | Members plus the consent record; indexed on `(is_published, sort_order)` and `tenure_end` |
| `2026_09_07_000002_move_address_from_site_settings` | Carries ten values into the profile, then drops them from `site_settings` |

The move was verified with **real data on MariaDB 12.3.3**, not just by
re-running migrations on an empty schema:

```
rollback to the Phase 2 schema, insert an address into site_settings
  → migrate:  temple_profiles.village = "Amarpur Pankhoriya"   ✅
              site_settings.village column dropped              ✅
              site_settings.tagline_hi / contact_email intact   ✅
  → rollback: site_settings.village = "Amarpur Pankhoriya"      ✅
              site_settings.map_url restored                    ✅
              temple_profiles / committee_members dropped       ✅
```

Reversible in both directions with nothing lost. `carry()` never overwrites a
value already present on the destination, so re-running the move cannot clobber
an address the committee has since corrected.

---

## 3. API endpoints

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/temple-profile?lang=` | public |
| GET | `/api/public/committee?lang=` | public |
| GET | `/api/admin/temple-profile` | `content.view` |
| PUT | `/api/admin/temple-profile` | `temple.manage` |
| GET | `/api/admin/committee-members` | `content.view` |
| POST | `/api/admin/committee-members` | `temple.manage` |
| GET/PUT/DELETE | `/api/admin/committee-members/{id}` | `content.view` / `temple.manage` |

`PUT /api/admin/site-settings` no longer accepts address fields.

Documented in `docs/api/openapi.yaml` (now **v0.4.0** — 25 paths, 21 schemas).

Reading is gated on `content.view` and writing on `temple.manage`, deliberately
separated: a Viewer can be shown the committee without being able to change it.
`temple.manage` was defined in Phase 2's catalogue and labelled "Available in
phase 3" — this phase attached endpoints to a key the committee could already
grant, which is exactly what that design was for.

---

## 4. The consent gate — the part that matters most

Committee members are named villagers, not staff of a company. Publishing a
phone number without permission is a harm the software should make structurally
difficult, so consent is **stored data** — a timestamp plus the account that
recorded it — and the rule is enforced in three independent places:

1. **`CommitteeService` refuses** to set any `show_*_publicly` flag while
   `contact_consent_at` is null, returning 422 against the named flag.
2. **Withdrawing consent clears all three flags** in the same transaction, so a
   stale `true` cannot survive the withdrawal.
3. **`PublicCommitteeMemberResource` asks again** before emitting each field.

`CommitteeConsentTest` proves each layer **separately**. A single end-to-end
test would still pass with two of the three removed, and the survivor would then
be the only thing between a bug and somebody's phone number on the open
internet. Layer 3 is tested by forcing the database into the state the service
refuses to create — which is what a future bug or a direct SQL edit looks like —
and asserting the public endpoint still withholds the detail.

Two further decisions:

* **A withheld detail is omitted, not nulled.** An absent key cannot be rendered
  by accident, logged, or misread by a future client as "unknown, ask again".
* **The consent date is never refreshed.** The day somebody gave permission is a
  fact about the past, not a "last touched" column.

Publication is off by default in both senses: a new member is unpublished and
unconsented, so putting a person on the public site is always a deliberate act.

---

## 5. Flutter routes and screens

| Path | Screen |
|---|---|
| `/committee` | Public committee page (declared before the catch-all slug route) |
| `/admin/temple-profile` | `AdminTempleProfileScreen` |
| `/admin/committee` | `AdminCommitteeScreen` — publication and consent state at a glance |
| `/admin/committee/new`, `/admin/committee/:id` | `AdminCommitteeMemberScreen` |

The home page gains a committee preview. The site-settings screen lost its
address fields and now links to the profile instead — one source of truth, said
once in the UI as well as in the schema.

New: `features/temple/` (domain, data, presentation), following the same
feature-first shape as `features/admin/`.

The member editor mirrors the server's rule rather than restating it: the three
visibility switches are inoperable until consent is recorded, and turning
consent off turns all three off. That is a courtesy so the form does not
disagree with the API — the server refuses the combination regardless, which
`TempleAuthorizationTest` and `CommitteeConsentTest` prove by calling it
directly.

---

## 6. The temple's name is now CMS content

Before this phase the temple's name and village were compiled into the app.
They are managed content now:

* every rendered surface prefers `temple_profile.name`;
* `l10n.appTitle` survives only as the **application shell fallback**, shown
  while the profile is loading or after it fails — a blank header on every cold
  load would be a worse product than a graceful degrade;
* `appSubtitle` — the hardcoded "अमरपुर पंखोरिया, कुर्मा पंचायत" — is **deleted**.
  The locality line is drawn from the profile's address and simply does not
  appear until the committee fills it in. No village name remains anywhere in
  the application;
* the pre-render tool reads the name from the API too, so a crawler that never
  runs JavaScript also sees the configured name.

`temple_name_takeover_test.dart` proves the whole story: a different profile
produces a different site name with no code change; an unwritten or failed
profile falls back to the app name rather than blanking; and
`find.textContaining('अमरपुर')` finds nothing on an unconfigured site.

---

## 7. Tests and command results

```
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  109 files, 0 changed
$ flutter test                                       258/258 passed
$ flutter build web --release                        Built build\web
$ ./vendor/bin/pint --test                           passed
$ php artisan test                                   216 passed (939 assertions)
$ migrate → rollback → migrate → db:seed (MariaDB)   reversible, data intact
```

**Backend, 216 tests** (164 from Phases 0–2 + 52 new): `TempleProfileTest`
(singleton behaviour, language resolution and fallback, the address served from
the profile and *not* from site settings, validation by field);
`CommitteeManagementTest` (public filtering by publication and tenure, a tenure
ending today still counts as serving, past members kept for the admin list,
CRUD, required Hindi fields, the tenure-order rule);
`CommitteeConsentTest` (the three layers, separately);
`TempleAuthorizationTest` (every endpoint × refused roles, guest, a deactivated
account, immediate effect of granting `temple.manage`).

**All 164 Phase 0–2 tests pass unchanged** apart from the deliberate
address-move edits — the check that removing the columns broke nothing.

**Flutter, 258 tests** (200 + 58 new): address-line composition with a
caller-supplied panchayat label, profile and member parsing including the
absent-personal-detail contract, draft null-blanking and numeric year handling,
the public committee list and its states, the profile editor including
read-only for `content.view`, the admin list's "personal details are public"
flag, the consent block's five behaviours, delete-confirmation, and the name
takeover across header, hero, footer, sign-in page and dashboard.

---

## 8. Defects found and fixed during the phase

| # | Defect | Fix |
|---|---|---|
| 1 | **A server refusal naming a consent switch was invisible.** Text fields surface their own field errors through `errorText`, but the switches are not text fields — a 422 against `show_phone_publicly` was reduced to the generic "there is an error in what you entered", leaving the editor with no idea what was wrong | The error panel now also lists messages for fields that have no input of their own. Found by a widget test, not by review |
| 2 | Every widget test attempted a real HTTP request | Correct consequence of the change, not a bug in it: the temple name is app-wide chrome now, so even the sign-in page reads the profile. `pumpScreen` supplies a stub temple repository by default, and tests that want a failing or unconfigured profile script it |
| 3 | A test asserted the admin list showed one "प्रकाशित" | The premise was wrong: the word was both a member's test name and the status chip's label. Renamed the fixtures and asserted both chips instead, which tests more |

---

## 9. Known issues and technical debt

1. **`web/index.html` and `manifest.json` still carry a build-time name.** These
   are the static shell served before any request; the pre-render tool now
   overwrites the `<title>` and Open Graph tags per route from the profile, but
   the PWA manifest and the pre-JS description remain deploy-time constants.
   Making them dynamic needs a server-side template, which this stack does not
   have.
2. **No file uploads.** `logo_url` and `photo_url` are URLs; Phase 5 builds
   media handling with server-side MIME and size validation, and can point these
   columns at uploaded files without a schema change.
3. **Committee ordering is a number field**, not drag-and-drop — the same
   reorderable-editor gap as the navigation menu (below).
4. **Consent changes are not audit-logged.** `contact_consent_at` and
   `consent_recorded_by` are stored now so Phase 11 has something to audit.
5. Carried: two-factor authentication (Phase 2 §7); the navigation-menu editor
   screen; no cross-stack end-to-end test (Phase 12); the pre-render tool is not
   wired into CI.

---

## 10. Next phase

**Phase 4 — Puja, Events & Calendar.** Planned but **not started**. The
permission key `events.manage` already exists in the matrix and is labelled
"Available in phase 4".
