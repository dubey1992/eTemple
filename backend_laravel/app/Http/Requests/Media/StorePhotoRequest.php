<?php

declare(strict_types=1);

namespace App\Http\Requests\Media;

use App\Models\Media;
use App\Services\Media\ImageProcessor;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * A photograph upload (multipart).
 *
 * The rules here are the **outer** wall only. `image` and `mimes` both trust
 * the extension and the browser's declared type, which are attacker-controlled,
 * so the real check is {@see ImageProcessor}: detected MIME,
 * decodability and dimensions, from the bytes themselves
 * (PHASE_5_PLAN assumption M2). Failing here first simply saves the work.
 */
class StorePhotoRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::MEDIA_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'file' => [
                'required',
                'file',
                'max:'.(int) config('media.max_upload_kb', 8192),
            ],

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
