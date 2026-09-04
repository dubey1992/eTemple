<?php

declare(strict_types=1);

namespace App\Http\Requests\Media;

use App\Models\Media;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Editing an existing item: titles, captions, album, order, status — and for a
 * video, the link.
 *
 * The **file** is deliberately absent. Every reference to a photograph on this
 * site is by URL, so swapping the bytes under a URL would silently change a
 * page, an event poster and a committee portrait at once. Uploading a new item
 * and repointing the reference is visible; replacing bytes in place is not.
 */
class UpdateMediaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::MEDIA_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'title_hi' => ['required', 'string', 'max:200'],
            'title_en' => ['nullable', 'string', 'max:200'],
            'caption_hi' => ['nullable', 'string', 'max:2000'],
            'caption_en' => ['nullable', 'string', 'max:2000'],

            'external_url' => ['nullable', 'url', 'max:500'],
            'thumbnail_url' => ['nullable', 'url', 'max:500'],

            'album_id' => ['nullable', 'integer', 'exists:albums,id'],
            'sort_order' => ['nullable', 'integer', 'min:0', 'max:65535'],
            'status' => ['required', Rule::in(Media::statuses())],
        ];
    }
}
