<?php

declare(strict_types=1);

use App\Http\Controllers\Api\Admin\AdminPingController;
use App\Http\Controllers\Api\Admin\PageController as AdminPageController;
use App\Http\Controllers\Api\Admin\SiteSettingsController as AdminSiteSettingsController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\PublicSite\PageController as PublicPageController;
use App\Http\Controllers\Api\PublicSite\SiteSettingsController as PublicSiteSettingsController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API routes
|--------------------------------------------------------------------------
| Public and admin surfaces are separated by prefix AND by middleware.
| Route groups below are the only place authorization is granted; the Flutter
| client hiding a control is never the access control.
*/

Route::get('/health', HealthController::class)
    ->middleware('throttle:api')
    ->name('api.health');

/*
| Authentication foundation (spec Phase 0).
*/
Route::prefix('auth')->name('api.auth.')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware(['throttle:auth-login'])
        ->name('login');

    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])
        ->middleware(['throttle:auth-forgot-password'])
        ->name('forgot-password');

    Route::post('/logout', [AuthController::class, 'logout'])
        ->middleware(['auth:sanctum', 'throttle:api'])
        ->name('logout');

    Route::get('/me', [AuthController::class, 'me'])
        ->middleware(['auth:sanctum', 'active', 'throttle:api'])
        ->name('me');
});

/*
| Public website content (spec Phase 1). No authentication, and only published
| content is reachable — the published filter lives in the query, not in the
| serializer.
*/
Route::prefix('public')
    ->name('api.public.')
    ->middleware('throttle:api')
    ->group(function () {
        Route::get('/site-settings', [PublicSiteSettingsController::class, 'show'])
            ->name('site-settings');

        Route::get('/pages/{slug}', [PublicPageController::class, 'show'])
            ->where('slug', '[a-z0-9]+(?:-[a-z0-9]+)*')
            ->name('pages.show');
    });

/*
| Protected admin surface. Every route inherits authentication plus the
| active-account check; content routes additionally require the
| `manage-content` ability, which Phase 2 replaces with the permission matrix.
*/
Route::prefix('admin')
    ->name('api.admin.')
    ->middleware(['auth:sanctum', 'active', 'throttle:api'])
    ->group(function () {
        Route::get('/ping', AdminPingController::class)->name('ping');

        Route::middleware('can:manage-content')->group(function () {
            Route::get('/pages', [AdminPageController::class, 'index'])->name('pages.index');
            Route::get('/pages/{page}', [AdminPageController::class, 'show'])->name('pages.show');
            Route::put('/pages/{page}', [AdminPageController::class, 'update'])->name('pages.update');

            Route::get('/site-settings', [AdminSiteSettingsController::class, 'show'])
                ->name('site-settings.show');
            Route::put('/site-settings', [AdminSiteSettingsController::class, 'update'])
                ->name('site-settings.update');
        });
    });
