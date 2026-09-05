<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Donations (spec Phase 6)
|--------------------------------------------------------------------------
| Kept here rather than in the code so a committee can change what its
| receipts look like without a release, and so the Flutter client can be told
| the same limits by the API.
*/

return [
    /*
    | The prefix every receipt number carries: RKT/2026-27/0001.
    |
    | Changing it changes only *future* numbers. Numbers already issued are
    | immutable, which is the whole point of them (PHASE_6_PLAN assumption N2).
    */
    'receipt_prefix' => env('DONATION_RECEIPT_PREFIX', 'RKT'),

    /* Zero-padding of the sequence within a financial year. */
    'receipt_sequence_length' => 4,

    /*
    | The month a financial year starts in. April, because that is the year a
    | temple's books in India are kept in.
    */
    'financial_year_start_month' => 4,

    /*
    | How far back a donation may be dated. A donation entered from a paper
    | book can legitimately be months old; a `2025` typed for `2026` is not, and
    | without a bound it would be silent.
    */
    'backdate_limit_days' => (int) env('DONATION_BACKDATE_LIMIT_DAYS', 366),

    /*
    | Largest single donation the form will accept, in rupees. Not a policy on
    | generosity — a guard against a slipped decimal point or an amount typed in
    | paise by mistake, which is the error a treasurer actually makes.
    */
    'max_rupees' => (int) env('DONATION_MAX_RUPEES', 10_000_000),

    /* Largest page the admin list will serve. */
    'max_per_page' => 100,
    'default_per_page' => 25,
];
