# Phase 10 Completion Report — Reports & Analytics

**Status: COMPLETE** · 2026-09-14

The phase that lets the committee take the data out of the application — which
is the whole risk of it. Every earlier phase was about keeping the right things
in; an export is a file that leaves the building, and it carries exactly the
columns Phases 6, 7 and 9 spent their effort withholding.

So this is a reporting feature with a disclosure control wrapped round it.

## 1. Implemented requirements checklist

| Requirement | Where |
|---|---|
| Donation, accounts, events, enquiries report endpoints | §2 — six reports, one endpoint family |
| PDF/CSV/Excel export | §4 — and each format's own hazard answered |
| **applying exactly the on-screen filters** | §3 — a property of the code, not a promise |
| **Role-gated access** | §5 |
| **Sensitive donor columns excluded without explicit permission** | §6 |

## 2. The six standard reports

| Key | Report | Shape | Needs |
|---|---|---|---|
| `donations` | दान रजिस्टर · Donation register | rows | `reports.view` + `donations.view` |
| `donation-summary` | दान सारांश · Donation summary | grouped | `reports.view` + `donations.view` |
| `income-expenditure` | आय-व्यय विवरण · Income & expenditure statement | statement | `reports.view` + `accounts.view` |
| `ledger` | बही · Ledger | rows | `reports.view` + `accounts.view` |
| `events` | आयोजित कार्यक्रम · Events held | rows | `reports.view` + `content.view` |
| `enquiries` | पूछताछ · Enquiries | rows | `reports.view` + `enquiries.manage` |

**The income & expenditure statement is the one that matters most** — the sheet a
committee reads out at the annual meeting and hands to whoever audits it. It is
computed by `TransparencyService`, the same code behind the public page, so the
statement the committee prints and the figures the village reads cannot
disagree. A live check asserts the two agree, and a third — the dashboard —
agrees with both.

**The events report expands occurrences, not records.** The daily aarti is one
row in the database and many events in a year, and "what did we hold" means the
second. Cancelled occurrences are listed and flagged rather than dropped: a
report that quietly omitted them would show a year that did not happen.

**What is deliberately absent**: attendance (nothing records it), page or visitor
analytics (there is no tracking on this site, and adding a pixel to a village
temple's website is not a reporting feature), and donor giving histories (that is
a profile, not a report).

## 3. The export is the report, not a copy of the screen

"Applying exactly the on-screen filters" is guaranteed structurally:

```
GET /api/admin/reports/{key}?year=2026&type=income      → the screen
GET .../{key}/export?format=csv&year=2026&type=income   → the file
```

Both parse the same query string with the same `ReportRequest`, and both call the
same `Report::rows()` through the same `ReportRunner`. **The client never uploads
rows to be exported**, and there is no second query for a report to drift into.
Paging is the only difference: a file is the whole filter, not the page somebody
happened to be looking at.

The live pass asserts it rather than asserting *about* it: the same query string
is sent twice, and the CSV's data rows are counted against the JSON's. Adding a
filter narrows both by the same amount.

The screen says so out loud, too — a treasurer cannot verify this and should not
have to take it on faith silently.

## 4. Three formats, three hazards

**CSV.** A byte-order mark, because without one Excel on Windows opens a UTF-8
file as Windows-1252 and every Hindi name becomes mojibake — the most likely
first experience of this whole feature, fixed with three bytes. CRLF endings. And
**no cell can execute**: a value beginning `=`, `+`, `-`, `@`, tab or carriage
return is prefixed with an apostrophe, because a donor recorded as
`=HYPERLINK("http://…")` is an attack carried out by the reader's own
spreadsheet, and the temple would be the one that handed them the file.

**XLSX — written by hand, with no new dependency.** CSV renamed to `.xlsx` would
be a lie the first time somebody double-clicked it. A worksheet holding one flat
table is five XML parts in a zip, and PHP ships `ZipArchive`; PhpSpreadsheet
would have been the fifth production dependency in a project that has four, on a
temple's shared host, to write a table of strings and numbers.

The risk of writing a format by hand is producing a file Excel refuses, and that
was answered in the gate rather than by hoping: **a workbook downloaded over HTTP
was read back with `openpyxl`** — an independent reader, installed locally and
not a project dependency — asserting the sheet, the header block, the Devanagari,
the bold heading row, and that money came back as *numbers* rather than text. Its
one warning (no default cell style) was fixed rather than tolerated.

**PDF is print-ready HTML**, for the reason `ReceiptRenderer` gave in Phase 6 and
which has not changed: no PHP PDF library shapes Devanagari, and `dompdf` would
set `रामप्रसाद` with its matras in the wrong order on a document a committee hands
to an auditor. The browser has a shaping engine and a PDF writer, and the person
exporting already has one open. The heading row repeats across printed pages.

**Money is a plain decimal in a file** — `1200.50`, never `₹1,200.50`. The symbol
and the grouping commas make a spreadsheet treat the column as text, and then
every total the treasurer tries to compute silently fails. The screen and the
printed page still format it, because those are for reading.

## 5. Role-gated, at three levels

- **`reports.view`** to reach the module at all. A Content Manager holds neither
  it nor any money key and is refused the catalogue, every report, every export
  and the dashboard figures — asserted directly against the API.
- **The report's own key.** The catalogue lists only what the caller may run, so
  the console never offers a door that will not open; and a report that is not
  listed is a **403 when asked for directly**, not a 404. Pretending it is absent
  would be obscurity standing in for a permission.
- **`reports.export` separately from reading.** A Viewer may read a report on
  screen and not take a copy away — and is told so on the catalogue, before they
  open one and wonder where the buttons are.

## 6. The disclosure control

A role check governs who may look at a screen. An export is a file that leaves
the application, so it gets a second gate.

Three outcomes, and the middle one is the point:

| | |
|---|---|
| Did not ask | Personal columns **absent from the response** — not blank, not masked. A masked column is still a column somebody can widen. |
| Asked, and may | The columns appear, and the file carries a line saying it holds personal data. |
| **Asked, and may not** | **Refused.** Not silently narrowed: dropping columns somebody explicitly asked for is how a treasurer concludes the export is broken and starts copying the register out by hand. |

`include_personal` defaults to **false** everywhere — the API, the client, and
the screen's switch.

Two further refusals inside the reports themselves:

- **An anonymous donor is never named**, at any permission. Their own receipt
  names them — it is their receipt — but a register export is read by people the
  donor never met, so the row says `(गुप्त)`.
- **`submitted_ip_hash` is not a column and never will be.** It is not
  serialized even to the committee (Phase 7), and a report is not a way round
  that. A test asserts it appears nowhere.

## 7. Analytics — the overview

Phase 8 §9 left the dashboard as a landing page and said this phase's figures
would go there; they do. This financial year's donations, income, expenditure and
balance; enquiries waiting; the next few events; and a twelve-month donation
trend drawn as twelve sized boxes — no charting package, for the same reason
there is no PDF library and no file-picker package.

**A panel this account may not see is absent, not empty.** An absent panel says
"not yours"; an empty one says "the temple received nothing", and only one of
those is true. Asserted on the server and again in the widget.

**Every month is in the trend, including the empty ones.** A chart that omitted
them would compress the gap and show a steady trickle where there was a festival
and then silence.

A failed overview does not take the dashboard down: the shortcuts below it are
what somebody signed in to use.

## 8. Database changes

**None.** This is a reading phase. A report that needed its own storage would be
a cache with a staleness problem attached.

One thing was added elsewhere: `EnquiryService::filtered()` gained a date window.
The enquiry report needs one, and a filter the caller asks for that the service
silently ignores is worse than one that does not exist — the rows would have been
all-time data under a heading naming a period.

## 9. Tests and command results

| Gate | Result |
|---|---|
| `flutter pub get` | ✅ |
| `flutter analyze` | ✅ No issues found |
| `dart format --set-exit-if-changed` | ✅ 0 of 217 files changed |
| `flutter test` | ✅ **553** passed (+27) |
| `flutter build web --release` | ✅ built |
| `./vendor/bin/pint --test` | ✅ passed |
| `php artisan test` | ✅ **666** passed (2402 assertions, +57) |
| **A produced workbook, read back by `openpyxl`** | ✅ sheet, headings, Devanagari, numbers, bold — §4 |
| Phase 0–9 tests | ✅ pass unchanged |
| Migrations | no new migration; Phases 0–9 still apply cleanly |

New backend tests: `ReportCatalogueTest` (13 with its data sets),
`ReportDisclosureTest` (7), `ReportExportTest` (11), `ReportContentTest` (13),
`OverviewTest` (8).

New Flutter tests: `admin_reports_test.dart` (23), `link_opener_test.dart` (4),
plus two more routes in the breadcrumb sweep.

### Live verification against the running API

**79 checks, all passing.** What the live pass covers that the unit tests cannot:
that the CSV downloaded over HTTP has exactly as many data rows as the JSON the
same query string produced; that adding `type=income` narrows both by the same
amount and the file names the filter; that the workbook is a real zip with the
five parts; that the printable document is served inline with print styles; that
the disclosure control holds on the wire in both the screen and the file; and
that the dashboard, the statement and the public transparency page all report the
same closing balance.

The run exceeded the API's own 60-per-minute limit part way through. That is the
rate limiter working, so the script now **waits and retries on a 429** rather
than reporting a false failure — switching the limit off would not be testing the
server the village talks to.

One earlier failure was the script's own: it checked for `दानदाता` in a file
that should not have had a donor column, but `दानदाता · Donors` is *also* a
summary figure label, so the needle was ambiguous. Replaced with the telephone
column's heading, which appears nowhere else.

### Verified in a browser

The release bundle was driven through a visible Chrome: the dashboard with the
figures, the twelve-month trend keeping its empty months, the pending enquiries
and the next five occurrences; the catalogue with all six reports and the three
that hold personal columns flagged; and the donation register with its financial
year chips, its figures, the disclosure switch **off with no donor column**, and
then **on** — the chip appearing and three columns arriving with it.

## 10. A defect found by a question, not by a test

Asked "is PDF downloading?", I checked in a browser rather than from memory —
and **none of the three exports worked at all**. Nor did the donation receipt
(Phase 6) or the transaction's bill (Phase 9): the same latent defect, shipped
four phases ago.

`LinkOpener` opened every tab with `noopener,noreferrer`. Sanctum decides a
request is stateful — and therefore carries the session — by matching the
`Referer` **or** the `Origin` against its configured domains. A top-level
navigation started by `window.open` sends no `Origin` at all, so stripping the
`Referer` left the request with neither: the API saw an anonymous caller.

It then failed twice over. Laravel's default is to redirect a guest to a route
named `login`, which this API does not have, so the caller got a
`RouteNotFoundException` and a **500 where a 401 belonged**.

**Why nothing caught it.** Every backend test and all 79 live checks send
`Accept: application/json` and an explicit `Origin` header — which a browser does
*not* send for a top-level navigation. The tests were exercising a path the app
does not use. The widget tests only asserted the URL string, which was correct
throughout.

Both halves are fixed and pinned:

- `LinkOpener.openOwn()` keeps `noopener` and drops `noreferrer`, and the three
  own-API call sites use it. The video darshan link (Phase 5) still uses `open()`
  — it is a third party and needs no session.
- `redirectGuestsTo()` returns null for `api/*`, so the guard throws
  `AuthenticationException` and the renderer returns a clean 401.
- `link_opener_test.dart` sweeps the source so a call site cannot quietly reach
  for the wrong door; `ReportCatalogueTest` asserts a browser navigation to every
  admin route is a 401 rather than a 500.

Verified afterwards in a real browser: the printable document opens signed in
with its Devanagari correct, and `donations-2026-09-05.csv` (1,618 bytes, opening
`EF BB BF`) and `donations-2026-09-05.xlsx` (3,082 bytes) both landed in the
downloads folder — the workbook read back cleanly with `openpyxl` from there.

## 11. Known issues and technical debt

- **Exports are not audit-logged** — Phase 11, and the right place for it. "Who
  took a copy of the donor list, and when" is exactly the question an audit log
  exists to answer, and this phase creates that question without answering it.
- **No scheduled or e-mailed reports.** Sending is Phase 8's machinery and a
  scheduled report needs a queue worker, which the deployment checklist already
  warns cannot be assumed.
- **No report builder**: no custom columns, no saved definitions. Six good
  reports beat a builder nobody in the committee will operate.
- **The export cap is 10,000 rows** and is not configurable. A temple that
  outgrows it needs paging by period, which the message already suggests.
- **The xlsx writer is minimal**: one sheet, no column widths, no number
  formats, no frozen header. A treasurer will widen the columns themselves.
- **The PDF is the browser's**, so its page size, margins and headers are
  whatever that browser is set to.
- **The events report is computed in PHP, not the database**, because
  occurrences are expanded from rules. A temple with many years of daily events
  and a wide date range will feel it.
- **No per-report saved filters.** The screen keeps them while the session
  lasts and forgets them on reload.

## 12. Next phase

**Phase 11 — Security, Audit, Backup & Privacy.** Planned but **not started**.

Three of the last five phases have ended by recording something that belongs in
it: consent changes are not logged (Phase 3), enquiry personal data has no
retention or purge (Phase 7), accounting approvals and reversals are not in an
append-only log (Phase 9), and now exports of personal data are not logged
either. That is the shape of Phase 11's first requirement, and this phase has
made it more urgent rather than less.
