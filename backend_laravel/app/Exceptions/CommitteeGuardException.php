<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * A refusal that protects a committee member's personal data.
 *
 * Like AdminGuardException these are not "you typed it wrong" errors: they are
 * the server declining to publish a villager's phone number, photograph or
 * e-mail address without their recorded permission. They surface as 422 against
 * the offending field so the editor sees the actual reason.
 */
final class CommitteeGuardException extends DomainException
{
    public static function consentRequired(string $field): self
    {
        return self::of(
            $field,
            'This detail cannot be published until the member\'s consent is recorded. '
            .'Tick "consent recorded" first.',
        );
    }

    public static function tenureEndsBeforeItStarts(): self
    {
        return self::of('tenure_end', 'The tenure end date cannot be before the start date.');
    }

    private static function of(string $field, string $message): self
    {
        return new self(ApiErrorCode::VALIDATION_FAILED, $message, 422, [$field => [$message]]);
    }
}
