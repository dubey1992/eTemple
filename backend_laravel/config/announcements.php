<?php

declare(strict_types=1);

/*
|--------------------------------------------------------------------------
| Announcements and notifications (spec Phase 8)
|--------------------------------------------------------------------------
*/

return [
    /*
    | Which channels this installation can deliver on.
    |
    | `site` is not listed because it needs no provider: publishing an
    | announcement *is* the site channel.
    |
    | SMS and WhatsApp default to **off** and must stay off until a provider has
    | been chosen, approved and configured — which the specification requires
    | and this project has not been given. Turning one on here without wiring a
    | provider would make the send silently do nothing, which is the one
    | outcome worse than not offering it (PHASE_8_PLAN assumption N5).
    */
    'channels' => [
        'email' => (bool) env('ANNOUNCEMENT_EMAIL_ENABLED', true),
        'sms' => (bool) env('ANNOUNCEMENT_SMS_ENABLED', false),
        'whatsapp' => (bool) env('ANNOUNCEMENT_WHATSAPP_ENABLED', false),
    ],

    /*
    | How far ahead an announcement may be scheduled. Not a policy — a guard
    | against a year typed wrong, which would otherwise hide a notice for a
    | decade with no error anywhere.
    */
    'max_schedule_days' => (int) env('ANNOUNCEMENT_MAX_SCHEDULE_DAYS', 730),

    'max_per_page' => 100,
    'default_per_page' => 25,
];
