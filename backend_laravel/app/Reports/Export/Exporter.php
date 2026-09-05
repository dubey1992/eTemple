<?php

declare(strict_types=1);

namespace App\Reports\Export;

use App\Models\User;
use App\Reports\ReportResult;

/**
 * One output format for a report.
 *
 * Every exporter is handed the **same** {@see ReportResult} — the one the
 * screen would have shown — and only decides how to write it down. There is no
 * per-format query and no per-format filtering, which is what makes the three
 * files and the screen agree by construction (PHASE_10_PLAN assumption N1).
 */
interface Exporter
{
    /** The `format=` value that selects this exporter. */
    public function format(): string;

    public function contentType(): string;

    public function extension(): string;

    public function render(ReportResult $result, User $actor): string;
}
