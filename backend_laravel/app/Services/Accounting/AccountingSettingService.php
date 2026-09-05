<?php

declare(strict_types=1);

namespace App\Services\Accounting;

use App\Exceptions\AccountingGuardException;
use App\Models\AccountingSetting;
use App\Models\User;
use App\Support\Money;
use Illuminate\Support\Carbon;

/**
 * The singleton settings row, read the way `site_settings`,
 * `temple_profiles` and `donation_settings` are read.
 *
 * It holds the two decisions nobody should be able to make by accident:
 * whether the books are public at all, and where they start.
 */
class AccountingSettingService
{
    public function current(): AccountingSetting
    {
        $settings = AccountingSetting::query()->orderBy('id')->first();

        if ($settings === null) {
            $settings = new AccountingSetting;
            // Not published, and starting at zero. Both defaults are refusals:
            // see PHASE_9_PLAN assumptions N7 and N8.
            $settings->is_published = false;
            $settings->opening_balance_paise = 0;
            $settings->save();
        }

        return $settings;
    }

    /** @param array<string, mixed> $attributes */
    public function update(array $attributes, User $actor): AccountingSetting
    {
        $settings = $this->current();

        if (array_key_exists('opening_balance', $attributes)) {
            $settings->opening_balance_paise = $this->signedPaise($attributes['opening_balance']);
        }

        if (array_key_exists('opening_balance_date', $attributes)) {
            $value = trim((string) ($attributes['opening_balance_date'] ?? ''));
            $settings->opening_balance_date = $value === '' ? null : Carbon::parse($value)->startOfDay();
        }

        foreach (['intro_hi', 'intro_en', 'note_hi', 'note_en'] as $field) {
            if (array_key_exists($field, $attributes)) {
                $value = trim((string) ($attributes[$field] ?? ''));
                $settings->{$field} = $value === '' ? null : $value;
            }
        }

        if (array_key_exists('is_published', $attributes)) {
            $settings->is_published = (bool) $attributes['is_published'];
        }

        $settings->updated_by = $actor->id;
        $settings->save();

        return $settings;
    }

    /**
     * An opening balance may be negative — a temple that begins in deficit
     * should be able to say so rather than rounding its own history up to zero.
     */
    private function signedPaise(mixed $amount): int
    {
        $raw = is_string($amount) ? trim($amount) : (string) $amount;
        $negative = str_starts_with($raw, '-');

        $paise = Money::parse(ltrim($raw, '-'));

        if ($paise === null) {
            throw AccountingGuardException::amountUnreadable();
        }

        $maxRupees = (int) config('accounting.max_rupees', 10_000_000);
        if ($paise > $maxRupees * Money::PAISE_PER_RUPEE) {
            throw AccountingGuardException::amountTooLarge($maxRupees);
        }

        return $negative ? -$paise : $paise;
    }
}
