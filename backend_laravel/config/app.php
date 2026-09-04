<?php

return [
    'name' => env('APP_NAME', 'Radha Krishna Thakurbari'),
    'env' => env('APP_ENV', 'production'),
    'debug' => (bool) env('APP_DEBUG', false),
    'url' => env('APP_URL', 'http://localhost'),
    'frontend_url' => env('FRONTEND_URL', 'http://localhost:5000'),

    // The temple operates in India; timestamps are stored in UTC and presented
    // against this zone (spec: "handle configured server timezone correctly").
    'timezone' => env('APP_TIMEZONE', 'Asia/Kolkata'),

    // Hindi is the default language of the product.
    'locale' => env('APP_LOCALE', 'hi'),
    'fallback_locale' => env('APP_FALLBACK_LOCALE', 'hi'),
    'faker_locale' => env('APP_FAKER_LOCALE', 'hi_IN'),

    'cipher' => 'AES-256-CBC',
    'key' => env('APP_KEY'),
    'previous_keys' => array_filter(explode(',', (string) env('APP_PREVIOUS_KEYS', ''))),

    'maintenance' => [
        'driver' => env('APP_MAINTENANCE_DRIVER', 'file'),
        'store' => env('APP_MAINTENANCE_STORE', 'database'),
    ],
];
