<?php

declare(strict_types=1);

namespace App\Http\Requests\Content;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Every settings field is optional: the committee fills the site in over time
 * and a half-configured site must still save.
 *
 * `navigation`, when present, replaces the whole menu (see SiteSettingService).
 */
class UpdateSiteSettingsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can('manage-content') ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'tagline_hi' => ['nullable', 'string', 'max:200'],
            'tagline_en' => ['nullable', 'string', 'max:200'],
            'footer_text_hi' => ['nullable', 'string', 'max:400'],
            'footer_text_en' => ['nullable', 'string', 'max:400'],

            'address_line1' => ['nullable', 'string', 'max:200'],
            'address_line2' => ['nullable', 'string', 'max:200'],
            'village' => ['nullable', 'string', 'max:120'],
            'panchayat' => ['nullable', 'string', 'max:120'],
            'police_station' => ['nullable', 'string', 'max:120'],
            'district' => ['nullable', 'string', 'max:120'],
            'state' => ['nullable', 'string', 'max:120'],
            'postal_code' => ['nullable', 'string', 'max:20'],
            'country' => ['nullable', 'string', 'max:120'],

            'contact_phone' => ['nullable', 'string', 'max:40'],
            'contact_email' => ['nullable', 'email:rfc', 'max:191'],
            'map_url' => ['nullable', 'url', 'max:500'],
            'social_links' => ['nullable', 'array'],
            'social_links.*' => ['nullable', 'url', 'max:300'],

            'default_meta_title_hi' => ['nullable', 'string', 'max:200'],
            'default_meta_title_en' => ['nullable', 'string', 'max:200'],
            'default_meta_description_hi' => ['nullable', 'string', 'max:320'],
            'default_meta_description_en' => ['nullable', 'string', 'max:320'],

            'navigation' => ['sometimes', 'array', 'max:20'],
            'navigation.*.label_hi' => ['required', 'string', 'max:120'],
            'navigation.*.label_en' => ['nullable', 'string', 'max:120'],
            'navigation.*.route' => ['required', 'string', 'max:300'],
            'navigation.*.sort_order' => ['nullable', 'integer', 'min:0', 'max:9999'],
            'navigation.*.is_visible' => ['nullable', 'boolean'],
        ];
    }
}
