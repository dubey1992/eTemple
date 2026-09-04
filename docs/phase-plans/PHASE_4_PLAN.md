# Phase 4 Plan — Puja, Events & Calendar

**Written before code**, per the working agreement. Assumptions are numbered
`E1…E10`.

---

## 1. Requirement review

From `IMPLEMENTATION_PLAN.md` (spec Phase 4):

| # | Requirement |
|---|---|
| 1 | `events` — `event_type`, bilingual title/description/venue, `start_at`, `end_at`, `poster_url`, `is_featured`, `status`, `created_by` |
| 2 | Public event list/detail + admin CRUD endpoints |
| 3 | Daily aarti, bhajan-kirtan, festival, one-time **and recurring** events |
| 4 | Past/upcoming views, featured flag, timezone-safe API values |
| 5 | Rules: `end_at >= start_at`; drafts never public; cancelled retained in history |

Requirement 3 is the one that shapes the schema. A daily aarti is not 365 rows.

---

## 2. Assumptions and decisions

### E1 — Recurrence is stored as a rule and expanded on read

An `events` row describes *when the event happens*, not one instance of it:

* `recurrence` — `none` | `daily` | `weekly` | `monthly` | `yearly`;
* `recurrence_days` — ISO weekday numbers (1 = Monday … 7 = Sunday), used by
  `weekly`;
* `recurrence_until` — the date the rule stops, nullable for "indefinitely".

`start_at` and `end_at` define the **first** occurrence; they also fix the time
of day and the duration that every later occurrence inherits. The public list
expands the rule across a requested window and returns dated occurrences.

Storing expanded rows instead would mean the daily aarti generates a row a day
forever, and changing its time would mean rewriting thousands of rows. The rule
is the thing the committee actually edits.

### E2 — The expansion window is bounded, and so is the occurrence count

Public list default: **now → +90 days**, `days` adjustable up to 366. Each event
contributes at most 366 occurrences. An unbounded expansion of an indefinite
daily event is a denial-of-service against our own API.

### E3 — Times are served in the temple's timezone, with the offset

Stored UTC (Laravel's default cast). Served as ISO-8601 **with the offset**, in
`Asia/Kolkata` — `2026-09-10T05:30:00+05:30` — and the payload names the
timezone explicitly. A client that ignores zones still shows the right local
time, and one that respects them has the offset to work with. "Timezone-safe"
means unambiguous, not UTC-only.

### E4 — Cancelled events stay visible until they have passed

Three statuses: `draft`, `published`, `cancelled`.

* **Draft is never public.** Same discipline as Phase 1 pages: filtered in the
  query, not the serializer.
* **Cancelled is public and flagged.** Silently removing a cancelled festival
  is the worst option: devotees who planned around it would simply find nothing
  and assume the site was broken. The occurrence is returned with
  `is_cancelled: true` so the UI can strike it through and say so.
* Cancelled events are never featured.

This is what "cancelled retained in history" is for.

### E5 — Past and upcoming are one endpoint with a `view` parameter

`?view=upcoming` (default) returns occurrences ending at or after now, soonest
first. `?view=past` returns occurrences that have ended, most recent first,
within a bounded look-back. One endpoint, one filter, per the project's
"define pagination/filter conventions once" rule.

### E6 — `is_featured` is a filter, not a second endpoint

`?featured=1`. The home page asks for featured upcoming occurrences; the events
page asks for all of them.

### E7 — Event types are a code-defined catalogue

`aarti`, `bhajan_kirtan`, `festival`, `puja`, `other` — in `App\Support\EventType`,
mirrored in Dart, exactly as `Permission` is. Labels are translated in the
client, so adding a type is one constant and two ARB entries, not a migration.

### E8 — `poster_url` is a URL, not an upload

Consistent with Phase 3's D10: file handling with server-side MIME and size
validation is Phase 5, and this column can point at uploaded media then without
a schema change.

### E9 — `events.manage` gates writes; `content.view` gates admin reads

The key already exists in Phase 2's catalogue labelled "Available in phase 4".
Same split as Phase 3: a Viewer can see the calendar in the admin area without
being able to change it.

### E10 — Detail is by event, with an optional occurrence date

`GET /api/public/events/{id}` returns the event plus its next occurrences.
`?on=YYYY-MM-DD` names which occurrence the visitor arrived at, so a shared link
to "the aarti on the 12th" says the 12th. An unknown or draft event is a 404,
indistinguishable from each other.

---

## 3. Database design

### `events` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `event_type` | string(40) | From the catalogue (E7) |
| `title_hi` | string(200) **not null** | Hindi is the source language |
| `title_en` | string(200) nullable | |
| `description_hi`, `description_en` | text nullable | |
| `venue_hi`, `venue_en` | string(200) nullable | |
| `start_at` | datetime **not null** | First occurrence; fixes the time of day |
| `end_at` | datetime nullable | `>= start_at`; null means "no stated end" |
| `recurrence` | string(20) default `none` | E1 |
| `recurrence_days` | json nullable | Weekday numbers for `weekly` |
| `recurrence_until` | date nullable | |
| `poster_url` | string(500) nullable | E8 |
| `is_featured` | boolean default false | |
| `status` | string(20) default `draft` | `draft` / `published` / `cancelled` |
| `created_by`, `updated_by` | FK users nullOnDelete | |
| timestamps | | |

Indexes: `(status, start_at)` for the public query, and `is_featured`.

---

## 4. API surface

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/events?lang=&view=&days=&featured=&type=` | public |
| GET | `/api/public/events/{id}?lang=&on=` | public |
| GET | `/api/admin/events` | `content.view` |
| POST | `/api/admin/events` | `events.manage` |
| GET/PUT/DELETE | `/api/admin/events/{id}` | `content.view` / `events.manage` |

---

## 5. Flutter surface

| Path | Screen |
|---|---|
| `/events` | Public list, upcoming and past |
| `/events/:id` | Public detail |
| `/admin/events` | `AdminEventsScreen` |
| `/admin/events/new`, `/admin/events/:id` | `AdminEventEditorScreen` |

The home page gains a featured/upcoming events section. The admin breadcrumb map
gains the events branch.

---

## 6. Implementation order

1. Migration + model + factory + `EventType`
2. `EventService` with recurrence expansion and the public filters
3. Requests, resources, controllers, routes
4. Backend tests — recurrence, filtering, the draft rule, the cancel rule
5. Flutter domain + repository + providers
6. Public screens, then admin screens, then the home section
7. Flutter tests
8. Regression: every Phase 0–3 test unchanged
9. `openapi.yaml` → v0.5.0, completion report, status update, **stop**

---

## 7. Delivery gate

```
flutter pub get · flutter analyze · dart format --set-exit-if-changed · flutter test
flutter build web --release
./vendor/bin/pint --test · php artisan test
migrate → rollback → migrate → db:seed on MariaDB
```

---

## 8. Explicitly out of scope

File uploads (Phase 5), calendar export (.ics), reminders and notifications
(Phase 8), per-occurrence overrides — cancelling *one* day of a recurring aarti
needs an exceptions table, which is not a Phase 4 requirement and is recorded as
debt rather than half-built.
