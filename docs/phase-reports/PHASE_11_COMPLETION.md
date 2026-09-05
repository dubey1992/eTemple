# Phase 11 — Security, Audit, Backup & Privacy · COMPLETION

**Status:** COMPLETE
**Completed:** 2026-09-16
**Plan:** `docs/phase-plans/PHASE_11_PLAN.md`

## 1. What the specification asked for, and where it is

| Requirement | Where |
|---|---|
| `audit_logs` with actor, action, entity, before/after and IP | `2026_09_16_000000_create_audit_logs_table` |
| Append-only audit behaviour | `App\Models\AuditLog` — `updating` and `deleting` throw |
| Permission enforcement on every admin endpoint | `SecurityPostureTest` sweeps the route table |
| Database + media backup and a **rehearsed** restore | `docs/BACKUP_AND_RESTORE.md`, §4 |
| Secure headers, HTTPS-only, CSRF, session timeout, login rate limits | `App\Http\Middleware\SecurityHeaders`; the rest verified, not assumed |
| No sensitive tokens in insecure browser storage | `test/core/browser_storage_test.dart` |

## 2. The trail records what somebody may be asked about

Not every write. Auditing everything produces a table nobody reads on a disk
nobody has — this is a village temple on shared hosting, and the trail has to
stay small enough for a treasurer to search at an annual meeting.

So: the donation and ledger lifecycles end to end; role, account and settings
changes; announcements sent; **every export of personal data**; and one read.

Two of those deserve their own note.

**The export.** Phase 10 shipped without an answer to "who took a copy of the
donor register, and when" — which is exactly what an audit trail exists for. It
is recorded even though an export is a `GET`: what makes an action worth
auditing is its consequence, not its verb. The row says which file, which
filters, and whether it carried personal details.

**Opening an enquiry** is the only read that is audited. Everywhere else,
reading a list is ordinary work; here the thing being read is a villager's
telephone number and their complaint, and "who has seen this" is a question the
committee may legitimately be asked.

## 3. What a row may hold, and what it may never

`before_data` and `after_data` hold **only the fields that changed**, and pass a
redaction list first: any key containing `password`, `token`, `secret`, `hash`
or `remember` is dropped, at any depth. A hash in an audit row is a hash
somebody can take away and attack offline, and it answers no question worth
asking.

Personal details **are** kept when they are what changed — "the amount on
Rampasad's donation was edited from ₹500 to ₹750" is the question the log
exists to answer, and a redacted log answers nothing. Which makes the table
itself a store of personal data, with two consequences by design:

* reading it needs `audit.view`, held by **Super Admin alone** — not even Admin;
* **there is no export.** Every report in Phase 10 has three. This has none.

The actor's name is copied onto the row rather than joined, so the trail
outlives the account: a row reading "(deleted user) approved ₹45,000" answers
nothing.

## 4. Append-only, enforced rather than promised

`updating` and `deleting` throw on the model, so no service, controller, tinker
session or future shortcut can rewrite history. There is no endpoint that
writes. A database trigger would be stronger, but the deployment target is
shared hosting where the application's own database user needs full rights for
migrations to run — a guarantee that holds only when somebody remembers to
configure it is worse than one the code enforces on every path.

`audit:prune` is the single exception, and it is deliberately hard to run by
accident: the age is required and has no default, it says what it will remove
and asks, and it writes a row recording that it ran. A log that grows forever
fills a shared host's disk and takes the site down with it, which is not more
secure than a log with a stated retention.

## 5. Two habits became properties of the code

**Every admin route carries a permission.** A route-table sweep asserts it, with
an exemption list that must be justified in the test itself. It found one:
`api/admin/ping`, the Phase 0 canary that `AdminRouteProtectionTest` uses to
prove the group's authentication is attached. It is now exempt on the record
rather than by accident.

**Nothing is written to browser storage.** The answer to "no sensitive tokens in
insecure browser storage" turned out to be stronger than a rule about which
values are safe: *nothing at all* is stored. The session is an HttpOnly cookie
the browser attaches and script cannot read, and the only cookie the client
reads is `XSRF-TOKEN`, which Laravel deliberately exposes. A source sweep keeps
it that way.

## 6. Headers

`nosniff`, `X-Frame-Options: DENY` with `frame-ancestors 'none'` beside it,
`Referrer-Policy`, a `Permissions-Policy` denying camera, microphone and
geolocation — and **HSTS only when the request arrived over HTTPS**. Sending it
from a development site teaches the browser to refuse plain HTTP for that host
for a year, and the only cure is clearing the browser's internal state.

The printable receipt, bill and export get a stricter policy of their own: they
are the only HTML this API emits, assembled from stored content, and they may
run nothing.

## 7. Backup, actually restored

`docs/BACKUP_AND_RESTORE.md` carries the procedure and the rehearsal record. The
restore was performed on 2026-09-16: a 15,221-byte dump verified with `gzip -t`,
restored into a scratch schema, and then checked on the things that matter
rather than on "the command finished" — every migration present, row counts
identical, `SUM(amount_paise)` equal to the ₹1,03,900 the public page shows, and
**Devanagari intact** (`रामप्रसाद यादव`, `अमरपुर पंखोरिया`), which is the check
the character-set flag exists for.

One thing was learned by doing it: **the application's database user cannot
create a database**, which is correct and means a restore rehearsal on a
production host needs a credential the application itself does not have. That is
now in the procedure.

**One check is not claimed.** No ledger entry in the development data has a bill
attached, so "an approved entry still finds its file" was vacuous. It is written
down as outstanding rather than ticked.

## 8. A defect the screen found

Verifying a donation recorded the *whole* record as though every field had
changed — eleven fields against a column of em dashes. It looked wrong the
moment it was rendered in a browser, which no test had asked about because every
assertion was on the fields present rather than on the ones that should not be.

Lifecycle events now record only what moved (`status` and the receipt number for
a verification; `status` and the reason for a reversal), and a creation renders
without a "before" column at all. Both halves are tested.

## 9. Verification

| Gate | Result |
|---|---|
| `flutter analyze` / `dart format` | clean, 229 files |
| `flutter test` | **587 passed** (+11) |
| `flutter build web --release` | built |
| `./vendor/bin/pint --test` | passed |
| `php artisan test` | **711 passed**, 2567 assertions (+20) |
| Migration up → rollback → up | MariaDB |
| Backup → restore → verify | rehearsed, §7 |
| The trail read in a real browser | an edit shows the two fields that moved |

## 10. Known issues and what is deliberately absent

* **No export of the audit trail**, and that is the design, not a gap.
* **`audit:prune` is not scheduled.** Nothing on this deployment runs on a timer
  the committee has not set up themselves; the retention is theirs to choose.
* **No backup scheduler ships in the application** — the host's cron is the
  reliable mechanism, and an in-application one would write the backup to the
  same disk it was backing up.
* The route sweep proves a permission is *attached*, not that it is the right
  one. The per-module authorization tests from Phases 2–10 prove that, and they
  stay.
* Committee member creation and update, and content deletions, are not yet
  audited — the catalogue names them and the call sites are the obvious next
  additions; only the deletion of a committee member is recorded today.
* A ledger entry's bill has not been through a restore rehearsal (§7).

## 11. Next phase

Phase 12 — Testing, Deployment & Handover. **It must not begin without explicit
approval.**
