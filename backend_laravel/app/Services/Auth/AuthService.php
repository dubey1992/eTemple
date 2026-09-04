<?php

declare(strict_types=1);

namespace App\Services\Auth;

use App\Exceptions\AuthenticationFailedException;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;

/**
 * All authentication business rules live here; the controller stays thin.
 */
class AuthService
{
    /**
     * Establish a session for a valid, active user.
     *
     * Credentials are verified *before* account status so that a caller who does
     * not know the password learns nothing about whether an account exists or
     * what state it is in.
     *
     * @throws AuthenticationFailedException
     */
    public function login(Request $request, string $email, string $password, bool $remember = false): User
    {
        /** @var User|null $user */
        $user = User::query()->with('role')->where('email', $email)->first();

        if ($user === null || ! Hash::check($password, $user->password)) {
            // Constant-ish work even when the user is missing, to avoid leaking
            // account existence through response timing.
            if ($user === null) {
                Hash::make($password);
            }

            $this->logAttempt($request, $email, 'invalid_credentials');

            throw AuthenticationFailedException::invalidCredentials();
        }

        if ($user->isBlocked()) {
            $this->logAttempt($request, $email, 'blocked');

            throw AuthenticationFailedException::blocked();
        }

        if (! $user->isActive()) {
            $this->logAttempt($request, $email, 'inactive');

            throw AuthenticationFailedException::inactive();
        }

        Auth::guard('web')->login($user, $remember);

        // Prevents session fixation: the pre-login session id can no longer be
        // used to ride the authenticated session.
        $request->session()->regenerate();

        $user->forceFill(['last_login_at' => now()])->save();

        $this->logAttempt($request, $email, 'success');

        return $user->refresh()->load('role');
    }

    public function logout(Request $request): void
    {
        Auth::guard('web')->logout();

        $request->session()->invalidate();
        $request->session()->regenerateToken();

        // The sanctum RequestGuard caches whatever user it resolved for this
        // request and never clears it, so dropping the resolved guards is what
        // actually makes the rest of this request see a signed-out visitor.
        Auth::forgetGuards();
    }

    /**
     * Send a password reset link.
     *
     * Returns nothing on purpose: the controller always answers with the same
     * generic message so the endpoint cannot be used to enumerate accounts.
     * Only active users are ever mailed a link.
     */
    public function sendPasswordResetLink(string $email): void
    {
        $user = User::query()->where('email', $email)->first();

        if ($user === null || ! $user->isActive()) {
            return;
        }

        Password::broker()->sendResetLink(['email' => $email]);
    }

    private function logAttempt(Request $request, string $email, string $outcome): void
    {
        Log::channel(config('logging.default'))->info('auth.login_attempt', [
            'email' => $email,
            'outcome' => $outcome,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);
    }
}
