# Phase 8 Completion Report — Announcements & Notifications

**Status: COMPLETE** · 2026-09-12

The first phase that sends something outward on the temple's behalf. Phase 7's
constraint was keeping unwanted messages out; this one's is not sending unwanted
messages out — and being able to say, afterwards, exactly what went to whom.

Also carries an approved UI change that is not part of the Phase 8
specification: the admin console's card grid is now a side menu (§9).

## 1. Implemented requirements checklist

| Requirement | Where |
|---|---|
| `announcements` with bilingual title/message, priority, window, channels, status, created_by | `2026_09_12_000000_create_announcements_table.php` |
| Public announcements endpoint | `GET /api/public/announcements` |
| Admin create/send endpoints | `Admin\AnnouncementController` — five verbs, four URLs |
| Homepage banner respecting backend schedule/expiry | `AnnouncementBanner` — §4 |
| Optional email | committee accounts only, off-switchable — §5 |
| SMS/WhatsApp only after provider approval | refused with a reason, not ignored — §6 |
| **No sends without explicit admin action** | §3 |

## 2. Database changes

One new table, `announcements`. Two things about it are worth reading twice:

- **`status` and the schedule answer different questions.** `status` is what a
  person decided — draft, published, archived. Whether a notice is *currently
  showing* is computed on read from `start_at`, `end_at` and the clock.
- **Publishing and sending are separate columns because they are separate
  acts.** `sent_at`, `sent_by` and `recipient_count` exist so that months later
  "was this ever sent, and to how many?" has an answer.

Verified reversible on MariaDB 12.3.3 — migrate → rollback → migrate.

## 3. Publishing and sending are two different acts

This is the phase's spine. Saving can be corrected; publishing can be archived;
**sending cannot be taken back**. So they are separate columns, separate
endpoints and separate buttons:

| | Endpoint | Undo |
|---|---|---|
| Save | `POST`/`PUT /admin/announcements` | edit it again |
| Publish | `POST .../publish` | archive it |
| Archive | `POST .../archive` | publish it again |
| **Send** | `POST .../send` | **none** |

Saving sends nothing. Publishing sends nothing. Only pressing send sends — and
`channels` is required with no default, because a default would mean the most
consequential action in this phase could happen without anybody choosing it.

**A second send is a 409.** A message cannot be unsent, so the second press is
refused rather than obeyed, with a refusal that says what to do instead: to say
it again, write a new announcement.

`status`, `sent_at` and `recipient_count` are not mass-assignable and are
ignored if a payload names them — asserted both in the test suite and live.

## 4. The schedule is a query, not a display convention

`start_at <= now <= end_at` is a `where` clause on the public endpoint. A notice
dated for next Tuesday is not reachable today by any request, in any language,
at any priority. If the filter lived in the serializer, "scheduled" would be
true on screen and false at the API, and the first caller to hit the endpoint
directly would read next week's news.

**There is no cron, deliberately.** A `scheduled → live` transition written by a
scheduler means an announcement goes live only when the scheduler runs — and on
a shared host where none is installed, never. The temple is on modest hosting; a
feature that silently depends on cron being configured is a feature that
silently does not work. `is_showing` is computed on every read instead.

The banner shows **one** notice, the loudest currently showing. A page whose top
third is a pile of notices is a page nobody reads. Dismissal lasts the session:
one that outlived the announcement would be worse than none, because a villager
who closed last month's banner would never see this month's.

## 5. Who an announcement e-mail reaches

**Active committee accounts, and nobody else.**

There is no subscriber list in this project, and the addresses that do exist
must not become one. A villager who left an e-mail on an enquiry gave it to get
an answer to their question; using it to send festival announcements is consent
laundering, and it is exactly what Phase 7's privacy rule forbids. There is a
test that creates an enquiry with an address and asserts the send never reaches
it.

Blocked and inactive accounts are excluded too: an account that cannot sign in
is not one the temple should be writing to.

A devotee mailing list is real work — opt-in, confirmation, unsubscribe in every
message, and a record of when each person consented. It is not in this phase and
is recorded as debt rather than half-built.

Unlike Phase 7's acknowledgement, this mail **does** carry the temple's words —
that is the point of it. The difference is who wrote them: a committee member
with `announcements.manage`, not an anonymous stranger. It is still escaped: the
author is trusted to write the notice, not to have avoided a `<` by accident,
and a mail client interprets markup as willingly as a browser.

## 6. SMS and WhatsApp are refused, not ignored

The specification says these come "only after provider approval", and none has
been approved. They are in the channel catalogue, they are **shown in the send
dialogue**, and they are **disabled with the reason printed under them**.

A checkbox that appears to send an SMS and quietly does nothing is worse than no
checkbox: the committee would believe the village had been told. One unavailable
channel refuses the *whole* send, because a partial send would leave nobody sure
what went out.

## 7. Flutter surface

- **The home page banner**, above the hero, priority-coloured, dismissible.
- `/admin/announcements` — what is showing, what is scheduled, what has expired,
  and what was sent, on the row rather than buried in the editor.
- `/admin/announcements/new` and `/:id` — the editor. Save and archive sit
  together; **send sits below a divider, on its own**, and disappears entirely
  once used, replaced by a panel saying when it went and to how many.

The send dialogue states the consequence before the button, ticks nothing by
default, and names the recipients — including the sentence that devotees are not
on a mailing list.

## 8. Tests and command results

| Gate | Result |
|---|---|
| `flutter pub get` | ✅ |
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 196 files changed |
| `flutter test` | ✅ **494** passed (+30) |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **544** passed (+40) |
| migrate → rollback → migrate (MariaDB) | ✅ reversible |
| Phase 0–7 tests | ✅ pass unchanged |

New backend tests: `AnnouncementScheduleTest` (10), `AnnouncementSendTest` (16),
`AnnouncementAuthorizationTest` (14).

New Flutter tests: `announcement_screens_test.dart` (22),
`admin_menu_test.dart` (8), plus three more routes in the breadcrumb sweep.

### Live verification against the running API

**54 checks over two passes**, all passing — 43 of 44 in the first, and the one
that did not settle was the script's own ordering: it checked the bilingual
fallback *after* archiving the only notice that was showing, leaving nothing to
inspect. The second pass creates one notice with English and one without, checks
the fallback both ways, and archives them.

What the live pass covers that the unit tests cannot: that writing, publishing
and sending really are separate over HTTP; that a payload naming `status` or
`sent_at` is ignored by the running server; that a scheduled notice is absent
from the public endpoint; that a second send is a 409; and that the public JSON
contains none of `sent_at`, `recipient_count`, `channels`, `status`,
`created_by` or `is_showing`.

### Verified in a browser

The release bundle was driven through Chrome: the banner above the hero on the
home page, the side menu, navigation between modules with the current one
marked, the announcement list, the editor, and the send dialogue — confirmed to
open with nothing ticked, SMS and WhatsApp greyed with their reason, and the
send button disabled.

## 9. The admin card grid is now a side menu

Approved separately from the Phase 8 requirements, and done here because Phase 8
adds the eleventh module.

**The problem.** Every switch between modules cost a round trip: back to the
dashboard, scan eleven cards, click. The menu makes it one click from anywhere.

**What was done:**

- **One list, not two.** The permission filtering lived inside the dashboard's
  card list, and the menu would have needed a copy. It moved to
  `AdminDestinations`, which both read. Two copies of a permission rule drift,
  and the day they disagree is the day somebody is shown a door that will not
  open. A test asserts the dashboard shows exactly what the catalogue says is
  visible.
- **The dashboard stays**, as a landing page rather than a menu. Its cards lost
  their descriptions — now tooltips — and got denser. It is where Phase 10's
  at-a-glance figures will go.
- **It collapses to a drawer below 900px**, so a committee member on a handset
  gets a menu button rather than a squeezed rail.
- **Breadcrumbs stay.** The menu says which module; the trail says how deep.
  Removing them would lose the way back from a deep link.
- The menu shows only what the account may open — a courtesy, never the access
  control, which is still the server's.

## 10. Known issues and technical debt

- **No devotee mailing list** — §5. Needs opt-in, confirmation, unsubscribe and
  a consent record.
- **SMS and WhatsApp are not implemented**, only refused cleanly. Wiring one
  means a provider, credentials, per-message cost and a delivery log.
- **`recipient_count` is what the queue was handed**, not what arrived. No mail
  system can promise delivery, and the report says so rather than implying it.
- **A send with no queue worker running records itself and delivers nothing** —
  the worst of both. Added to the deployment checklist; it cannot be detected
  from inside the request.
- **No read receipts or open tracking**, and none planned: it would mean a
  tracking pixel in a village temple's e-mail.
- **The banner's dismissal is per session**, held in memory. Persisting it needs
  per-visitor storage and a rule for when a dismissal expires.
- **No per-recipient language preference**: the notification carries both
  languages because no account has a column saying which one it reads.

## 11. Next phase

**Phase 9 — Accounts & Transparency.** Planned but **not started**. Keys
`accounts.view` and `accounts.manage` already exist in the matrix. It is the
phase that publishes what the temple did with the money, which makes the
question of what may be shown about a named donor — `donations.is_anonymous`,
stored since Phase 6 and respected by nothing yet — its shaping constraint.
