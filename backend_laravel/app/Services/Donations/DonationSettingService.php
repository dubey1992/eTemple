<?php

declare(strict_types=1);

namespace App\Services\Donations;

use App\Models\DonationSetting;
use App\Models\User;
use App\Services\Audit\AuditLogger;
use App\Support\AuditAction;

/**
 * The singleton row of public donation details.
 *
 * Same shape as `TempleProfileService` and `SiteSettingService`: read through
 * `current()` so exactly one row exists, and start empty — the working
 * agreement forbids shipping invented temple content, and a bank account is the
 * last thing to invent.
 */
class DonationSettingService
{
    public function __construct(private readonly AuditLogger $audit) {}

    public function current(): DonationSetting
    {
        return DonationSetting::query()->oldest('id')->firstOr(
            callback: static fn () => DonationSetting::query()->create([]),
        );
    }

    /**
     * What a visitor may see: the row, but only once the committee has both
     * published it and put something payable in it.
     */
    public function publiclyVisible(): ?DonationSetting
    {
        $settings = DonationSetting::query()->oldest('id')->first();

        return $settings?->isPubliclyVisible() === true ? $settings : null;
    }

    /**
     * @param  array<string, mixed>  $attributes
     */
    public function update(array $attributes, User $editor): DonationSetting
    {
        $settings = $this->current();
        $before = $settings->only(array_keys($attributes));

        foreach ([
            'upi_id', 'bank_name', 'account_name', 'account_number', 'ifsc',
            'qr_url', 'intro_hi', 'intro_en', 'note_hi', 'note_en',
        ] as $field) {
            if (array_key_exists($field, $attributes)) {
                $value = $attributes[$field];
                $trimmed = is_string($value) ? trim($value) : null;
                // Blank is stored as absent, not as an empty string: the
                // bilingual fallback keys on absence, and so does
                // `hasPayableDetails()`.
                $settings->{$field} = ($trimmed === null || $trimmed === '') ? null : $trimmed;
            }
        }

        if (array_key_exists('is_published', $attributes)) {
            $settings->is_published = (bool) $attributes['is_published'];
        }

        $settings->updated_by = $editor->id;
        $settings->save();

        // Settings are the site's own configuration; a change here is
        // visible to every visitor, so it leaves a trace.
        $this->audit->recordChange(
            action: AuditAction::DONATION_SETTINGS_UPDATED,
            entity: $settings,
            before: $before,
            after: $settings->only(array_keys($before)),
        );

        return $settings->fresh() ?? $settings;
    }
}
