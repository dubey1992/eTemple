<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\AnnouncementPriority;
use Database\Factories\AnnouncementFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * One notice from the temple (spec Phase 8 entity).
 *
 *   draft ──publish──▶ published ──archive──▶ archived
 *
 * and, separately and at most once:
 *
 *   published ──send──▶ (still published, now with sent_at)
 *
 * Those two are not the same axis, which is the whole point. Publishing decides
 * what the website shows; sending puts the notice in somebody's inbox and
 * cannot be taken back (PHASE_8_PLAN assumption N1).
 *
 * @property int $id
 * @property string $title_hi
 * @property string|null $title_en
 * @property string $message_hi
 * @property string|null $message_en
 * @property string $priority
 * @property Carbon $start_at
 * @property Carbon|null $end_at
 * @property array<int, string>|null $channels
 * @property string $status
 * @property Carbon|null $sent_at
 * @property int|null $recipient_count
 */
class Announcement extends Model
{
    /** @use HasFactory<AnnouncementFactory> */
    use HasFactory;

    /** Written, not shown to anybody. */
    public const STATUS_DRAFT = 'draft';

    /** Shown on the website — but only inside its own window. */
    public const STATUS_PUBLISHED = 'published';

    /** Taken down. Kept, with whatever record of sending it carries. */
    public const STATUS_ARCHIVED = 'archived';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [self::STATUS_DRAFT, self::STATUS_PUBLISHED, self::STATUS_ARCHIVED];
    }

    /**
     * What an editor may set.
     *
     * Deliberately not `status`, `sent_at`, `sent_by` or `recipient_count`:
     * publishing, archiving and sending are decisions, not fields, and each has
     * its own endpoint and its own rules.
     *
     * @var list<string>
     */
    protected $fillable = [
        'title_hi', 'title_en', 'message_hi', 'message_en',
        'priority', 'start_at', 'end_at', 'link_url',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'start_at' => 'datetime',
            'end_at' => 'datetime',
            'sent_at' => 'datetime',
            'channels' => 'array',
            'recipient_count' => 'integer',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function author(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    /** @return BelongsTo<User, $this> */
    public function sender(): BelongsTo
    {
        return $this->belongsTo(User::class, 'sent_by');
    }

    public function isPublished(): bool
    {
        return $this->status === self::STATUS_PUBLISHED;
    }

    public function isArchived(): bool
    {
        return $this->status === self::STATUS_ARCHIVED;
    }

    public function wasSent(): bool
    {
        return $this->sent_at !== null;
    }

    /**
     * Whether this announcement is on the website **right now**.
     *
     * Computed, never stored. A stored flag would have to be flipped by a
     * scheduler, and an announcement that goes live only when cron runs does
     * not go live at all on a host without cron (assumption N3).
     */
    public function isShowing(?Carbon $at = null): bool
    {
        $moment = $at ?? Carbon::now();

        return $this->isPublished()
            && $this->start_at->lessThanOrEqualTo($moment)
            && ($this->end_at === null || $this->end_at->greaterThan($moment));
    }

    /** Published, but its window has not opened yet. */
    public function isScheduled(?Carbon $at = null): bool
    {
        return $this->isPublished() && $this->start_at->greaterThan($at ?? Carbon::now());
    }

    /** Published, but its window has closed. */
    public function hasExpired(?Carbon $at = null): bool
    {
        $moment = $at ?? Carbon::now();

        return $this->isPublished()
            && $this->end_at !== null
            && $this->end_at->lessThanOrEqualTo($moment);
    }

    /**
     * Everything the public may see: published, and inside its window.
     *
     * The filter is here, in the query, rather than in a serializer. If it lived
     * in the serializer then "scheduled" would be a display convention, and the
     * first caller to hit the endpoint directly would read next week's news
     * (assumption N2).
     *
     * @param  Builder<Announcement>  $query
     */
    public function scopeCurrentlyShowing(Builder $query, ?Carbon $at = null): void
    {
        $moment = $at ?? Carbon::now();

        $query->where('status', self::STATUS_PUBLISHED)
            ->where('start_at', '<=', $moment)
            ->where(function (Builder $window) use ($moment) {
                $window->whereNull('end_at')->orWhere('end_at', '>', $moment);
            });
    }

    /**
     * Loudest first, then the one that started most recently.
     *
     * @param  Builder<Announcement>  $query
     */
    public function scopeInNoticeOrder(Builder $query): void
    {
        $query->orderByRaw(
            'CASE priority WHEN ? THEN 3 WHEN ? THEN 2 ELSE 1 END DESC',
            [AnnouncementPriority::URGENT, AnnouncementPriority::IMPORTANT],
        )->orderByDesc('start_at')->orderByDesc('id');
    }
}
