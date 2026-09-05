<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\EnquiryFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * One message from a devotee (spec Phase 7 entity).
 *
 * The lifecycle:
 *
 *   new ──▶ in_progress ──▶ resolved
 *    └──────────────────────▶ spam
 *
 * `spam` is terminal and to the side: it takes a row out of the inbox without
 * destroying it, which is the only removal this phase has (PHASE_7_PLAN N8).
 * Reopening a resolved enquiry clears `resolved_at`, so that column always
 * answers "when was this actually closed" rather than "when was it last
 * touched" (N7).
 *
 * @property int $id
 * @property string $reference
 * @property string $name
 * @property string|null $mobile
 * @property string|null $email
 * @property string $category
 * @property string $message
 * @property string $preferred_language
 * @property string $status
 * @property int|null $assigned_to
 * @property Carbon|null $resolved_at
 * @property Carbon|null $acknowledged_at
 * @property Carbon $created_at
 */
class Enquiry extends Model
{
    /** @use HasFactory<EnquiryFactory> */
    use HasFactory;

    /** Nobody has picked it up yet. */
    public const STATUS_NEW = 'new';

    /** Somebody is dealing with it. */
    public const STATUS_IN_PROGRESS = 'in_progress';

    /** Answered. `resolved_at` says when. */
    public const STATUS_RESOLVED = 'resolved';

    /** Junk. Kept, but out of the way. */
    public const STATUS_SPAM = 'spam';

    /** @return list<string> */
    public static function statuses(): array
    {
        return [
            self::STATUS_NEW,
            self::STATUS_IN_PROGRESS,
            self::STATUS_RESOLVED,
            self::STATUS_SPAM,
        ];
    }

    /**
     * Only what a devotee types.
     *
     * Deliberately not `reference`, `status`, `assigned_to`, `resolved_at` or
     * any of the forensic columns: those are administrative decisions or facts
     * about the request, and an anonymous payload must not be able to reach one
     * by naming it. The service sets each of those explicitly.
     *
     * @var list<string>
     */
    protected $fillable = [
        'name', 'mobile', 'email', 'category', 'message', 'preferred_language',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'resolved_at' => 'datetime',
            'acknowledged_at' => 'datetime',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function assignee(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_to');
    }

    /** @return BelongsTo<User, $this> */
    public function resolver(): BelongsTo
    {
        return $this->belongsTo(User::class, 'resolved_by');
    }

    public function isResolved(): bool
    {
        return $this->status === self::STATUS_RESOLVED;
    }

    public function isSpam(): bool
    {
        return $this->status === self::STATUS_SPAM;
    }

    /** Still needs somebody: what the inbox counts as outstanding. */
    public function isOpen(): bool
    {
        return in_array($this->status, [self::STATUS_NEW, self::STATUS_IN_PROGRESS], true);
    }

    /**
     * The inbox's default: everything except junk.
     *
     * Spam is excluded by a scope rather than by deletion, so it is one query
     * parameter away when somebody wants to check what was thrown out.
     *
     * @param  Builder<Enquiry>  $query
     */
    public function scopeNotSpam(Builder $query): void
    {
        $query->where('status', '!=', self::STATUS_SPAM);
    }

    /**
     * Unanswered first, then newest first.
     *
     * @param  Builder<Enquiry>  $query
     */
    public function scopeInInboxOrder(Builder $query): void
    {
        $query->orderByRaw(
            'CASE status WHEN ? THEN 0 WHEN ? THEN 1 ELSE 2 END',
            [self::STATUS_NEW, self::STATUS_IN_PROGRESS],
        )->orderByDesc('created_at')->orderByDesc('id');
    }
}
