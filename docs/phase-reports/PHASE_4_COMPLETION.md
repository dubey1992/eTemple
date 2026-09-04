# Phase 4 Completion Report — Puja, Events & Calendar

**Date:** 2026-09-08
**Status: COMPLETE.** Every specified requirement is delivered, plus two
usability findings raised against Phase 3 and fixed in the same change.

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 · Composer 2.10.3 ·
Laravel 12.69.1 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 4 requirement | Status | Where |
|---|---|---|---|
| 1 | `events` — type, bilingual title/description/venue, start/end, poster, featured, status, created_by | ✅ | `events` table, `Event` model |
| 2 | Public event list/detail + admin CRUD | ✅ | 7 endpoints — §3 |
| 3 | Daily aarti, bhajan-kirtan, festival, one-time **and recurring** | ✅ | Stored as a rule, expanded on read — §4 |
| 4 | Past/upcoming views, featured flag, timezone-safe values | ✅ | `?view=`, `?featured=`, offsets on every instant |
| 5 | `end_at >= start_at`; drafts never public; cancelled retained | ✅ | §5 |

### Findings raised against Phase 3, fixed here

| # | Finding | Result |
|---|---|---|
| 6 | Committee cards were ragged, and a withheld phone/e-mail left no row at all | ✅ Rows are equal height; both lines always present, a withheld one reading **NA** |
| 7 | No way back after opening a detail screen | ✅ Breadcrumb trail plus a back control on every admin screen |

---

## 2. Database changes

| Migration | Table |
|---|---|
| `2026_09_08_000000_create_events_table` | `events` — type, bilingual title/description/venue, `start_at`/`end_at`, the three recurrence columns, `poster_url`, `is_featured`, `status`, `created_by`/`updated_by`; indexed on `(status, start_at)` and `is_featured` |

Verified on **MariaDB 12.3.3**: `migrate:fresh` (15) → `rollback` (13) →
`migrate` (13) → `db:seed`.

---

## 3. API endpoints

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/events?lang=&view=&days=&featured=&type=` | public |
| GET | `/api/public/events/{id}?lang=&on=` | public |
| GET | `/api/admin/events?status=` | `content.view` |
| POST | `/api/admin/events` | `events.manage` |
| GET/PUT/DELETE | `/api/admin/events/{id}` | `content.view` / `events.manage` |

Documented in `docs/api/openapi.yaml` (now **v0.5.0** — 29 paths, 24 schemas).

`events.manage` was defined in Phase 2's catalogue and labelled "Available in
phase 4"; this phase attached endpoints to a key the committee could already
grant. Reading is gated on `content.view` so a Viewer can see the calendar
without being able to change it — the same split as Phase 3.

---

## 4. Recurrence — the part that matters most

**An `events` row is a rule, not an instance.** The daily aarti is one record
with `recurrence = daily`; the server expands it into dates across a bounded
window whenever the calendar is read.

The alternative — storing one row per occurrence — means an indefinite daily
event generating a row a day forever, and changing its time meaning a rewrite of
thousands of rows. What the committee edits is the rule, so the rule is what is
stored.

Four things this had to get right, each tested directly rather than through the
API:

* **An event that began years ago.** Expansion fast-forwards to the window with
  integer arithmetic instead of stepping day by day, so a 2015 aarti costs the
  same as one created yesterday — and still lands on the correct day and time.
* **A month with no 31st.** A monthly puja on the 31st falls on 30 April rather
  than rolling into 1 May and drifting from then on (`addMonthNoOverflow`).
* **Bounded output.** A 10,000-day window on an indefinite daily rule returns at
  most 366 occurrences. Without the cap it is a denial-of-service against our own
  API.
* **Something still running is not past.** A three-day festival that began
  yesterday appears under "upcoming", because it has not been missed.

Client-side recurrence arithmetic was deliberately **not** written: two
implementations of the same rule is how the two come to disagree. The Flutter
client renders the dates it is given.

---

## 5. The rules the specification names

| Rule | How it is enforced |
|---|---|
| `end_at >= start_at` | Form request **and** `EventService`, so it holds however the record is reached; 422 against `end_at` |
| Drafts never public | `scopePubliclyVisible` filters in the query, not the serializer. A draft and an unknown id are both 404 |
| Cancelled retained in history | Cancelled events **stay on the public calendar**, flagged and struck through, until they have passed |

The cancellation decision is the one worth stating plainly: hiding a cancelled
festival would leave devotees who had planned around it finding nothing and
concluding the site was broken. They are told instead. A cancelled event is also
stripped of `is_featured`, so it is never promoted on the home page.

---

## 6. Flutter routes and screens

| Path | Screen |
|---|---|
| `/events` | Public calendar, upcoming and past |
| `/events/:id?on=` | Public event detail |
| `/admin/events` | `AdminEventsScreen`, filterable by status |
| `/admin/events/new`, `/admin/events/:id` | `AdminEventEditorScreen` |

The home page gains a "coming up" section. New: `features/events/`.

In the editor the weekday picker appears **only** for a weekly rule, because
that is the only rule it means anything for, and the hint says in plain words
that a repeating event is entered once.

---

## 7. The two findings from Phase 3

**Committee cards.** Rows are now built by hand rather than with `Wrap`, which
sized each card independently and left them ragged whenever one member had a bio
and another did not. Phone and e-mail lines are always present; a detail the
server withheld reads **NA**. That reveals nothing — the server still decides
what to send, and the consent gate is untouched — but every card now has the
same shape. The same layout is used for event cards.

**Breadcrumbs.** `adminTrail()` is a pure function from a path to a trail, so
the whole navigation map is unit-tested without pumping a widget, and a test
asserts that *every* admin route produces a trail — a screen with no way back
now fails the build. The back control goes to the nearest linked ancestor (the
list), not all the way home, so the reader does not lose their place. An
unmapped admin path still gets a way home rather than a dead end.

---

## 8. Tests and command results

```
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  124 files, 0 changed
$ flutter test                                       318/318 passed
$ flutter build web --release                        Built build\web
$ ./vendor/bin/pint --test                           passed
$ php artisan test                                   279 passed (1129 assertions)
$ migrate → rollback → migrate → db:seed (MariaDB)   reversible
```

**Backend, 279 tests** (216 from Phases 0–3 + 63 new): `RecurrenceTest` (14 —
one-off, daily, weekly on named days, monthly month-end, yearly, until-dates,
expired rules, the cap, a still-running multi-day event);
`EventPublicTest` (20 — draft invisibility, cancelled visibility, ordering,
past/upcoming, filters, language fallback, the offset contract, occurrence
links); `EventManagementTest` (17 — CRUD, required fields, the two date
refusals, weekday normalisation, cancel-clears-featured, status filtering);
`EventAuthorizationTest` (12 — every endpoint × refused roles, guest, a
deactivated account, immediate effect of a grant).

**All 216 Phase 0–3 tests pass unchanged.**

**Flutter, 318 tests** (258 + 60 new): event parsing including offsets and
midnight-spanning events, draft serialisation and the weekly-only day list,
`EventQuery` value equality (without it every rebuild refetches), the public
list and its states, view switching, cancelled rendering, equal card heights,
detail including the occurrence link and not-found, the admin list and its
filter, the editor's conditional weekday picker, validation, delete
confirmation and read-only mode; plus 14 breadcrumb tests and the committee
card changes.

---

## 9. Defects found and fixed during the phase

| # | Defect | Fix |
|---|---|---|
| 1 | **Weekly events landed on the wrong days.** `startOfWeek()` follows the locale and returned Sunday here, so every named weekday shifted by one — asking for Tuesday and Saturday produced Monday and Friday | Monday pinned explicitly. Caught by a recurrence test, not by review |
| 2 | `StateProvider` no longer exists outside Riverpod 3's legacy import | Replaced with a `Notifier`; the view choice belongs in a provider anyway, so switching language does not throw the reader back to "upcoming" |
| 3 | Two of my own recurrence tests asserted the wrong count | The premise was wrong, not the code: a window that closes at midnight legitimately excludes that evening's occurrence. Expectations corrected and the boundary documented in the test |
| 4 | A test fixture used the title "आगामी", which is also the Upcoming button's label | Renamed, so the assertion is about the list rather than the buttons |

---

## 10. Known issues and technical debt

1. **No per-occurrence overrides.** Cancelling *one* day of a recurring aarti
   needs an exceptions table; today only the whole rule can be cancelled. Not a
   Phase 4 requirement, recorded rather than half-built.
2. **No calendar export (.ics)** and no reminders — notifications are Phase 8.
3. **`poster_url` is a URL, not an upload** (Phase 5, as with the temple logo).
4. **Recurrence expansion is not cached.** Fine at village scale; if the
   calendar grows, the public list is the obvious thing to cache.
5. Carried: two-factor authentication (Phase 2 §7); the build-time name in
   `web/index.html` and `manifest.json` (Phase 3 §9.1); reorderable editors for
   the navigation menu and the committee; consent changes not audit-logged
   (Phase 11); no cross-stack end-to-end test (Phase 12); pre-render tool not
   wired into CI.

---

## 11. Next phase

**Phase 5 — Gallery & Video Darshan.** Planned but **not started**. It brings
the first real file uploads, which `poster_url`, `photo_url` and `logo_url` are
all waiting on.
