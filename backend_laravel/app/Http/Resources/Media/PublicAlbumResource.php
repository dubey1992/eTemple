<?php

declare(strict_types=1);

namespace App\Http\Resources\Media;

use App\Models\Album;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One album as a visitor sees it, with its cover and how many **published**
 * photographs it holds — the public count, not the library's.
 *
 * @mixin Album
 */
class PublicAlbumResource extends JsonResource
{
    public function __construct(Album $album, private readonly Language $language)
    {
        parent::__construct($album);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Album $album */
        $album = $this->resource;

        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'requested_language' => $this->language->value,
            'title' => LocalizedText::resolve(
                $this->title_hi, $this->title_en, $this->language
            )->toArray(),
            'description' => LocalizedText::resolve(
                $this->description_hi, $this->description_en, $this->language
            )->toArray(),
            'cover_url' => $album->cover?->variantUrl('medium'),
            'media_count' => (int) ($album->media_count ?? 0),
            'sort_order' => $this->sort_order,
        ];
    }
}
