<?php

declare(strict_types=1);

namespace App\Reports\Export;

use App\Exceptions\ReportGuardException;

/**
 * The three formats, and the one place `format=` is resolved.
 *
 * An unknown format is refused by name rather than silently answered with CSV:
 * a treasurer who asked for Excel and received something else would not notice
 * until the file failed to open.
 */
class ExporterRegistry
{
    /** @var list<Exporter> */
    private readonly array $exporters;

    public function __construct(
        CsvExporter $csv,
        XlsxExporter $xlsx,
        PrintExporter $print,
    ) {
        $this->exporters = [$csv, $xlsx, $print];
    }

    public function for(string $format): Exporter
    {
        foreach ($this->exporters as $exporter) {
            if ($exporter->format() === $format) {
                return $exporter;
            }
        }

        throw ReportGuardException::unknownFormat($format);
    }

    /** @return list<string> */
    public function formats(): array
    {
        return array_map(
            static fn (Exporter $exporter) => $exporter->format(),
            $this->exporters,
        );
    }
}
