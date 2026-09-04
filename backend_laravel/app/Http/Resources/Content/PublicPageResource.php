<?php

declare(strict_types=1);

namespace App\Http\Resources\Content;

use App\Models\Page;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A published page resolved for one language.
 *
 * Every text block reports which language was actually served and whether the
 * Hindi fallback was used, so the client can tell the visitor instead of
 * silently showing the wrong language.
 *
 * @mixin Page
 */
class PublicPageResource extends JsonResource
{
    public function __construct(Page $page, private readonly Language $language)
    {
        parent::__construct($page);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'requested_language' => $this->language->value,
            'title' => LocalizedText::resolve($this->title_hi, $this->title_en, $this->language)->toArray(),
            'content' => LocalizedText::resolve($this->content_hi, $this->content_en, $this->language)->toArray(),
            'meta_title' => LocalizedText::resolve(
                $this->meta_title_hi, $this->meta_title_en, $this->language
            )->toArray(),
            'meta_description' => LocalizedText::resolve(
                $this->meta_description_hi, $this->meta_description_en, $this->language
            )->toArray(),
            'published_at' => $this->published_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
