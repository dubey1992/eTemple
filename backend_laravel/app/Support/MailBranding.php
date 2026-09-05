<?php

declare(strict_types=1);

namespace App\Support;

use App\Models\SiteSetting;
use App\Services\Temple\TempleProfileService;

/**
 * The temple's own identity, as an e-mail should carry it.
 *
 * Built once and handed to every template, so a mail leaving this system is
 * signed by the temple rather than by the application. Every field comes from
 * the CMS — the specification forbids compiling temple content into the app,
 * and an e-mail is the place where a hardcoded name is hardest to notice and
 * most embarrassing to send.
 *
 * Everything here is optional. A committee that has not filled the profile in
 * still gets a legible message; it simply says less.
 */
final class MailBranding
{
    private function __construct(
        public readonly string $templeName,
        /**
         * The Roman spelling, for the English half of a bilingual message.
         * Falls back to the Hindi, so a temple that has written only one name
         * still reads sensibly rather than showing a gap.
         */
        public readonly string $templeNameEn,
        public readonly ?string $address,
        public readonly ?string $phone,
        public readonly ?string $email,
        public readonly ?string $siteUrl,
    ) {}

    public static function current(): self
    {
        $profile = app(TempleProfileService::class)->current();
        $settings = SiteSetting::query()->oldest('id')->first();

        // Hindi first, because the mail is Hindi first. `मंदिर` is the last
        // resort — a message signed "Laravel" would be worse than a generic
        // Hindi word for the place it came from.
        $name = trim((string) ($profile->name_hi ?: $profile->name_en));
        $nameEn = trim((string) ($profile->name_en ?: $profile->name_hi));

        $address = implode(', ', array_filter([
            $profile->village_hi ?: $profile->village_en,
            $profile->district_hi ?: $profile->district_en,
            $profile->state_hi ?: $profile->state_en,
            $profile->postal_code,
        ], static fn ($part) => trim((string) $part) !== ''));

        return new self(
            templeName: $name !== '' ? $name : 'मंदिर',
            templeNameEn: $nameEn !== '' ? $nameEn : 'the temple',
            address: $address !== '' ? $address : null,
            phone: self::blankToNull($settings?->contact_phone),
            email: self::blankToNull($settings?->contact_email),
            siteUrl: self::blankToNull((string) config('app.frontend_url')),
        );
    }

    private static function blankToNull(?string $value): ?string
    {
        $value = trim((string) $value);

        return $value === '' ? null : $value;
    }
}
