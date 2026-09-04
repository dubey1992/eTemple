<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\EventFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * A puja, aarti, bhajan-kirtan or festival (spec Phase 4 entity).
 *
 * The row is the **rule**, not one instance: see the migration and
 * `EventService::occurrences()`.
 *
 * @property int $id
 * @property string $event_type
 * @property string $title_hi
 * @property Carbon $start_at
 * @property Carbon|null $end_at
 * @property string $recurrence
 * @property array<int, int>|null $recurrence_days
 * @property Carbon|null $recurrence_until
 * @property bool $is_featured
 * @property string $status
 */
class Event extends Model
{
    /** @use HasFactory<EventFactory> */
    use HasFactory;

    public const STATUS_DRAFT = 'draft';

    public const STATUS_PUBLISHED = 'published';

    public const STATUS_CANCELLED = 'cancelled';

    public const RECURRENCE_NONE = 'none';

    public const RECURRENCE_DAILY = 'daily';

    public const RECURRENCE_WEEKLY = 'weekly';

    public const RECURRENCE_MONTHLY = 'monthly';

    public const RECURRENCE_YEARLY = 'yearly';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [self::STATUS_DRAFT, self::STATUS_PUBLISHED, self::STATUS_CANCELLED];
    }

    /** @return list<string> */
    public static function recurrences(): array
    {
        return [
            self::RECURRENCE_NONE,
            self::RECURRENCE_DAILY,
            self::RECURRENCE_WEEKLY,
            self::RECURRENCE_MONTHLY,
            self::RECURRENCE_YEARLY,
        ];
    }

    /** @var list<string> */
    protected $fillable = [
        'event_type',
        'title_hi', 'title_en',
        'description_hi', 'description_en',
        'venue_hi', 'venue_en',
        'start_at', 'end_at',
        'recurrence', 'recurrence_days', 'recurrence_until',
        'poster_url', 'is_featured', 'status',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'start_at' => 'datetime',
            'end_at' => 'datetime',
            'recurrence_until' => 'date',
            'recurrence_days' => 'array',
            'is_featured' => 'boolean',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function createdBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function isPublished(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }

    public function isCancelled(): bool
    {
        return $this->status === self::STATUS_CANCELLED;
    }

    public function repeats(): bool
    {
        return $this->recurrence !== self::RECURRENCE_NONE;
    }

    /** How long one occurrence lasts, or null when no end was stated. */
    public function duration(): ?\DateInterval
    {
        return $this->end_at?->diffAsDateInterval($this->start_at);
    }

    /**
     * What a visitor may see.
     *
     * Published **and** cancelled: silently dropping a cancelled festival is
     * the worst option, because devotees who planned around it would find
     * nothing and assume the site was broken. Drafts are excluded here, in the
     * query rather than the serializer, so an unfinished event cannot leak
     * through a presentation mistake (PHASE_4_PLAN assumption E4).
     *
     * @param  Builder<Event>  $query
     * @return Builder<Event>
     */
    public function scopePubliclyVisible(Builder $query): Builder
    {
        return $query->whereIn('status', [self::STATUS_PUBLISHED, self::STATUS_CANCELLED]);
    }
}
