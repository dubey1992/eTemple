<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Devotee enquiries (spec Phase 7)
|--------------------------------------------------------------------------
| The public contact form is the only place an anonymous visitor writes to
| this database, so every number that decides how much abuse it will absorb
| lives here rather than in the code — a committee under a spam wave can
| tighten them without waiting for a release.
*/

return [
    /* The prefix every enquiry reference carries: RKT/E/2026-27/0001. */
    'reference_prefix' => env('ENQUIRY_REFERENCE_PREFIX', 'RKT/E'),

    'reference_sequence_length' => 4,

    /* Message bounds, enforced on the server (PHASE_7_PLAN assumption N12). */
    'min_message_length' => 20,
    'max_message_length' => 2000,

    /* Largest page the admin inbox will serve. */
    'max_per_page' => 100,
    'default_per_page' => 25,

    /*
    | Anti-spam (PHASE_7_PLAN assumption N2).
    |
    | `min_fill_seconds` is the floor on how fast a form can be filled in. A
    | human reading a label, typing a name and writing twenty characters of
    | message does not finish in three seconds; a script finishes in none.
    |
    | `token_lifetime_minutes` is the ceiling: a token older than this is
    | refused, so a farm of tokens harvested once cannot be spent all week.
    */
    'min_fill_seconds' => (int) env('ENQUIRY_MIN_FILL_SECONDS', 4),
    'token_lifetime_minutes' => (int) env('ENQUIRY_TOKEN_LIFETIME_MINUTES', 120),

    /*
    | How many submissions one address may make before the form starts asking
    | a question, and the window that count is kept over.
    */
    'challenge_threshold' => (int) env('ENQUIRY_CHALLENGE_THRESHOLD', 2),
    'challenge_window_minutes' => (int) env('ENQUIRY_CHALLENGE_WINDOW_MINUTES', 60),

    /* Hard daily ceiling per address, on top of the per-minute rate limit. */
    'daily_limit_per_ip' => (int) env('ENQUIRY_DAILY_LIMIT_PER_IP', 10),

    /*
    | Acknowledgement e-mail (assumption N3).
    |
    | Off by default. An anonymous form with an e-mail field is an open relay
    | for harassment unless it is rate-limited per address and carries none of
    | the sender's own words, so it stays off until a committee turns it on
    | deliberately.
    */
    'acknowledgement' => [
        'enabled' => (bool) env('ENQUIRY_ACKNOWLEDGEMENT_ENABLED', false),
        'per_address_cooldown_minutes' => (int) env('ENQUIRY_ACK_COOLDOWN_MINUTES', 60),
    ],
];
