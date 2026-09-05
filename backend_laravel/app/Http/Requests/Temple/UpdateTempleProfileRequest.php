<?php

declare(strict_types=1);

namespace App\Http\Requests\Temple;

use App\Models\TempleProfile;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Every profile field is optional: the committee fills the temple's details in
 * over time and a half-configured profile must still save.
 *
 * Hindi is not forced here even though it is the source language — requiring a
 * name before the committee has agreed one would block them from saving the
 * address, which is the field they usually have first.
 */
class UpdateTempleProfileRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::TEMPLE_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'name_hi' => ['nullable', 'string', 'max:200'],
            'name_en' => ['nullable', 'string', 'max:200'],
            'history_hi' => ['nullable', 'string', 'max:20000'],
            'history_en' => ['nullable', 'string', 'max:20000'],
            'mission_hi' => ['nullable', 'string', 'max:20000'],
            'mission_en' => ['nullable', 'string', 'max:20000'],

            // The address is bilingual like everything else the site publishes:
            // `अमरपुर पंखोरिया` and `Amarpur Pankhoriya` are the same village
            // written in two scripts, and one column cannot hold both.
            'address_line1_hi' => ['nullable', 'string', 'max:200'],
            'address_line1_en' => ['nullable', 'string', 'max:200'],
            'address_line2_hi' => ['nullable', 'string', 'max:200'],
            'address_line2_en' => ['nullable', 'string', 'max:200'],
            'village_hi' => ['nullable', 'string', 'max:120'],
            'village_en' => ['nullable', 'string', 'max:120'],
            'panchayat_hi' => ['nullable', 'string', 'max:120'],
            'panchayat_en' => ['nullable', 'string', 'max:120'],
            'police_station_hi' => ['nullable', 'string', 'max:120'],
            'police_station_en' => ['nullable', 'string', 'max:120'],
            'district_hi' => ['nullable', 'string', 'max:120'],
            'district_en' => ['nullable', 'string', 'max:120'],
            'state_hi' => ['nullable', 'string', 'max:120'],
            'state_en' => ['nullable', 'string', 'max:120'],
            // Digits: the same in either language.
            'postal_code' => ['nullable', 'string', 'max:20'],
            'country_hi' => ['nullable', 'string', 'max:120'],
            'country_en' => ['nullable', 'string', 'max:120'],

            // The retired single-language columns are **refused**, not ignored.
            // A caller that still sends `village` would otherwise get a 200
            // back with nothing saved, which is the silent narrowing this
            // project refuses everywhere else.
            ...array_fill_keys(TempleProfile::BILINGUAL_ADDRESS_PARTS, ['prohibited']),

            // URLs rather than uploads until Phase 5 builds media handling with
            // its own MIME and size validation (PHASE_3_PLAN assumption D10).
            'logo_url' => ['nullable', 'url', 'max:500'],
            'map_url' => ['nullable', 'url', 'max:500'],

            'established_year' => ['nullable', 'integer', 'min:1000', 'max:'.(int) date('Y')],
        ];
    }
}
