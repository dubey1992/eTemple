<?php

declare(strict_types=1);

namespace App\Services\Audit;

use App\Models\AuditLog;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Request;

/**
 * Writes the audit trail.
 *
 * One place, so that every row has the same shape and the redaction rules are
 * applied once rather than remembered at twenty call sites.
 *
 * **Recording must never break the thing being recorded.** If writing the trail
 * fails — a full disk, a locked table — the donation is still recorded and the
 * treasurer still gets their receipt; the failure goes to the application log
 * instead. An audit system that can take the temple's books offline is a worse
 * risk than the one it mitigates.
 */
class AuditLogger
{
    /**
     * Keys whose values never reach the audit table, in any form.
     *
     * Matched on the key name, not the value, and by substring: `password`
     * catches `password_confirmation`, `token` catches `remember_token` and
     * `api_token`. A hash in an audit row is a hash somebody can take away and
     * attack offline, and it answers no question worth asking.
     *
     * @var list<string>
     */
    private const REDACTED = [
        'password', 'token', 'secret', 'hash', 'remember',
    ];

    /**
     * Record something that happened.
     *
     * @param  array<string, mixed>|null  $before
     * @param  array<string, mixed>|null  $after
     */
    public function record(
        string $action,
        ?Model $entity = null,
        ?array $before = null,
        ?array $after = null,
        ?string $context = null,
        ?string $label = null,
        ?User $actor = null,
    ): ?AuditLog {
        try {
            $actor ??= Auth::user();
            $actor = $actor instanceof User ? $actor : null;

            return AuditLog::query()->create([
                'user_id' => $actor?->id,
                // The name is copied, not joined: the trail outlives the
                // account, and a row that reads "(deleted user) approved
                // ₹45,000" answers nothing.
                'actor_name' => $actor?->fullName(),
                'actor_role' => $actor?->role?->slug,
                'action' => $action,
                'entity_type' => $entity === null ? null : $this->typeOf($entity),
                'entity_id' => $entity?->getKey(),
                'entity_label' => $label === null ? null : mb_substr($label, 0, 200),
                'before_data' => $this->clean($before),
                'after_data' => $this->clean($after),
                'context' => $context,
                'ip_address' => Request::ip(),
                'user_agent' => mb_substr((string) Request::userAgent(), 0, 500) ?: null,
            ]);
        } catch (\Throwable $exception) {
            Log::error('An audit entry could not be written.', [
                'action' => $action,
                'exception' => $exception->getMessage(),
            ]);

            return null;
        }
    }

    /**
     * Record an edit, keeping only the fields that actually changed.
     *
     * A row holding every column of a record is unreadable and stores personal
     * data nobody asked about. "What changed" is the question; storing the
     * answer to it is the whole design.
     *
     * Returns null when nothing changed — a save that changed nothing is not an
     * event, and logging it would bury the ones that are.
     *
     * @param  array<string, mixed>  $before
     * @param  array<string, mixed>  $after
     */
    public function recordChange(
        string $action,
        Model $entity,
        array $before,
        array $after,
        ?string $context = null,
        ?string $label = null,
    ): ?AuditLog {
        $changedKeys = [];

        foreach ($after as $key => $value) {
            $was = $before[$key] ?? null;
            // Loose comparison on purpose: a form sends "1" where the column
            // holds 1, and recording that as a change would fill the log with
            // edits nobody made.
            if ($was != $value) {
                $changedKeys[] = $key;
            }
        }

        if ($changedKeys === []) {
            return null;
        }

        return $this->record(
            action: $action,
            entity: $entity,
            before: array_intersect_key($before, array_flip($changedKeys)),
            after: array_intersect_key($after, array_flip($changedKeys)),
            context: $context,
            label: $label,
        );
    }

    /**
     * A short, stable code for the kind of record.
     *
     * The table name rather than the class name, so renaming a class does not
     * rewrite history and a row written last year still points at something.
     */
    private function typeOf(Model $entity): string
    {
        return mb_substr($entity->getTable(), 0, 40);
    }

    /**
     * Drop the keys that must never be stored, at any depth.
     *
     * @param  array<string, mixed>|null  $data
     * @return array<string, mixed>|null
     */
    private function clean(?array $data): ?array
    {
        if ($data === null) {
            return null;
        }

        $cleaned = [];

        foreach ($data as $key => $value) {
            if ($this->isRedacted((string) $key)) {
                continue;
            }

            $cleaned[$key] = is_array($value) ? $this->clean($value) : $value;
        }

        return $cleaned;
    }

    private function isRedacted(string $key): bool
    {
        $key = mb_strtolower($key);

        foreach (self::REDACTED as $needle) {
            if (str_contains($key, $needle)) {
                return true;
            }
        }

        return false;
    }
}
