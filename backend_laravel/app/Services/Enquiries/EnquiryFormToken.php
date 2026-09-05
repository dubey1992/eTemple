<?php

declare(strict_types=1);

namespace App\Services\Enquiries;

use App\Exceptions\EnquiryGuardException;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Str;

/**
 * The ticket a visitor must hold to post the contact form.
 *
 * ## What it is for
 *
 * `POST /api/public/enquiries` is the only endpoint in this application that an
 * anonymous stranger can write to. A rate limit alone caps how fast the abuse
 * arrives; it does nothing about a script that simply POSTs at the endpoint
 * forever at a polite speed. This makes the visitor fetch a ticket first, and
 * the ticket carries three facts a script has to reckon with:
 *
 *  * **when the form was opened** — a submission that arrives faster than a
 *    person could type is refused;
 *  * **which address opened it** — a ticket issued to one visitor cannot be
 *    handed round a botnet;
 *  * **whether a question must be answered** — the escalation the specification
 *    calls "CAPTCHA-after-threshold".
 *
 * ## Why the answer is not in the token
 *
 * A self-contained signed token would have to carry the expected answer, and a
 * one-digit sum is brute-forced from a hash in microseconds. So the token is a
 * signed **nonce** and the state sits in the cache, which buys two things: the
 * answer never leaves the server, and the ticket can be **spent once**. One
 * harvested token is worth exactly one message.
 *
 * The trade is that clearing the cache invalidates outstanding forms. A visitor
 * then sees "this form has expired, please send it again" — which is honest,
 * and recoverable in one tap.
 */
class EnquiryFormToken
{
    private const CACHE_PREFIX = 'enquiry-form:';

    /**
     * Issues a ticket, with a question attached when the address has earned one.
     *
     * @return array{token: string, challenge: array{question_hi: string, question_en: string}|null, min_fill_seconds: int, expires_in_seconds: int}
     */
    public function issue(string $ipHash, bool $withChallenge): array
    {
        $nonce = Str::random(40);
        $lifetime = $this->lifetimeMinutes();

        $challenge = $withChallenge ? $this->makeChallenge() : null;

        Cache::put(
            self::CACHE_PREFIX.$nonce,
            [
                'issued_at' => now()->timestamp,
                'ip_hash' => $ipHash,
                'answer' => $challenge['answer'] ?? null,
            ],
            now()->addMinutes($lifetime),
        );

        return [
            'token' => $this->sign($nonce),
            'challenge' => $challenge === null ? null : [
                'question_hi' => $challenge['question_hi'],
                'question_en' => $challenge['question_en'],
            ],
            'min_fill_seconds' => $this->minFillSeconds(),
            'expires_in_seconds' => $lifetime * 60,
        ];
    }

    /**
     * Spends a ticket, or refuses the submission.
     *
     * Pulled rather than read: whatever happens next, this ticket is now gone.
     * A refused submission does not get to retry with the same one, which is
     * what stops a script from grinding at the question until it guesses.
     *
     * @param  bool  $challengeNowRequired  the threshold re-checked at submission
     *                                      time, so a ticket fetched before the
     *                                      abuse started is not a way round it
     *
     * @throws EnquiryGuardException
     */
    public function consume(
        ?string $token,
        ?string $answer,
        string $ipHash,
        bool $challengeNowRequired,
    ): void {
        $nonce = $this->verifySignature($token);

        /** @var array{issued_at: int, ip_hash: string, answer: string|null}|null $state */
        $state = Cache::pull(self::CACHE_PREFIX.$nonce);

        if ($state === null || ! hash_equals($state['ip_hash'], $ipHash)) {
            throw EnquiryGuardException::formExpired();
        }

        if (now()->timestamp - $state['issued_at'] < $this->minFillSeconds()) {
            throw EnquiryGuardException::submittedTooQuickly();
        }

        // The ticket predates the threshold being crossed: the visitor is sent
        // back for a form that carries the question.
        if ($challengeNowRequired && $state['answer'] === null) {
            throw EnquiryGuardException::challengeRequired();
        }

        if ($state['answer'] !== null && ! $this->answerMatches($state['answer'], $answer)) {
            throw EnquiryGuardException::challengeIncorrect();
        }
    }

    /**
     * A small sum, asked in both languages.
     *
     * Addition of two single digits, written in words rather than figures, so
     * the question cannot be answered by pattern-matching digits out of the
     * page. It is not a hard problem — it is not meant to be. It is meant to be
     * more work than the next unprotected contact form on the internet.
     *
     * @return array{question_hi: string, question_en: string, answer: string}
     */
    private function makeChallenge(): array
    {
        $left = random_int(1, 9);
        $right = random_int(1, 9);

        return [
            'question_hi' => sprintf(
                '%s और %s को जोड़ने पर कितना होता है?',
                self::HINDI_NUMBERS[$left],
                self::HINDI_NUMBERS[$right],
            ),
            'question_en' => sprintf(
                'What is %s plus %s?',
                self::ENGLISH_NUMBERS[$left],
                self::ENGLISH_NUMBERS[$right],
            ),
            'answer' => (string) ($left + $right),
        ];
    }

    /**
     * Compares the answer, accepting Devanagari digits.
     *
     * A Hindi keyboard types `१२`, and refusing that would fail exactly the
     * villagers this site is for.
     */
    private function answerMatches(string $expected, ?string $given): bool
    {
        if ($given === null) {
            return false;
        }

        $normalised = strtr(trim($given), self::DEVANAGARI_DIGITS);

        return hash_equals($expected, $normalised);
    }

    private function sign(string $nonce): string
    {
        return $nonce.'.'.hash_hmac('sha256', $nonce, $this->key());
    }

    /**
     * Returns the nonce carried by a well-formed token.
     *
     * The signature check is what lets a forged token be refused without
     * touching the cache, so garbage cannot be used to probe for live nonces.
     *
     * @throws EnquiryGuardException
     */
    private function verifySignature(?string $token): string
    {
        if ($token === null || ! str_contains($token, '.')) {
            throw EnquiryGuardException::formExpired();
        }

        [$nonce, $signature] = explode('.', $token, 2);

        if ($nonce === '' || ! hash_equals(hash_hmac('sha256', $nonce, $this->key()), $signature)) {
            throw EnquiryGuardException::formExpired();
        }

        return $nonce;
    }

    private function key(): string
    {
        // The application key, which is already required to be present and
        // secret. No new secret is introduced by this phase.
        return (string) config('app.key');
    }

    private function minFillSeconds(): int
    {
        return max(0, (int) config('enquiries.min_fill_seconds', 4));
    }

    private function lifetimeMinutes(): int
    {
        return max(1, (int) config('enquiries.token_lifetime_minutes', 120));
    }

    /** @var array<int, string> */
    private const HINDI_NUMBERS = [
        1 => 'एक', 2 => 'दो', 3 => 'तीन', 4 => 'चार', 5 => 'पाँच',
        6 => 'छह', 7 => 'सात', 8 => 'आठ', 9 => 'नौ',
    ];

    /** @var array<int, string> */
    private const ENGLISH_NUMBERS = [
        1 => 'one', 2 => 'two', 3 => 'three', 4 => 'four', 5 => 'five',
        6 => 'six', 7 => 'seven', 8 => 'eight', 9 => 'nine',
    ];

    /** @var array<string, string> */
    private const DEVANAGARI_DIGITS = [
        '०' => '0', '१' => '1', '२' => '2', '३' => '3', '४' => '4',
        '५' => '5', '६' => '6', '७' => '7', '८' => '8', '९' => '9',
    ];
}
