<?php

declare(strict_types=1);

namespace App\Http\Resources\Content;

use App\Models\NavigationItem;
use App\Models\SiteSetting;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * Site settings as the editor sees them: both languages raw, and every
 * navigation item including hidden ones.
 *
 * @mixin SiteSetting
 */
class AdminSiteSettingsResource extends JsonResource
{
    /**
     * @param  Collection<int, NavigationItem>  $navigation
     */
    public function __construct(SiteSetting $settings, private readonly Collection $navigation)
    {
        parent::__construct($settings);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'tagline_hi' => $this->tagline_hi,
            'tagline_en' => $this->tagline_en,
            'footer_text_hi' => $this->footer_text_hi,
            'footer_text_en' => $this->footer_text_en,
            'contact_phone' => $this->contact_phone,
            'contact_email' => $this->contact_email,
            'social_links' => $this->social_links ?? [],
            'default_meta_title_hi' => $this->default_meta_title_hi,
            'default_meta_title_en' => $this->default_meta_title_en,
            'default_meta_description_hi' => $this->default_meta_description_hi,
            'default_meta_description_en' => $this->default_meta_description_en,
            'updated_at' => $this->updated_at?->toIso8601String(),
            'navigation' => $this->navigation
                ->map(fn (NavigationItem $item) => (new NavigationItemResource($item))->resolve($request))
                ->all(),
        ];
    }
}
