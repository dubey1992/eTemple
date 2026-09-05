<?php

declare(strict_types=1);

namespace App\Reports\Export;

use App\Models\User;
use App\Reports\ReportColumn;
use App\Reports\ReportResult;
use App\Support\Money;

/**
 * A report as CSV.
 *
 * Two decisions here only look small, and both are about the file arriving
 * intact on a committee member's Windows laptop.
 *
 * **A byte-order mark.** Without one, Excel opens a UTF-8 CSV as Windows-1252
 * and every Hindi name becomes mojibake. That is the most likely first
 * experience of this whole feature, and it costs three bytes
 * (PHASE_10_PLAN assumption N5).
 *
 * **No cell can execute.** A value beginning `=`, `+`, `-`, `@`, a tab or a
 * carriage return is prefixed with an apostrophe. A donor recorded as
 * `=HYPERLINK("http://…","Click")` is not hypothetical: it is an attack carried
 * out by the reader's own spreadsheet, and the temple would be the one that
 * handed them the file.
 */
class CsvExporter implements Exporter
{
    /** Excel and the CSV specification both expect CRLF. */
    private const EOL = "\r\n";

    private const BOM = "\xEF\xBB\xBF";

    public function __construct(private readonly ExportHeader $header) {}

    public function format(): string
    {
        return 'csv';
    }

    public function contentType(): string
    {
        return 'text/csv; charset=UTF-8';
    }

    public function extension(): string
    {
        return 'csv';
    }

    public function render(ReportResult $result, User $actor): string
    {
        $out = self::BOM;

        foreach ($this->header->lines($result, $actor) as [$label, $value]) {
            $out .= $this->row([$label, $value]);
        }
        $out .= self::EOL;

        // The figures, above the rows, as they are on screen.
        foreach ($result->summary as $figure) {
            $out .= $this->row([
                $figure['label'],
                $this->value($figure['value'], $figure['type']),
            ]);
        }
        $out .= self::EOL;

        $out .= $this->row(array_map(
            static fn (ReportColumn $column) => $column->label($result->language),
            $result->columns,
        ));

        foreach ($result->rows as $row) {
            $out .= $this->row(array_map(
                fn (ReportColumn $column) => $this->value(
                    $row[$column->key] ?? null,
                    $column->type,
                ),
                $result->columns,
            ));
        }

        return $out;
    }

    /** @param list<string> $cells */
    private function row(array $cells): string
    {
        return implode(',', array_map($this->quote(...), $cells)).self::EOL;
    }

    private function quote(string $value): string
    {
        $value = $this->neutralise($value);

        return '"'.str_replace('"', '""', $value).'"';
    }

    /**
     * Stops a spreadsheet treating a cell as a formula.
     *
     * The apostrophe is the conventional prefix and both Excel and LibreOffice
     * strip it on display, so the reader sees the value they expect.
     */
    private function neutralise(string $value): string
    {
        if ($value === '') {
            return $value;
        }

        return str_contains("=+-@\t\r", $value[0]) ? "'".$value : $value;
    }

    /**
     * A value as a spreadsheet should read it.
     *
     * Money is a plain decimal — `1200.50`, never `₹1,200.50`. The symbol and
     * the grouping commas make the column text, and then every total the
     * treasurer tries to compute silently fails (assumption N6).
     */
    private function value(mixed $value, string $type): string
    {
        if ($value === null) {
            return '';
        }

        return match ($type) {
            ReportColumn::MONEY => Money::toDecimalString((int) $value),
            ReportColumn::NUMBER => (string) $value,
            default => (string) $value,
        };
    }
}
