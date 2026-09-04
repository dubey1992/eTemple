<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\CommitteeMemberFactory;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * A member of the temple management committee (spec Phase 3 entity).
 *
 * Personal details are consent-gated. `contact_consent_at` is a recorded fact,
 * not a UI checkbox: it carries a timestamp and the account that recorded it,
 * and no personal detail is published while it is null — see
 * `mayPublish()` and PHASE_3_PLAN assumption D4.
 *
 * @property int $id
 * @property string $name_hi
 * @property string|null $name_en
 * @property string $designation_hi
 * @property bool $is_published
 * @property Carbon|null $contact_consent_at
 * @property Carbon|null $tenure_start
 * @property Carbon|null $tenure_end
 */
class CommitteeMember extends Model
{
    /** @use HasFactory<CommitteeMemberFactory> */
    use HasFactory;

    /**
     * The visibility flags, mapped to the column each one reveals.
     *
     * @var array<string, string>
     */
    public const CONSENT_GATED = [
        'show_phone_publicly' => 'phone',
        'show_email_publicly' => 'email',
        'show_photo_publicly' => 'photo_url',
    ];

    /** @var list<string> */
    protected $fillable = [
        'name_hi', 'name_en',
        'designation_hi', 'designation_en',
        'bio_hi', 'bio_en',
        'phone', 'email', 'photo_url',
        'tenure_start', 'tenure_end',
        'is_published',
        'show_phone_publicly', 'show_email_publicly', 'show_photo_publicly',
        'sort_order',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'tenure_start' => 'date',
            'tenure_end' => 'date',
            'is_published' => 'boolean',
            'contact_consent_at' => 'datetime',
            'show_phone_publicly' => 'boolean',
            'show_email_publicly' => 'boolean',
            'show_photo_publicly' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function consentRecordedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'consent_recorded_by');
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

    public function hasConsent(): bool
    {
        return $this->contact_consent_at !== null;
    }

    /**
     * Whether one consent-gated detail may appear publicly.
     *
     * The visibility flag alone is never enough: consent must be on record.
     * This is the last of the three checks — the service refuses to set a flag
     * without consent, withdrawal clears the flags, and the public resource
     * still asks this before emitting the field.
     */
    public function mayPublish(string $flag): bool
    {
        if (! array_key_exists($flag, self::CONSENT_GATED)) {
            return false;
        }

        return $this->hasConsent() && (bool) $this->{$flag};
    }

    /** True once the member's term has ended. */
    public function tenureHasEnded(): bool
    {
        return $this->tenure_end !== null && $this->tenure_end->isBefore(today());
    }

    /**
     * The members a visitor may see: published, and still serving.
     *
     * Filtered in the query rather than the serializer, so an unpublished
     * member cannot leak through a presentation mistake — the same discipline
     * Phase 1 established for draft pages.
     *
     * @param  Builder<CommitteeMember>  $query
     * @return Builder<CommitteeMember>
     */
    public function scopePubliclyVisible(Builder $query): Builder
    {
        return $query
            ->where('is_published', true)
            ->where(fn (Builder $q) => $q
                ->whereNull('tenure_end')
                ->orWhere('tenure_end', '>=', today()));
    }

    /**
     * @param  Builder<CommitteeMember>  $query
     * @return Builder<CommitteeMember>
     */
    public function scopeInDisplayOrder(Builder $query): Builder
    {
        return $query->orderBy('sort_order')->orderBy('id');
    }
}
