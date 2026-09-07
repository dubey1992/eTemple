<?php

declare(strict_types=1);

namespace App\Http\Resources\Content;

use App\Models\Page;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One published page in the index: enough to link to it, not its content.
 *
 * Deliberately no `content`. The index is fetched on the home page, and shipping
 * every page's full text to answer "which pages exist" would grow without limit
 * as the committee writes more.
 *
 * @mixin Page
 */
class PublicPageSummaryResource extends JsonResource
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
            'title' => LocalizedText::resolve($this->title_hi, $this->title_en, $this->language)->toArray(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
