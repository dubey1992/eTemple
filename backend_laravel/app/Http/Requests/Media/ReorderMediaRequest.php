<?php

declare(strict_types=1);

namespace App\Http\Requests\Media;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * A new gallery arrangement.
 *
 * The whole ordering is sent, not a single move, so the server applies one
 * transaction and a dropped request leaves the previous arrangement intact
 * rather than half of a new one.
 */
class ReorderMediaRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::MEDIA_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'ids' => ['required', 'array', 'min:1', 'max:500'],
            'ids.*' => ['integer', 'exists:media,id'],
        ];
    }
}
