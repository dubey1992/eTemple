<?php

declare(strict_types=1);

namespace App\Http\Resources\Media;

use App\Models\Media;
use App\Support\Language;
use App\Support\LocalizedText;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One gallery item as a visitor sees it, resolved for a language.
 *
 * All three image sizes are sent on every item so the client can pick per use —
 * a grid tile takes `thumb`, a lightbox takes `medium` or `large` by form
 * factor. Sending one size only would mean either a grid that downloads
 * full-size photographs or a lightbox that shows blurred ones
 * (PHASE_5_PLAN assumption M11).
 *
 * For a video the embed URL is **built from the stored id**, never from
 * anything an admin typed.
 *
 * @mixin Media
 */
class PublicMediaResource extends JsonResource
{
    public function __construct(Media $media, private readonly Language $language)
    {
        parent::__construct($media);
    }

    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Media $media */
        $media = $this->resource;

        return [
            'id' => $this->id,
            'media_type' => $this->media_type,
            'requested_language' => $this->language->value,
            'title' => LocalizedText::resolve(
                $this->title_hi, $this->title_en, $this->language
            )->toArray(),
            'caption' => LocalizedText::resolve(
                $this->caption_hi, $this->caption_en, $this->language
            )->toArray(),

            'thumb_url' => $media->variantUrl('thumb'),
            'medium_url' => $media->variantUrl('medium'),
            'large_url' => $media->variantUrl('large'),
            'file_url' => $media->fileUrl(),

            'external_url' => $this->external_url,
            'provider' => $this->provider,
            'embed_url' => $media->embedUrl(),
            'thumbnail_url' => $this->thumbnail_url,

            'width' => $this->width,
            'height' => $this->height,
            'album_id' => $this->album_id,
            'sort_order' => $this->sort_order,
        ];
    }
}
