<?php

declare(strict_types=1);

namespace App\Http\Resources\Temple;

use App\Models\CommitteeMember;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One committee member as the editor sees them: both languages raw, every
 * personal detail present, and the consent record shown explicitly.
 *
 * The editor is authenticated and holds `temple.manage` or `content.view`, so
 * the personal columns are visible here — that is the whole point of the admin
 * screen. What consent governs is *publication*, not administration.
 *
 * @mixin CommitteeMember
 */
class AdminCommitteeMemberResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var CommitteeMember $member */
        $member = $this->resource;

        return [
            'id' => $this->id,
            'name_hi' => $this->name_hi,
            'name_en' => $this->name_en,
            'designation_hi' => $this->designation_hi,
            'designation_en' => $this->designation_en,
            'bio_hi' => $this->bio_hi,
            'bio_en' => $this->bio_en,
            'phone' => $this->phone,
            'email' => $this->email,
            'photo_url' => $this->photo_url,
            'tenure_start' => $this->tenure_start?->toDateString(),
            'tenure_end' => $this->tenure_end?->toDateString(),
            'tenure_has_ended' => $member->tenureHasEnded(),
            'is_published' => $member->is_published,
            'sort_order' => $this->sort_order,

            'has_consent' => $member->hasConsent(),
            'contact_consent_at' => $this->contact_consent_at?->toIso8601String(),
            'consent_recorded_by' => $this->whenLoaded(
                'consentRecordedBy',
                fn () => $this->consentRecordedBy?->fullName(),
            ),
            'show_phone_publicly' => $member->show_phone_publicly,
            'show_email_publicly' => $member->show_email_publicly,
            'show_photo_publicly' => $member->show_photo_publicly,

            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
