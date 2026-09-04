<?php

/*
 | Cross-origin rules for the Flutter Web client.
 |
 | supports_credentials must stay true for Sanctum cookie/session auth, which
 | means allowed_origins can never be a wildcard -- the browser rejects that
 | pairing. Origins come from the environment so staging/production stay explicit.
 */

$origins = array_values(array_filter(array_map(
    'trim',
    explode(',', (string) env('CORS_ALLOWED_ORIGINS', (string) env('FRONTEND_URL', 'http://localhost:5000')))
)));

return [
    'paths' => ['api/*', 'sanctum/csrf-cookie'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => $origins,
    'allowed_origins_patterns' => [],
    'allowed_headers' => ['Accept', 'Authorization', 'Content-Type', 'X-Requested-With', 'X-XSRF-TOKEN', 'X-Request-Id'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
