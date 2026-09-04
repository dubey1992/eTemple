<?php

declare(strict_types=1);

namespace App\Http\Resources\Content;

use App\Models\NavigationItem;
use App\Models\SiteSetting;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Site-wide public content: hero tagline, footer, contact block, navigation and
 * default SEO metadata, all resolved for one language.
 *
 * The address block is Phase 1's source of truth and moves to the authoritative
 * temple_profile in Phase 3 (PHASE_1_PLAN assumption B2).
 *
 * @mixin SiteSetting
 */
class PublicSiteSettingsResource extends JsonResource
{
    /**
     * @param  Collection<int, NavigationItem>  $navigation
     */
    public function __construct(
        SiteSetting $settings,
        private readonly Language $language,
        private readonly Collection $navigation,
    ) {
        parent::__construct($settings);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'requested_language' => $this->language->value,
            'tagline' => LocalizedText::resolve(
                $this->tagline_hi, $this->tagline_en, $this->language
            )->toArray(),
            'footer_text' => LocalizedText::resolve(
                $this->footer_text_hi, $this->footer_text_en, $this->language
            )->toArray(),
            'contact' => [
                'address_line1' => $this->address_line1,
                'address_line2' => $this->address_line2,
                'village' => $this->village,
                'panchayat' => $this->panchayat,
                'police_station' => $this->police_station,
                'district' => $this->district,
                'state' => $this->state,
                'postal_code' => $this->postal_code,
                'country' => $this->country,
                'phone' => $this->contact_phone,
                'email' => $this->contact_email,
                'map_url' => $this->map_url,
            ],
            'social_links' => $this->social_links ?? [],
            'default_meta_title' => LocalizedText::resolve(
                $this->default_meta_title_hi, $this->default_meta_title_en, $this->language
            )->toArray(),
            'default_meta_description' => LocalizedText::resolve(
                $this->default_meta_description_hi, $this->default_meta_description_en, $this->language
            )->toArray(),
            'navigation' => $this->navigation
                ->map(fn (NavigationItem $item) => (new NavigationItemResource($item, $this->language))->resolve($request))
                ->all(),
        ];
    }
}
