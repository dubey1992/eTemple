<?php

declare(strict_types=1);

namespace App\Http\Resources\Donations;

use App\Models\DonationSetting;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The donation details as the editor sees them: both languages raw, and the
 * publication state.
 *
 * `is_publicly_visible` is not the same as `is_published`, and the editor is
 * told both: a row published with every field blank would render an empty box
 * on the public page, which reads as a broken site rather than an unconfigured
 * one.
 *
 * @mixin DonationSetting
 */
class AdminDonationSettingsResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var DonationSetting $settings */
        $settings = $this->resource;

        return [
            'upi_id' => $this->upi_id,
            'bank_name' => $this->bank_name,
            'account_name' => $this->account_name,
            'account_number' => $this->account_number,
            'ifsc' => $this->ifsc,
            'qr_url' => $this->qr_url,
            'intro_hi' => $this->intro_hi,
            'intro_en' => $this->intro_en,
            'note_hi' => $this->note_hi,
            'note_en' => $this->note_en,
            'is_published' => $settings->is_published,
            'is_publicly_visible' => $settings->isPubliclyVisible(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
