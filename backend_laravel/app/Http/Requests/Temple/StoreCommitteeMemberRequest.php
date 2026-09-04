<?php

declare(strict_types=1);

namespace App\Http\Requests\Temple;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Validation for creating and editing a committee member.
 *
 * Hindi name and designation are required: Hindi is the source language and a
 * member with no name in it cannot be rendered at all.
 *
 * `has_consent` and the three `show_*_publicly` flags are accepted here but the
 * *rule* between them — no publication without recorded consent — belongs to
 * CommitteeService, so it holds however the record is reached.
 */
class StoreCommitteeMemberRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::TEMPLE_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'name_hi' => ['required', 'string', 'max:160'],
            'name_en' => ['nullable', 'string', 'max:160'],
            'designation_hi' => ['required', 'string', 'max:160'],
            'designation_en' => ['nullable', 'string', 'max:160'],
            'bio_hi' => ['nullable', 'string', 'max:5000'],
            'bio_en' => ['nullable', 'string', 'max:5000'],

            'phone' => ['nullable', 'string', 'max:40'],
            'email' => ['nullable', 'email:rfc', 'max:191'],
            'photo_url' => ['nullable', 'url', 'max:500'],

            'tenure_start' => ['nullable', 'date'],
            // Also checked in the service, so the rule holds for any caller.
            'tenure_end' => ['nullable', 'date', 'after_or_equal:tenure_start'],

            'is_published' => ['nullable', 'boolean'],
            'has_consent' => ['nullable', 'boolean'],
            'show_phone_publicly' => ['nullable', 'boolean'],
            'show_email_publicly' => ['nullable', 'boolean'],
            'show_photo_publicly' => ['nullable', 'boolean'],

            'sort_order' => ['nullable', 'integer', 'min:0', 'max:9999'],
        ];
    }
}
