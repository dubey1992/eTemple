<?php

declare(strict_types=1);

namespace App\Reports;

use App\Support\Language;

/**
 * One standard report.
 *
 * A report is a **server-side definition**: its columns, the permission it
 * needs, and a method that turns filters into rows. The screen renders it and
 * an export serializes it, and because both go through {@see ReportRunner} with
 * the same {@see ReportRequest}, "the export applies exactly the on-screen
 * filters" is a property of the code rather than a promise
 * (PHASE_10_PLAN assumption N1).
 *
 * A report never writes its own queries against a module it does not own: it
 * calls that module's service, so a figure here and the same figure on its own
 * screen cannot disagree (assumption N9).
 */
interface Report
{
    /** Stable, URL-safe, and the same string the client uses. */
    public function key(): string;

    public function title(Language $language): string;

    /** One line saying what question this report answers. */
    public function description(Language $language): string;

    /**
     * The domain permission this report needs, **on top of** `reports.view`.
     *
     * A report of the ledger needs `accounts.view`; one of the inbox needs
     * `enquiries.manage`. The catalogue hides what the caller cannot run.
     */
    public function permission(): string;

    /**
     * The permission that unlocks this report's personal columns, or null when
     * it has none.
     */
    public function personalPermission(): ?string;

    /** @return list<ReportColumn> */
    public function columns(): array;

    /**
     * The rows, in the order they should be read.
     *
     * Values are raw: integer paise for money, `Y-m-d` for a date. Formatting
     * is the exporter's job, and it differs per format — the screen wants
     * `₹1,25,500.00` and a spreadsheet wants `125500.00`.
     *
     * @return list<array<string, mixed>>
     */
    public function rows(ReportRequest $request): array;

    /**
     * The figures that belong above the rows — totals, counts, a balance.
     *
     * Computed over the whole filter by the database, never by adding up the
     * rows this method's sibling returned: a page's total is not the total.
     *
     * @return list<array{key: string, label: string, value: mixed, type: string}>
     */
    public function summary(ReportRequest $request): array;
}
