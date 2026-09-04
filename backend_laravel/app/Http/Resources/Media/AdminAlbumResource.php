<?php

declare(strict_types=1);

namespace App\Http\Resources\Media;

use App\Models\Album;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One album as the editor sees it: both languages raw, and a count that
 * **includes drafts**.
 *
 * Deliberately a different number from the public one: an editor needs to know
 * how much is still unfinished, and a visitor needs to know how much there is
 * to look at.
 *
 * @mixin Album
 */
class AdminAlbumResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Album $album */
        $album = $this->resource;

        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'title_hi' => $this->title_hi,
            'title_en' => $this->title_en,
            'description_hi' => $this->description_hi,
            'description_en' => $this->description_en,
            'cover_media_id' => $this->cover_media_id,
            'cover_url' => $album->cover?->variantUrl('thumb'),
            'media_count' => (int) ($album->media_count ?? 0),
            'sort_order' => $this->sort_order,
            'status' => $this->status,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
