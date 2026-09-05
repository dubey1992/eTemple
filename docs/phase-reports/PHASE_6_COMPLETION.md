# Phase 6 Completion Report — Donations & Receipts

**Date:** 2026-09-10
**Status: COMPLETE.** Every specified requirement is delivered, including the
one the rest of the phase is shaped around: nothing in the temple's books can be
quietly changed.

**Toolchain:** Flutter 3.47.0 / Dart 3.13.0 · PHP 8.3.33 · Composer 2.10.3 ·
Laravel 12.69.1 · PHPUnit 11.5.56 · MariaDB 12.3.3.

---

## 1. Implemented requirements checklist

| # | Phase 6 requirement | Status | Where |
|---|---|---|---|
| 1 | `donations` — `receipt_number`, `donor_name`, `amount`, `donation_date`, `payment_mode`, `reference_number`, `purpose`, `notes`, `status`, `recorded_by` | ✅ | `donations` table — §2 |
| 2 | `donation_settings` — public bank/UPI details | ✅ | `donation_settings` singleton — §2 |
| 3 | Admin donation endpoints + a receipt endpoint; printable/PDF receipt | ✅ | 11 endpoints — §3; the receipt — §5 |
| 4 | Amount > 0; receipt number unique **and immutable**; **no hard delete** (reversal records); donor privacy | ✅ | §4 |

---

## 2. Database changes

| Migration | Table |
|---|---|
| `2026_09_10_000000_create_donations_table` | `donations` — `receipt_number` (nullable, **unique**), donor fields, `amount_paise`, `donation_date`, `payment_mode`, `reference_number`, `purpose`, `notes`, `status`, the three audit pairs and `reversal_reason`; indexed on `(status, donation_date)`, `donation_date` and `payment_mode` |
| `2026_09_10_000001_create_donation_settings_table` | `donation_settings` — a singleton of UPI, bank, IFSC, `qr_url`, bilingual intro/note and `is_published` |

Verified on **MariaDB 12.3.3**: `migrate:fresh` (20) → `rollback` (18) →
`migrate` (18) → `db:seed`.

**Money is an integer number of paise, never a float** (`amount_paise`). A rupee
amount held as a float is exact for one value and inexact for a sum of them,
which is precisely the operation a treasurer cares about. Every total in this
phase, and every total Phase 9 builds on it, is exact addition. The column is
named for its unit because `amount` holding paise is a trap for the next person
to write a query.

---

## 3. API endpoints

| Method | Path | Ability |
|---|---|---|
| GET | `/api/public/donation-settings?lang=` | public |
| GET | `/api/admin/donations?status=&mode=&purpose=&from=&to=&q=&page=` | `donations.view` |
| GET | `/api/admin/donations/summary` | `donations.view` |
| GET | `/api/admin/donations/{id}` | `donations.view` |
| GET | `/api/admin/donations/{id}/receipt` | `donations.view` — HTML |
| POST | `/api/admin/donations` | `donations.manage` |
| PUT | `/api/admin/donations/{id}` | `donations.manage` |
| POST | `/api/admin/donations/{id}/confirm` | `donations.manage` |
| POST | `/api/admin/donations/{id}/reverse` | `donations.manage` |
| GET | `/api/admin/donation-settings` | `donations.view` |
| PUT | `/api/admin/donation-settings` | `donations.manage` |

Documented in `docs/api/openapi.yaml` (now **v0.7.0** — 47 paths, 37 schemas).

**There is no `DELETE`, anywhere in this phase.** Its absence is the rule.

`donations.view` and `donations.manage` were defined in Phase 2's catalogue and
labelled "available in phase 6"; this phase attached endpoints to keys the
committee could already grant.

---

## 4. The four rules, and how each is enforced

### An amount is more than zero, and is exact

Parsed from the string the treasurer typed — "501", "501.50", "1,25,500",
"₹501" — into integer paise in exactly one place. Anything not fully understood
is **refused rather than guessed at**: a misread amount is worse than one that
has to be typed again. A slipped decimal beyond a configurable ceiling is
refused too, because that is the error a treasurer actually makes.

### A receipt number is unique and immutable

Issued **on verification, not on entry** — the approved prototype's own words
are that a receipt follows verification. So a pending donation has no number,
and every number that exists corresponds to a receipt that was really given,
leaving no gaps for an auditor to ask about.

`RKT/2026-27/0001`: the Indian financial year, April to March, taken from the
**donation's own date** so confirming a March donation in April does not move it
into next year's book.

Uniqueness is guaranteed by the **unique index**, not by the application's
arithmetic. Two treasurers confirming at the same instant both read the same
highest sequence; only the database can stop them, and the generator retries
when it does. There is a test that asserts the database refuses a duplicate even
when the application asks for one.

### Nothing is deleted; reversal is the only undo

No delete endpoint exists at any status — a `DELETE` returns 405, and there is a
test that says so. Reversal keeps the row, keeps its receipt number, stops it
counting towards every total, and records who, when and **why**. The reason is
required because "why was five thousand rupees removed from the books" is the
first question an auditor asks, and the answer must not depend on somebody's
memory.

A **pending** donation can be reversed too: the record of a mistake is itself
worth keeping.

### Donor privacy

The strongest form available: **there is nowhere for the data to come out.** No
public donation list, no count, no total, no "our latest donor" — the entire
public surface of this phase is one endpoint that says where to send money, and
a test asserts that four plausible public donation paths all 404.

Reading the register needs `donations.view`; the Phase 2 matrix already gives a
Content Manager neither key, and a test asserts that is still true now there is
something to see.

---

## 5. Two decisions worth stating plainly

### The receipt is printed by the browser, not rendered to PDF on the server

The specification asks for a "printable/PDF receipt". The endpoint serves a
**print-optimised HTML document** that the committee opens and prints — to paper
or to PDF — from the browser.

The reason is Devanagari. A donor is `श्री रामप्रसाद यादव`, and rendering that
means reordering matras and forming conjuncts. `dompdf` and the FPDF family do
not shape complex scripts: they would print the letters in the wrong order, on a
receipt for money. Every browser ships a shaping engine and a PDF writer, and
the committee already has one open.

This does not make the site a Blade application — the public site and the admin
console remain entirely Flutter. The document is rendered by one PHP class with
a **single escaping choke point**, which is a smaller and more checkable surface
than a template where `{!! !!}` is one keystroke away. A test uploads a donor
name of `<script>alert(1)</script>` and asserts it comes back escaped.

A reversed donation prints as **CANCELLED**, in the largest type on the page.
Handing somebody a receipt for money that is no longer in the books, with
nothing to say so, is the one genuinely dangerous thing that file could do.

### Changing the bank details needs the money permission, not the content one

`PUT /api/admin/donation-settings` is gated on `donations.manage`. Changing the
published UPI id is the single most valuable attack on this site: a compromised
Content Manager account can rewrite the About page and must not be able to
redirect the temple's donations. There is a test that names exactly this.

---

## 6. Flutter surface

| Path | Screen |
|---|---|
| `/donate` | The prototype's `दान` section as its own page |
| `/admin/donations` | The register: totals, filters, search, pagination |
| `/admin/donations/new`, `/admin/donations/:id` | Record; and the page for one that exists |
| `/admin/donation-settings` | The published bank/UPI block |

The register's four figures across the top are **the server's**, computed over
every donation matching the filter. Adding up the rows in view would report the
total of one page as the total of everything, which for a temple's books is not
a rounding error but a wrong answer. The summary deliberately ignores the status
filter it sits beside, so the register never says "received: ₹0.00" to somebody
looking at the pending tab.

Recording and viewing are **one screen**, because a donation's own life decides
which it is: pending it is a form, receipted it is a document with a notes box.
The transition is visible rather than a navigation.

The donate block matches the approved design — the card, the dashed-gold bank
box, the QR panel — and each row carries a copy button, because the alternative
on a phone is transcribing an IFSC by eye and a mistyped account number is a
donation that goes somewhere else.

### Integration with the earlier phases

* The QR code is chosen with the Phase 5 `MediaPickerField`, and **the Phase 5
  deletion guard learned about `donation_settings.qr_url` in the same change** —
  a new referrer that does not register itself is a silent hole, and there is a
  test for it.
* The receipt opens through the Phase 5 `LinkOpener`.
* `दान / Donate` joins the seeded navigation, in the prototype's position.
* The home page gains the donate block between the events and the gallery,
  which is where the approved design puts it.
* Breadcrumbs cover all four new admin routes; the existing test that requires
  *every* admin route to produce a trail still passes.
* `ApiEnvelope` now carries the raw `meta` object, so an endpoint can send more
  than pagination — which is how the totals ride with the register.

---

## 7. Tests and command results

```
$ flutter analyze                                    No issues found!
$ dart format --output=none --set-exit-if-changed .  169 files, 0 changed
$ flutter test                                       441/441 passed
$ flutter build web --release                        Built build\web
$ ./vendor/bin/pint --test                           passed
$ php artisan test                                   450 passed (1592 assertions)
$ migrate → rollback → migrate → db:seed (MariaDB)   reversible
```

**Backend, 450 tests** (362 from Phases 0–5, 87 new here, and one added to
Phase 5's own suite for the QR in the deletion guard):

* `MoneyTest` (28) — parsing what a person types and refusing what it cannot
  read, Indian digit grouping, the exact decimal string, amount-in-words in
  lakh and crore, and a test that adds ten ten-paise amounts and gets exactly
  one rupee.
* `ReceiptNumberTest` (11) — the first number of a year, sequence, the April
  turnover, the year coming from the donation rather than from today, no reuse
  after a reversal, the string-sort trap at ten, idempotence per donation, and
  the database refusing a duplicate the application asked for.
* `DonationManagementTest` (32) — recording, the amounts accepted and refused,
  the cash exception to the reference rule, future and absurd dates, the
  lifecycle, the immutability rule and the notes exception, the absent delete,
  reversal and its required reason, the totals (including that they ignore the
  status filter and are not the total of one page), and the receipt document
  including its escaping, its CANCELLED stamp, and that it prints words
  rather than codes.
* `DonationPrivacyTest` (16) — four public paths that must 404, the public block
  carrying no donor, the unpublished and published-but-empty cases, and every
  endpoint against every refused role.

**All 362 Phase 0–5 tests pass unchanged.**

**Flutter, 441 tests** (394 + 47 new): the domain models and their defensive
parsing, the draft sending the amount as a string, `DonationQuery` value
equality, the formatting of every mode/purpose/status and of dates, the public
donate page in all four of its states, the register with its server totals and
filters and pager, the editor through record → confirm → lock → reverse → print,
the settings screen including the published-but-empty warning, the home block,
and one breadcrumb test.

### Live verification against the running API

**44 checks, all passing.** A donation was recorded, corrected, verified,
printed and reversed over HTTP; the receipt number was proved immutable by
attempting to change the amount after receipting (409) and confirming the number
was unchanged; `DELETE` was proved absent (405); the reversed receipt printed as
CANCELLED; and the published bank block was checked to carry no donor name, no
amount and no receipt number.

---

## 8. Defects found and fixed during the phase

| # | Defect | Fix |
|---|---|---|
| 1 | The reversal dialogue's `TextEditingController` was disposed the moment `showDialog` returned, while the field was still attached during the dismiss animation — Flutter asserts, and it cascaded into nine unrelated test failures | The controller is held for the life of the screen and disposed with the others |
| 2 | Two of my own `MoneyTest` expectations were wrong: 1,000,000,000 paise is ₹1,00,00,000 — one crore, not ten lakh | The code was right and the expectations were corrected |
| 3 | A live-check assertion used `??`, which cannot tell a null value from a missing key, and reported a correct empty state as a failure | The key is checked explicitly |
| 4 | **The printed receipt showed raw codes** — `festival`, `cash` — where a villager needs words. The Flutter client's translations cannot reach a document the server renders, and this was only visible in a screenshot of a real receipt | Bilingual labels live beside the codes on `PaymentMode` and `DonationPurpose`, and a test asserts the receipt carries `त्योहार` rather than `festival` |

---

## 9. Known issues and technical debt

1. **No online payment collection.** No gateway, no order/webhook flow. This
   phase records donations the temple has already received; taking card payments
   is a different product with PCI obligations and a merchant account.
2. **No 80G / PAN fields on the receipt.** Whether this temple is
   80G-registered is not something this project has been told, and inventing the
   fields would invite the committee to issue a receipt that claims something
   untrue.
3. **No server-side PDF** with an embedded Devanagari font and a shaping engine
   (§5). The browser route is correct today; a true PDF would let the receipt be
   e-mailed, which Phase 8 may want.
4. **No bank statement import or automatic matching.** Verification is a human
   decision.
5. **No CSV/Excel export** — Phase 10.
6. **`is_anonymous` is stored and respected by nothing yet.** It exists for the
   Phase 9 transparency figures, which are the first place a donor could be
   named publicly. Recorded rather than half-built.
7. **The audit trail is on the row, not in a log.** `recorded_by`,
   `confirmed_by` and `reversed_by` with their timestamps make the three events
   attributable; the general audit log is Phase 11.
8. Carried: two-factor authentication (Phase 2 §7); the build-time name in
   `web/index.html` and `manifest.json`; reorderable editors for the navigation
   menu, the committee and the media library; consent changes not audit-logged;
   no per-occurrence event overrides; videos linked rather than embedded; no
   cross-stack end-to-end test (Phase 12); pre-render tool not wired into CI.

---

## 10. Next phase

**Phase 7 — Devotee Contact & Enquiries.** Planned but **not started**. It is
the prototype's `संपर्क` section, and the first phase that accepts input from an
anonymous member of the public — which makes spam protection and rate limiting
its shaping constraint, as file validation was for Phase 5.
