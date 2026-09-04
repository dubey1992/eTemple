<?php

declare(strict_types=1);

namespace App\Http\Requests\Temple;

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

            'address_line1' => ['nullable', 'string', 'max:200'],
            'address_line2' => ['nullable', 'string', 'max:200'],
            'village' => ['nullable', 'string', 'max:120'],
            'panchayat' => ['nullable', 'string', 'max:120'],
            'police_station' => ['nullable', 'string', 'max:120'],
            'district' => ['nullable', 'string', 'max:120'],
            'state' => ['nullable', 'string', 'max:120'],
            'postal_code' => ['nullable', 'string', 'max:20'],
            'country' => ['nullable', 'string', 'max:120'],

            // URLs rather than uploads until Phase 5 builds media handling with
            // its own MIME and size validation (PHASE_3_PLAN assumption D10).
            'logo_url' => ['nullable', 'url', 'max:500'],
            'map_url' => ['nullable', 'url', 'max:500'],

            'established_year' => ['nullable', 'integer', 'min:1000', 'max:'.(int) date('Y')],
        ];
    }
}
