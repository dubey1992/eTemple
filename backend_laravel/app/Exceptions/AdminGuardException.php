<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * A refusal that protects the administration itself.
 *
 * These are not validation errors in the "you typed it wrong" sense — they are
 * the server declining to let an administrator destroy their own access, or
 * everyone's. They surface as 422 with the offending field named, so the UI can
 * point at it.
 */
final class AdminGuardException extends DomainException
{
    /** @param list<string> $keys */
    public static function unknownPermissions(array $keys): self
    {
        return self::of('permissions', 'Unknown permission keys: '.implode(', ', $keys));
    }

    public static function lastSuperAdmin(string $field): self
    {
        return self::of(
            $field,
            'This is the last active Super Admin. Promote another account first, '
            .'otherwise nobody can administer the temple site.',
        );
    }

    public static function cannotChangeOwnRole(): self
    {
        return self::of('role_id', 'You cannot change your own role.');
    }

    public static function cannotChangeOwnStatus(): self
    {
        return self::of('status', 'You cannot deactivate or block your own account.');
    }

    public static function superAdminPermissionsAreFixed(): self
    {
        return self::of(
            'permissions',
            'Super Admin always has every permission and cannot be restricted.',
        );
    }

    private static function of(string $field, string $message): self
    {
        return new self(ApiErrorCode::VALIDATION_FAILED, $message, 422, [$field => [$message]]);
    }
}
