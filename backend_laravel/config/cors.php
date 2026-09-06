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
    /*
    | `storage/*` is here for hosts that route uploads through PHP. Most do not
    | — a static file is served by the web server and never reaches Laravel — so
    | the header on the uploads path is a **web-server** setting, and the
    | deployment checklist asks for it. Without it a browser cannot read the
    | image bytes cross-origin; the Flutter client falls back to an <img>
    | element so the gallery still renders, at the cost of the bounded decode.
    */
    'paths' => ['api/*', 'sanctum/csrf-cookie', 'storage/*'],
    'allowed_methods' => ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    'allowed_origins' => $origins,
    'allowed_origins_patterns' => [],
    /*
    | X-HTTP-Method-Override is load-bearing, not a convenience. The production
    | host answers PUT, PATCH and DELETE with a 403 raised before PHP, so the
    | client tunnels all three through POST with that header. Leave it out and
    | the preflight still succeeds — it is the *actual* request the browser then
    | refuses to send, which surfaces as a bare net::ERR_FAILED with no status
    | to read. curl never reproduces it, because curl does not enforce CORS.
    */
    'allowed_headers' => ['Accept', 'Authorization', 'Content-Type', 'X-Requested-With', 'X-XSRF-TOKEN', 'X-Request-Id', 'X-HTTP-Method-Override'],
    'exposed_headers' => [],
    'max_age' => 0,
    'supports_credentials' => true,
];
