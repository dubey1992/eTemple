<?php

declare(strict_types=1);

namespace App\Http\Resources\Accounting;

use App\Models\AccountingSetting;
use App\Support\Money;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The settings row as the committee sees it.
 *
 * @mixin AccountingSetting
 */
class AdminAccountingSettingsResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var AccountingSetting $settings */
        $settings = $this->resource;

        return [
            'is_published' => $settings->is_published,

            'opening_balance_paise' => $settings->opening_balance_paise,
            'opening_balance_formatted' => Money::format($settings->opening_balance_paise),
            'opening_balance_date' => $settings->opening_balance_date?->toDateString(),

            'intro_hi' => $this->intro_hi,
            'intro_en' => $this->intro_en,
            'note_hi' => $this->note_hi,
            'note_en' => $this->note_en,

            'updated_at' => $settings->updated_at?->toIso8601String(),
            'updated_by_name' => $this->whenLoaded(
                'updatedBy',
                fn () => $settings->updatedBy?->fullName(),
            ),
        ];
    }
}
