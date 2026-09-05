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

    /**
     * A media file cannot be deleted because something still points at it
     * (spec Phase 5 deletion guard). Distinct from VALIDATION_FAILED: the
     * request was well formed, the site's state refuses it.
     */
    public const MEDIA_IN_USE = 'MEDIA_IN_USE';

    /**
     * A donation cannot be changed, confirmed or reversed because of the state
     * it is already in (spec Phase 6). Distinct from VALIDATION_FAILED: the
     * request was well formed, and it is the history that refuses it — so the
     * client shows it as a fact about the record rather than a field error.
     */
    public const DONATION_LOCKED = 'DONATION_LOCKED';

    public const SERVER_ERROR = 'SERVER_ERROR';
}
