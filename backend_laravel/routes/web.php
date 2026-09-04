<?php

declare(strict_types=1);

use Illuminate\Support\Facades\Route;

/*
| The public website and admin console are Flutter Web applications; this
| backend serves JSON only. The single web route below reports what this host is
| so an accidental browser visit is not a blank page.
*/

Route::get('/', fn () => response()->json([
    'success' => true,
    'data' => [
        'application' => config('app.name'),
        'message' => 'API only. The website is served by the Flutter Web client.',
        'health' => url('/api/health'),
    ],
    'meta' => null,
]))->name('root');
