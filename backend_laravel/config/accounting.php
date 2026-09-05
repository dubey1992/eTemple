<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Accounts and transparency (spec Phase 9)
|--------------------------------------------------------------------------
| Limits and controls live here rather than in the services, so a committee
| can tighten them without a code change.
*/

return [
    /*
    | Whether the person who recorded a transaction may also approve it.
    |
    | `false` here means they may — which is the default, and is deliberate.
    | Requiring two people is the standard control and several committees will
    | want it, but this temple may have exactly one treasurer, and a control
    | that deadlocks the books on day one is a control nobody keeps: they share
    | a login instead, which is worse than no control at all
    | (PHASE_9_PLAN assumption N3).
    */
    'require_second_approver' => (bool) env('ACCOUNTS_REQUIRE_SECOND_APPROVER', false),

    /*
    | The category code that means "a donation". It is reserved: donated income
    | is counted from the donation register, never re-entered as a transaction,
    | because a donation entered in both places is published at twice its value
    | (assumption N1).
    */
    'donation_category_code' => 'donation',

    /* Largest single transaction, in rupees. A wall against a slipped decimal
    | point, not a policy about what the temple may spend. */
    'max_rupees' => (int) env('ACCOUNTS_MAX_RUPEES', 10_000_000),

    /* How far back a transaction may be dated. Books are written up late; they
    | are not written up years late. */
    'backdate_limit_days' => (int) env('ACCOUNTS_BACKDATE_LIMIT_DAYS', 366),

    'default_per_page' => 25,
    'max_per_page' => 100,

    /* How many financial years the public page offers. */
    'public_years' => (int) env('ACCOUNTS_PUBLIC_YEARS', 5),

    'attachments' => [
        /*
        | The private disk. `local` is storage/app/private, which is not
        | web-reachable — these are shop bills, not gallery photographs, and
        | the media library is deliberately not reused (assumption N5).
        */
        'disk' => env('ACCOUNTS_ATTACHMENT_DISK', 'local'),

        'path' => env('ACCOUNTS_ATTACHMENT_PATH', 'accounts/attachments'),

        'max_upload_kb' => (int) env('ACCOUNTS_ATTACHMENT_MAX_KB', 8192),

        /*
        | Accepted types, keyed by the MIME the server detects from the bytes —
        | never the browser's Content-Type or the file name (Phase 5's rule).
        |
        | PDF is here and not in the media library because that is what a bank
        | sends. No SVG: it is a script container.
        */
        'accepted_mimes' => [
            'image/jpeg' => 'jpg',
            'image/png' => 'png',
            'image/webp' => 'webp',
            'application/pdf' => 'pdf',
        ],
    ],
];
