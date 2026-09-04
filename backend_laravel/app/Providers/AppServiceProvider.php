<?php

declare(strict_types=1);

namespace App\Providers;

use App\Models\Role;
use App\Models\User;
use App\Support\ApiErrorCode;
use App\Support\ApiResponse;
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
     * Content-management authorization.
     *
     * Phase 2 introduces the permission matrix and will replace this gate. Until
     * then the check is on the baseline role slug, which is deliberately
     * narrower than "any authenticated user": a Treasurer or a Viewer has no
     * business editing public pages, and the server must be the one saying so.
     */
    private function configureGates(): void
    {
        Gate::define('manage-content', static function (User $user): bool {
            // Explicit load: Model::shouldBeStrict() forbids lazy loading and the
            // session guard hydrates the user without its role.
            $user->loadMissing('role');

            return in_array($user->role?->slug, [
                Role::SUPER_ADMIN,
                Role::ADMIN,
                Role::CONTENT_MANAGER,
            ], true);
        });
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
