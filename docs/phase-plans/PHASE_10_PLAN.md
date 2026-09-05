# Phase 10 Plan — Reports & Analytics

The phase that lets the committee take the data out of the application.

That is the whole risk of it. Every earlier phase has been about keeping the
right things in: donor detail off the public site (Phase 6), a villager's
telephone number out of any public response (Phase 7), payees and bills off the
transparency page (Phase 9). An export is a file that leaves the building — it
lands in a downloads folder, gets forwarded, gets left on a shared laptop — and
it carries exactly the columns those phases spent their effort withholding.

So this phase is a reporting feature with a disclosure control wrapped round it.

Everything here is written before any code, per the execution contract.

## 1. Requirement review

From `docs/IMPLEMENTATION_PLAN.md`:

- [ ] Donation, accounts, events, enquiries report endpoints
- [ ] PDF/CSV/Excel export applying exactly the on-screen filters
- [ ] Role-gated access; sensitive donor columns excluded without explicit
      permission

Read closely, the second requirement is a *guarantee* and the third is a
*refusal*. "Exactly the on-screen filters" cannot be achieved by asking the
client to send what it happens to be showing; and "excluded without explicit
permission" is about a file, not a screen.

Global rules that bear on this phase:

- money is exact (integer paise, never a float);
- nothing sensitive is disclosed without consent or a permission;
- Hindi is the default language and must survive every format;
- authorization is the server's, whatever the client hides.

## 2. The standard reports

Six, and no more. Each is a real question a village temple committee asks; none
of them invents a figure the database does not hold (N10).

| Key | Report | Shape | Reads | Needs |
|---|---|---|---|---|
| `donations` | दान रजिस्टर · Donation register | rows | donations | `reports.view` + `donations.view` |
| `donation-summary` | दान सारांश · Donation summary | grouped totals | donations | `reports.view` + `donations.view` |
| `income-expenditure` | आय-व्यय विवरण · Income & expenditure statement | statement | donations + transactions | `reports.view` + `accounts.view` |
| `ledger` | बही · Ledger | rows | transactions | `reports.view` + `accounts.view` |
| `events` | कार्यक्रम · Events held | rows | events | `reports.view` + `content.view` |
| `enquiries` | पूछताछ · Enquiries | rows | enquiries | `reports.view` + `enquiries.manage` |

**Why these six.**

- **The income & expenditure statement is the one that matters most.** It is the
  sheet a committee reads out at the annual meeting and hands to whoever audits
  it: opening balance, receipts by head, payments by head, closing balance. Every
  other report is a working list; this one is the temple's account of itself.
- **The donation register and the ledger** are the row-level lists. A treasurer
  needs to hand somebody the actual entries, not a summary of them.
- **The donation summary** answers "how much came in for the festival this year",
  grouped by purpose, by mode and by month — the question `DonationPurpose` was
  made a code catalogue for, back in Phase 6.
- **Events held** answers "what did we hold last year", expanded from the
  recurrence rules, with cancelled occurrences flagged rather than dropped.
- **Enquiries** answers "how many people wrote, about what, and how long did we
  take" — the last part is the only performance figure in the phase, and it is
  computed from timestamps that already exist.

**What is deliberately not here** (N10): attendance at events, because nothing
records attendance; visitor or page analytics, because there is no tracking on
this site and adding a tracking pixel to a village temple's website is not a
reporting feature; and anything about individual donors' giving history, which
is a profile, not a report.

## 3. Analytics — the overview

Phase 8 §9 left the admin dashboard as a landing page and said this phase's
at-a-glance figures would go there. They do:

- this financial year's **donations received**, **expenditure** and **balance**,
  read from the same service the public page uses (N9);
- **enquiries waiting** — new and in-progress;
- **the next few events**;
- a **twelve-month donation trend**, drawn as a plain bar chart.

Each figure is a link into the report or module behind it, so a number that looks
wrong can be opened rather than wondered about. No charting package is added: a
twelve-bar chart is a row of sized boxes, and this project has consistently not
taken a dependency for something that small.

Every panel is permission-gated by the module it reads, so a Content Manager sees
an overview with no money on it at all.

## 4. Assumptions and decisions

### N1 — The export runs the report, not the screen's copy of it

"Applying exactly the on-screen filters" is guaranteed structurally, not by
discipline:

```
GET /api/admin/reports/{key}?from=&to=&status=…            → the screen
GET /api/admin/reports/{key}/export?format=csv&<the same>  → the file
```

Both parse the same query string with the same code and call the same
`Report::rows()`. The only difference is that the screen paginates and the export
does not. The client never sends rows to be exported, and there is no second
query for a report to drift into.

### N2 — Personal columns are gated twice, and default to absent

A role check governs who may look at a screen. An export is a file that leaves
the application, and it deserves a second gate.

- **The role.** Donor identity needs `donations.view`; an enquirer's name and
  telephone number need `enquiries.manage`.
- **The deliberate act.** `include_personal=1`, default **false**. Without it the
  personal columns are **absent from the response**, not blank and not masked —
  a masked column is still a column somebody can widen.
- **The file says so.** An export containing personal data carries a line in its
  header block stating it, so the person who opens it six months later knows what
  they are holding.

Asking for personal columns without the permission is a 403, not a quietly
narrower file: silently dropping columns somebody asked for is how a treasurer
concludes the export is broken.

### N3 — PDF is print-ready HTML, for the reason Phase 6 already gives

`ReceiptRenderer` established it: **no PHP PDF library shapes Devanagari**.
`dompdf` and the FPDF family would print `रामप्रसाद` with its matras in the wrong
order — on a financial document. Every browser ships a shaping engine and a PDF
writer, and the committee already has one open.

So the PDF format is a server-rendered, print-ready HTML document opened in a new
tab, with `@media print` rules and page headers. The same decision, the same
reason, and no new dependency on a shared host.

### N4 — XLSX is written directly, with no new package

The requirement says Excel, and CSV-renamed-to-`.xlsx` would be a lie the first
time somebody double-clicked it.

A worksheet holding one flat table is a small, fully specified thing: a zip of
five XML parts, which PHP's built-in `ZipArchive` can write. PhpSpreadsheet is a
capable library and it is not needed to write a table of strings and numbers; it
would be the fifth production dependency in a project that has four, on a temple's
shared host.

The risk of writing the format by hand is producing a file Excel refuses to open,
and that risk is answered in the gate rather than by hoping: **the delivery gate
reads the produced workbook back with an independent reader** (`openpyxl`, a local
tool and not a project dependency) and asserts the sheet, the headings and the
cell values. A file openpyxl parses is a file Excel opens.

Numbers are written as numbers, so a treasurer can sum a column; dates as ISO
strings, which every spreadsheet parses.

### N5 — CSV is UTF-8 with a BOM, and no cell can execute

Two decisions that only look small:

- **A byte-order mark.** Without one, Excel on Windows opens a UTF-8 CSV as
  Windows-1252 and every Hindi name becomes mojibake. That is the most likely
  first experience of this feature, and it is a three-byte fix.
- **Formula injection is neutralised.** A cell beginning `=`, `+`, `-`, `@`, tab
  or carriage return is prefixed with an apostrophe. A donor recorded as
  `=HYPERLINK("http://…","click")` is not a hypothetical: it is an attack on
  whoever opens the file, executed by their spreadsheet, and the temple would be
  the one that handed them the file.

Line endings are CRLF, which is what the CSV specification says and what Excel
expects.

### N6 — Money in a file is a plain decimal

`1200.50`, never `₹1,200.50`. The rupee symbol and the grouping commas make a
spreadsheet treat the column as text, and then every total the treasurer tries to
compute silently fails or refuses.

The **screen** keeps the formatted string, because a person reads `₹1,25,500.00`
more easily than `125500.00`. The two come from the same integer paise, and only
the display divides by a hundred.

### N7 — Every export states what it is

A header block on every format: the temple's name, the report's name, the period
covered, **the filters that were applied**, when it was generated and by whom,
and the personal-data line when N2 applies.

A printed sheet passed round a meeting with no date and no statement of its
filters is a sheet somebody will misread — and "these are last year's figures, not
this year's" is not a discovery to make afterwards.

### N8 — Reports are read-only, and bounded

Nothing in this phase writes. Every endpoint is a `GET`.

An export is capped at 10,000 rows. When the cap bites the response **says so and
suggests a narrower period** rather than truncating silently — a file that is
quietly missing its last four hundred rows is worse than one that refused.

### N9 — A report reads the same service the screen does

No report writes its own queries against a module it does not own. In particular
the **income & expenditure statement is computed by `TransparencyService`** — the
same code behind the public page — so the statement the committee prints and the
figures the village reads cannot disagree. That is Phase 9's assumption N1
extended: a total assembled in two places eventually disagrees with itself.

Where a report needs a shape the service does not offer, the shape is added to
that service, not reimplemented here.

### N10 — Nothing is invented

Reports report what is stored. Where a committee might expect a figure this
project does not hold — attendance, page views, a donor's lifetime giving — the
report does not carry a plausible-looking substitute. §2 lists what is absent and
why.

### N11 — Reading needs `reports.view`; downloading needs `reports.export`

Both keys have been in the matrix since Phase 2 and are held by the Treasurer;
the Viewer holds `reports.view` only, so a Viewer may read a report on screen and
not take a copy away. A Content Manager holds neither.

Each report additionally declares the domain permission it needs, and **the
catalogue endpoint returns only the reports the caller may actually run** — the
console never offers a door that will not open.

### N12 — Bilingual, in every format

Column headings and labels come from the report definition in both languages, and
the requested language is a parameter like everywhere else. Data that is itself
bilingual — a category name, an event title — resolves through `LocalizedText`
with the same Hindi fallback as the rest of the site.

A CSV is the one place a fallback cannot be footnoted, so a value served as a
fallback is exported as-is: the Hindi, which is what is actually stored.

## 5. Database design

**None.** This phase adds no table and no column. It is a reading phase, and a
report that needed its own storage would be a cache with a staleness problem
attached.

## 6. API surface

All admin, all `GET`, all behind `auth:sanctum` + `active`:

| Method | Path | Permission |
|---|---|---|
| GET | `/api/admin/reports` | `reports.view` — the catalogue, filtered to what the caller may run |
| GET | `/api/admin/reports/{key}` | `reports.view` + the report's own key |
| GET | `/api/admin/reports/{key}/export` | `reports.export` + the report's own key |
| GET | `/api/admin/overview` | `reports.view` — the dashboard figures, panels filtered by permission |

`export` takes `format=csv|xlsx|pdf` and the same filters as the report itself.
`pdf` returns a print-ready HTML document (N3); the other two return a file.

## 7. Flutter surface

- **`/admin`** — the dashboard gains the overview panels and the trend (§3),
  above the module cards.
- **`/admin/reports`** — the report catalogue: what may be run, and what each
  one answers.
- **`/admin/reports/:key`** — one report: its filters, its figures, its rows, and
  the three export buttons. The personal-data switch appears only for an account
  that may use it, and starts off.

## 8. Implementation order

1. The report abstraction: a `Report` contract, a registry, a runner, a filter
   parser shared by the screen and the export.
2. The six reports, each reading its module's existing service.
3. The three exporters — CSV, XLSX, print HTML — and the shared header block.
4. Controllers, routes, resources.
5. Backend tests: the filter guarantee, the permission matrix, the disclosure
   control, the formats, the arithmetic.
6. The overview service and endpoint.
7. Flutter domain, repository, providers.
8. Flutter screens, ARB entries for both languages, the dashboard panels.
9. Flutter tests.
10. Gates — including reading a produced workbook back with an independent
    reader (N4) — live verification, browser showcase.
11. OpenAPI, `.env.example`, deployment checklist, completion report.

## 9. Delivery gate

`flutter pub get` · `flutter analyze` · `dart format --set-exit-if-changed` ·
`flutter test` · `flutter build web --release` · `pint --test` ·
`php artisan test` · **a produced `.xlsx` parsed by an independent reader** ·
live checks through the running API · the app driven in a real browser.

Phases 0–9 must pass unchanged. No migration is added, so there is nothing to
roll back — the migration gate is satisfied by Phases 0–9 still applying cleanly.

## 10. Explicitly out of scope

- **Scheduled or e-mailed reports.** Sending is Phase 8's machinery and a report
  on a schedule needs a queue worker running, which the deployment checklist
  already warns cannot be assumed.
- **A report builder.** Custom columns and saved definitions are a product, not a
  phase; six good reports beat a builder nobody in the committee will operate.
- **Audit logging of exports.** Phase 11. It is the right place for it and it is
  recorded as debt, because "who took a copy of the donor list" is exactly the
  question an audit log exists to answer.
- **Charts beyond the one trend.** A dashboard of graphs is a demonstration, not
  a tool.
- **Attendance, page views, donor profiles.** See N10.
