# Phase 7 Plan — Devotee Contact & Enquiries

Approved to start: 2026-09-11.

This is the prototype's `संपर्क` section. It is also the first phase in which
the temple's database is written to by somebody who is not a committee member
and has not signed in. That single fact shapes every decision below.

## 1. Requirement review

From `IMPLEMENTATION_PLAN.md`:

- `enquiries` (`name`, `mobile`, `email`, `category`, `message`,
  `preferred_language`, `status`, `assigned_to`, `resolved_at`)
- `POST /api/public/enquiries`, admin inbox + status endpoints
- Spam protection, rate limiting, CAPTCHA-after-threshold, optional
  acknowledgement email
- Enquiry content never displayed publicly

Global rules that bite hardest here:

- *"Rate-limit login/password-reset and abuse-prone public forms."* This is the
  abuse-prone public form.
- *"Sensitive donor, enquiry and committee-member data must not be exposed
  publicly without permission/consent."* Enquiry is named explicitly.
- *"API validation and authorization are mandatory even when Flutter
  validates/hides controls."*
- Loading / success / empty / error / unauthorized states on every API-driven
  screen; Hindi default with English secondary.

## 2. Assumptions and decisions

### N1 — An enquiry is never readable in public, at any status

There is no public `GET` for an enquiry, no list, no count, and no "recent
questions" block. The one public write returns a **reference number and nothing
else** — not the stored row. Echoing the submission back would turn the endpoint
into a reflector: anybody could POST a payload and have the server serve it back,
which is how a contact form becomes a delivery van for somebody else's content.

This mirrors Phase 6's donor-privacy stance (`PHASE_6_PLAN` N5): the protection
is that there is nowhere for the data to come out, not that a serializer
remembers to hide it.

### N2 — Spam protection is four layers, and none of them is a third-party CAPTCHA

Google reCAPTCHA and hCaptcha would each mean every villager who opens the
temple's contact page is fingerprinted by a third party, and both need keys this
project has not been given. For a village temple that trade is not worth making,
so all four layers are served by our own server:

1. **Rate limit by IP** — `enquiry-submit`, tighter than the general public
   limit, with a daily cap on top of the per-minute one.
2. **Honeypot** — a field a human never sees and never fills. Non-empty means a
   bot, and the response is the *success* shape: telling a bot it was detected
   is free tuning feedback for whoever wrote it. Nothing is stored.
3. **Form token with a time window** — `GET /api/public/enquiry-form` issues an
   HMAC-signed token stamped with its issue time. A submission that arrives
   faster than a human could type, or on a token older than the window, is
   refused. This is what stops a script POSTing straight at the endpoint.
4. **Challenge after a threshold** — once an IP has submitted more than the
   threshold within the window, the next form it is issued carries a small
   bilingual arithmetic question, verified server-side. The expected answer
   never leaves the server in readable form: the token carries a hash of it.

Layer 4 is the spec's "CAPTCHA-after-threshold". The threshold is evaluated
again when the submission arrives, so fetching a clean token before starting to
abuse the form buys nothing.

### N3 — The acknowledgement e-mail must not become a weapon

An anonymous form plus an e-mail field is an open relay for harassment: the
attacker types the victim's address and our server sends the mail. So:

- It is **off unless configured** (`ENQUIRY_ACKNOWLEDGEMENT_ENABLED`), which is
  how "optional acknowledgement email" in the spec is read.
- It is sent **at most once per address per hour**.
- It carries **no visitor-supplied text at all** — not even the sender's name.
  Reference number, category label, and the temple's own contact details. A mail
  that quoted the message body would let an attacker put arbitrary words into a
  message arriving from the temple's own address.
- It is **queued**, so a slow or dead SMTP server cannot hold a public request
  open — the one place where a public endpoint could be made to hang.

### N4 — Category is a code catalogue with server-side labels

Like `PaymentMode` and `DonationPurpose`: codes in the column, labels beside
them. Adding one is a constant and two ARB entries, not a migration.

The labels are bilingual and live on the server as well as in the ARB files,
because the acknowledgement e-mail is rendered by the **server** and cannot
reach Flutter's translations. That is the defect Phase 6 shipped and caught only
by screenshotting a real receipt (`PHASE_6_COMPLETION` §8.4); this phase pays it
up front rather than rediscovering it.

### N5 — `preferred_language` is an instruction to the committee

It is not a display preference — the visitor has already chosen the interface
language. It records *which language the devotee wants to be answered in*, which
for Amarpur Pankhoriya is usually Hindi and occasionally English, and it shows in
the inbox beside the message so whoever replies knows before they start.

It defaults to the language the form was submitted in.

### N6 — At least one way to reply is mandatory

Name and message are required. Mobile and e-mail are individually optional but
**at least one is required**, enforced on the server. An enquiry nobody can
answer is not an enquiry; it is a note the committee can only stare at.

### N7 — Status is `new → in_progress → resolved`, with `spam` to the side

`resolved_at` is stamped on entering `resolved` and cleared if the enquiry is
reopened, so the column always means "when this was actually closed" rather than
"when it was last touched". `spam` is terminal and hides the row from the default
inbox view without destroying it.

### N8 — Nothing is deleted in this phase

Same reasoning as Phase 6: there is no `DELETE` endpoint. A complaint that can be
deleted by whoever it is about is not a complaint system. `spam` is how noise
gets out of the way, and it keeps the row.

Personal data does not belong in a database forever, so a retention policy and a
purge are real work — they are Phase 11's, recorded as debt rather than
half-built here.

### N9 — Reading the inbox needs `enquiries.manage`; there is no view-only tier

A Viewer can see the calendar, the committee and the donation totals. A Viewer
cannot read a villager's phone number and their complaint. There is deliberately
no `enquiries.view` key: read and write are the same right here, because the
sensitive act is *reading*.

### N10 — The submitter's IP is stored hashed, never in the clear

Abuse handling needs to know that thirty enquiries came from one place. It does
not need to know where that place is. The column holds an HMAC of the address
keyed by `APP_KEY`, which correlates within this installation and identifies
nobody outside it.

### N11 — `assigned_to` must be somebody who can act on it

Assignment is validated server-side against active users who hold
`enquiries.manage`. Assigning an enquiry to a Treasurer who cannot open the inbox
is a silent black hole.

### N12 — The message is length-capped, and the cap is enforced on the server

20 to 2000 characters. A public endpoint with an unbounded text column is a disk
filler.

### N13 — The public page mirrors the donate pattern

The home page keeps its `पता एवं संपर्क` band and gains a button into a full
`/contact` page carrying the address and the form — the shape Phase 6 gave
`/donate`. The navigation menu gains `संपर्क`, seeded like the others.

## 3. Database design

### `enquiries` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `reference` | string(24), unique | `RKT/E/2026-27/0001`, shown to the visitor |
| `name` | string(120) | |
| `mobile` | string(20), nullable | one of mobile/e-mail required (N6) |
| `email` | string(190), nullable | |
| `category` | string(40), indexed | code catalogue (N4) |
| `message` | text | 20–2000 chars, enforced in the request |
| `preferred_language` | string(5) | `hi` / `en` (N5) |
| `status` | string(20) | `new` / `in_progress` / `resolved` / `spam` |
| `assigned_to` | FK users, nullable, null on delete | N11 |
| `resolved_at` | timestamp, nullable | N7 |
| `resolved_by` | FK users, nullable, null on delete | who closed it |
| `submitted_ip_hash` | string(64), indexed, nullable | N10 |
| `submitted_user_agent` | string(255), nullable | truncated |
| `acknowledged_at` | timestamp, nullable | when the ack mail was queued |
| timestamps | | |

Indexes: `(status, created_at)` for the inbox's default ordering, `category`,
`submitted_ip_hash`.

## 4. API surface

| Method | Path | Guard |
|---|---|---|
| GET | `/api/public/enquiry-form` | public, `throttle:api` |
| POST | `/api/public/enquiries` | public, `throttle:enquiry-submit` |
| GET | `/api/admin/enquiries` | `enquiries.manage` |
| GET | `/api/admin/enquiries/summary` | `enquiries.manage` |
| GET | `/api/admin/enquiries/{id}` | `enquiries.manage` |
| PUT | `/api/admin/enquiries/{id}/status` | `enquiries.manage` |

No public GET of an enquiry. No DELETE anywhere.

## 5. Flutter surface

- `/contact` — address + the form. Success replaces the form with the reference
  number; the challenge appears only when the server says it is required.
- `/admin/enquiries` — the inbox: status and category filters, newest first,
  paginated, with the count per status.
- `/admin/enquiries/:id` — the enquiry, its reply channel, and the status and
  assignment controls.
- A dashboard tile, breadcrumbs for both admin routes, and `संपर्क` in the seeded
  navigation.

## 6. Implementation order

1. Migration, model, factory, category catalogue, config.
2. Form-token and spam services, with unit tests, before any controller exists.
3. `EnquiryService`, request classes, controllers, resources, routes.
4. Backend tests: submission, refusals, privacy, authorization, inbox.
5. Flutter domain, repository, providers.
6. `/contact`, then the admin inbox and detail screens.
7. Wiring: routes, breadcrumbs, dashboard tile, nav seed, home button.
8. Gate, live verification through the running API, docs.

## 7. Delivery gate

`flutter pub get` · `flutter analyze` · `dart format --set-exit-if-changed` ·
`flutter test` · `flutter build web --release` · `pint --test` ·
`php artisan test` · migrate → rollback → migrate → seed on MariaDB ·
live checks through the running API · every earlier phase's tests unchanged.

## 8. Defects carried into this phase

Found while verifying login at the end of Phase 6, fixed here rather than left
in the tree:

- **D1 — the app's dev API origin is a fixed hostname.** `API_BASE_URL` defaults
  to `http://localhost:8000/api`. Open the app on `127.0.0.1:5000` and the
  `XSRF-TOKEN` cookie is written against host `localhost`, is invisible to
  `document.cookie` on `127.0.0.1`, and every sign-in fails with a 419 reported
  as "session expired". Cookies are keyed by host, and `localhost` and
  `127.0.0.1` are two hosts.

Any further defects found during the phase are recorded in the completion
report.

## 9. Explicitly out of scope

- Replying to an enquiry from inside the admin console (an outbound mail system
  with delivery tracking is its own phase; Phase 8 brings notifications).
- Retention and purge of personal data — Phase 11.
- Threaded conversations; an enquiry is one message and a status.
- Attachments on an enquiry: unauthenticated upload is a different risk class
  from Phase 5's authenticated one, and nothing has asked for it.
