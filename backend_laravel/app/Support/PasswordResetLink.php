<?php

declare(strict_types=1);

namespace App\Support;

use App\Models\User;

/**
 * The one place that knows what a password link looks like.
 *
 * It has to be the Flutter client's route, not a Blade page — this API serves
 * no HTML. Three callers need the same URL (the framework's reset notification,
 * our own reset mail and the invitation mail), and three copies of a
 * hand-assembled query string is how one of them ends up subtly different and
 * nobody notices until a committee member cannot sign in.
 */
final class PasswordResetLink
{
    private function __construct() {}

    public static function for(string $email, string $token): string
    {
        $frontend = rtrim((string) config('app.frontend_url'), '/');

        return $frontend.'/reset-password?token='.urlencode($token)
            .'&email='.urlencode($email);
    }

    public static function forUser(User $user, string $token): string
    {
        return self::for((string) $user->email, $token);
    }

    /**
     * How long the link is good for, in words a reader can act on.
     *
     * Read from the framework's own configuration rather than written into the
     * message, so the sentence cannot drift away from the truth.
     */
    public static function expiresInMinutes(): int
    {
        return (int) config('auth.passwords.users.expire', 60);
    }
}
