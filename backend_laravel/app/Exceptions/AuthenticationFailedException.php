<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Raised when a login attempt is rejected.
 *
 * The message is intentionally generic for bad credentials so the endpoint cannot
 * be used to enumerate registered e-mail addresses.
 */
final class AuthenticationFailedException extends DomainException
{
    public static function invalidCredentials(): self
    {
        return new self(
            ApiErrorCode::INVALID_CREDENTIALS,
            'These credentials do not match our records.',
            401,
        );
    }

    public static function inactive(): self
    {
        return new self(
            ApiErrorCode::ACCOUNT_INACTIVE,
            'This account is not active. Please contact the temple committee.',
            403,
        );
    }

    public static function blocked(): self
    {
        return new self(
            ApiErrorCode::ACCOUNT_BLOCKED,
            'This account has been blocked. Please contact the temple committee.',
            403,
        );
    }
}
