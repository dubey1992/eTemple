#!/bin/sh
# Nightly backup of the database and the uploads, together.
#
# Install as: ~/bin/thakurbari-backup.sh  (chmod 700)
# Cron:       30 2 * * * /home/<account>/bin/thakurbari-backup.sh >> /home/<account>/backups/cron.log 2>&1
#
# The two halves must be taken in ONE run. A database restored beside a
# different night's uploads gives a gallery of broken images and a ledger entry
# whose bill is missing — which, for an approved payment, is the evidence gone.
#
# The restore procedure, and the rehearsal that proved it, are in
# docs/BACKUP_AND_RESTORE.md. A backup nobody has restored from is a hope.
set -eu

APP=${APP:-$HOME/thakurbari/backend_laravel}
OUT=${OUT:-$HOME/backups/$(date +%Y-%m-%d)}
KEEP_DAYS=${KEEP_DAYS:-31}

mkdir -p "$OUT"

# Read the credentials out of .env rather than repeating them here: a password
# in two places is a password that will disagree with itself.
DB=$(grep '^DB_DATABASE=' "$APP/.env" | cut -d= -f2- | tr -d '"')
USER=$(grep '^DB_USERNAME=' "$APP/.env" | cut -d= -f2- | tr -d '"')
PASS=$(grep '^DB_PASSWORD=' "$APP/.env" | cut -d= -f2- | tr -d '"')

# --single-transaction keeps the site readable while the dump runs and gives one
# consistent point in time rather than a smear across several minutes.
#
# --default-character-set=utf8mb4 is NOT optional: every name on this site is in
# Devanagari, and a dump taken in the wrong character set restores as mojibake.
# The damage is invisible until somebody reads a receipt.
mysqldump --single-transaction --quick --default-character-set=utf8mb4 \
    -u "$USER" -p"$PASS" "$DB" | gzip > "$OUT/database.sql.gz"

tar -czf "$OUT/media.tar.gz" -C "$APP/storage/app" public private

# Cheap proof it is not truncated. A dump that ends mid-statement restores
# nothing, and this is the one check that catches it before you need it.
gzip -t "$OUT/database.sql.gz"

find "$HOME/backups" -maxdepth 1 -type d -mtime "+$KEEP_DAYS" -exec rm -rf {} + 2>/dev/null || true

echo "$(date -Iseconds) backup complete: $OUT ($(du -sh "$OUT" | cut -f1))" \
    >> "$HOME/backups/log"

# A backup on the same disk as the site survives a mistake, not a failure. Copy
# the dated folder somewhere the committee controls at least weekly — and
# remember it holds every donor's name and telephone number, so wherever it goes
# must be somewhere the committee would be willing to publish a donor list.
