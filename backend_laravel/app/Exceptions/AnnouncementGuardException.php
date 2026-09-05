<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals around putting something out in the temple's name.
 *
 * The ones about *state* are 409s, not 422s: the request was well formed, and
 * it is what has already happened that refuses it. Sending twice is the one
 * this file exists for.
 */
final class AnnouncementGuardException extends DomainException
{
    /**
     * The rule this phase is built around (PHASE_8_PLAN assumption N6).
     *
     * Worded to tell the committee what to do instead, because "already sent"
     * on its own leaves somebody staring at a button.
     */
    public static function alreadySent(): self
    {
        return new self(
            ApiErrorCode::ANNOUNCEMENT_ALREADY_SENT,
            'This announcement has already been sent, and a message cannot be unsent. '
                .'To say it again, write a new announcement.',
            409,
        );
    }

    public static function cannotSendDraft(): self
    {
        return new self(
            ApiErrorCode::ANNOUNCEMENT_NOT_PUBLISHED,
            'Publish this announcement before sending it. What goes out by e-mail should be '
                .'the same notice the website is showing.',
            409,
        );
    }

    public static function cannotSendArchived(): self
    {
        return new self(
            ApiErrorCode::ANNOUNCEMENT_NOT_PUBLISHED,
            'This announcement has been archived, so it is no longer the temple\'s current notice.',
            409,
        );
    }

    /**
     * A channel nobody has wired up (assumption N5).
     *
     * Named explicitly rather than ignored: a committee that ticked "SMS" and
     * saw a success message would believe the village had been told.
     */
    public static function channelNotAvailable(string $channel): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            sprintf(
                'The %s channel is not connected to a provider, so nothing would be sent. '
                    .'It has to be arranged and configured before it can be used.',
                $channel,
            ),
            422,
            ['channels' => [sprintf('%s is not connected to a provider.', $channel)]],
        );
    }

    public static function noChannelChosen(): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            'Choose at least one way to send this announcement.',
            422,
            ['channels' => ['Choose at least one way to send this.']],
        );
    }

    public static function endsBeforeItStarts(): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            'The end of the notice is before its beginning.',
            422,
            ['end_at' => ['This is before the start.']],
        );
    }

    public static function scheduledTooFarAhead(int $days): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            sprintf('That start date is more than %d days away. Check the year.', $days),
            422,
            ['start_at' => ['Check the year.']],
        );
    }
}
