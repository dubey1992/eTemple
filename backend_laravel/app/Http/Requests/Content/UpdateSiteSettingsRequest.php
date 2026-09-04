<?php

declare(strict_types=1);

namespace App\Http\Requests\Content;

use Illuminate\Foundation\Http\FormRequest;

/**
 * Every settings field is optional: the committee fills the site in over time
 * and a half-configured site must still save.
 *
 * `navigation`, when present, replaces the whole menu (see SiteSettingService).
 *
 * The postal address is deliberately absent: Phase 3 moved it to the temple
 * profile, and an address sent here is unknown input rather than a field that
 * is quietly ignored.
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

            'contact_phone' => ['nullable', 'string', 'max:40'],
            'contact_email' => ['nullable', 'email:rfc', 'max:191'],
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
