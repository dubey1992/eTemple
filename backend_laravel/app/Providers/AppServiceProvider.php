<?php

declare(strict_types=1);

namespace App\Providers;

use App\Models\User;
use App\Support\ApiErrorCode;
use App\Support\ApiResponse;
use App\Support\Permission;
use Illuminate\Auth\Notifications\ResetPassword;
use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Gate;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    public function register(): void
    {
        //
    }

    public function boot(): void
    {
        $this->configureModels();
        $this->configureUrls();
        $this->configureRateLimiting();
        $this->configurePasswordReset();
        $this->configureGates();
    }

    /**
     * Fail loudly in development on lazy loading and mass-assignment mistakes;
     * stay lenient in production so a stray access never takes the site down.
     */
    private function configureModels(): void
    {
        Model::shouldBeStrict(! $this->app->isProduction());
    }

    private function configureUrls(): void
    {
        if ($this->app->isProduction()) {
            URL::forceScheme('https');
        }
    }

    /**
     * Named limiters used by routes/api.php.
     *
     * Login and password reset are keyed on e-mail + IP so one abusive client
     * cannot lock out every account, and a single account cannot be brute-forced
     * from one address (spec: "Rate-limit login and password reset requests").
     */
    private function configureRateLimiting(): void
    {
        RateLimiter::for('api', fn (Request $request) => Limit::perMinute(60)->by(
            $request->user()?->id ?: $request->ip()
        ));

        RateLimiter::for('auth-login', fn (Request $request) => Limit::perMinute(5)
            ->by(self::credentialKey($request))
            ->response(self::throttled(...)));

        RateLimiter::for('auth-forgot-password', fn (Request $request) => Limit::perMinute(3)
            ->by(self::credentialKey($request))
            ->response(self::throttled(...)));
    }

    /**
     * Permission-matrix authorization (spec Phase 2).
     *
     * Every catalogue key becomes an ability, so a route declares what it needs
     * (`can:users.manage`) and the answer comes from the role's stored
     * permissions. This replaces the Phase 1 `manage-content` role-slug gate;
     * that ability is kept as an alias of `content.manage` so Phase 1's routes
     * and tests keep working unchanged, which is the check that the swap was
     * faithful (PHASE_2_PLAN assumption C6).
     */
    private function configureGates(): void
    {
        // Super Admin is granted everything before any individual check runs, so
        // no edit to the matrix can lock the temple out of its own administration.
        Gate::before(static function (User $user): ?bool {
            $user->loadMissing('role');

            return ($user->isActive() && $user->isSuperAdmin()) ? true : null;
        });

        foreach (Permission::all() as $permission) {
            Gate::define(
                $permission,
                static fn (User $user): bool => $user->hasPermission($permission),
            );
        }

        // Phase 1 compatibility alias.
        Gate::define(
            'manage-content',
            static fn (User $user): bool => $user->hasPermission(Permission::CONTENT_MANAGE),
        );
    }

    /**
     * The reset link must land on the Flutter Web client, not on a Blade page.
     *
     * The matching reset screen and reset endpoint are delivered in Phase 2
     * ("Password reset"); Phase 0 establishes only the request side.
     */
    private function configurePasswordReset(): void
    {
        ResetPassword::createUrlUsing(static function (object $notifiable, string $token): string {
            $frontend = rtrim((string) config('app.frontend_url'), '/');
            $email = urlencode((string) $notifiable->getEmailForPasswordReset());

            return $frontend.'/reset-password?token='.$token.'&email='.$email;
        });
    }

    private static function credentialKey(Request $request): string
    {
        $email = mb_strtolower(trim((string) $request->input('email')));

        return sha1($email.'|'.$request->ip());
    }

    /**
     * @param  array<string, mixed>  $headers
     */
    private static function throttled(Request $request, array $headers): JsonResponse
    {
        $retryAfter = (int) ($headers['Retry-After'] ?? 60);

        return ApiResponse::error(
            ApiErrorCode::TOO_MANY_REQUESTS,
            'Too many attempts. Please try again in '.$retryAfter.' seconds.',
            429,
            ['retry_after' => $retryAfter],
        )->withHeaders($headers);
    }
}
