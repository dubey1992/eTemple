<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals that keep the calendar coherent.
 *
 * Like the other guard exceptions these surface as 422 against the offending
 * field, so the editor sees which date is wrong rather than a generic message.
 */
final class EventGuardException extends DomainException
{
    public static function endsBeforeItStarts(): self
    {
        return self::of('end_at', 'The event cannot end before it starts.');
    }

    public static function repeatsUntilBeforeItStarts(): self
    {
        return self::of(
            'recurrence_until',
            'The repeat-until date cannot be before the first occurrence.',
        );
    }

    private static function of(string $field, string $message): self
    {
        return new self(ApiErrorCode::VALIDATION_FAILED, $message, 422, [$field => [$message]]);
    }
}
