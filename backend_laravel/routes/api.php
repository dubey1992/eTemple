<?php

declare(strict_types=1);

use App\Http\Controllers\Api\Admin\AdminPingController;
use App\Http\Controllers\Api\Admin\CommitteeMemberController;
use App\Http\Controllers\Api\Admin\PageController as AdminPageController;
use App\Http\Controllers\Api\Admin\RoleController;
use App\Http\Controllers\Api\Admin\SiteSettingsController as AdminSiteSettingsController;
use App\Http\Controllers\Api\Admin\TempleProfileController;
use App\Http\Controllers\Api\Admin\UserController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\PublicSite\PageController as PublicPageController;
use App\Http\Controllers\Api\PublicSite\SiteSettingsController as PublicSiteSettingsController;
use App\Http\Controllers\Api\PublicSite\TempleController as PublicTempleController;
use App\Support\Permission;
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
| Authentication (spec Phase 0, completed in Phase 2).
*/
Route::prefix('auth')->name('api.auth.')->group(function () {
    Route::post('/login', [AuthController::class, 'login'])
        ->middleware(['throttle:auth-login'])
        ->name('login');

    Route::post('/forgot-password', [AuthController::class, 'forgotPassword'])
        ->middleware(['throttle:auth-forgot-password'])
        ->name('forgot-password');

    Route::post('/reset-password', [AuthController::class, 'resetPassword'])
        ->middleware(['throttle:auth-forgot-password'])
        ->name('reset-password');

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

        // Temple identity and committee (Phase 3). The profile is authoritative
        // for the temple's name and address. The committee list carries only the
        // personal details each member has consented to publish — the filter is
        // in the query and the consent check is repeated in the serializer.
        Route::get('/temple-profile', [PublicTempleController::class, 'profile'])
            ->name('temple-profile');

        Route::get('/committee', [PublicTempleController::class, 'committee'])
            ->name('committee');

        Route::get('/pages/{slug}', [PublicPageController::class, 'show'])
            ->where('slug', '[a-z0-9]+(?:-[a-z0-9]+)*')
            ->name('pages.show');
    });

/*
| Protected admin surface. Every route inherits authentication plus the
| active-account check, and then declares the permission it needs. Super Admin
| passes every check via Gate::before, so the matrix cannot lock it out.
*/
Route::prefix('admin')
    ->name('api.admin.')
    ->middleware(['auth:sanctum', 'active', 'throttle:api'])
    ->group(function () {
        Route::get('/ping', AdminPingController::class)->name('ping');

        // --- Website content (Phase 1) ---------------------------------
        Route::middleware('can:'.Permission::CONTENT_MANAGE)->group(function () {
            Route::get('/pages', [AdminPageController::class, 'index'])->name('pages.index');
            Route::get('/pages/{page}', [AdminPageController::class, 'show'])->name('pages.show');
            Route::put('/pages/{page}', [AdminPageController::class, 'update'])->name('pages.update');

            Route::get('/site-settings', [AdminSiteSettingsController::class, 'show'])
                ->name('site-settings.show');
            Route::put('/site-settings', [AdminSiteSettingsController::class, 'update'])
                ->name('site-settings.update');
        });

        // --- Committee accounts (Phase 2) ------------------------------
        Route::get('/users', [UserController::class, 'index'])
            ->middleware('can:'.Permission::USERS_VIEW)->name('users.index');
        Route::get('/users/{user}', [UserController::class, 'show'])
            ->middleware('can:'.Permission::USERS_VIEW)->name('users.show');
        Route::post('/users', [UserController::class, 'store'])
            ->middleware('can:'.Permission::USERS_MANAGE)->name('users.store');
        Route::put('/users/{user}', [UserController::class, 'update'])
            ->middleware('can:'.Permission::USERS_MANAGE)->name('users.update');
        Route::post('/users/{user}/send-password-reset', [UserController::class, 'sendPasswordReset'])
            ->middleware('can:'.Permission::USERS_MANAGE)->name('users.send-password-reset');

        // Login history is security information, gated separately from user
        // administration: seeing who tried to sign in is not the same right as
        // being able to create accounts.
        Route::get('/users/{user}/login-history', [UserController::class, 'loginHistory'])
            ->middleware('can:'.Permission::SECURITY_VIEW)->name('users.login-history');

        // --- Roles and the permission matrix (Phase 2) -----------------
        Route::get('/roles', [RoleController::class, 'index'])
            ->middleware('can:'.Permission::ROLES_VIEW)->name('roles.index');
        Route::get('/permissions', [RoleController::class, 'permissions'])
            ->middleware('can:'.Permission::ROLES_VIEW)->name('permissions.index');
        Route::put('/roles/{role}/permissions', [RoleController::class, 'updatePermissions'])
            ->middleware('can:'.Permission::ROLES_MANAGE)->name('roles.permissions.update');

        // --- Temple profile and committee (Phase 3) --------------------
        // Reading is granted with content.view so a Viewer can see the committee
        // without being able to change it; every write needs temple.manage.
        Route::get('/temple-profile', [TempleProfileController::class, 'show'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('temple-profile.show');
        Route::put('/temple-profile', [TempleProfileController::class, 'update'])
            ->middleware('can:'.Permission::TEMPLE_MANAGE)->name('temple-profile.update');

        Route::get('/committee-members', [CommitteeMemberController::class, 'index'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('committee-members.index');
        Route::get('/committee-members/{member}', [CommitteeMemberController::class, 'show'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('committee-members.show');
        Route::post('/committee-members', [CommitteeMemberController::class, 'store'])
            ->middleware('can:'.Permission::TEMPLE_MANAGE)->name('committee-members.store');
        Route::put('/committee-members/{member}', [CommitteeMemberController::class, 'update'])
            ->middleware('can:'.Permission::TEMPLE_MANAGE)->name('committee-members.update');
        Route::delete('/committee-members/{member}', [CommitteeMemberController::class, 'destroy'])
            ->middleware('can:'.Permission::TEMPLE_MANAGE)->name('committee-members.destroy');
    });
