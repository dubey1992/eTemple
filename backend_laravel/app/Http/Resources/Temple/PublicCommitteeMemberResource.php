<?php

declare(strict_types=1);

namespace App\Http\Resources\Temple;

use App\Models\CommitteeMember;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One committee member as the public site sees them.
 *
 * The third and last layer of the consent gate. The service already refuses to
 * set a visibility flag without recorded consent, and withdrawal already clears
 * the flags — this asks `mayPublish()` once more before emitting each personal
 * field, because this is the code path that actually reaches a stranger's
 * browser.
 *
 * A detail that may not be published is **omitted**, not sent as null
 * (PHASE_3_PLAN assumption D5): an absent key cannot be rendered by accident,
 * logged, or misread by a future client as "unknown, ask again".
 *
 * @mixin CommitteeMember
 */
class PublicCommitteeMemberResource extends JsonResource
{
    public function __construct(CommitteeMember $member, private readonly Language $language)
    {
        parent::__construct($member);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var CommitteeMember $member */
        $member = $this->resource;

        return [
            'id' => $this->id,
            'name' => LocalizedText::resolve($this->name_hi, $this->name_en, $this->language)->toArray(),
            'designation' => LocalizedText::resolve(
                $this->designation_hi, $this->designation_en, $this->language
            )->toArray(),
            'bio' => LocalizedText::resolve($this->bio_hi, $this->bio_en, $this->language)->toArray(),
            'tenure_start' => $this->tenure_start?->toDateString(),
            'tenure_end' => $this->tenure_end?->toDateString(),
            'sort_order' => $this->sort_order,

            // Personal details, each behind its own consent-checked flag.
            ...($member->mayPublish('show_phone_publicly') ? ['phone' => $this->phone] : []),
            ...($member->mayPublish('show_email_publicly') ? ['email' => $this->email] : []),
            ...($member->mayPublish('show_photo_publicly') ? ['photo_url' => $this->photo_url] : []),
        ];
    }
}
