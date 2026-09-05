<?php

declare(strict_types=1);

namespace App\Services\Accounting;

use App\Exceptions\AccountingGuardException;
use App\Models\Transaction;
use Illuminate\Contracts\Filesystem\Filesystem;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

/**
 * Bills, kept where the web cannot reach them.
 *
 * The specification calls the column `attachment_url`. It is a path on a
 * private disk here, and the difference is the whole point: a bill photograph
 * carries a trader's name, a telephone number and sometimes a signature, and a
 * public URL to one is a public URL forever, guessable or not
 * (PHASE_9_PLAN assumption N5).
 *
 * The Phase 5 media library is deliberately not reused. It writes to the public
 * disk and exists to publish photographs; this is the opposite kind of object.
 *
 * The type is decided by **reading the file**, never by its name or the
 * browser's `Content-Type` — Phase 5's rule, and the reason a `.jpg` that is
 * really a PHP script gets no further than this class.
 */
class AttachmentStore
{
    /**
     * Validates and stores an upload, returning the columns to write.
     *
     * @return array{attachment_path: string, attachment_name: string, attachment_size: int, attachment_mime: string}
     */
    public function store(UploadedFile $file): array
    {
        if (! $file->isValid()) {
            throw AccountingGuardException::attachmentUnreadable();
        }

        $maxKb = (int) config('accounting.attachments.max_upload_kb', 8192);
        if ($file->getSize() > $maxKb * 1024) {
            throw AccountingGuardException::attachmentTooLarge($maxKb);
        }

        $path = $file->getRealPath();
        if ($path === false || ! is_readable($path)) {
            throw AccountingGuardException::attachmentUnreadable();
        }

        $mime = $this->detectMime($path);

        /** @var array<string, string> $accepted */
        $accepted = config('accounting.attachments.accepted_mimes', []);
        if (! isset($accepted[$mime])) {
            throw AccountingGuardException::attachmentTypeRefused(
                array_values(array_unique(array_values($accepted))),
            );
        }

        // The stored name is generated, never the uploader's. A file name is
        // attacker-controlled text that ends up in a path, and the original is
        // kept in its own column for display instead.
        $stored = sprintf(
            '%s/%s.%s',
            trim((string) config('accounting.attachments.path', 'accounts/attachments'), '/'),
            Str::uuid()->toString(),
            $accepted[$mime],
        );

        $this->disk()->put($stored, (string) file_get_contents($path));

        return [
            'attachment_path' => $stored,
            'attachment_name' => $this->safeDisplayName($file->getClientOriginalName(), $accepted[$mime]),
            'attachment_size' => (int) $file->getSize(),
            'attachment_mime' => $mime,
        ];
    }

    /** The bytes, for the authenticated endpoint that streams them. */
    public function read(Transaction $transaction): string
    {
        if (! $transaction->hasAttachment() || ! $this->disk()->exists($transaction->attachment_path)) {
            throw AccountingGuardException::attachmentMissing();
        }

        return (string) $this->disk()->get($transaction->attachment_path);
    }

    /**
     * Removes a stored file.
     *
     * Only ever called when a bill is *replaced* on a transaction that is not
     * yet approved. A reversal keeps its bill: the row stays, and so does the
     * evidence for it.
     */
    public function forget(?string $path): void
    {
        if ($path !== null && $path !== '' && $this->disk()->exists($path)) {
            $this->disk()->delete($path);
        }
    }

    private function disk(): Filesystem
    {
        return Storage::disk((string) config('accounting.attachments.disk', 'local'));
    }

    private function detectMime(string $path): string
    {
        $finfo = finfo_open(FILEINFO_MIME_TYPE);
        if ($finfo === false) {
            throw AccountingGuardException::attachmentUnreadable();
        }

        $mime = finfo_file($finfo, $path);
        finfo_close($finfo);

        return $mime === false ? '' : $mime;
    }

    /**
     * A name safe to put in a `Content-Disposition` header and in JSON.
     *
     * Directory separators, control characters and quotes are stripped, and the
     * extension is the one the bytes earned rather than the one claimed.
     */
    private function safeDisplayName(string $original, string $extension): string
    {
        $base = pathinfo(str_replace(['\\', '/'], '', $original), PATHINFO_FILENAME);
        $base = preg_replace('/[^\p{L}\p{N}\-_. ]/u', '', $base) ?? '';
        $base = trim(mb_substr($base, 0, 120));

        return ($base === '' ? 'bill' : $base).'.'.$extension;
    }
}
