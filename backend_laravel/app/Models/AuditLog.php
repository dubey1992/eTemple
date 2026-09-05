<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use RuntimeException;

/**
 * One entry in the temple's audit trail (spec Phase 11).
 *
 * **Append-only, and the model is what enforces it.** `updating` and `deleting`
 * throw, so there is no code path — service, controller, tinker session or
 * future maintainer's shortcut — that can quietly rewrite history. A database
 * trigger would be the stronger guarantee, but the deployment target is shared
 * hosting where the application's own database user needs full rights for
 * migrations to run; a guarantee that holds only when somebody remembers to
 * configure it is worse than one the code enforces on every path
 * (PHASE_11_PLAN assumption S3).
 *
 * Pruning is the single exception and goes through {@see self::prune()}, which
 * is a deliberate retention decision rather than an edit (S4).
 *
 * @property int $id
 * @property string $action
 * @property array<string, mixed>|null $before_data
 * @property array<string, mixed>|null $after_data
 */
class AuditLog extends Model
{
    /** There is no `updated_at`, because there is no update. */
    public const UPDATED_AT = null;

    /** @var list<string> */
    protected $fillable = [
        'user_id', 'actor_name', 'actor_role',
        'action', 'entity_type', 'entity_id', 'entity_label',
        'before_data', 'after_data', 'context',
        'ip_address', 'user_agent',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'before_data' => 'array',
            'after_data' => 'array',
            'created_at' => 'datetime',
        ];
    }

    protected static function booted(): void
    {
        static::updating(static function (): never {
            throw new RuntimeException(
                'Audit entries are append-only: an entry cannot be changed once written.'
            );
        });

        static::deleting(static function (): never {
            throw new RuntimeException(
                'Audit entries are append-only: use AuditLog::prune() to apply a retention policy.'
            );
        });
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /**
     * Apply a retention policy.
     *
     * The one way rows leave this table, and it is deliberately not an edit: it
     * removes everything older than a date somebody chose, and the caller
     * records that it happened. A log that grows forever fills a shared host's
     * disk and takes the site down with it, which is not more secure than a log
     * with a stated retention.
     *
     * Bypasses the model events on purpose — this is the exception they exist
     * to make visible, and it is reachable only from `audit:prune`.
     */
    public static function prune(\DateTimeInterface $before): int
    {
        return static::query()->where('created_at', '<', $before)->getQuery()->delete();
    }

    /** @param  Builder<self>  $query */
    public function scopeNewestFirst(Builder $query): void
    {
        $query->orderByDesc('created_at')->orderByDesc('id');
    }
}
