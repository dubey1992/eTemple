<?php

declare(strict_types=1);

namespace App\Http\Resources\Donations;

use App\Models\DonationSetting;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Where devotees may send money — the only public thing this phase adds.
 *
 * Deliberately the whole of the public surface. There is no donation list, no
 * count, no total and no "our latest donor": donor detail reaches no public
 * endpoint at any status (PHASE_6_PLAN assumption N5). Aggregate transparency
 * is Phase 9, which is a different requirement with a different consent
 * question.
 *
 * @mixin DonationSetting
 */
class PublicDonationSettingsResource extends JsonResource
{
    public function __construct(DonationSetting $settings, private readonly Language $language)
    {
        parent::__construct($settings);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'requested_language' => $this->language->value,
            'upi_id' => $this->upi_id,
            'bank_name' => $this->bank_name,
            'account_name' => $this->account_name,
            // Exactly as the committee typed it; masking is their decision.
            'account_number' => $this->account_number,
            'ifsc' => $this->ifsc,
            'qr_url' => $this->qr_url,
            'intro' => LocalizedText::resolve($this->intro_hi, $this->intro_en, $this->language)->toArray(),
            'note' => LocalizedText::resolve($this->note_hi, $this->note_en, $this->language)->toArray(),
        ];
    }
}
