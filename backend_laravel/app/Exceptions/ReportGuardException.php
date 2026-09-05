<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;

/**
 * Refusals from the reporting module.
 *
 * Both are about disclosure rather than about input, which is why neither is a
 * 422 against a field: the request was well formed, and it is who is asking —
 * or how much they asked for — that refuses it.
 */
final class ReportGuardException extends DomainException
{
    /**
     * The disclosure control (PHASE_10_PLAN assumption N2).
     *
     * Stated in full because the reader needs to know that the report itself is
     * available to them — it is only the personal columns that are not.
     */
    public static function personalColumnsRefused(): self
    {
        return new self(
            ApiErrorCode::REPORT_DISCLOSURE_REFUSED,
            'This report can be run, but personal details — names, telephone numbers and addresses — '
                .'need a permission this account does not have. Ask an administrator, or run the report '
                .'without them.',
            403,
        );
    }

    /**
     * The report exists, and this account may not run it.
     *
     * A 403 rather than a 404: pretending a report is absent would be obscurity
     * standing in for a permission, and the catalogue endpoint already declines
     * to list it.
     */
    public static function reportRefused(): self
    {
        return new self(
            ApiErrorCode::FORBIDDEN,
            'This account does not have permission to run that report.',
            403,
        );
    }

    public static function tooLarge(int $limit): self
    {
        return new self(
            ApiErrorCode::REPORT_TOO_LARGE,
            sprintf(
                'That covers more than %s rows, which is more than one file should carry. '
                    .'Choose a shorter period and export it in parts.',
                number_format($limit),
            ),
            422,
        );
    }

    public static function unknownFormat(string $format): self
    {
        return new self(
            ApiErrorCode::VALIDATION_FAILED,
            sprintf('There is no "%s" export. Choose CSV, Excel or PDF.', $format),
            422,
            ['format' => ['Choose CSV, Excel or PDF.']],
        );
    }
}
