<?php

declare(strict_types=1);

namespace App\Http\Resources\Enquiries;

use App\Models\Enquiry;
use App\Support\EnquiryCategory;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One enquiry as the committee sees it.
 *
 * There is no public counterpart and there is not going to be: a villager's
 * name, telephone number and complaint reach no public endpoint at any status
 * (PHASE_7_PLAN assumption N1). Every field below is behind
 * `enquiries.manage` — and that is the *read* right as well as the write one,
 * because reading is the sensitive act here (N9).
 *
 * `submitted_ip_hash` is deliberately absent even from this. It exists for
 * correlating abuse inside the database, not for showing to a committee member,
 * and nothing in the inbox is improved by putting a hash on the screen.
 *
 * @mixin Enquiry
 */
class AdminEnquiryResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Enquiry $enquiry */
        $enquiry = $this->resource;

        return [
            'id' => $this->id,
            'reference' => $this->reference,

            'name' => $this->name,
            'mobile' => $this->mobile,
            'email' => $this->email,

            'category' => $this->category,
            // The label travels too, so a client that has not been taught a
            // newly added category still shows a word rather than a code.
            'category_label' => EnquiryCategory::label($enquiry->category),

            'message' => $this->message,
            'preferred_language' => $this->preferred_language,

            'status' => $this->status,
            'is_open' => $enquiry->isOpen(),

            'assigned_to' => $enquiry->assigned_to,
            'assigned_to_name' => $this->whenLoaded('assignee', fn () => $enquiry->assignee?->fullName()),

            'resolved_at' => $enquiry->resolved_at?->toIso8601String(),
            'resolved_by_name' => $this->whenLoaded('resolver', fn () => $enquiry->resolver?->fullName()),

            'acknowledged_at' => $enquiry->acknowledged_at?->toIso8601String(),

            'created_at' => $enquiry->created_at?->toIso8601String(),
            'updated_at' => $enquiry->updated_at?->toIso8601String(),
        ];
    }
}
