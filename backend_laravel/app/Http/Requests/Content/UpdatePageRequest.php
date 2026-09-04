<?php

declare(strict_types=1);

namespace App\Http\Requests\Content;

use App\Models\Page;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Hindi is the source language, so title_hi and content_hi are required.
 * Every English field is optional; a missing one triggers the documented
 * Hindi fallback rather than blocking the save.
 *
 * `slug` is not accepted here: it is the page's public URL (see PageService).
 */
class UpdatePageRequest extends FormRequest
{
    public function authorize(): bool
    {
        // The route already carries can:manage-content; this keeps the Form
        // Request honest if the route middleware is ever changed.
        return $this->user()?->can('manage-content') ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'title_hi' => ['required', 'string', 'max:200'],
            'title_en' => ['nullable', 'string', 'max:200'],
            'content_hi' => ['required', 'string', 'max:100000'],
            'content_en' => ['nullable', 'string', 'max:100000'],
            'meta_title_hi' => ['nullable', 'string', 'max:200'],
            'meta_title_en' => ['nullable', 'string', 'max:200'],
            'meta_description_hi' => ['nullable', 'string', 'max:320'],
            'meta_description_en' => ['nullable', 'string', 'max:320'],
            'status' => ['required', Rule::in([Page::STATUS_DRAFT, Page::STATUS_PUBLISHED])],
        ];
    }
}
