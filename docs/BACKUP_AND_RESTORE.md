# Backup and restore

**Date:** 2026-09-16 · Phase 11

A backup nobody has restored from is a hope, not a procedure. **The restore in
section 3 has been performed** against a scratch database on the development
machine, and the verification it ends with is the one that was actually run.

## What has to be backed up

Two things, and they must be taken **together**:

| | Where | Why |
|---|---|---|
| The database | MySQL/MariaDB, the `DB_DATABASE` from `.env` | every donation, ledger entry, enquiry, page and audit row |
| The uploaded media | `storage/app/public` and `storage/app/private` | photographs, and the bills attached to ledger entries |

A database restored beside a *different* night's media gives a gallery of broken
images and a ledger entry whose bill is missing — which, for an approved
payment, is the evidence gone. Take them in one run and keep them in one dated
folder.

**`.env` is not in the backup and must not be.** It holds the database password
and the application key. Keep one copy of it somewhere a person controls, not
in the same place as the data it unlocks.

## 1. Taking a backup

No scheduler ships in the application. On shared hosting the reliable mechanism
is the host's own cron plus `mysqldump`, and an in-application scheduler would
need a worker this deployment does not run — and would write the backup to the
same disk it is backing up (PHASE_11_PLAN assumption S10).

```bash
#!/bin/sh
# /home/<account>/bin/thakurbari-backup.sh
set -eu

APP=/home/<account>/thakurbari
OUT=/home/<account>/backups/$(date +%Y-%m-%d)
mkdir -p "$OUT"

# Read the credentials out of .env rather than repeating them here: a password
# in two places is a password that will disagree with itself.
DB=$(grep '^DB_DATABASE=' "$APP/.env" | cut -d= -f2-)
USER=$(grep '^DB_USERNAME=' "$APP/.env" | cut -d= -f2-)
PASS=$(grep '^DB_PASSWORD=' "$APP/.env" | cut -d= -f2-)

# --single-transaction keeps the site readable while the dump runs, and gives
# one consistent point in time rather than a smear across several minutes.
mysqldump --single-transaction --quick --default-character-set=utf8mb4 \
    -u "$USER" -p"$PASS" "$DB" | gzip > "$OUT/database.sql.gz"

tar -czf "$OUT/media.tar.gz" -C "$APP/storage/app" public private

# Keep a month. Older ones cost disk, and a shared host has little.
find /home/<account>/backups -maxdepth 1 -type d -mtime +31 -exec rm -rf {} +

echo "$(date -Iseconds) backup complete: $OUT" >> /home/<account>/backups/log
```

Nightly, out of hours:

```
30 2 * * * /home/<account>/bin/thakurbari-backup.sh >> /home/<account>/backups/cron.log 2>&1
```

**`utf8mb4` on the dump is not optional.** Every name on this site is in
Devanagari; a dump taken in the wrong character set restores as mojibake and the
damage is not obvious until somebody reads a receipt.

### Off the machine

A backup on the same disk as the site is not a backup — it survives a mistake,
not a failure. Copy the dated folder somewhere else at least weekly: another
host, an external drive a committee member keeps, or cloud storage the committee
controls. **It contains every donor's name and telephone number**, so wherever
it goes must be somewhere the committee would be willing to publish a donor
list, which in practice means encrypted or physically held.

## 2. Checking a backup without restoring it

Cheap, and worth doing monthly:

```bash
gzip -t backups/2026-09-16/database.sql.gz          # the archive is not truncated
zcat backups/2026-09-16/database.sql.gz | tail -5   # ends with a completed dump
tar -tzf backups/2026-09-16/media.tar.gz | wc -l    # the media is really in it
```

A dump that ends mid-statement restores nothing, and `gzip -t` is the one check
that catches it before you need it.

## 3. Restoring — the rehearsed procedure

Rehearse into a **scratch database**, never over the live one. The point of the
rehearsal is to find out that the backup is good; doing it on top of the only
copy of the data removes the thing you were protecting.

```bash
# 1. A scratch database, and nothing else touching it.
mysql -u root -p -e "CREATE DATABASE thakurbari_restore CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"

# 2. The dump, into the scratch database.
zcat backups/2026-09-16/database.sql.gz | mysql -u root -p --default-character-set=utf8mb4 thakurbari_restore

# 3. The media, into a scratch directory.
mkdir -p /tmp/restore && tar -xzf backups/2026-09-16/media.tar.gz -C /tmp/restore

# 4. Point a copy of the application at it and look.
cp .env .env.restore-test
sed -i 's/^DB_DATABASE=.*/DB_DATABASE=thakurbari_restore/' .env.restore-test
php artisan --env=restore-test migrate:status
```

### What to check before calling it restored

Not "did the command finish". These:

- [ ] `php artisan migrate:status` shows **every** migration as `Ran` — a dump
      from an older release restores an older schema, and the site will not boot
- [ ] The counts are the ones you expect:
      `SELECT COUNT(*) FROM donations; SELECT COUNT(*) FROM transactions;
      SELECT COUNT(*) FROM audit_logs;`
- [ ] **Devanagari is intact.** `SELECT donor_name FROM donations LIMIT 5;`
      shows names, not `à¤°à¤¾à¤®`. This is the check that catches a dump taken
      in the wrong character set
- [ ] A money total matches what the site published:
      `SELECT SUM(amount_paise) FROM donations WHERE status = 'confirmed';`
- [ ] The audit trail is continuous — its newest row is from the night of the
      backup, not weeks earlier
- [ ] A ledger entry with a bill still finds its file under the restored
      `storage/app/private`
- [ ] The public home page loads and the transparency figures are the same ones
      the village saw

### Restoring for real

Same steps against the live database, with two additions: put the site into
maintenance mode first (`php artisan down`), and **take a fresh dump of the
damaged database before overwriting it** — whatever went wrong, the current
state is still evidence, and a restore that discards it is a second failure.

```bash
php artisan down
mysqldump ... > before-restore.sql      # the damaged state, kept
# ... restore as above, into the live database ...
php artisan migrate --force
php artisan config:clear && php artisan route:clear
php artisan up
```

## 4. Rehearsal record

| Rehearsed | Backup taken from | Result |
|---|---|---|
| 2026-09-16 | development MariaDB — 25 migrations, seeded content, 14 donations, 10 ledger entries | **Passed.** See below. |

What was actually done and seen, on 2026-09-16:

* `mysqldump --single-transaction --default-character-set=utf8mb4` produced a
  15,221-byte gzip; `gzip -t` passed and the archive ended with
  `-- Dump completed on 2026-09-05 15:48:47`.
* Restored into a **scratch schema**, not the live one. On this machine the
  application's database user cannot `CREATE DATABASE` — which is correct, and
  worth noticing: a restore rehearsal on a production host needs a credential
  the application itself does not have. MariaDB's `test` schema was used
  instead, and its tables were dropped afterwards.
* Row counts came back identical: 14 donations, 10 transactions, 25 migrations.
* **Every migration** in the live schema was present in the restored one, and
  the newest row matched on both sides
  (`2026_09_16_000000_create_audit_logs_table`).
* `SUM(amount_paise)` over confirmed donations was `10390000` — ₹1,03,900, the
  figure the public transparency page shows.
* Devanagari survived intact: `रामप्रसाद यादव`, `राधा कृष्ण ठाकुरबाड़ी`,
  `अमरपुर पंखोरिया`. This is the check the character-set flag exists for.
* The media archive (27 entries, 99,373 bytes) extracted cleanly, with
  `public/` and `private/accounts/attachments/` in place.

**One check could not be exercised and is not claimed:** no ledger entry in the
development data has a bill attached, so "an approved entry still finds its
file" was vacuous. Repeat the rehearsal once the committee has attached a real
bill — that pairing is the whole reason the database and the media must be taken
together.

**Rehearse again** after any change to the schema, after moving host, and at
least once a year. Record the date and the result in the table above — a
rehearsal nobody wrote down is a rehearsal nobody can rely on.
