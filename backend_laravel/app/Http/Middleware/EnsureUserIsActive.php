<?php

declare(strict_types=1);

namespace App\Http\Middleware;

use App\Exceptions\AuthenticationFailedException;
use App\Models\User;
use Closure;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Server-side enforcement of the Phase 0 rule:
 * "Inactive or blocked users cannot access admin endpoints or protected routes."
 *
 * This runs on every authenticated route, so a user deactivated mid-session
 * loses access on their next request rather than at their next login.
 */
class EnsureUserIsActive
{
    public function handle(Request $request, Closure $next): Response
    {
        $user = $request->user();

        if (! $user instanceof User) {
            throw new AuthenticationException;
        }

        if ($user->isBlocked()) {
            throw AuthenticationFailedException::blocked();
        }

        if (! $user->isActive()) {
            throw AuthenticationFailedException::inactive();
        }

        return $next($request);
    }
}
