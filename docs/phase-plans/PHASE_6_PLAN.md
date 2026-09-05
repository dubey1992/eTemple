# Phase 6 Plan — Donations & Receipts

**Written before code**, per the working agreement. Assumptions are numbered
`N1…N14`.

---

## 1. Requirement review

From `IMPLEMENTATION_PLAN.md` (spec Phase 6):

| # | Requirement |
|---|---|
| 1 | `donations` — `receipt_number`, `donor_name`, `amount`, `donation_date`, `payment_mode`, `reference_number`, `purpose`, `notes`, `status`, `recorded_by` |
| 2 | `donation_settings` — public bank/UPI details |
| 3 | Admin donation endpoints + a receipt endpoint; printable/PDF receipt |
| 4 | Rules: amount > 0; receipt number unique **and immutable**; **no hard delete** (reversal records); donor privacy |

This is the first phase that handles money, and the first whose records an
outside auditor may one day read. Three of the four requirements are about
**not being able to change history**, which is what shapes every decision below.

The approved prototype's `दान` section is the public half: a card explaining the
arrangement, a box of UPI/bank details, a QR code, and a footnote saying the
demo values will be replaced with real ones.

---

## 2. Assumptions and decisions

### N1 — Money is stored as integer paise, never as a float

`amount_paise`, an unsigned big integer. Not a float, and not a `DECIMAL` read
back into PHP arithmetic.

A rupee amount in a float is exact until it is summed; then ₹1,25,500.00 quietly
becomes ₹1,25,499.99 and a treasurer loses an afternoon. Integers cannot do
that. Every total in this phase — and every total Phase 9 builds on it — is
exact addition.

The API sends both `amount_paise` (the authority) and `amount_formatted` (what a
person reads), so no client ever has to divide.

The column is named for its unit on purpose. `amount` holding paise is a trap
for the next person to write a query.

### N2 — A receipt number is issued on **confirmation**, not on entry

The prototype's own words: *"सत्यापन के बाद डिजिटल रसीद उपलब्ध कराई जाएगी"* — a
receipt is issued after verification. That is a real process, and the schema
follows it:

* `pending` — recorded, not yet matched against the bank statement or the cash
  box. **No receipt number.**
* `confirmed` — verified. A receipt number is assigned, once, and never changes.
* `reversed` — cancelled after confirmation. **Keeps its receipt number.**

Issuing numbers at entry would burn them on mistakes and produce gaps an auditor
has to ask about. Issuing at confirmation means every number that exists
corresponds to a receipt that was really given.

Format: `RKT/2026-27/0001` — the Indian financial year (April–March), because
that is the year a temple's books are kept in, and a four-digit sequence within
it. Uniqueness is enforced by a database unique index, not only by the
application: two treasurers confirming at the same moment must not be able to
produce the same number.

### N3 — A confirmed donation is immutable except for its notes

Once a receipt exists on paper or in a devotee's hand, changing the amount, the
date, the payer or the mode in the database makes the two disagree. So after
confirmation only `notes` may be edited.

To correct anything else: **reverse and record again**. That is how a receipt
book works, and it leaves both the mistake and the correction visible.

### N4 — Nothing is ever deleted; reversal is the only undo

There is no `DELETE /donations/{id}`, at any status. A pending entry that was
never real can be reversed too — the record of the mistake is itself worth
keeping.

Reversal writes `status = reversed`, `reversed_at`, `reversed_by` and a
**required** `reversal_reason` onto the row. The reason is required because "why
was ₹5,000 removed from the books" is the first question an auditor asks, and
the answer must not depend on somebody's memory.

A reversed donation is excluded from every total and stays in every list,
flagged.

Kept on the row rather than in a second table: one donation has at most one
reversal, and it is not itself a transaction — it is a fact about that donation.
A separate table would be a join for no extra truth.

### N5 — Donor detail is never public, in any aggregate, at any status

There is **no public donations endpoint at all**. Not a list, not a count, not a
total, not "our latest donor". The only public thing this phase adds is
`donation_settings` — where to send money.

Phase 9 publishes aggregate income and expenditure. That is a different
requirement with a different consent question, and it is deliberately not
anticipated here.

Reading donations needs `donations.view`; recording, confirming and reversing
need `donations.manage`. The Phase 2 matrix already gives a Content Manager
**neither**, which is exactly right and is asserted by a test.

### N6 — Changing the published bank details needs `donations.manage`, not `content.manage`

The single most valuable attack on this site is changing the UPI id devotees pay
into. That control therefore sits behind the money permission, not the content
one — a compromised Content Manager account can rewrite the About page but
cannot redirect the temple's donations.

### N7 — Only what the committee marks published is published

`donation_settings.is_published` gates the whole block, and each detail is
optional. An unconfigured site shows the prototype's card with an empty state,
never invented bank details.

The account number is stored **exactly as the committee types it**. The
prototype masks it (`XXXX XXXX 1234`); whether to mask, and how, is the
committee's decision and their bank's policy, not ours to guess. The field is
labelled to say so.

### N8 — Payment mode and purpose are code catalogues

`payment_mode`: `cash`, `upi`, `bank_transfer`, `cheque`, `card`, `other`.
`purpose`: `general`, `puja`, `maintenance`, `festival`, `annadan`,
`construction`, `other`.

Code-defined like `EventType` and `MediaType`: the labels are translated in the
client, so adding one is a constant and two ARB entries rather than a migration.
Purposes as codes rather than free text is what makes the Phase 10 report
possible; the free text goes in `notes`.

### N9 — A non-cash donation must carry its reference

`reference_number` is required for every mode except `cash` — a UPI reference, a
cheque number, an NEFT/UTR. Without it a bank entry cannot be matched to a
donation, which is the entire point of the `pending → confirmed` step. Enforced
in the form request **and** in the service.

`donation_date` cannot be in the future, and cannot be more than
`donations.backdate_limit_days` (default 366) in the past — a typo of `2025` for
`2026` is otherwise silent.

### N10 — The receipt is printed by the browser, not rendered to PDF on the server

The specification asks for a "printable/PDF receipt". This phase serves a
**print-optimised HTML receipt** from the API, which the committee opens and
prints — to paper or to PDF — from the browser.

The reason is Devanagari. A donor's name is `श्री रामप्रसाद यादव`, and rendering
that correctly means reordering matras and forming conjuncts. `dompdf` and the
FPDF family do not shape complex scripts; they would emit a receipt with the
letters in the wrong order, and it would be a receipt for money. Every browser
ships a shaping engine and a PDF writer, and the committee already has one open.

This does **not** make the site a Blade application: the public site and the
admin console stay entirely Flutter. One Blade template renders one document,
escaping the donor's name by default — which is why it is Blade and not string
concatenation. The Flutter detail screen opens it in a new tab through the
`LinkOpener` written in Phase 5.

A true server-side PDF, with an embedded Devanagari font and a shaping engine,
is recorded as debt rather than half-built.

### N11 — Donor contact detail is minimal and gated

`donor_phone` and `donor_address` are optional, because a real receipt carries
them and the committee's paper book already does. There is no e-mail and no PAN:
PAN belongs to an 80G receipt, and whether this temple is 80G-registered is not
something this project has been told. Recorded as out of scope rather than
guessed at.

Every one of these fields is behind `donations.view`. None reaches any public
endpoint.

### N12 — Who did what is recorded on the row; the audit log is Phase 11

`recorded_by`, `confirmed_by`, `reversed_by` and their timestamps are columns
here, so the three events that matter are always attributable even before the
audit log exists. Phase 11 adds the general log; this phase does not pretend to.

### N13 — The QR code comes from the media library

`qr_url` is filled by the Phase 5 `MediaPickerField`, like the temple logo, a
member's photograph and an event poster — and **the Phase 5 deletion guard
learns about it in the same change**, so a QR code in use cannot be deleted out
from under the donation page. That guard is only as good as its list of
referrers, and a new referrer that does not register itself is a silent hole.

### N14 — Totals are computed in SQL over confirmed rows only

The admin list carries a summary — count and total for the current filter —
computed by the database with `SUM(amount_paise) WHERE status = 'confirmed'`.
Never by adding up a page of results in Dart, which would silently report the
total of one page as the total of everything.

---

## 3. Database design

### `donations` (new)

| Column | Type | Notes |
|---|---|---|
| `id` | id | |
| `receipt_number` | string(40), nullable, **unique** | Null until confirmed (N2) |
| `donor_name` | string(200) | Required — a receipt needs a payee |
| `donor_phone` | string(20), nullable | Never public (N11) |
| `donor_address` | string(500), nullable | Never public |
| `is_anonymous` | boolean, default false | The donor asked not to be named in any future listing; the receipt still names them |
| `amount_paise` | unsigned big integer | > 0 (N1) |
| `donation_date` | date | Not future, not absurdly past (N9) |
| `payment_mode` | string(30) | N8 |
| `reference_number` | string(100), nullable | Required unless cash (N9) |
| `purpose` | string(30), default `general` | N8 |
| `notes` | text, nullable | The only field editable after confirmation |
| `status` | string(20), default `pending` | `pending` \| `confirmed` \| `reversed` |
| `confirmed_at` / `confirmed_by` | timestamp / fk users nullOnDelete | |
| `reversed_at` / `reversed_by` | timestamp / fk users nullOnDelete | |
| `reversal_reason` | string(500), nullable | Required when reversing (N4) |
| `recorded_by` / `updated_by` | fk users nullOnDelete | |

Indexes: `(status, donation_date)` for the list and its totals,
`donation_date`, `payment_mode`, and the unique index on `receipt_number`.

### `donation_settings` (new, singleton)

| Column | Type |
|---|---|
| `upi_id`, `bank_name`, `account_name`, `account_number`, `ifsc` | string, nullable |
| `qr_url` | string(500), nullable — from the media library (N13) |
| `intro_hi` / `intro_en`, `note_hi` / `note_en` | text, nullable |
| `is_published` | boolean, default false (N7) |
| `updated_by` | fk users nullOnDelete |

Read through a service so exactly one row exists, like `site_settings` and
`temple_profiles`.

---

## 4. API surface

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/donation-settings?lang=` | public |
| GET | `/api/admin/donations?status=&mode=&purpose=&from=&to=&q=&page=` | `donations.view` |
| GET | `/api/admin/donations/{id}` | `donations.view` |
| GET | `/api/admin/donations/{id}/receipt` | `donations.view` — print-ready HTML |
| GET | `/api/admin/donations/summary?from=&to=` | `donations.view` |
| POST | `/api/admin/donations` | `donations.manage` |
| PUT | `/api/admin/donations/{id}` | `donations.manage` — refuses everything but `notes` once confirmed |
| POST | `/api/admin/donations/{id}/confirm` | `donations.manage` |
| POST | `/api/admin/donations/{id}/reverse` | `donations.manage` |
| GET | `/api/admin/donation-settings` | `donations.view` |
| PUT | `/api/admin/donation-settings` | `donations.manage` (N6) |

**No `DELETE`, anywhere.** Its absence is the rule (N4).

---

## 5. Flutter surface

| Path | Screen |
|---|---|
| `/donate` | The prototype's `दान` section as its own page |
| `/admin/donations` | List, filters, running totals |
| `/admin/donations/new`, `/admin/donations/:id` | Record; detail with confirm, reverse and print |
| `/admin/donation-settings` | The published bank/UPI block |

Plus: the donate block on the home page in the prototype's position (after the
events, before the gallery), a `दान / Donate` navigation item, a dashboard tile
gated on `donations.view`, and breadcrumbs for every new admin route.

---

## 6. Implementation order

1. Migrations, models, factories, the two code catalogues.
2. `ReceiptNumberGenerator` — the unique/immutable rule, tested against
   concurrency before anything depends on it.
3. `DonationService` — record, confirm, reverse, the immutability rule, totals.
4. `DonationSettingService`.
5. Requests, resources, controllers, routes; the receipt template.
6. Backend tests: the money rules, the reversal, authorization, privacy.
7. Flutter domain, repository, providers.
8. Public donate page and home block; admin list, editor, detail, settings.
9. Wire the QR into the Phase 5 picker **and its deletion guard**.
10. l10n, seeder, OpenAPI, docs.
11. Gate.

---

## 7. Delivery gate

`flutter pub get` · `flutter analyze` · `dart format --set-exit-if-changed` ·
`flutter test` · `flutter build web --release` · `pint --test` ·
`php artisan test` · migrate → rollback → migrate → seed on MariaDB ·
all Phase 0–5 tests unchanged · a donation recorded, confirmed, printed and
reversed through the **running API**, with the receipt number proved immutable.

---

## 8. Explicitly out of scope

* **Online payment collection.** No gateway, no order/webhook flow. This phase
  records donations the temple has already received; taking card payments is a
  different product with PCI obligations and a merchant account.
* **80G / PAN fields on the receipt** — the temple's registration status is not
  something this project has been told (N11).
* **Server-side PDF generation** with an embedded Devanagari font (N10).
* **Public donor lists or leaderboards** (N5).
* **Bank statement import and automatic matching.** Confirmation is a human
  decision here.
* **Aggregate transparency figures** — Phase 9.
* Recurring or pledged donations, and receipts issued in bulk.
