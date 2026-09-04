<?php

declare(strict_types=1);

namespace App\Http\Resources\Content;

use App\Models\Page;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A page as the editor sees it: both languages raw, no fallback applied, and
 * including drafts. Only ever returned from the authorized admin surface.
 *
 * @mixin Page
 */
class AdminPageResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'title_hi' => $this->title_hi,
            'title_en' => $this->title_en,
            'content_hi' => $this->content_hi,
            'content_en' => $this->content_en,
            'meta_title_hi' => $this->meta_title_hi,
            'meta_title_en' => $this->meta_title_en,
            'meta_description_hi' => $this->meta_description_hi,
            'meta_description_en' => $this->meta_description_en,
            'status' => $this->status,
            'published_at' => $this->published_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
