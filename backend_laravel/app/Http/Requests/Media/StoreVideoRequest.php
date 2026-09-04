<?php

declare(strict_types=1);

namespace App\Http\Requests\Media;

use App\Models\Media;
use App\Services\Media\VideoLink;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * A linked video (JSON). Nothing is uploaded.
 *
 * `url` here only establishes the shape; the host allow-list and the video-id
 * extraction are {@see VideoLink}, because an arbitrary
 * embed source coming out of an admin form is a stored-XSS vector
 * (PHASE_5_PLAN assumption M1).
 */
class StoreVideoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::MEDIA_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'external_url' => ['required', 'url', 'max:500'],
            'thumbnail_url' => ['nullable', 'url', 'max:500'],

            'title_hi' => ['required', 'string', 'max:200'],
            'title_en' => ['nullable', 'string', 'max:200'],
            'caption_hi' => ['nullable', 'string', 'max:2000'],
            'caption_en' => ['nullable', 'string', 'max:2000'],

            'album_id' => ['nullable', 'integer', 'exists:albums,id'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:65535'],
            'status' => ['required', Rule::in(Media::statuses())],
        ];
    }
}
