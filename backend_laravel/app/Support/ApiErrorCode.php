<?php

declare(strict_types=1);

namespace App\Support;

/**
 * Stable, machine-readable error codes.
 *
 * These strings are part of the public API contract and are mirrored by the
 * Flutter client (`lib/core/errors/error_code.dart`). Never rename a code
 * without changing the client in the same release.
 */
final class ApiErrorCode
{
    public const VALIDATION_FAILED = 'VALIDATION_FAILED';

    public const UNAUTHENTICATED = 'UNAUTHENTICATED';

    public const INVALID_CREDENTIALS = 'INVALID_CREDENTIALS';

    public const ACCOUNT_INACTIVE = 'ACCOUNT_INACTIVE';

    public const ACCOUNT_BLOCKED = 'ACCOUNT_BLOCKED';

    public const FORBIDDEN = 'FORBIDDEN';

    public const NOT_FOUND = 'NOT_FOUND';

    public const METHOD_NOT_ALLOWED = 'METHOD_NOT_ALLOWED';

    public const TOO_MANY_REQUESTS = 'TOO_MANY_REQUESTS';

    public const CSRF_TOKEN_MISMATCH = 'CSRF_TOKEN_MISMATCH';

    public const SERVER_ERROR = 'SERVER_ERROR';
}
