<?php

declare(strict_types=1);

namespace App\Http\Resources\Media;

use App\Models\Media;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * One item as the library sees it: both languages raw, plus the technical
 * detail an editor needs to judge a file — its detected type, its stored size
 * and its dimensions.
 *
 * `original_name` is the uploader's own file name, kept as a label so they can
 * recognise what they picked. It is never a path (PHASE_5_PLAN assumption M2).
 *
 * @mixin Media
 */
class AdminMediaResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        /** @var Media $media */
        $media = $this->resource;

        return [
            'id' => $this->id,
            'media_type' => $this->media_type,
            'title_hi' => $this->title_hi,
            'title_en' => $this->title_en,
            'caption_hi' => $this->caption_hi,
            'caption_en' => $this->caption_en,

            'thumb_url' => $media->variantUrl('thumb'),
            'medium_url' => $media->variantUrl('medium'),
            'large_url' => $media->variantUrl('large'),
            'file_url' => $media->fileUrl(),

            'external_url' => $this->external_url,
            'provider' => $this->provider,
            'provider_ref' => $this->provider_ref,
            'embed_url' => $media->embedUrl(),
            'thumbnail_url' => $this->thumbnail_url,

            'mime_type' => $this->mime_type,
            'byte_size' => $this->byte_size,
            'width' => $this->width,
            'height' => $this->height,
            'original_name' => $this->original_name,

            'album_id' => $this->album_id,
            'sort_order' => $this->sort_order,
            'status' => $this->status,
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
