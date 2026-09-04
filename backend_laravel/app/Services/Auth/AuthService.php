<?php

declare(strict_types=1);

namespace App\Services\Auth;

use App\Exceptions\AuthenticationFailedException;
use App\Models\LoginAttempt;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password;
use Illuminate\Support\Str;

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

            $this->logAttempt($request, $email, LoginAttempt::OUTCOME_INVALID_CREDENTIALS, $user);

            throw AuthenticationFailedException::invalidCredentials();
        }

        if ($user->isBlocked()) {
            $this->logAttempt($request, $email, LoginAttempt::OUTCOME_BLOCKED, $user);

            throw AuthenticationFailedException::blocked();
        }

        if (! $user->isActive()) {
            $this->logAttempt($request, $email, LoginAttempt::OUTCOME_INACTIVE, $user);

            throw AuthenticationFailedException::inactive();
        }

        Auth::guard('web')->login($user, $remember);

        // Prevents session fixation: the pre-login session id can no longer be
        // used to ride the authenticated session.
        $request->session()->regenerate();

        $user->forceFill(['last_login_at' => now()])->save();

        $this->logAttempt($request, $email, LoginAttempt::OUTCOME_SUCCESS, $user);

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

    /**
     * Record an attempt to the log and to the login history.
     *
     * Failures are recorded too: a trail of failed attempts against an account
     * is the point of the history (spec Phase 2, "Login history").
     */
    /**
     * Complete a password reset (spec Phase 2, "Password reset").
     *
     * Every other session is invalidated by rotating the remember token, so a
     * reset triggered because an account was compromised actually ends the
     * intruder's session rather than leaving it alive.
     *
     * @return bool true when the token was valid and the password was changed
     */
    public function resetPassword(string $email, string $token, string $password): bool
    {
        $status = Password::broker()->reset(
            [
                'email' => $email,
                'password' => $password,
                'password_confirmation' => $password,
                'token' => $token,
            ],
            static function (User $user) use ($password): void {
                $user->forceFill([
                    'password' => $password,
                    'remember_token' => Str::random(60),
                ])->save();
            },
        );

        return $status === Password::PASSWORD_RESET;
    }

    private function logAttempt(
        Request $request,
        string $email,
        string $outcome,
        ?User $user = null,
    ): void {
        Log::channel(config('logging.default'))->info('auth.login_attempt', [
            'email' => $email,
            'outcome' => $outcome,
            'ip' => $request->ip(),
            'user_agent' => $request->userAgent(),
        ]);

        LoginAttempt::query()->create([
            'user_id' => $user?->id,
            'email' => $email,
            'outcome' => $outcome,
            'ip_address' => $request->ip(),
            // Trimmed to the column width; a forged header must not break a login.
            'user_agent' => mb_substr((string) $request->userAgent(), 0, 500) ?: null,
        ]);
    }
}
