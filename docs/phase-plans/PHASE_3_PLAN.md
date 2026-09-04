# Phase 3 Plan — Temple Profile & Committee Management

**Written before code**, per the working agreement. Assumptions are numbered
`D1…D11` and each one is either resolved by the specification or recorded here
as a deliberate decision for the product owner to overturn.

---

## 1. Requirement review

From `IMPLEMENTATION_PLAN.md` (spec Phase 3):

| # | Requirement |
|---|---|
| 1 | `temple_profile` — bilingual name / address / history / mission, `logo_url`, `map_url` |
| 2 | `committee_members` — designation, tenure dates, public/private visibility |
| 3 | `GET /api/public/temple-profile`, `PUT /api/admin/temple-profile` |
| 4 | `GET /api/public/committee`, `POST /api/admin/committee-members` |
| 5 | Consent-gated publication of member personal details |

Two obligations carried in from earlier phases, recorded in `PHASE_STATUS.md`:

| # | Carried obligation | Source |
|---|---|---|
| 6 | **Move** the address out of `site_settings` — do not duplicate it | PHASE_1_PLAN B2 |
| 7 | **Take over** the temple name from the ARB files | PHASE_2_COMPLETION §9.2 |

Requirement 5 is the one with real consequences. Committee members are named
villagers, not staff of a company; publishing a phone number without permission
is a harm the software should make structurally difficult, not merely
discouraged.

---

## 2. Assumptions and decisions

### D1 — `temple_profile` is a singleton row, like `site_settings`

There is one temple. The service reads through `TempleProfileService::current()`,
which creates an empty row on first access, exactly as `SiteSettingService` does.
Empty is the correct initial state: the specification forbids shipping invented
temple content.

### D2 — The address **moves**; the columns are dropped

`site_settings` currently owns nine address columns plus `map_url`. Phase 3
makes `temple_profile` authoritative, so a second migration copies the existing
values across and then **drops** the columns. Two rows of truth for one address
is precisely the defect this phase exists to prevent.

`down()` re-creates the columns and copies the values back, so the pair is
reversible and the delivery gate's rollback check is honest.

**What stays in `site_settings`:** `contact_phone`, `contact_email`,
`social_links`, tagline, footer and default SEO. The specification assigns the
*address* to the temple profile and the *contact block* to site settings; that
split is kept rather than second-guessed. The public address card composes the
two, which is a presentation concern and belongs in the widget.

### D3 — The ARB temple name becomes a boot fallback, not the source

`appTitle` / `appSubtitle` cannot simply be deleted: the browser tab title, the
login screen and the app bar all render before any API response arrives, and a
blank header on every cold load would be a worse product.

The rule this phase establishes:

* **Every rendered surface prefers `temple_profile.name`**, resolved for the
  current language through the normal fallback.
* `l10n.appTitle` is used **only** while the profile is loading or unreachable.
  It is documented in the ARB file as an application-shell fallback.
* `appSubtitle` — the village line — is **removed from every render path**. A
  village name is temple content, not chrome; when the profile has no address
  the line simply does not appear, matching how the tagline already behaves.

So the name is CMS-driven with a graceful degrade, and the village is fully
CMS-driven with no hardcoded value anywhere. This closes known issue #2.

### D4 — Committee visibility is two independent gates

A member row carries:

* `is_published` — does this person appear on the public site at all;
* `contact_consent_at` + `consent_recorded_by` — a recorded fact that the person
  agreed their personal details may be published, with a timestamp and the
  account that recorded it;
* `show_phone_publicly`, `show_email_publicly`, `show_photo_publicly` — what
  specifically may be shown.

**The rule:** a visibility flag is honoured publicly only when consent is
recorded. It is enforced in three places, deliberately:

1. **The service refuses** to set any `show_*_publicly` flag while
   `contact_consent_at` is null — 422 against the named field.
2. **Withdrawing consent clears all three flags** in the same transaction, so a
   stale `true` can never survive a withdrawal.
3. **The public resource re-checks consent** before emitting each field. Belt
   and braces on purpose: this is the one place in the codebase where a bug
   publishes a villager's phone number.

A consent checkbox that only lives in the UI would satisfy nobody. It is stored
data, and `CommitteeConsentTest` proves each of the three layers independently.

### D5 — Personal details are excluded from the public payload, not blanked

When consent is absent, the public JSON has no `phone` key at all rather than
`"phone": null`. An absent key cannot be accidentally rendered, logged, or
picked up by a future client that treats null as "unknown, try again".

### D6 — The public committee list shows current members; admin sees everyone

Public: `is_published = true` **and** the tenure has not ended
(`tenure_end IS NULL OR tenure_end >= today`). The filter lives in the query,
not the serializer — the same discipline Phase 1 established for drafts.

Admin: every member, including unpublished and past ones. Committee membership
is village history and is not deleted when a term ends.

### D7 — Ending a tenure is retirement; `DELETE` is erasure

`tenure_end` retires a member and keeps the record. `DELETE` exists as well and
genuinely removes the row, because a person may ask for their personal data to
be erased and "we can only hide it" is not an acceptable answer. The API
documentation says which is which.

### D8 — Endpoints beyond the two the spec names

The specification names `POST /api/admin/committee-members`. A module the
committee can actually run needs the rest of the verbs, so the admin surface is
index / show / store / update / destroy. This is completing the named
requirement, not inventing scope: a create-only endpoint cannot correct a typo
in a member's name.

### D9 — `temple.manage` is the gate; it already exists

The key was defined in Phase 2's catalogue and labelled "Available in phase 3".
This phase attaches endpoints to it — exactly the design Phase 2 planned for.
Content Manager already holds it by default; Treasurer and Viewer do not.

`content.view` grants read access to the admin profile/committee screens so a
Viewer can see the committee list without being able to change it.

### D10 — `logo_url` and `photo_url` are URLs, not uploads

File upload is **Phase 5** (`media`, with server-side MIME/size validation).
Implementing an uploader here would duplicate work that phase must do properly.
These columns store a URL, validated as a URL with a length bound. Phase 5 will
be able to point them at uploaded media without a schema change.

### D11 — History and mission are plain text with paragraph breaks

Consistent with Phase 1 pages (assumption B6). No HTML is stored, so nothing is
rendered as HTML, and there is no sanitisation gap to get wrong.

---

## 3. Database design

### `temple_profiles` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `name_hi`, `name_en` | string(200) nullable | Takes over from the ARB strings (D3) |
| `history_hi`, `history_en` | text nullable | |
| `mission_hi`, `mission_en` | text nullable | |
| `address_line1`, `address_line2` | string(200) nullable | Moved from `site_settings` |
| `village`, `panchayat`, `police_station`, `district`, `state` | string(120) nullable | Moved |
| `postal_code` | string(20) nullable | Moved |
| `country` | string(120) nullable | Moved |
| `logo_url`, `map_url` | string(500) nullable | `map_url` moved |
| `established_year` | smallint unsigned nullable | Common on temple profiles; optional |
| `updated_by` | FK users nullOnDelete | |
| timestamps | | |

### `committee_members` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `name_hi` | string(160) **not null** | Hindi is the source language |
| `name_en` | string(160) nullable | |
| `designation_hi` | string(160) **not null** | |
| `designation_en` | string(160) nullable | |
| `bio_hi`, `bio_en` | text nullable | |
| `phone` | string(40) nullable | Personal — consent-gated |
| `email` | string(191) nullable | Personal — consent-gated |
| `photo_url` | string(500) nullable | Personal — consent-gated |
| `tenure_start` | date nullable | |
| `tenure_end` | date nullable | `>= tenure_start` |
| `is_published` | boolean default false | Off by default — publishing a person is a decision |
| `contact_consent_at` | timestamp nullable | The recorded fact (D4) |
| `consent_recorded_by` | FK users nullOnDelete | Who recorded it |
| `show_phone_publicly` | boolean default false | |
| `show_email_publicly` | boolean default false | |
| `show_photo_publicly` | boolean default false | |
| `sort_order` | unsigned int default 0 | Display order |
| `created_by`, `updated_by` | FK users nullOnDelete | |
| timestamps | | |

Index on `(is_published, sort_order)` for the public query and on `tenure_end`.

### `2026_09_07_000002_move_address_to_temple_profile`

`up()`: create the profile row if absent, copy the ten values across, drop the
columns from `site_settings`.
`down()`: re-add the columns, copy back from the profile.

---

## 4. API surface

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/temple-profile?lang=` | public |
| GET | `/api/public/committee?lang=` | public |
| GET | `/api/admin/temple-profile` | `content.view` |
| PUT | `/api/admin/temple-profile` | `temple.manage` |
| GET | `/api/admin/committee-members` | `content.view` |
| POST | `/api/admin/committee-members` | `temple.manage` |
| GET | `/api/admin/committee-members/{id}` | `content.view` |
| PUT | `/api/admin/committee-members/{id}` | `temple.manage` |
| DELETE | `/api/admin/committee-members/{id}` | `temple.manage` |

`PUT /api/admin/site-settings` loses its address fields in the same change;
sending them is rejected as unknown input rather than silently ignored.

---

## 5. Flutter surface

| Path | Screen |
|---|---|
| `/admin/temple-profile` | `AdminTempleProfileScreen` — bilingual identity, address, history, mission |
| `/admin/committee` | `AdminCommitteeScreen` — list, ordering, published/consent status at a glance |
| `/admin/committee/new`, `/admin/committee/:id` | `AdminCommitteeMemberScreen` |
| `/committee` | Public committee page, added to the dashboard and reachable from the CMS menu |

Home page gains a committee section; the header, hero, footer, login and tab
title switch to the profile name (D3).

New: `features/temple/` (domain, data, presentation), following the same
feature-first shape as `features/admin/`.

---

## 6. Implementation order

1. Migrations (create, then move) + models + factories
2. `TempleProfileService`, `CommitteeService` with the consent rules
3. Form requests, resources, controllers, routes
4. Backend tests — including the three consent layers proven separately
5. Flutter domain + repository + providers
6. Admin screens, then public screens, then the name takeover
7. Flutter tests
8. Regression: every Phase 0–2 test unchanged
9. `openapi.yaml` → v0.4.0, completion report, status update, **stop**

---

## 7. Delivery gate

```
flutter pub get · flutter analyze · dart format --set-exit-if-changed · flutter test
flutter build web --release
./vendor/bin/pint --test · php artisan test
migrate → rollback → migrate → db:seed on MariaDB, address values verified
  intact across the move and back
```

Phase 3 is not marked COMPLETE while any of these fail, and the address move is
not accepted until a rollback has been shown to restore the Phase 2 schema with
the data still present.

---

## 8. Explicitly out of scope

File uploads (Phase 5), the navigation-menu editor (carried), audit logging of
consent changes (Phase 11 — `consent_recorded_by` and the timestamp are stored
now so that phase has something to audit), and two-factor authentication
(deferred from Phase 2).
