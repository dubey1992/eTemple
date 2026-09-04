<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Media library (spec Phase 5)
|--------------------------------------------------------------------------
| Limits and formats live here rather than in the validator so a deployment
| on a slower connection can lower them without a code change, and so the
| Flutter client can be told the same numbers by the API.
*/

return [
    /*
    | The disk uploads are written to. `public` is the default (a symlinked
    | storage/app/public); production may point this at `s3` without a code
    | change (PHASE_5_PLAN assumption M5).
    */
    'disk' => env('MEDIA_DISK', 'public'),

    /* Directory prefix on that disk. */
    'path' => env('MEDIA_PATH', 'media'),

    /* Largest accepted upload, in kilobytes. PHP's own upload_max_filesize is
    | a second, independent wall. */
    'max_upload_kb' => (int) env('MEDIA_MAX_UPLOAD_KB', 8192),

    /*
    | Accepted image types, keyed by the MIME the server itself detects from
    | the bytes — never by the browser's Content-Type or the file name
    | (assumption M2).
    |
    | No GIF: animation would survive re-encoding as a single frame and
    | surprise the uploader. No SVG: it is a script container, and there is no
    | safe way to serve one from the same origin as the admin session.
    */
    'accepted_mimes' => [
        'image/jpeg' => 'jpg',
        'image/png' => 'png',
        'image/webp' => 'webp',
    ],

    /* Refuse absurd dimensions before allocating a GD image for them. */
    'max_pixels' => (int) env('MEDIA_MAX_PIXELS', 50_000_000),
    'min_dimension' => 16,

    /*
    | Responsive variants, longest edge in pixels. An image smaller than a
    | bound is never upscaled — the variant reuses the next size down
    | (assumption M4).
    */
    'variants' => [
        'thumb' => 480,
        'medium' => 1080,
        'large' => 1920,
    ],

    'quality' => (int) env('MEDIA_QUALITY', 82),

    /*
    | Video providers we will embed. An arbitrary iframe src from an admin form
    | is a stored-XSS vector; a validated video id is not (assumption M1).
    */
    'video_hosts' => [
        'youtube.com',
        'www.youtube.com',
        'm.youtube.com',
        'youtu.be',
    ],
];
