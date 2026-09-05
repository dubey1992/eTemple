<?php

declare(strict_types=1);

namespace App\Http\Requests\Announcements;

use App\Support\AnnouncementChannel;
use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

/**
 * Sending an announcement.
 *
 * `channels` is **required and non-empty**. There is no default, deliberately:
 * the specification's rule is "no sends without explicit admin action", and a
 * default channel would mean the most consequential action in this phase could
 * happen without anybody choosing it.
 *
 * The rule below accepts any *known* channel; whether it is actually connected
 * to a provider is `AnnouncementService`'s answer, so a disabled channel is
 * refused with a sentence explaining why rather than with "invalid value"
 * (PHASE_8_PLAN assumption N5).
 */
class SendAnnouncementRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ANNOUNCEMENTS_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'channels' => ['required', 'array', 'min:1'],
            'channels.*' => [Rule::in(AnnouncementChannel::all())],
        ];
    }

    /** @return array<string, string> */
    public function messages(): array
    {
        return [
            'channels.required' => 'Choose at least one way to send this announcement.',
            'channels.min' => 'Choose at least one way to send this announcement.',
        ];
    }
}
