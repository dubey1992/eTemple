# Phase 8 Plan — Announcements & Notifications

Approved to start: 2026-09-11.

The first phase that sends something outward on the temple's behalf. Phase 7's
shaping constraint was keeping unwanted messages *out*; this one's is not
sending unwanted messages *out* — and being able to say, afterwards, exactly
what went to whom.

Carries one approved UI change that is not part of the Phase 8 specification:
the admin console's card grid becomes a side menu (§9).

## 1. Requirement review

From `IMPLEMENTATION_PLAN.md`:

- `announcements` (bilingual title/message, `priority`, `start_at`, `end_at`,
  `channels`, `status`, `created_by`)
- Public announcements endpoint + admin create/send endpoints
- Homepage banner respecting backend schedule/expiry
- Optional email; SMS/WhatsApp only after provider approval; **no sends without
  explicit admin action**

Global rules that bite hardest here:

- Only published content from public APIs — and here "published" has a *time*
  attached to it.
- Bilingual `*_hi`/`*_en` stored independently, with a documented Hindi fallback.
- *"Sensitive donor, enquiry and committee-member data must not be exposed
  publicly without permission/consent."*
- Loading / success / empty / error / unauthorized states on every API-driven
  screen.

## 2. Assumptions and decisions

### N1 — Publishing and sending are two different acts

Publishing puts an announcement on the website for its scheduled window.
**Sending** puts it in somebody's inbox. They are separate columns, separate
endpoints and separate buttons, because they have opposite failure modes: an
unpublished announcement is invisible and fixable, while a sent one is gone.

This is the specification's "no sends without explicit admin action" read
literally. Saving an announcement never sends anything. Publishing it never
sends anything. Only pressing send sends.

### N2 — The schedule is enforced in the query, not in the serializer

`start_at <= now <= end_at` is a `where` clause on the public endpoint. An
announcement scheduled for next Tuesday is not reachable today by any public
request, in any language, at any priority.

If the filter lived in the serializer, "scheduled" would be a display
convention rather than a fact about what the API will hand out — and the first
person to call the endpoint directly would read next week's news.

### N3 — There is no cron, and the status does not change by itself

`status` is `draft`, `published` or `archived` — three things a person decides.
Whether an announcement is *currently showing* is computed on read from
`start_at`, `end_at` and the clock.

A "scheduled → live" transition written by a scheduler would mean an
announcement goes live only when the scheduler happens to run, and on a shared
host where no scheduler is installed, never. The temple is on modest hosting;
a feature that silently depends on cron being configured is a feature that
silently does not work.

### N4 — A send goes to the committee, not to devotees

There is no subscriber list in this project, and the addresses that do exist
must not become one:

- **Enquiry e-mail addresses are off limits.** A villager gave that address to
  get an answer to their question. Using it to send them festival announcements
  is consent laundering, and it is precisely what Phase 7's privacy rule
  forbids.
- **Committee accounts are legitimate recipients.** They have accounts, they
  are the temple's own people, and an announcement reaching them is an internal
  notification rather than a mailshot.

So the e-mail channel notifies the committee. A devotee mailing list is real
work — opt-in, confirmation, unsubscribe in every message, and a record of when
each person consented — and it is not in this phase. Recorded as debt in §10
rather than half-built.

### N5 — SMS and WhatsApp are refused, not silently ignored

The specification says these come "only after provider approval", and no
provider has been approved. They exist in the channel catalogue as known codes
and are **refused with a message that says so**.

A checkbox that appears to send an SMS and quietly does nothing is worse than
no checkbox: the committee would believe the village had been told.

### N6 — One send per announcement

A second send is refused with 409. To say it again, write it again.

The failure mode being designed against is the double-press and the
"did that work? let me try again" — not a committee that genuinely wants to
send twice, which is rare and can make a new announcement. `sent_at`,
`sent_by` and `recipient_count` are written on the row, so months later the
question "was this ever sent, and to how many?" has an answer.

### N7 — The mail is queued, and a failure does not lose the record

Mail is queued, as in Phase 7. The send is recorded when it is *dispatched*,
and the count recorded is the number of recipients the queue was given — not a
delivery guarantee, which no mail system can offer. The report says so plainly
rather than implying every message arrived.

### N8 — Priority changes prominence, not permission

`normal`, `important`, `urgent`. It decides how the banner looks and how the
list sorts. It grants nothing: an urgent announcement obeys exactly the same
schedule and publication rules as any other.

### N9 — The banner shows one announcement, and can be dismissed

The home page shows the highest-priority currently-showing announcement, not a
stack of them. A page whose top third is a pile of notices is a page nobody
reads.

Dismissal is per visitor and lasts the session. Persisting it would need
per-visitor storage, and a dismissal that outlives the announcement is worse
than one that does not: a villager who dismissed last month's notice would
never see this month's.

### N10 — Bilingual, with the Hindi fallback the rest of the site uses

`title_hi`/`title_en`, `message_hi`/`message_en`, resolved through the existing
`LocalizedText` machinery. Hindi is required; English is optional and falls back
to Hindi with `fallback_used` set, exactly as Phase 1 established.

### N11 — Reading needs `content.view`; writing and sending need `announcements.manage`

Consistent with the calendar and the gallery. Sending is the same permission as
writing rather than a separate one: the person trusted to write in the temple's
name is the person trusted to say it out loud, and a third key would be a
distinction the committee does not have.

### N12 — Nothing is deleted

Same as Phases 6 and 7. `archived` takes an announcement off the site and out
of the default list, and keeps the row — including the record of what was sent.

## 3. Database design

### `announcements` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `title_hi` / `title_en` | string(200) / nullable | N10 |
| `message_hi` / `message_en` | text / nullable | N10 |
| `priority` | string(20), indexed | `normal` / `important` / `urgent` |
| `start_at` | timestamp | when it begins showing |
| `end_at` | timestamp, nullable | null = until archived |
| `channels` | json | the codes chosen when it was sent |
| `status` | string(20), indexed | `draft` / `published` / `archived` |
| `created_by` | FK users, nullable, null on delete | |
| `updated_by` | FK users, nullable, null on delete | |
| `sent_at` | timestamp, nullable | N6 |
| `sent_by` | FK users, nullable, null on delete | |
| `recipient_count` | unsignedInteger, nullable | what the queue was given (N7) |
| `link_url` | string(500), nullable | "read more" — an internal route or an external link |
| timestamps | | |

Index on `(status, start_at)`: the public query's shape.

## 4. API surface

| Method | Path | Guard |
|---|---|---|
| GET | `/api/public/announcements` | public — currently showing only |
| GET | `/api/admin/announcements` | `content.view` |
| GET | `/api/admin/announcements/{id}` | `content.view` |
| POST | `/api/admin/announcements` | `announcements.manage` |
| PUT | `/api/admin/announcements/{id}` | `announcements.manage` |
| POST | `/api/admin/announcements/{id}/publish` | `announcements.manage` |
| POST | `/api/admin/announcements/{id}/archive` | `announcements.manage` |
| POST | `/api/admin/announcements/{id}/send` | `announcements.manage` |

No DELETE.

## 5. Flutter surface

- The **home page banner**, above the hero, dismissible, priority-coloured.
- `/admin/announcements` — the list, with what is showing now, what is
  scheduled, what has expired, and what was sent.
- `/admin/announcements/new` and `/admin/announcements/:id` — the editor, with
  publish, archive and a separately-confirmed **send**.

## 6. Implementation order

1. Migration, model, factory, priority/channel catalogues, config.
2. `AnnouncementService` and the send path, with tests, before the controllers.
3. Requests, resources, controllers, routes.
4. Backend tests: the schedule, the send rules, authorization, privacy.
5. Flutter domain, repository, providers.
6. The banner, then the admin list and editor.
7. The **side menu** (§9).
8. Gate, live verification, docs.

## 7. Delivery gate

`flutter pub get` · `flutter analyze` · `dart format --set-exit-if-changed` ·
`flutter test` · `flutter build web --release` · `pint --test` ·
`php artisan test` · migrate → rollback → migrate → seed on MariaDB ·
live checks through the running API · every earlier phase's tests unchanged.

## 8. Explicitly out of scope

- A devotee mailing list (opt-in, confirmation, unsubscribe) — N4.
- SMS and WhatsApp delivery — N5, and the specification's own condition.
- Push notifications.
- Per-announcement read receipts or open tracking.

## 9. Carried UI change — the admin card grid becomes a side menu

Approved separately from the Phase 8 requirements, and done here because Phase 8
adds the eleventh module and the grid has stopped scaling.

**The problem.** Every switch between modules costs a round trip: back to the
dashboard, scan a grid of eleven cards, click. With a persistent menu it is one
click from anywhere.

**Decisions:**

- **One list, not two.** The permission filtering currently lives inside the
  dashboard's card list. It moves to a single `AdminDestinations` catalogue that
  both the menu and the dashboard read. Two copies would drift, and the day they
  disagree is the day somebody is shown a door they cannot open.
- **The dashboard stays**, as a landing page rather than a menu. Its cards lose
  their descriptions — the menu carries the labels now — and it becomes the
  place Phase 10's at-a-glance figures will go.
- **It collapses to a drawer on a phone.** The committee will use handsets; the
  shell already knows `Breakpoints.of(context).isCompact`.
- **Breadcrumbs stay.** They answer a different question: the menu shows which
  module, the trail shows how deep. Removing them would lose the way back from a
  deep link.
- The menu shows only what the signed-in account may open — a courtesy, never
  the access control, which remains the server's.
