<?php

declare(strict_types=1);

namespace App\Http\Resources\Temple;

use App\Models\TempleProfile;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The temple's public identity, resolved for one language.
 *
 * Authoritative for the name and the address: the Flutter client renders its
 * header, hero, footer and page titles from `name` here, falling back to the
 * application shell string only while this request is in flight
 * (PHASE_3_PLAN assumption D3).
 *
 * @mixin TempleProfile
 */
class PublicTempleProfileResource extends JsonResource
{
    public function __construct(TempleProfile $profile, private readonly Language $language)
    {
        parent::__construct($profile);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'requested_language' => $this->language->value,
            'name' => LocalizedText::resolve($this->name_hi, $this->name_en, $this->language)->toArray(),
            'history' => LocalizedText::resolve(
                $this->history_hi, $this->history_en, $this->language
            )->toArray(),
            'mission' => LocalizedText::resolve(
                $this->mission_hi, $this->mission_en, $this->language
            )->toArray(),
            'address' => [
                'address_line1' => $this->address_line1,
                'address_line2' => $this->address_line2,
                'village' => $this->village,
                'panchayat' => $this->panchayat,
                'police_station' => $this->police_station,
                'district' => $this->district,
                'state' => $this->state,
                'postal_code' => $this->postal_code,
                'country' => $this->country,
                'map_url' => $this->map_url,
            ],
            'logo_url' => $this->logo_url,
            'established_year' => $this->established_year,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
