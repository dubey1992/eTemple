<?php

declare(strict_types=1);

namespace App\Http\Requests\Announcements;

use App\Support\AnnouncementPriority;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Writing or correcting an announcement.
 *
 * The shape only. That the window makes sense, and that a start date is not a
 * decade away because a year was mistyped, is checked again in
 * `AnnouncementService` so it holds however the record is reached.
 *
 * Note what is **not** here: `status`, `channels`, `sent_at`. Publishing and
 * sending are decisions with their own endpoints, not fields somebody can set
 * by naming them in a payload.
 */
class StoreAnnouncementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ANNOUNCEMENTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            // Hindi is the source language and is required; English is optional
            // and falls back to it on read.
            'title_hi' => ['required', 'string', 'max:200'],
            'title_en' => ['nullable', 'string', 'max:200'],
            'message_hi' => ['required', 'string', 'max:5000'],
            'message_en' => ['nullable', 'string', 'max:5000'],

            'priority' => ['nullable', Rule::in(AnnouncementPriority::all())],

            'start_at' => ['nullable', 'date'],
            'end_at' => ['nullable', 'date'],

            // An internal route or an external link. Bounded, and only ever
            // rendered as a link — never fetched or followed by the server.
            'link_url' => ['nullable', 'string', 'max:500'],
        ];
    }

    protected function prepareForValidation(): void
    {
        foreach (['title_en', 'message_en', 'link_url'] as $key) {
            $value = $this->input($key);
            if (is_string($value) && trim($value) === '') {
                // An untouched optional field means "not written", not "written
                // as empty" — which would defeat the Hindi fallback.
                $this->merge([$key => null]);
            }
        }
    }
}
