<?php

use Illuminate\Cookie\Middleware\EncryptCookies;
use Illuminate\Foundation\Http\Middleware\ValidateCsrfToken;
use Laravel\Sanctum\Http\Middleware\AuthenticateSession;

return [
    // Hosts that may authenticate with cookies/sessions instead of tokens.
    // Must list the exact Flutter Web origin(s); never a wildcard in production.
    'stateful' => explode(',', (string) env('SANCTUM_STATEFUL_DOMAINS', implode(',', [
        'localhost',
        'localhost:5000',
        '127.0.0.1',
        '127.0.0.1:5000',
        '::1',
    ]))),

    'guard' => ['web'],

    'expiration' => null,

    'token_prefix' => env('SANCTUM_TOKEN_PREFIX', ''),

    'middleware' => [
        'authenticate_session' => AuthenticateSession::class,
        'encrypt_cookies' => EncryptCookies::class,
        'validate_csrf_token' => ValidateCsrfToken::class,
    ],
];
