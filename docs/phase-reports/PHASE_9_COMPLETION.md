# Phase 9 Completion Report — Accounts & Transparency

**Status: COMPLETE** · 2026-09-13

The phase that publishes what the temple did with the money.

Its three requirements are one feature and two refusals, and the refusals are
the harder half: the ledger is ordinary bookkeeping, but a number published in
the temple's name has to be one the books can defend, and a page that opens the
accounts must not open the people in them.

## 1. Implemented requirements checklist

| Requirement | Where |
|---|---|
| `accounting_categories`, `transactions` with the specified columns | §2 — plus an `accounting_settings` singleton (§6) |
| Admin transaction + summary endpoints | `Admin\TransactionController` — seven verbs, six URLs |
| `GET /api/public/transparency` | aggregates only — §5 |
| **Only approved data in public totals** | §4 — and in *every* total, not only the public ones |
| **Attachments private** | §7 — a private disk and an authenticated endpoint, not a URL |
| **Reversal preserves audit trail** | §8 — no DELETE anywhere; reason required |

## 2. Database changes

Three new tables. Two things about them are worth reading twice:

- **`transactions.amount_paise` is an integer**, as every amount in this project
  has been since Phase 6. A rupee figure that is exact until it is summed is not
  exact, and summing is the whole operation here.
- **A category belongs to one side of the books.** "Maintenance" as both an
  income and an expense heading would make a breakdown ambiguous, and the one
  question the public page must answer without ambiguity is which way the money
  went. The type is denormalised onto each transaction and the service refuses
  a disagreement.

`category_id` is `restrictOnDelete`, so the database refuses what the service
refuses (§9).

Verified reversible on MariaDB 12.3.3 — migrate → rollback → migrate → seed.

### A deliberate deviation from the specification

The spec's column is **`attachment_url`**; it is implemented as
**`attachment_path`**, and the rename is the point. A column called `_url` is
eventually rendered as one — that is what the name invites — and these files are
shop bills carrying a trader's name, a telephone number and sometimes a
signature. See §7.

## 3. Income is counted once, and double-counting is made impossible

This is the phase's central hazard and it is not hypothetical. Donations already
exist. If a treasurer records a ₹5,000 donation in the register **and** enters it
as income here, the published total says ₹10,000 — the village told the temple
received twice what it received. Over years and changing treasurers, care does
not prevent this. It has to be structural.

So:

- **Donations are never re-entered.** The transparency figures read the donation
  register for donated income and the ledger for everything else — hall hire,
  interest, grants.
- **The category code `donation` is reserved** and refused on a hand-entered
  transaction, with a message saying where donations are counted instead. A rule
  written only in a manual is a rule the third treasurer breaks.
- The two are reported as **separate lines**, so a reader can see which is which
  and check each against its own source.

The same fact reaches the console: the ledger's own figures exclude donations,
so the screen says so beneath them (§10.1).

## 4. Only approved money counts — everywhere

```
pending ──approve──▶ approved ──reverse──▶ reversed
   └──────────────reverse──────────────────▶
```

The requirement says "only approved data in public totals". It is written more
strongly here: **only approved data in any total**. A treasurer's screen showing
a different figure from the public page, with no label saying why, is how a
committee ends up quoting the wrong number in a meeting.

Pending money is shown as its own figure, named as pending, in the console and
nowhere at all on the public page.

**Approval is the point of no return.** From it the figure is in a total the
village reads, and only the `description` may change — the amount, date,
category, type, mode and reference are fixed. Anything else is a 409 whose
message says what to do instead: reverse it and record it again.

## 5. The public page is aggregates, and no names

Transparency means the village can see what the temple received and spent. It
does not mean publishing a list of payments naming the shopkeeper who was paid,
the cheque number and the date.

So the response carries **category totals for a financial year and no individual
transaction at any status**. There is a test that puts a payee, a reference and a
description into the database and asserts none of them appears in the public
JSON, and the live pass repeats it against the running server.

### The consent question, answered

The Phase 8 report named this phase's shaping constraint as "what may be shown
about a named donor". The answer is: **nothing, yet.**

A donor board is a real and ordinary thing at a village temple, and the committee
may well want one. It cannot be built out of the flag that exists:

- `donations.is_anonymous` defaults to **false**. Every donation recorded so far
  was recorded under a rule that said no donor detail is ever public. Publishing
  all of them because a default said `false` would publish people who were never
  asked — and a default is not consent.
- The question that has to be asked at the counter is not "do you wish to be
  anonymous?" but "may we print your name on the temple's website?" Those are
  different questions and a devotee may answer them differently.

So Phase 9 publishes aggregates and no names, and the test that matters asserts
that **no public response contains a donor name at all** — anonymous or not. The
donor roll is recorded as debt with its design sketched (§12).

## 6. The committee decides when the books go public

`accounting_settings.is_published`, default **false**, beside the donation
settings row it resembles.

Until it is turned on, `GET /api/public/transparency` reports that the temple has
not published its accounts — **with no summary block at all, not a set of
zeros**. Zeros would read as "the temple received nothing", which is a false
statement about somebody's finances rather than a missing feature.

**An opening balance sits here too.** The temple did not begin with an empty cash
box on the day this software was installed; without one, the published balance
understates what the temple holds by exactly whatever was already there. It is
shown as its own line rather than folded into a total, and it may be negative — a
temple that begins in deficit should be able to say so.

## 7. The bill is private, and there is no URL to it

Bills live on the `local` disk (`storage/app/private`), which is not
web-reachable, and are served only by

```
GET /api/admin/transactions/{id}/attachment
```

behind **`accounts.view`** — not `accounts.manage`, deliberately: a Viewer
auditing the books needs to see the evidence, which is the entire reason for
attaching it.

The stored path is **never serialized** — not to a Viewer, not to a Treasurer,
not to the Super Admin. The resource carries `has_attachment`, a display name and
a size, and nothing a client could turn into a URL, leak in a screenshot, or
leave in a browser history.

The type is decided by **reading the bytes** with `finfo`, never by the file name
or the browser's `Content-Type` — Phase 5's rule. JPEG, PNG, WebP and PDF; PDF
because that is what a bank sends, and no SVG because it is a script container.
The stored file name is generated, and the uploader's is kept in its own column
with its separators stripped.

Phase 5's media library is deliberately **not** reused: it writes to the public
disk and exists to publish photographs. A shop bill is the opposite kind of
object.

Served as `Content-Disposition: attachment` with `X-Content-Type-Options:
nosniff`, so nothing that got past the byte check can execute in the admin
session's origin.

## 8. Nothing is deleted

No `DELETE` on a transaction at any status. Reversal writes a reason, a time and
an actor onto the row, and the row stays — with its bill. "Where did that ₹45,000
go?" must have an answer that does not depend on somebody's memory.

The reason is **required and has no default**: it is the entire explanation of
why a figure that was once counted no longer is, and a default would put the same
sentence on every reversal in the temple's history. The dialogue's confirm button
stays dead until something is written.

## 9. A heading that has been used cannot be rewritten

The one `DELETE` in Phases 6–9 is on an **unused** category, and it is narrow: a
heading nothing is filed under is a mistyped heading, not history.

A used one is refused with a message naming the count and offering deactivation
instead — which stops it being offered on new entries and leaves every old one
still readable. **Its type is locked too**: flipping a heading from expense to
income would move every historical entry to the other side of the books,
silently, in figures the village has already read.

The console shows the same rule rather than producing it as a surprise: a used
heading has no delete button at all, and its type dropdown is disabled with the
reason written out.

## 10. Flutter surface

- **`/transparency`** — the public page: the year, the opening balance, what came
  in (donations and other income on separate lines), what went out by heading
  largest-first, the closing balance, and two sentences saying that only approved
  entries are counted and that nobody is named. Linked from the donate page,
  because "where does my money go" is the question a donor is already asking
  there.
- **`/admin/accounts`** — the ledger, with the running figures above it.
- **`/admin/accounts/new`**, **`/admin/accounts/:id`** — the editor. Save and
  cancel sit together; **approve and reverse sit below a divider**, each with its
  consequence written beside it.
- **`/admin/accounting-categories`** and **`/admin/accounting-settings`**.

One new entry in `AdminDestinations`, which has been the only list since
Phase 8 §9.

### 10.1 A defect found by looking at the screen

The console's running figures are the **ledger's** and exclude donations; the
public page adds them. The first screenshot showed `बही का शुद्ध −₹91,140` on a
screen whose public counterpart said `+₹1,01,060`, with nothing explaining the
difference — precisely the "committee quotes the wrong number in a meeting"
failure this phase's own plan warns about.

Fixed: the figure is now labelled *ledger* net, and the sentence "donations are
not recorded here; they are recorded in the donation register and counted from
it" sits directly beneath it. Asserted by a test.

It was found by screenshotting a real browser, not by any test — the same way
Phase 7's three identically-labelled controls were found.

## 11. Tests and command results

| Gate | Result |
|---|---|
| `flutter pub get` | ✅ |
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 208 files changed |
| `flutter test` | ✅ **526** passed (+32) |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **609** passed (2161 assertions, +65) |
| migrate → rollback → migrate → seed (MariaDB) | ✅ reversible |
| Phase 0–8 tests | ✅ pass unchanged |

New backend tests: `TransactionLifecycleTest` (18), `TransparencyTest` (14),
`AccountingPrivacyTest` (5), `AccountingAuthorizationTest` (10 with their data
sets), `AccountingCategoryTest` (8), `AttachmentTest` (8).

New Flutter tests: `transparency_screen_test.dart` (11),
`admin_accounts_test.dart` (16), plus five more admin routes and one new case in
the breadcrumb sweep.

### Live verification against the running API

**72 checks, all passing.** What the live pass covers that the unit tests cannot:
that a payload naming `status` or `approved_by` is ignored by the running server;
that an approved amount really is refused over HTTP with `TRANSACTION_LOCKED`;
that a PHP script renamed `bill.jpg` is refused by its bytes after a real
multipart upload; that the streamed bill is real JPEG bytes; that the published
balance adds up from the figures beside it; and that six field names that must
never be public — `payee_name`, `reference_number`, `donor_name`,
`receipt_number`, `attachment`, `created_by` — appear nowhere in the public JSON.

The first run reported one failure and it was the script's own: `??` cannot tell
a null value from a missing key, so a correctly-absent English name read as
present. The same trap as Phase 7; fixed with `array_key_exists`.

The run also exceeded the API's own 60-per-minute limit part way through. That is
the rate limiter working, so the script now **waits the window out** rather than
configuring the limit away — a run that switched it off would not be testing the
server the village talks to.

### Verified in a browser

The release bundle was driven through a visible Chrome: the public accounts page
in Hindi and in English, the year's figures and the heading breakdown, the two
notes at the foot; the ledger with the side menu, the status chips and the
pending line; the editor on an approved entry showing the locked notice, the
greyed fields, the still-editable description and reverse standing alone below a
divider; the categories screen where used headings have no delete button; and the
settings screen with the publish switch and its consequence spelled out.

## 12. Known issues and technical debt

- **No donor roll** (§5). It needs an explicit publication-consent field asked
  when the donation is recorded — `is_anonymous` is not that field — plus an
  effective-from date, so that switching a board on never retroactively publishes
  somebody recorded before the temple started asking.
- **No CSV, PDF or Excel export** of the ledger or the figures — Phase 10.
- **These approvals and reversals are not in an append-only audit log.** The
  columns on the row record who and when; the separate log is Phase 11.
- **No bank statement import or reconciliation.** Matching is done by eye,
  against the reference the treasurer typed.
- **No budgets, forecasts, per-project accounting or double-entry.** Not asked
  for, and a village temple's books do not need a general ledger.
- **A transfer between the cash box and the bank cannot be recorded**, and that
  is deliberate: as an income and an expense it would inflate both published
  figures by the same amount. If the committee needs it, it needs a third type
  that no total counts.
- **`ACCOUNTS_REQUIRE_SECOND_APPROVER` is off by default** (§4 in the plan). On a
  one-treasurer temple it must stay off, and that means the recorder can approve
  their own entry.
- **Attachment storage is unbounded.** Nothing prunes bills, and nothing warns
  when the disk fills.
- **The opening balance is a single figure**, not an opening trial balance: it
  says what the temple held, not what it held where.

## 13. Next phase

**Phase 10 — Reports & Analytics.** Planned but **not started**. Keys
`reports.view` and `reports.export` already exist in the matrix and have been
granted to the Treasurer and the Viewer since Phase 2.

Its shaping constraint is already visible in this phase: an export is a copy of
the data that leaves the application, and the columns this phase spent its effort
keeping off the public page — donor names, payees, references, bills — are
exactly the ones an export would carry into somebody's downloads folder. The
specification's own wording anticipates it: "sensitive donor columns excluded
without explicit permission".
