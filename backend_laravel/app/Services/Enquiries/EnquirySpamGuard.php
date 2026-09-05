<?php

declare(strict_types=1);

namespace App\Services\Enquiries;

use App\Exceptions\EnquiryGuardException;
use Illuminate\Support\Facades\Cache;

/**
 * What the contact form knows about where a submission came from.
 *
 * Three separate jobs, kept together because they all key off the same thing:
 *
 *  * turning an IP address into something storable (see below);
 *  * counting recent submissions, which decides when the form starts asking a
 *    question (PHASE_7_PLAN assumption N2, layer 4);
 *  * the daily ceiling, which sits above the per-minute rate limit because a
 *    limit of six a minute still allows eight thousand a day.
 *
 * ## Why the address is hashed
 *
 * Recognising that thirty messages came from one place does not require knowing
 * the place. The column holds an HMAC keyed by `APP_KEY`: it correlates
 * perfectly inside this installation, and outside it identifies nobody — a
 * stolen database backup does not become a list of who wrote to the temple
 * (assumption N10).
 */
class EnquirySpamGuard
{
    private const COUNT_PREFIX = 'enquiry-count:';

    private const DAILY_PREFIX = 'enquiry-daily:';

    /** Stable within this installation, meaningless outside it. */
    public function ipHash(?string $ip): string
    {
        return hash_hmac('sha256', (string) $ip, (string) config('app.key'));
    }

    /**
     * Whether this address has submitted enough to be asked a question.
     *
     * Deliberately evaluated from the count of *accepted* submissions, not of
     * requests: somebody whose first attempt was refused for a missing phone
     * number has not been abusing anything, and should not be handed a puzzle
     * for making a typing mistake.
     */
    public function requiresChallenge(string $ipHash): bool
    {
        $threshold = max(1, (int) config('enquiries.challenge_threshold', 2));

        return $this->recentCount($ipHash) >= $threshold;
    }

    public function recentCount(string $ipHash): int
    {
        return (int) Cache::get(self::COUNT_PREFIX.$ipHash, 0);
    }

    public function dailyCount(string $ipHash): int
    {
        return (int) Cache::get(self::DAILY_PREFIX.$ipHash, 0);
    }

    /**
     * @throws EnquiryGuardException when the address is over its daily ceiling
     */
    public function assertWithinDailyLimit(string $ipHash): void
    {
        $limit = max(1, (int) config('enquiries.daily_limit_per_ip', 10));

        if ($this->dailyCount($ipHash) >= $limit) {
            throw EnquiryGuardException::dailyLimitReached();
        }
    }

    /**
     * Records that a message was accepted from this address.
     *
     * Two counters with different lifetimes: a short window that decides the
     * question, and a day-long one that decides the ceiling. Both are cache
     * entries — losing them on a restart costs the temple nothing worse than a
     * spammer getting a few more attempts before being asked to add up.
     */
    public function recordSubmission(string $ipHash): void
    {
        $window = max(1, (int) config('enquiries.challenge_window_minutes', 60));

        $this->increment(self::COUNT_PREFIX.$ipHash, now()->addMinutes($window));
        $this->increment(self::DAILY_PREFIX.$ipHash, now()->endOfDay());
    }

    /**
     * Increments a counter without extending the window it lives in.
     *
     * `Cache::increment` does not create a key with a TTL, and re-`put`ting the
     * value with a fresh expiry would let a steady trickle keep its own window
     * open indefinitely — the counter would never fall back to zero, and after
     * the first burst every visitor from that address would face a question
     * forever. So the expiry is set only when the counter is first created.
     */
    private function increment(string $key, \DateTimeInterface $expiresAt): void
    {
        if (Cache::add($key, 1, $expiresAt)) {
            return;
        }

        Cache::increment($key);
    }
}
