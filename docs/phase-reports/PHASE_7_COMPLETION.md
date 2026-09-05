# Phase 7 Completion Report — Devotee Contact & Enquiries

**Status: COMPLETE** · 2026-09-11

The prototype's `संपर्क` section, and the first time this application lets
somebody who has not signed in write to the temple's database. Everything below
follows from that one fact.

## 1. Implemented requirements checklist

| Requirement | Where |
|---|---|
| `enquiries` table with the specified columns | `2026_09_11_000000_create_enquiries_table.php` |
| `POST /api/public/enquiries` | `PublicSite\EnquiryController@store` |
| Admin inbox + status endpoints | `Admin\EnquiryController` |
| Spam protection | `EnquiryFormToken`, `EnquirySpamGuard`, honeypot |
| Rate limiting | `throttle:enquiry-submit` (3/min per address) + a daily ceiling |
| CAPTCHA-after-threshold | a server-issued bilingual question, after 2 submissions in an hour |
| Optional acknowledgement e-mail | `EnquiryAcknowledgement`, off unless configured |
| Enquiry content never displayed publicly | no public read exists — §4 |

## 2. Database changes

One new table, `enquiries`. Beyond the specified columns:

- `reference` (unique) — `RKT/E/2026-27/0001`, and the only thing the public
  response contains;
- `resolved_by` — who closed it, beside `resolved_at`;
- `submitted_ip_hash` — an HMAC of the address keyed by `APP_KEY`, never the
  address;
- `submitted_user_agent`, truncated to the column;
- `acknowledged_at` — so the courtesy mail is queued once.

Both foreign keys are `nullOnDelete`: a committee member leaving must not take
the temple's enquiries with them.

Verified reversible on MariaDB 12.3.3 — migrate → rollback → migrate → seed.

## 3. API endpoints

| Method | Path | Guard |
|---|---|---|
| GET | `/api/public/enquiry-form` | public |
| POST | `/api/public/enquiries` | public, `throttle:enquiry-submit` |
| GET | `/api/admin/enquiries` | `enquiries.manage` |
| GET | `/api/admin/enquiries/summary` | `enquiries.manage` |
| GET | `/api/admin/enquiries/{id}` | `enquiries.manage` |
| PUT | `/api/admin/enquiries/{id}/status` | `enquiries.manage` |

Documented in `docs/api/openapi.yaml` **v0.8.0** — 53 paths, 42 schemas.

## 4. Spam protection: four layers, and why none of them is reCAPTCHA

Google reCAPTCHA and hCaptcha would each mean **every villager who opens the
temple's contact page is fingerprinted by a third party**, and both need keys
this project has not been given. For a village temple that is not a trade worth
making, so all four layers are served by the temple's own server.

### 1. Rate limit

`throttle:enquiry-submit` — three submissions a minute, keyed by address only.
There is no account to key on, which is exactly what makes this the abusable
endpoint. A daily ceiling sits on top, because three a minute still allows four
thousand a day.

### 2. Honeypot

A field no human sees, sent empty by the client on every submission. Anything in
it means a bot — and the answer is the **success shape**: HTTP 201, the same
sentence a real visitor gets, and nothing stored. Telling a bot it was detected
is free tuning feedback for whoever wrote it.

### 3. A timed, single-use ticket

`GET /api/public/enquiry-form` issues an HMAC-signed nonce. A submission that
arrives faster than a person could type is refused; so is one on a ticket older
than the window; so is a second use of the same ticket. **One harvested token is
worth one message.**

The signature is checked before the cache is touched, so forged tokens cannot be
used to probe for live nonces.

### 4. A question, after a threshold

Once an address has sent more than the threshold within the window, the next
form it is issued carries a small bilingual arithmetic question — written in
words, not figures, so it cannot be answered by pattern-matching digits.

Two details matter:

- **The answer never leaves the server.** The token carries a nonce; the
  expected answer sits in the cache. A self-contained signed token would have to
  carry the answer, and a one-digit sum is brute-forced from a hash in
  microseconds.
- **The threshold is re-evaluated at submission time.** Fetching a clean ticket
  before starting to abuse the form buys nothing: the submission is bounced with
  `ENQUIRY_CHALLENGE_REQUIRED` and the visitor is sent for a form that has the
  question on it.

The counter's window does not extend itself. `Cache::increment` does not create
a key with a TTL, and re-`put`ting the value with a fresh expiry would let a
steady trickle keep its own window open forever — after one burst, every visitor
from that address would face arithmetic permanently. The expiry is set once,
when the counter is created.

## 5. Privacy: there is nowhere for it to come out

The specification names enquiry data alongside donor data. As in Phase 6, the
strongest form of that is not a careful serializer but an absent endpoint.

- **No public read.** No list, no count, no "recent questions", no fetch by
  reference. Four plausible public paths are asserted to 404 or 405, and to
  carry no name or number, in `EnquiryPrivacyTest`.
- **The submission is not echoed.** The response is a reference and a sentence.
  Returning the stored row would make the endpoint a reflector: anybody could
  POST content and have the temple's own API serve it back.
- **`enquiries.manage` covers the reads too.** There is deliberately no
  `enquiries.view` key. A Viewer may see the calendar, the committee and the
  donation totals; a villager's telephone number and their complaint are not
  general committee reading. A Treasurer and a Viewer are both refused, asserted
  by calling the API directly.
- **The address is hashed.** Recognising that thirty messages came from one
  place does not require knowing the place. A stolen database backup does not
  become a list of who wrote to the temple. The hash is not serialized even to
  the committee.

## 6. Two decisions worth stating plainly

### The acknowledgement e-mail carries none of the sender's words

An anonymous form with an e-mail field is an open relay for harassment: the
attacker types a victim's address and our server delivers whatever text the
attacker chose, from the temple's own domain.

So the mail is **off unless configured**, is sent **at most once per address per
hour**, and contains **no visitor-supplied text at all** — not even their name.
A reference number, a category label from a fixed catalogue, and the temple's
own published contact details. It is queued, so a dead SMTP server cannot hold a
public request open.

The category labels are bilingual and live on the **server** as well as in the
ARB files, because the mail is rendered by PHP and cannot reach Flutter's
translations. Phase 6 learned this the expensive way — its first receipts printed
`festival` and `cash` at a villager, found only by screenshotting a real receipt
(`PHASE_6_COMPLETION` §8.4). This phase paid it up front.

### Nothing is deleted, and `spam` is the only removal

No `DELETE` endpoint at any status; a `DELETE` returns 405, asserted. A complaint
that its subject can erase is not a complaint system. `spam` takes a row out of
the default inbox and keeps it, one query parameter away.

Personal data does not belong in a database forever, so retention and purge are
real work and are recorded as Phase 11's rather than half-built here.

## 7. Flutter surface

- **`/contact`** — the address first and the form second, because most people
  arriving want a telephone number and should not have to fill in a form to find
  one. The form fetches its ticket when the page opens (which is also how the
  server times it), shows the question only when the server asks one, and on
  success shows the reference.
- **`/admin/enquiries`** — the inbox: status tabs carrying the server's counts,
  category and assignee filters, search, paging. Unanswered first.
- **`/admin/enquiries/:id`** — how to reply before what was asked, the message,
  the status controls and assignment.

**A refused submission never costs somebody their message.** When a ticket has
gone stale or been spent — the common case, and entirely recoverable — every word
stays on screen and a fresh ticket is fetched underneath the visitor. Losing a
villager's message to an anti-spam measure would be a worse failure than the
spam.

### Integration with the earlier phases

- `संपर्क` joins the seeded navigation after `मंदिर समिति`.
- The home page's `पता एवं संपर्क` band gains a button into `/contact` — the
  shape Phase 6 gave `/donate`, so the home page does not grow a second long
  form.
- A dashboard tile behind `enquiries.manage`, and breadcrumbs for both admin
  routes (still asserted for **every** admin route by
  `admin_breadcrumbs_test.dart`).
- The shared test harness installs an enquiry fake alongside the temple, event,
  media and donation ones, so no screen can reach a real network by accident.

## 8. Defects found and fixed during the phase

### 8.1 `DONATION_LOCKED` was never mirrored in the Flutter client

`ApiErrorCode` says of itself: *"These strings are part of the public API
contract and are mirrored by the Flutter client. Never rename a code without
changing the client in the same release."* Nothing enforced it, and Phase 6
shipped `DONATION_LOCKED` on the server with **no matching `ErrorCode` entry**.
The translated message for it, `errorDonationLocked`, existed the whole time and
was never reachable.

The effect: a treasurer who edited a receipted donation was told *"something went
wrong"* instead of *"a receipt has been issued, so only the notes can be changed
— to correct it, reverse it and record it again."* The refusal was correct; the
explanation was lost.

Fixed, and `test/core/error_code_mirror_test.dart` now reads the PHP catalogue
across the repository and fails if any code has no client mirror. No test could
have noticed this before, because the gap was *between* the two languages.

### 8.2 The dev API origin was a fixed hostname (D1)

Found while checking that login worked at the end of Phase 6. `API_BASE_URL`
defaulted to `http://localhost:8000/api`. Open the app at `127.0.0.1:5000` and
the `XSRF-TOKEN` cookie is written against host `localhost`, is invisible to
`document.cookie` on `127.0.0.1`, no `X-XSRF-TOKEN` header is sent, and **every
sign-in fails** with a 419 shown as "session expired — reload the page". True,
and useless: cookies are keyed by host, and `localhost` and `127.0.0.1` are two
hosts.

The development default now takes its host from `window.location`, keeping the
scheme, port and path. Production is untouched: `API_BASE_URL` is always
supplied there and is used exactly as given.

The web branch needs a browser and is verified by the live check below rather
than by a unit test; the VM behaviour is asserted in `app_config_test.dart`.

### 8.3 Three controls, all labelled "सौंपा गया"

Found by screenshotting the real enquiry screen, not by any test. The section
heading, the "assign to me" button and the member dropdown were all reading
`enquiryAssignedTo` — three different controls with identical labels, one of
which was a heading and two of which were actions.

They now read `मुझे सौंपें` (assign to me), `जिम्मेदारी हटाएं` (remove
assignment) and `किसी सदस्य को सौंपें` (give it to a member). A widget test
asserting "the button exists" passes either way; the defect only exists on
screen, which is where it was found — the same lesson Phase 6's receipt taught.

### 8.4 A category label the server could not translate

Caught by writing the acknowledgement mail rather than by a test: the mail is
rendered by PHP and has no access to the ARB files. Rather than shipping codes
and fixing it later, `EnquiryCategory::label()` exists from the first commit —
see §6.

## 9. Tests and command results

| Gate | Result |
|---|---|
| `flutter pub get` | ✅ |
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 182 files changed |
| `flutter test` | ✅ **464** passed (+23) |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **504** passed (+54) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Phase 0–6 tests | ✅ pass unchanged |

New backend tests: `EnquirySubmissionTest` (19), `EnquiryInboxTest` (12),
`EnquiryPrivacyTest` (17), `EnquiryReferenceTest` (6).

New Flutter tests: `contact_screen_test.dart` (10),
`admin_enquiries_test.dart` (10), `error_code_mirror_test.dart` (2), plus the
config assertion and two more admin routes in the breadcrumb sweep.

### Live verification against the running API

**64 checks over two passes**, all passing. Every anti-spam layer was exercised
over real HTTP, including **waiting out the rate limit** rather than configuring
it away — a limit verified with the limit turned down is not the limit that
ships.

The first pass reported five failures. None was a product defect:

- three were `??` in the checking script, which cannot distinguish a null value
  from a missing key — so a correct `"reference": null` read as "absent". This
  is the same mistake Phase 6's live check made, which is why the second pass
  has an `isExplicitlyNull()` helper and uses it everywhere;
- two followed from the script assuming when the question would first be asked.
  The counters are per address and last an hour, so a second run starts where
  the first left off and a form that "should not" carry a question does. The
  second pass adapts instead — it answers whatever the server asks, which is
  what a browser does anyway.

The escalation was then observed working from a real starting state: the
question appeared, a wrong answer was refused, the right one was accepted, and
each accepted message got its own reference.

### Verified in a browser

The release bundle was served and driven through Chrome: the contact page, a
sign-in, the dashboard tile, the inbox with its per-status counts, and an
enquiry being assigned and unassigned. This is also where §8.2 and §8.3 were
confirmed — a sign-in on `127.0.0.1` now reaches `/admin` where it previously
failed with a 419.

## 10. Known issues and technical debt

- **No reply from inside the console.** Answering happens by telephone or
  e-mail; the devotee's preferred language is shown at the top of the enquiry.
  An outbound mail system with delivery tracking is its own phase, and a "send"
  button that silently fails is worse than no button.
- **Handing an enquiry to another member needs `users.view`.** The member list
  lives behind that permission, which `enquiries.manage` does not imply. A
  Content Manager can take a message and answer it; they cannot pass it on. An
  "assignable members" endpoint would fix this and is not in this phase's scope.
- **No retention or purge** of personal data — Phase 11.
- **No threading**: an enquiry is one message and a status.
- **No attachments**: unauthenticated upload is a different risk class from
  Phase 5's authenticated one, and nothing has asked for it.
- **The acknowledgement mail is untested against a real SMTP server** — the
  local mailer is `log`. What is asserted is that it is queued once per address,
  only when enabled, and carries none of the sender's words.
- **Spam counters live in the cache.** Losing them on a restart costs the temple
  nothing worse than a spammer getting a few more attempts before being asked to
  add up.

## 11. Next phase

**Phase 8 — Announcements & Notifications.** Planned but **not started**. Key
`announcements.manage` already exists in the matrix. It is the first phase that
sends anything outward on the temple's behalf, which makes delivery — and being
able to say what was sent and to whom — its shaping constraint, as spam
protection was for this one.
