<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals that keep the temple's books honest.
 *
 * Most surface as 422 against the offending field, so a treasurer sees which
 * box is wrong. The two that are about *state* rather than input — editing a
 * receipted donation, or acting on one twice — are 409s: the request was well
 * formed, and it is the history that refuses it.
 */
final class DonationGuardException extends DomainException
{
    public static function amountNotPositive(): self
    {
        return self::field('amount', 'A donation must be more than zero.');
    }

    public static function amountTooLarge(int $maxRupees): self
    {
        return self::field('amount', sprintf(
            'That is larger than the ₹%s limit. Check the decimal point, or raise the limit in the settings.',
            number_format($maxRupees),
        ));
    }

    public static function amountUnreadable(): self
    {
        return self::field('amount', 'The amount could not be read. Use digits, for example 501 or 501.50.');
    }

    public static function dateInFuture(): self
    {
        return self::field('donation_date', 'A donation cannot be dated in the future.');
    }

    public static function dateTooOld(int $days): self
    {
        return self::field('donation_date', sprintf(
            'That date is more than %d days ago. Check the year.',
            $days,
        ));
    }

    public static function referenceRequired(): self
    {
        return self::field(
            'reference_number',
            'A reference is required for anything but cash — the UPI reference, cheque number or transfer id. '
                .'Without it this donation cannot be matched against the bank statement.',
        );
    }

    /**
     * The immutability rule (PHASE_6_PLAN assumption N3).
     *
     * Stated in full because it also tells the treasurer what to do instead,
     * and "reverse and record again" is not obvious from a refusal alone.
     */
    public static function receiptedAndLocked(): self
    {
        return new self(
            ApiErrorCode::DONATION_LOCKED,
            'A receipt has been issued for this donation, so its details can no longer be changed — '
                .'only the notes. To correct it, reverse it and record it again.',
            409,
        );
    }

    public static function alreadyConfirmed(): self
    {
        return new self(
            ApiErrorCode::DONATION_LOCKED,
            'This donation has already been confirmed and has a receipt number.',
            409,
        );
    }

    public static function alreadyReversed(): self
    {
        return new self(
            ApiErrorCode::DONATION_LOCKED,
            'This donation has already been reversed.',
            409,
        );
    }

    public static function cannotConfirmReversed(): self
    {
        return new self(
            ApiErrorCode::DONATION_LOCKED,
            'A reversed donation cannot be confirmed. Record it again instead, so both entries remain visible.',
            409,
        );
    }

    public static function reversalReasonRequired(): self
    {
        return self::field(
            'reversal_reason',
            'Say why this donation is being reversed. It stays in the books, and the reason is what explains it.',
        );
    }

    private static function field(string $field, string $message): self
    {
        return new self(ApiErrorCode::VALIDATION_FAILED, $message, 422, [$field => [$message]]);
    }
}
