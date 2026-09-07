<?php

declare(strict_types=1);

use App\Http\Controllers\Api\Admin\AccountingCategoryController;
use App\Http\Controllers\Api\Admin\AccountingSettingsController;
use App\Http\Controllers\Api\Admin\AdminPingController;
use App\Http\Controllers\Api\Admin\AlbumController;
use App\Http\Controllers\Api\Admin\AnnouncementController as AdminAnnouncementController;
use App\Http\Controllers\Api\Admin\AuditLogController;
use App\Http\Controllers\Api\Admin\CommitteeMemberController;
use App\Http\Controllers\Api\Admin\DonationController as AdminDonationController;
use App\Http\Controllers\Api\Admin\DonationSettingsController;
use App\Http\Controllers\Api\Admin\EnquiryController as AdminEnquiryController;
use App\Http\Controllers\Api\Admin\EventController as AdminEventController;
use App\Http\Controllers\Api\Admin\MediaController as AdminMediaController;
use App\Http\Controllers\Api\Admin\OverviewController;
use App\Http\Controllers\Api\Admin\PageController as AdminPageController;
use App\Http\Controllers\Api\Admin\ReportController;
use App\Http\Controllers\Api\Admin\RoleController;
use App\Http\Controllers\Api\Admin\SiteSettingsController as AdminSiteSettingsController;
use App\Http\Controllers\Api\Admin\TempleProfileController;
use App\Http\Controllers\Api\Admin\TransactionController;
use App\Http\Controllers\Api\Admin\UserController;
use App\Http\Controllers\Api\Auth\AuthController;
use App\Http\Controllers\Api\HealthController;
use App\Http\Controllers\Api\PublicSite\AnnouncementController as PublicAnnouncementController;
use App\Http\Controllers\Api\PublicSite\DonationController as PublicDonationController;
use App\Http\Controllers\Api\PublicSite\EnquiryController as PublicEnquiryController;
use App\Http\Controllers\Api\PublicSite\EventController as PublicEventController;
use App\Http\Controllers\Api\PublicSite\MediaController as PublicMediaController;
use App\Http\Controllers\Api\PublicSite\PageController as PublicPageController;
use App\Http\Controllers\Api\PublicSite\SiteSettingsController as PublicSiteSettingsController;
use App\Http\Controllers\Api\PublicSite\TempleController as PublicTempleController;
use App\Http\Controllers\Api\PublicSite\TransparencyController as PublicTransparencyController;
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

        // The temple's current notices (Phase 8). Published **and** inside
        // their window — the schedule is a where clause, so a notice dated for
        // next week is not reachable today by any request.
        Route::get('/announcements', [PublicAnnouncementController::class, 'index'])
            ->name('announcements.index');

        // What the temple did with the money (Phase 9). Aggregates only: no
        // individual transaction and no person's name reaches this endpoint at
        // any status, and only approved money is counted. When the committee
        // has not published its books it says so plainly rather than serving a
        // page of zeros, which would read as "the temple received nothing"
        // (PHASE_9_PLAN assumptions N6, N7 and N9).
        Route::get('/transparency', [PublicTransparencyController::class, 'show'])
            ->name('transparency');

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

        Route::get('/pages', [PublicPageController::class, 'index'])
            ->name('pages.index');

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

        /*
         * --- The audit trail (Phase 11) --------------------------------
         *
         * Read only, and deliberately nothing else. There is no POST, PUT or
         * DELETE at any permission — the trail is append-only, and an endpoint
         * that could edit it would make every row in it worthless. There is no
         * export either: it carries donor names and enquiry references, and a
         * downloadable audit trail is a personal-data leak with an
         * official-sounding name.
         */
        Route::get('/audit-logs', [AuditLogController::class, 'index'])
            ->middleware('can:'.Permission::AUDIT_VIEW)->name('audit-logs.index');
        Route::get('/audit-logs/actions', [AuditLogController::class, 'actions'])
            ->middleware('can:'.Permission::AUDIT_VIEW)->name('audit-logs.actions');

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

        // --- Announcements and notifications (Phase 8) -----------------
        // Reading is granted with content.view, as for the calendar and the
        // gallery; writing, publishing, archiving and sending all need
        // announcements.manage.
        //
        // Publishing, archiving and **sending** are separate endpoints rather
        // than a status somebody can PUT. They have different consequences and
        // one of them cannot be undone: giving the irreversible one its own URL
        // is what makes "no sends without explicit admin action" true of the
        // API and not merely of the screen (PHASE_8_PLAN assumption N1).
        //
        // No DELETE: archiving keeps the row and its record of what was sent.
        Route::get('/announcements', [AdminAnnouncementController::class, 'index'])
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('announcements.index');
        Route::get('/announcements/{announcement}', [AdminAnnouncementController::class, 'show'])
            ->whereNumber('announcement')
            ->middleware('can:'.Permission::CONTENT_VIEW)->name('announcements.show');

        Route::post('/announcements', [AdminAnnouncementController::class, 'store'])
            ->middleware('can:'.Permission::ANNOUNCEMENTS_MANAGE)->name('announcements.store');
        Route::put('/announcements/{announcement}', [AdminAnnouncementController::class, 'update'])
            ->whereNumber('announcement')
            ->middleware('can:'.Permission::ANNOUNCEMENTS_MANAGE)->name('announcements.update');
        Route::post('/announcements/{announcement}/publish', [AdminAnnouncementController::class, 'publish'])
            ->whereNumber('announcement')
            ->middleware('can:'.Permission::ANNOUNCEMENTS_MANAGE)->name('announcements.publish');
        Route::post('/announcements/{announcement}/archive', [AdminAnnouncementController::class, 'archive'])
            ->whereNumber('announcement')
            ->middleware('can:'.Permission::ANNOUNCEMENTS_MANAGE)->name('announcements.archive');
        Route::post('/announcements/{announcement}/send', [AdminAnnouncementController::class, 'send'])
            ->whereNumber('announcement')
            ->middleware('can:'.Permission::ANNOUNCEMENTS_MANAGE)->name('announcements.send');

        // --- Accounts and transparency (Phase 9) -----------------------
        // Reading the books needs accounts.view; recording, approving and
        // reversing need accounts.manage. Both keys have been in the matrix
        // since Phase 2: a Treasurer holds both, a Viewer holds the first, and
        // a Content Manager holds neither — the specification says a Content
        // Manager never sees financial detail.
        //
        // As with donations there is **no DELETE on a transaction**: reversal,
        // which keeps the row, its bill and a stated reason, is the only undo.
        Route::get('/transactions', [TransactionController::class, 'index'])
            ->middleware('can:'.Permission::ACCOUNTS_VIEW)->name('transactions.index');
        Route::get('/transactions/summary', [TransactionController::class, 'summary'])
            ->middleware('can:'.Permission::ACCOUNTS_VIEW)->name('transactions.summary');
        Route::get('/transactions/{transaction}', [TransactionController::class, 'show'])
            ->whereNumber('transaction')
            ->middleware('can:'.Permission::ACCOUNTS_VIEW)->name('transactions.show');

        // The bill, streamed from a private disk. `accounts.view` rather than
        // `accounts.manage` on purpose: a Viewer auditing the books needs to
        // see the evidence, which is the entire reason for attaching it. The
        // stored path is never serialized anywhere (PHASE_9_PLAN assumption N5).
        Route::get('/transactions/{transaction}/attachment', [TransactionController::class, 'attachment'])
            ->whereNumber('transaction')
            ->middleware('can:'.Permission::ACCOUNTS_VIEW)->name('transactions.attachment');

        Route::post('/transactions', [TransactionController::class, 'store'])
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('transactions.store');
        Route::put('/transactions/{transaction}', [TransactionController::class, 'update'])
            ->whereNumber('transaction')
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('transactions.update');
        Route::post('/transactions/{transaction}/approve', [TransactionController::class, 'approve'])
            ->whereNumber('transaction')
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('transactions.approve');
        Route::post('/transactions/{transaction}/reverse', [TransactionController::class, 'reverse'])
            ->whereNumber('transaction')
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('transactions.reverse');

        // Categories carry a DELETE, unlike everything else in Phases 6-9, and
        // it is narrow: a heading that has never been used is a typo, not
        // history. One that has been used is refused, and the database says the
        // same thing one layer down via restrictOnDelete.
        Route::get('/accounting-categories', [AccountingCategoryController::class, 'index'])
            ->middleware('can:'.Permission::ACCOUNTS_VIEW)->name('accounting-categories.index');
        Route::post('/accounting-categories', [AccountingCategoryController::class, 'store'])
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('accounting-categories.store');
        Route::put('/accounting-categories/{category}', [AccountingCategoryController::class, 'update'])
            ->whereNumber('category')
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('accounting-categories.update');
        Route::delete('/accounting-categories/{category}', [AccountingCategoryController::class, 'destroy'])
            ->whereNumber('category')
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('accounting-categories.destroy');

        // Whether the books are public at all, and where they start. Behind the
        // money permission for the same reason the bank details are: a
        // compromised content account must not be able to publish, unpublish or
        // restate the temple's accounts.
        Route::get('/accounting-settings', [AccountingSettingsController::class, 'show'])
            ->middleware('can:'.Permission::ACCOUNTS_VIEW)->name('accounting-settings.show');
        Route::put('/accounting-settings', [AccountingSettingsController::class, 'update'])
            ->middleware('can:'.Permission::ACCOUNTS_MANAGE)->name('accounting-settings.update');

        // --- Reports and analytics (Phase 10) --------------------------
        // Everything here is a GET; nothing in this module writes.
        //
        // `reports.view` is the ticket in, and each report declares the domain
        // key it also needs — so a report of the ledger needs accounts.view and
        // one of the inbox needs enquiries.manage. The catalogue lists only
        // what the caller may actually run.
        //
        // Downloading is a **separate** permission from reading: a Viewer may
        // read a report on screen and not take a copy away. And the export
        // shares the screen's query string and its runner, which is what makes
        // "the export applies exactly the on-screen filters" true of the code
        // rather than a promise (PHASE_10_PLAN assumption N1).
        Route::get('/reports', [ReportController::class, 'index'])
            ->middleware('can:'.Permission::REPORTS_VIEW)->name('reports.index');
        Route::get('/reports/{key}', [ReportController::class, 'show'])
            ->where('key', '[a-z0-9-]+')
            ->middleware('can:'.Permission::REPORTS_VIEW)->name('reports.show');
        Route::get('/reports/{key}/export', [ReportController::class, 'export'])
            ->where('key', '[a-z0-9-]+')
            ->middleware('can:'.Permission::REPORTS_VIEW)->name('reports.export');

        // The dashboard's figures. Each panel is gated again by the module it
        // reads, so an account with no money keys gets a dashboard with no
        // money on it rather than one full of zeros.
        Route::get('/overview', [OverviewController::class, 'show'])
            ->middleware('can:'.Permission::REPORTS_VIEW)->name('overview');
    });
