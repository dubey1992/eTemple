# Phase 9 Plan — Accounts & Transparency

The phase that publishes what the temple did with the money.

Phase 6 recorded what came in and refused to show any of it publicly, saying
that aggregate transparency was Phase 9's problem "with its own consent
question". This is that phase, and the consent question is answered in N9.

Everything here is written before any code, per the execution contract.

## 1. Requirement review

From `docs/IMPLEMENTATION_PLAN.md`:

- [ ] `accounting_categories`, `transactions` (`type`, `category_id`, `amount`,
      `transaction_date`, `payment_mode`, `reference_number`, `description`,
      `attachment_url`, `approved_by`, `status`, `created_by`)
- [ ] Admin transaction + summary endpoints, `GET /api/public/transparency`
- [ ] Only approved data in public totals; attachments private; reversal
      preserves audit trail

Three requirements, and two of them are refusals. That is the shape of the
phase: the work is less about adding a ledger than about being certain that the
number the village reads is one the books can defend.

Global rules that bear on this phase specifically:

- money is exact (Phase 6 N1: integer paise, never a float);
- nothing sensitive is public without consent;
- uploads are validated on the server by their bytes, not by what the browser
  claims;
- authorization is the server's, whatever the client hides.

## 2. Assumptions and decisions

### N1 — Income is counted once, and double-counting is made impossible

This is the central hazard of the phase, and it is not a hypothetical.

Donations already exist. If a treasurer records a ₹5,000 donation in the
donation register (Phase 6) and *also* enters it as an income transaction here,
the published total says ₹10,000. The village would be told the temple received
twice what it received. No amount of care prevents this over years and changing
treasurers; it has to be structural.

So:

- **Donations are never re-entered as transactions.** The transparency figures
  read the donation register directly for donated income and the transactions
  table for everything else — hall hire, interest, the sale of old material.
- The reserved category code **`donation` is refused** on a hand-entered
  transaction, with a message saying donations are counted from the donation
  register. A rule that is only written in a manual is a rule that will be
  broken; this one is enforced by the API and asserted by a test.

The public response reports donated income and other income as **separate
lines**, so a reader can see which is which and the two can be checked against
their own sources.

### N2 — A transaction is pending until somebody approves it, and only approved money is counted

Statuses, mirroring the donation lifecycle so the console behaves consistently:

```
pending ──approve──▶ approved ──reverse──▶ reversed
   └──────────────reverse──────────────────▶
```

`pending` is recorded but not yet checked against the bill or the statement.
`approved` is checked, and is the **only** status that counts in any total —
public or admin. `reversed` counts in nothing and keeps its row.

The requirement says "only approved data in public totals". It is written more
strongly here: only approved data in *any* total. A treasurer's own screen
showing a different figure from the public page, with no label saying why, is
how a committee ends up quoting the wrong number in a meeting. Pending money is
shown as its own separate figure, named as not yet approved.

### N3 — Approval can require a second pair of hands, but does not by default

`accounts.require_second_approver`, default **false**.

Turned on, the person who recorded a transaction cannot be the person who
approves it. That is the standard control and several committees will want it.
It is off by default because this temple may have exactly one treasurer, and a
control that deadlocks the books on day one is a control nobody keeps — they
would share a login instead, which is worse than no control at all.

Both settings are tested.

### N4 — Approved is locked, and reversal is the only undo

Once approved, the figure has been counted in a published total. From that
moment only the `description` may be edited; the amount, date, category, type,
mode and reference are fixed. Anything else is refused with a message saying to
reverse and record again — exactly the rule a receipted donation follows
(Phase 6 N3), and for the same reason: the correction must leave a trace.

**There is no DELETE anywhere in this phase.** Reversal writes a reason, a time
and an actor onto the row and the row stays. "Where did that ₹40,000 expense
go?" must have an answer that does not depend on somebody's memory.

A category that has ever been used cannot be deleted either — it can be
deactivated, which hides it from the picker and leaves every historical
transaction still readable. A deleted category would turn old rows into
"expense: ₹12,000, category: —".

### N5 — Attachments are private, and are not URLs

The requirement says attachments are private. The specification's column is
named `attachment_url`, and it is implemented here as **`attachment_path` on a
private disk**.

That is a deliberate, documented deviation. A column called `_url` will
eventually be rendered as one — that is what the name invites — and a bill
photograph carries a shop's name, a telephone number and sometimes a signature.
The bills live on the `local` disk (`storage/app/private`), which is not
web-reachable, and are served only by

```
GET /api/admin/transactions/{id}/attachment
```

behind `accounts.view`, streaming the bytes. The path itself is never
serialized, not even to the committee; the resource carries `has_attachment`,
a file name and a size, and nothing a URL could be built from.

The Phase 5 media library is deliberately **not** reused: it writes to the
public disk and exists to publish photographs. A shop bill is the opposite kind
of object.

Validation follows Phase 5's rule — the MIME is detected from the bytes with
`finfo`, never from the browser's `Content-Type` or the file name. Accepted:
JPEG, PNG, WebP and PDF. PDF is added because that is what a bank sends. No
SVG, for the reason Phase 5 gives.

### N6 — The public page is aggregates only, and never individual rows

Transparency means the village can see what the temple received and what it
spent. It does not mean publishing a list of payments naming the shopkeeper who
was paid, the cheque number, and when.

So the public response carries **totals and category breakdowns for a period**,
and no individual transaction at any status. Category granularity — "निर्माण
कार्य ₹1,20,000" — answers the question a villager actually asks, and identifies
nobody.

### N7 — The committee decides when the books go public

`accounting_settings.is_published`, default **false**, exactly like the
donation settings row it sits beside.

A ledger publishes itself the moment the first transaction is saved only if
somebody designed it that way. Half-entered books are not transparency; they are
a misstatement with the temple's name on it. Until the committee turns this on,
`GET /api/public/transparency` reports that the temple has not published its
accounts — a clean, documented answer, not an error and not a page of zeros.

### N8 — An opening balance, or the published balance is a lie

The temple did not begin with an empty cash box on the day this software was
installed. Without an opening balance, "balance = received − spent" understates
what the temple holds by whatever was already there.

`opening_balance_paise` and `opening_balance_date` live on the settings row. The
published figure states the opening balance as its own line rather than folding
it silently into the total, so a reader can see the books start somewhere.

### N9 — No donor names are published, and why `is_anonymous` is not consent

`donations.is_anonymous` has been stored since Phase 6 and respected by nothing.
The Phase 8 report named this phase's shaping constraint as "what may be shown
about a named donor". The answer is: **nothing, yet.**

A donor board is a real and ordinary thing at a village temple, and the
committee may well want one. It cannot be built out of the flag we have:

- `is_anonymous` defaults to **false**. Every donation recorded so far was
  recorded under a rule that said no donor detail is ever public. Publishing all
  of them because a default said `false` would publish people who were never
  asked — a default is not consent, and it is precisely the pattern the
  project's own privacy rule forbids.
- The question that has to be asked at the counter is not "do you wish to be
  anonymous?" but "may we print your name on the temple's website?" Those are
  different questions and a devotee may answer them differently.

So Phase 9 publishes aggregates and no names. The test that matters asserts that
**no public transparency response contains a donor name at all**, anonymous or
otherwise. A donor roll is recorded as debt with its design sketched: an explicit
publication-consent field, asked when the donation is recorded, plus an
effective-from date so that switching the board on never retroactively publishes
somebody recorded before the temple started asking.

### N10 — The period is the Indian financial year

April to March, because that is the year the committee's own accounts, its
auditor and every form it files already use. `?year=2026` means FY 2026–27, and
the default is the financial year in progress.

Balances carry across years properly: the opening balance for a chosen year is
the settings row's opening balance plus everything approved before that year
began. It is computed, never stored, so a correction to an old transaction
cannot leave last year's closing and this year's opening disagreeing.

### N11 — Totals are computed by the database

Every figure is a `SUM` over a filtered query, never the addition of a page of
results — Phase 6 N14, restated because this is the phase where a page-shaped
total would be published to the village rather than shown to one treasurer.

Integer paise throughout, as everywhere else.

### N12 — Reading needs `accounts.view`; writing and approving need `accounts.manage`

Both keys already exist in the matrix and have been granted since Phase 2:
Treasurer holds both, Viewer holds `accounts.view`, and a Content Manager holds
neither — the specification says a Content Manager never sees financial detail.

The attachment endpoint sits behind `accounts.view` rather than `accounts.manage`:
a Viewer auditing the books needs to see the bill, which is the entire point of
attaching it.

### N13 — Bilingual categories, with the same Hindi fallback as everything else

Category names are stored `name_hi` / `name_en` independently and resolved
through `LocalizedText`, like every other pair of language columns in the
project. A category with no English name is served its Hindi with
`fallback_used: true`.

Descriptions on individual transactions are **not** bilingual: they are a
treasurer's working note about one payment, written once, and never published.

## 3. Database design

### `accounting_categories` (new)

| Column | Notes |
|---|---|
| `id` | |
| `code` | unique, slug; `donation` is reserved and refused on transactions (N1) |
| `type` | `income` or `expense`; a category belongs to one side of the books |
| `name_hi`, `name_en` | independent, Hindi required (N13) |
| `description_hi`, `description_en` | optional |
| `sort_order` | the order the picker offers them |
| `is_active` | deactivation instead of deletion (N4) |
| `created_by`, `updated_by` | `nullOnDelete` |
| timestamps | |

Index on `(type, is_active, sort_order)` — the shape of every picker query.

### `transactions` (new)

| Column | Notes |
|---|---|
| `id` | |
| `type` | `income` or `expense`; must match the category's type |
| `category_id` | `restrictOnDelete` — the database refuses what N4 refuses |
| `amount_paise` | unsigned big integer, exact (N11) |
| `transaction_date` | the day the money moved, not the day it was typed |
| `payment_mode` | reuses `App\Support\PaymentMode` from Phase 6 |
| `reference_number` | required for every mode but cash, as in Phase 6 |
| `description` | a working note, not published (N13) |
| `payee_name` | who was paid or who paid; **never public** (N6) |
| `attachment_path`, `attachment_name`, `attachment_size`, `attachment_mime` | private disk (N5) |
| `status` | `pending` / `approved` / `reversed` (N2) |
| `approved_at`, `approved_by` | |
| `reversed_at`, `reversed_by`, `reversal_reason` | reason required (N4) |
| `created_by`, `updated_by` | |
| timestamps | |

Indexes on `(status, transaction_date)`, `transaction_date`, `(type, status)`
and `category_id` — the four shapes the list, the summary and the transparency
query use.

### `accounting_settings` (new, singleton)

`is_published` (default false, N7), `opening_balance_paise`,
`opening_balance_date`, `intro_hi`/`intro_en`, `note_hi`/`note_en`,
`updated_by`, timestamps. Read through a service that guarantees one row, as
`site_settings`, `temple_profiles` and `donation_settings` already are.

### Seed

A default category set, clearly marked as seed data and safe to edit: income —
हॉल किराया, ब्याज, अन्य आय; expense — पूजा सामग्री, बिजली एवं पानी, रखरखाव एवं
मरम्मत, वेतन एवं मानदेय, भंडारा एवं प्रसाद, निर्माण कार्य, अन्य व्यय.

## 4. API surface

Public:

| Method | Path | Notes |
|---|---|---|
| GET | `/api/public/transparency` | aggregates only; `?year=`; reports "not published" when N7 is off |

Admin, all behind `auth:sanctum` + `active`:

| Method | Path | Permission |
|---|---|---|
| GET | `/api/admin/accounting-categories` | `accounts.view` |
| POST / PUT | `/api/admin/accounting-categories[/{id}]` | `accounts.manage` |
| GET | `/api/admin/transactions` | `accounts.view` |
| GET | `/api/admin/transactions/summary` | `accounts.view` |
| GET | `/api/admin/transactions/{id}` | `accounts.view` |
| GET | `/api/admin/transactions/{id}/attachment` | `accounts.view` (N5) |
| POST / PUT | `/api/admin/transactions[/{id}]` | `accounts.manage` |
| POST | `/api/admin/transactions/{id}/approve` | `accounts.manage` (N2, N3) |
| POST | `/api/admin/transactions/{id}/reverse` | `accounts.manage` (N4) |
| GET / PUT | `/api/admin/accounting-settings` | `accounts.view` / `accounts.manage` |

No `DELETE` on any of them.

Approve and reverse are separate endpoints rather than a `status` a `PUT` can
set, for the reason Phase 8 gives: an operation with its own consequences gets
its own URL, and `status` is not mass-assignable.

## 5. Flutter surface

- `/transparency` — the public page: the period, the opening balance, what came
  in (donations and other income as separate lines), what went out by category,
  the closing balance, and the date it was last updated. Linked from the donate
  page, because "where does my money go" is the question a donor is already
  asking on that screen.
- `/admin/accounts` — the register: filters by type, status, category and date;
  the running figures above it; pending money named as pending.
- `/admin/accounts/new`, `/admin/accounts/:id` — the editor and the detail view,
  with approve and reverse; reverse asks for its reason and says it cannot be
  undone.
- `/admin/accounting-categories` — the category list and editor.
- `/admin/accounting-settings` — the opening balance and the switch that
  publishes the books, with plain words about what turning it on does.

One new entry in `AdminDestinations`, which is now the only list (Phase 8 §9).

## 6. Implementation order

1. Migrations, models, factories, seed categories.
2. `Money`-based service layer: categories, transactions, approval, reversal.
3. The transparency service — the only place the public figures are computed.
4. Requests, resources, controllers, routes.
5. Backend tests: lifecycle, authorization, privacy, the arithmetic.
6. Flutter domain, repository, providers.
7. Flutter screens, ARB entries for both languages.
8. Flutter tests.
9. Gates, live verification against the running API, browser showcase.
10. OpenAPI, `.env.example`, deployment checklist, completion report.

## 7. Delivery gate

`flutter pub get` · `flutter analyze` · `dart format --set-exit-if-changed` ·
`flutter test` · `flutter build web --release` · `pint --test` ·
`php artisan test` · migrate → rollback → migrate on MariaDB · live checks
through the running API · the app driven in a real browser.

Phases 0–8 must pass unchanged.

## 8. Explicitly out of scope

- **A donor roll** (N9) — needs a publication-consent field and an effective-from
  date, neither of which exists.
- **CSV/PDF/Excel export** — Phase 10, which is the reporting phase.
- **Audit logging** of these approvals and reversals — Phase 11. The columns on
  the row record who and when; the separate append-only log is that phase's.
- **Budgets, forecasts, per-project accounting, double-entry** — not asked for,
  and a village temple's books do not need a general ledger.
- **Bank statement import or reconciliation.**
- **Automatic posting of donations into the ledger** — see N1; they are read
  from their own register instead.
