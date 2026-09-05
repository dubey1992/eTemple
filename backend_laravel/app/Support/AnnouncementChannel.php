<?php

declare(strict_types=1);

namespace App\Support;

/**
 * How an announcement can reach people.
 *
 * ## Why the disabled ones are here at all
 *
 * The specification says SMS and WhatsApp come "only after provider approval",
 * and no provider has been approved. They could simply have been left out — but
 * then a committee asking "can we WhatsApp this?" would get silence, and the
 * next developer would have to rediscover that it was a deliberate decision
 * rather than an oversight.
 *
 * So they are here, known, and **refused with a message that says why**. A
 * checkbox that appears to send an SMS and quietly does nothing is worse than
 * no checkbox: the committee would believe the village had been told
 * (PHASE_8_PLAN assumption N5).
 */
final class AnnouncementChannel
{
    /** The website banner. Always on: publishing *is* this channel. */
    public const SITE = 'site';

    /** E-mail to committee accounts — never to devotees (assumption N4). */
    public const EMAIL = 'email';

    public const SMS = 'sms';

    public const WHATSAPP = 'whatsapp';

    /** @return list<string> */
    public static function all(): array
    {
        return [self::SITE, self::EMAIL, self::SMS, self::WHATSAPP];
    }

    /**
     * The channels this installation can actually deliver on.
     *
     * `site` is always available because it needs no provider. `email` is
     * available when a mailer is configured; the rest are not available until
     * somebody has approved and configured a provider, which is a decision the
     * temple has not made.
     *
     * @return list<string>
     */
    public static function enabled(): array
    {
        $enabled = [self::SITE];

        if ((bool) config('announcements.channels.email', true)) {
            $enabled[] = self::EMAIL;
        }

        foreach ([self::SMS, self::WHATSAPP] as $channel) {
            if ((bool) config('announcements.channels.'.$channel, false)) {
                $enabled[] = $channel;
            }
        }

        return $enabled;
    }

    public static function exists(string $channel): bool
    {
        return in_array($channel, self::all(), true);
    }

    public static function isEnabled(string $channel): bool
    {
        return in_array($channel, self::enabled(), true);
    }

    /** Bilingual labels, for anything the server renders. */
    public static function label(string $channel): string
    {
        return match ($channel) {
            self::SITE => 'वेबसाइट / Website',
            self::EMAIL => 'ईमेल / E-mail',
            self::SMS => 'एसएमएस / SMS',
            self::WHATSAPP => 'WhatsApp',
            default => $channel,
        };
    }
}
