<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals on the temple's one anonymous write endpoint.
 *
 * These are worded for a villager on a phone, not for whoever wrote the script:
 * every one of them says what to do next, because the person who actually reads
 * this message is almost always somebody whose token quietly expired while they
 * were composing a long message.
 */
final class EnquiryGuardException extends DomainException
{
    /**
     * The form token was missing, forged, spent, or is from a session that has
     * since expired. One refusal for all four on purpose: distinguishing them
     * would tell a script which of its attempts was closest.
     */
    public static function formExpired(): self
    {
        return new self(
            ApiErrorCode::ENQUIRY_FORM_EXPIRED,
            'This form has expired. Please reload the page and send your message again — '
                .'your text can be pasted straight back in.',
            422,
        );
    }

    /** Filled in faster than a person can type (PHASE_7_PLAN assumption N2). */
    public static function submittedTooQuickly(): self
    {
        return new self(
            ApiErrorCode::ENQUIRY_FORM_EXPIRED,
            'That was sent before the form finished loading. Please try once more.',
            422,
        );
    }

    public static function challengeRequired(): self
    {
        return new self(
            ApiErrorCode::ENQUIRY_CHALLENGE_REQUIRED,
            'Please reload the page and answer the small question shown with the form.',
            422,
        );
    }

    public static function challengeIncorrect(): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            'That answer was not right. Please try the question again.',
            422,
            ['challenge_answer' => ['That answer was not right. Please try the question again.']],
        );
    }

    /** The per-address daily ceiling, above the per-minute rate limit. */
    public static function dailyLimitReached(): self
    {
        return new self(
            ApiErrorCode::TOO_MANY_REQUESTS,
            'Several messages have already been sent from here today. '
                .'Please telephone the temple if it is urgent, or write again tomorrow.',
            429,
        );
    }

    public static function contactChannelRequired(): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            'Please give a mobile number or an e-mail address, otherwise the committee cannot reply.',
            422,
            [
                'mobile' => ['Give a mobile number or an e-mail address.'],
                'email' => ['Give a mobile number or an e-mail address.'],
            ],
        );
    }

    public static function assigneeCannotHandleEnquiries(): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            'That member cannot open the enquiry inbox, so nothing would reach them. '
                .'Choose somebody with enquiry permission.',
            422,
            ['assigned_to' => ['That member cannot open the enquiry inbox.']],
        );
    }
}
