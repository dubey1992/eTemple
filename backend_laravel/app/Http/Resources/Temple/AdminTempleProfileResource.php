<?php

declare(strict_types=1);

namespace App\Http\Resources\Temple;

use App\Models\TempleProfile;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The temple profile as the editor sees it: both languages raw, no fallback.
 *
 * @mixin TempleProfile
 */
class AdminTempleProfileResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'name_hi' => $this->name_hi,
            'name_en' => $this->name_en,
            'history_hi' => $this->history_hi,
            'history_en' => $this->history_en,
            'mission_hi' => $this->mission_hi,
            'mission_en' => $this->mission_en,
            'address_line1' => $this->address_line1,
            'address_line2' => $this->address_line2,
            'village' => $this->village,
            'panchayat' => $this->panchayat,
            'police_station' => $this->police_station,
            'district' => $this->district,
            'state' => $this->state,
            'postal_code' => $this->postal_code,
            'country' => $this->country,
            'logo_url' => $this->logo_url,
            'map_url' => $this->map_url,
            'established_year' => $this->established_year,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
