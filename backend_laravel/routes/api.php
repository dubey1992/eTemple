<?php

declare(strict_types=1);

use App\Http\Controllers\Api\Admin\AdminPingController;
use App\Http\Controllers\Api\Admin\AlbumController;
use App\Http\Controllers\Api\Admin\CommitteeMemberController;
use App\Http\Controllers\Api\Admin\DonationController as AdminDonationController;
use App\Http\Controllers\Api\Admin\DonationSettingsController;
use App\Http\Controllers\Api\Admin\EnquiryController as AdminEnquiryController;
use App\Http\Controllers\Api\Admin\EventController as AdminEventController;
use App\Http\Controllers\Api\Admin\MediaController as AdminMediaController;
use App\Http\Controllers\Api\Admin\PageController as AdminPageController;
use App\Http\Controllers\Api\Admin\RoleController;
use App\Http\Controllers\Api\Admin\SiteSettingsController as AdminSiteSettingsController;
use App\Http\Controllers\Api\Admin\TempleProfileController;
use App\Http\Controllers\Api\Admin\UserController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\PublicSite\DonationController as PublicDonationController;
use App\Http\Controllers\Api\PublicSite\EnquiryController as PublicEnquiryController;
use App\Http\Controllers\Api\PublicSite\EventController as PublicEventController;
use App\Http\Controllers\Api\PublicSite\MediaController as PublicMediaController;
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

        // Puja, aarti and festivals (Phase 4). The list returns dated
        // occurrences expanded from each event's recurrence rule, not stored
        // rows: the daily aarti is one record and many occurrences.
        Route::get('/events', [PublicEventController::class, 'index'])
            ->name('events.index');

        Route::get('/events/{event}', [PublicEventController::class, 'show'])
            ->whereNumber('event')
            ->name('events.show');

        // Gallery and video darshan (Phase 5). Published items only, filtered
        // in the query; the list is paginated because an unbounded gallery is a
        // denial-of-service against our own API.
        Route::get('/media', [PublicMediaController::class, 'index'])
            ->name('media.index');

        Route::get('/media/{media}', [PublicMediaController::class, 'show'])
            ->whereNumber('media')
            ->name('media.show');

        Route::get('/albums', [PublicMediaController::class, 'albums'])
            ->name('albums.index');

        // Where devotees may send money (Phase 6). This is the *whole* public
        // donation surface: no list, no count, no total, no donor. Donor detail
        // reaches no public endpoint at any status, and aggregate transparency
        // is Phase 9's requirement rather than an omission here.
        Route::get('/donation-settings', [PublicDonationController::class, 'settings'])
            ->name('donation-settings');

        // The contact form (Phase 7). Two endpoints and no third: fetch a
        // form, send a message. There is deliberately **no public read** of an
        // enquiry at any status — nothing a stranger posts here can be served
        // back to anybody (PHASE_7_PLAN assumption N1).
        //
        // The submission carries `throttle:enquiry-submit` *in addition* to the
        // group's general public limit, because this is the one endpoint in the
        // application that an anonymous request can write with.
        Route::get('/enquiry-form', [PublicEnquiryController::class, 'form'])
            ->name('enquiry-form');

        Route::post('/enquiries', [PublicEnquiryController::class, 'store'])
            ->middleware('throttle:enquiry-submit')
            ->name('enquiries.store');

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

        // --- Puja, events and the calendar (Phase 4) -------------------
        // Reading is granted with content.view so a Viewer can see the
        // calendar without being able to change it; writes need events.manage.
        Route::get('/events', [AdminEventController::class, 'index'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('events.index');
        Route::get('/events/{event}', [AdminEventController::class, 'show'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('events.show');
        Route::post('/events', [AdminEventController::class, 'store'])
            ->middleware('can:'.Permission::EVENTS_MANAGE)->name('events.store');
        Route::put('/events/{event}', [AdminEventController::class, 'update'])
            ->middleware('can:'.Permission::EVENTS_MANAGE)->name('events.update');
        Route::delete('/events/{event}', [AdminEventController::class, 'destroy'])
            ->middleware('can:'.Permission::EVENTS_MANAGE)->name('events.destroy');

        // --- Gallery and video darshan (Phase 5) -----------------------
        // Reading is granted with content.view, as for the committee and the
        // calendar; every write needs media.manage. Uploading carries its own
        // rate limit on top: it is the only endpoint that consumes disk.
        Route::get('/media', [AdminMediaController::class, 'index'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('media.index');
        Route::get('/media/{media}', [AdminMediaController::class, 'show'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('media.show');
        Route::get('/media/{media}/references', [AdminMediaController::class, 'references'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('media.references');

        Route::post('/media', [AdminMediaController::class, 'store'])
            ->middleware(['can:'.Permission::MEDIA_MANAGE, 'throttle:media-upload'])
            ->name('media.store');
        Route::post('/media/video', [AdminMediaController::class, 'storeVideo'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('media.store-video');
        Route::post('/media/reorder', [AdminMediaController::class, 'reorder'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('media.reorder');
        Route::put('/media/{media}', [AdminMediaController::class, 'update'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('media.update');
        Route::delete('/media/{media}', [AdminMediaController::class, 'destroy'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('media.destroy');

        Route::get('/albums', [AlbumController::class, 'index'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('albums.index');
        Route::get('/albums/{album}', [AlbumController::class, 'show'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('albums.show');
        Route::post('/albums', [AlbumController::class, 'store'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('albums.store');
        Route::put('/albums/{album}', [AlbumController::class, 'update'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('albums.update');
        Route::delete('/albums/{album}', [AlbumController::class, 'destroy'])
            ->middleware('can:'.Permission::MEDIA_MANAGE)->name('albums.destroy');

        // --- Donations and receipts (Phase 6) --------------------------
        // Reading the register needs donations.view; recording, confirming and
        // reversing need donations.manage. There is deliberately **no DELETE**
        // on any of these: nothing is ever deleted, and reversal — which keeps
        // the row, its receipt number and a stated reason — is the only undo.
        Route::get('/donations', [AdminDonationController::class, 'index'])
            ->middleware('can:'.Permission::DONATIONS_VIEW)->name('donations.index');
        Route::get('/donations/summary', [AdminDonationController::class, 'summary'])
            ->middleware('can:'.Permission::DONATIONS_VIEW)->name('donations.summary');
        Route::get('/donations/{donation}', [AdminDonationController::class, 'show'])
            ->whereNumber('donation')
            ->middleware('can:'.Permission::DONATIONS_VIEW)->name('donations.show');
        Route::get('/donations/{donation}/receipt', [AdminDonationController::class, 'receipt'])
            ->whereNumber('donation')
            ->middleware('can:'.Permission::DONATIONS_VIEW)->name('donations.receipt');

        Route::post('/donations', [AdminDonationController::class, 'store'])
            ->middleware('can:'.Permission::DONATIONS_MANAGE)->name('donations.store');
        Route::put('/donations/{donation}', [AdminDonationController::class, 'update'])
            ->whereNumber('donation')
            ->middleware('can:'.Permission::DONATIONS_MANAGE)->name('donations.update');
        Route::post('/donations/{donation}/confirm', [AdminDonationController::class, 'confirm'])
            ->whereNumber('donation')
            ->middleware('can:'.Permission::DONATIONS_MANAGE)->name('donations.confirm');
        Route::post('/donations/{donation}/reverse', [AdminDonationController::class, 'reverse'])
            ->whereNumber('donation')
            ->middleware('can:'.Permission::DONATIONS_MANAGE)->name('donations.reverse');

        // The published bank/UPI block sits behind the **money** permission,
        // not the content one: a compromised Content Manager account can
        // rewrite the About page but must not be able to redirect the temple's
        // donations (PHASE_6_PLAN assumption N6).
        Route::get('/donation-settings', [DonationSettingsController::class, 'show'])
            ->middleware('can:'.Permission::DONATIONS_VIEW)->name('donation-settings.show');
        Route::put('/donation-settings', [DonationSettingsController::class, 'update'])
            ->middleware('can:'.Permission::DONATIONS_MANAGE)->name('donation-settings.update');

        // --- Devotee enquiries (Phase 7) -------------------------------
        // `enquiries.manage` on the reads as well as the writes. Unlike the
        // calendar or the committee there is no content.view tier here: every
        // row holds a villager's name, their telephone number and whatever
        // they chose to tell the temple, and reading that is the sensitive act
        // (PHASE_7_PLAN assumption N9).
        //
        // No DELETE, for the same reason donations have none: `spam` moves a
        // row out of the inbox and keeps it.
        Route::get('/enquiries', [AdminEnquiryController::class, 'index'])
            ->middleware('can:'.Permission::ENQUIRIES_MANAGE)->name('enquiries.index');
        Route::get('/enquiries/summary', [AdminEnquiryController::class, 'summary'])
            ->middleware('can:'.Permission::ENQUIRIES_MANAGE)->name('enquiries.summary');
        Route::get('/enquiries/{enquiry}', [AdminEnquiryController::class, 'show'])
            ->whereNumber('enquiry')
            ->middleware('can:'.Permission::ENQUIRIES_MANAGE)->name('enquiries.show');
        Route::put('/enquiries/{enquiry}/status', [AdminEnquiryController::class, 'updateStatus'])
            ->whereNumber('enquiry')
            ->middleware('can:'.Permission::ENQUIRIES_MANAGE)->name('enquiries.update-status');
    });
