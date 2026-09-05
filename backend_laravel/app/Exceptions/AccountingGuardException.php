<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals that keep the temple's ledger defensible.
 *
 * The sibling of {@see DonationGuardException}, and shaped the same way: input
 * problems are 422 against the offending field, and refusals about *state* —
 * editing an approved figure, acting on one twice — are 409s, because the
 * request was well formed and it is the history that refuses it.
 */
final class AccountingGuardException extends DomainException
{
    public static function amountNotPositive(): self
    {
        return self::field('amount', 'An amount must be more than zero.');
    }

    public static function amountUnreadable(): self
    {
        return self::field('amount', 'The amount could not be read. Use digits, for example 1200 or 1200.50.');
    }

    public static function amountTooLarge(int $maxRupees): self
    {
        return self::field('amount', sprintf(
            'That is larger than the ₹%s limit. Check the decimal point, or raise the limit in the settings.',
            number_format($maxRupees),
        ));
    }

    public static function dateInFuture(): self
    {
        return self::field('transaction_date', 'A transaction cannot be dated in the future.');
    }

    public static function dateTooOld(int $days): self
    {
        return self::field('transaction_date', sprintf(
            'That date is more than %d days ago. Check the year.',
            $days,
        ));
    }

    public static function referenceRequired(): self
    {
        return self::field(
            'reference_number',
            'A reference is required for anything but cash — the UPI reference, cheque number or transfer id. '
                .'Without it this entry cannot be matched against the bank statement.',
        );
    }

    public static function categoryRequired(): self
    {
        return self::field('category_id', 'Choose a category. It is what the public breakdown is grouped by.');
    }

    public static function categoryInactive(): self
    {
        return self::field(
            'category_id',
            'That category is no longer in use. Choose an active one, or reactivate it first.',
        );
    }

    /**
     * The type/category agreement rule.
     *
     * A category belongs to one side of the books, and an expense filed under
     * an income heading would appear on the wrong side of the public
     * breakdown — silently, and in a figure the village reads.
     */
    public static function categoryTypeMismatch(string $categoryType): self
    {
        return self::field('category_id', sprintf(
            'That category belongs to %s, so the entry must be %s too. '
                .'Change the type, or choose a category on the other side.',
            $categoryType === 'income' ? 'income' : 'expenditure',
            $categoryType === 'income' ? 'income' : 'expenditure',
        ));
    }

    /**
     * The double-counting guard (PHASE_9_PLAN assumption N1).
     *
     * Stated in full because it also says where the money is already counted,
     * which is the part a treasurer needs in order to stop worrying that it has
     * been left out.
     */
    public static function donationsAreNotTransactions(): self
    {
        return self::field(
            'category_id',
            'Donations are not entered here. They are recorded in the donation register and counted from it, '
                .'so entering one again would publish it twice. Use the donations screen instead.',
        );
    }

    public static function categoryCodeReserved(): self
    {
        return self::field(
            'code',
            'That code is reserved for donations, which are counted from the donation register. Choose another.',
        );
    }

    public static function categoryInUse(int $count): self
    {
        return new self(
            ApiErrorCode::TRANSACTION_LOCKED,
            sprintf(
                'This category is used by %d entr%s, so it cannot be removed — the old entries would lose their '
                    .'heading. Deactivate it instead: it stops being offered, and history still reads correctly.',
                $count,
                $count === 1 ? 'y' : 'ies',
            ),
            409,
        );
    }

    /**
     * The immutability rule (assumption N4).
     *
     * Says what to do instead, because "reverse and record again" is not
     * obvious from a refusal alone.
     */
    public static function approvedAndLocked(): self
    {
        return new self(
            ApiErrorCode::TRANSACTION_LOCKED,
            'This entry has been approved and counted in the published totals, so its details can no longer be '
                .'changed — only the description. To correct it, reverse it and record it again.',
            409,
        );
    }

    public static function alreadyApproved(): self
    {
        return new self(
            ApiErrorCode::TRANSACTION_LOCKED,
            'This entry has already been approved.',
            409,
        );
    }

    public static function alreadyReversed(): self
    {
        return new self(
            ApiErrorCode::TRANSACTION_LOCKED,
            'This entry has already been reversed.',
            409,
        );
    }

    public static function cannotApproveReversed(): self
    {
        return new self(
            ApiErrorCode::TRANSACTION_LOCKED,
            'A reversed entry cannot be approved. Record it again instead, so both entries remain visible.',
            409,
        );
    }

    /**
     * Separation of duties, when the committee has switched it on
     * (assumption N3).
     */
    public static function needsASecondApprover(): self
    {
        return new self(
            ApiErrorCode::TRANSACTION_LOCKED,
            'You recorded this entry, and the temple has asked that somebody else approve what they did not record. '
                .'Another member with accounts permission needs to approve it.',
            409,
        );
    }

    public static function reversalReasonRequired(): self
    {
        return self::field(
            'reversal_reason',
            'Say why this entry is being reversed. It stays in the books, and the reason is what explains it.',
        );
    }

    public static function attachmentUnreadable(): self
    {
        return self::field('attachment', 'That file could not be read.');
    }

    /** @param list<string> $extensions */
    public static function attachmentTypeRefused(array $extensions): self
    {
        return self::field('attachment', sprintf(
            'A bill must be a %s file. The type is checked by reading the file, not by its name.',
            implode(', ', $extensions),
        ));
    }

    public static function attachmentTooLarge(int $maxKb): self
    {
        return self::field('attachment', sprintf(
            'That file is larger than %d MB. Photograph the bill at a smaller size, or scan it as a PDF.',
            intdiv($maxKb, 1024),
        ));
    }

    public static function attachmentMissing(): self
    {
        return new self(
            ApiErrorCode::NOT_FOUND,
            'There is no bill attached to this entry.',
            404,
        );
    }

    /**
     * The books are not public (assumption N7). A 200 carries this instead —
     * see `TransparencyController`; the exception exists for the paths that
     * genuinely cannot answer.
     */
    public static function accountsNotPublished(): self
    {
        return new self(
            ApiErrorCode::ACCOUNTS_NOT_PUBLISHED,
            'The temple has not published its accounts.',
            404,
        );
    }

    private static function field(string $field, string $message): self
    {
        return new self(ApiErrorCode::VALIDATION_FAILED, $message, 422, [$field => [$message]]);
    }
}
