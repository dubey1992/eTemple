<?php

declare(strict_types=1);

namespace App\Reports\Export;

use App\Models\User;
use App\Reports\ReportColumn;
use App\Reports\ReportResult;
use App\Support\Money;
use ZipArchive;

/**
 * A report as a real `.xlsx`.
 *
 * ## Why this is written by hand
 *
 * CSV renamed to `.xlsx` would be a lie the first time somebody double-clicked
 * it, so the requirement's "Excel" needs a real workbook. A worksheet holding
 * one flat table is a small, fully specified thing — five XML parts in a zip,
 * and PHP ships `ZipArchive`.
 *
 * PhpSpreadsheet is a capable library and it is not needed to write a table of
 * strings and numbers. It would be the fifth production dependency in a project
 * that has four, installed on a temple's shared host, to do this
 * (PHASE_10_PLAN assumption N4).
 *
 * The risk of writing a format by hand is producing a file Excel refuses to
 * open, and that risk is answered in the delivery gate rather than by hoping:
 * the gate reads a produced workbook back with an independent reader and
 * asserts its sheet, headings and values.
 *
 * ## What it does not do
 *
 * No styles beyond a bold header row, no formulas, no merged cells, no second
 * sheet. Numbers are written as numbers so a column can be summed; everything
 * else is an inline string, which avoids a shared-string table for no loss on a
 * file of this size.
 */
class XlsxExporter implements Exporter
{
    public function __construct(private readonly ExportHeader $header) {}

    public function format(): string
    {
        return 'xlsx';
    }

    public function contentType(): string
    {
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }

    public function extension(): string
    {
        return 'xlsx';
    }

    public function render(ReportResult $result, User $actor): string
    {
        $rows = $this->sheetRows($result, $actor);

        $path = tempnam(sys_get_temp_dir(), 'rkt-xlsx-');
        if ($path === false) {
            throw new \RuntimeException('Could not create a temporary file for the workbook.');
        }

        $zip = new ZipArchive;
        // OVERWRITE because tempnam has already created the (empty) file, and
        // an empty file is not a zip.
        if ($zip->open($path, ZipArchive::OVERWRITE) !== true) {
            @unlink($path);
            throw new \RuntimeException('Could not open the workbook for writing.');
        }

        $zip->addFromString('[Content_Types].xml', $this->contentTypes());
        $zip->addFromString('_rels/.rels', $this->rootRelationships());
        $zip->addFromString('xl/workbook.xml', $this->workbook($result));
        $zip->addFromString('xl/_rels/workbook.xml.rels', $this->workbookRelationships());
        $zip->addFromString('xl/styles.xml', $this->styles());
        $zip->addFromString('xl/worksheets/sheet1.xml', $this->sheet($rows));
        $zip->close();

        $bytes = (string) file_get_contents($path);
        @unlink($path);

        return $bytes;
    }

    /**
     * The whole sheet as rows of `[value, type, bold]`.
     *
     * The header block, the figures, a blank line, the column headings, then the
     * data — the same order as the CSV, so the two files read alike.
     *
     * @return list<list<array{0: mixed, 1: string, 2: bool}>>
     */
    private function sheetRows(ReportResult $result, User $actor): array
    {
        $rows = [];

        foreach ($this->header->lines($result, $actor) as [$label, $value]) {
            $rows[] = [
                [$label, ReportColumn::TEXT, true],
                [$value, ReportColumn::TEXT, false],
            ];
        }

        $rows[] = [];

        foreach ($result->summary as $figure) {
            $rows[] = [
                [$figure['label'], ReportColumn::TEXT, true],
                [$figure['value'], $figure['type'], false],
            ];
        }

        $rows[] = [];

        $rows[] = array_map(
            static fn (ReportColumn $column) => [$column->label($result->language), ReportColumn::TEXT, true],
            $result->columns,
        );

        foreach ($result->rows as $row) {
            $rows[] = array_map(
                static fn (ReportColumn $column) => [
                    $row[$column->key] ?? null,
                    $column->type,
                    false,
                ],
                $result->columns,
            );
        }

        return $rows;
    }

    /** @param list<list<array{0: mixed, 1: string, 2: bool}>> $rows */
    private function sheet(array $rows): string
    {
        $xml = '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            .'<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            .'<sheetData>';

        foreach ($rows as $index => $cells) {
            $number = $index + 1;
            $xml .= '<row r="'.$number.'">';

            foreach ($cells as $column => [$value, $type, $bold]) {
                $xml .= $this->cell($this->reference($column, $number), $value, $type, $bold);
            }

            $xml .= '</row>';
        }

        return $xml.'</sheetData></worksheet>';
    }

    private function cell(string $reference, mixed $value, string $type, bool $bold): string
    {
        $style = $bold ? ' s="1"' : '';

        if ($value === null || $value === '') {
            return '<c r="'.$reference.'"'.$style.'/>';
        }

        // Money and numbers are written as numbers, so a treasurer can select
        // the column and see a total. Money is the decimal, never the paise:
        // a spreadsheet showing 12050000 for one lakh twenty thousand is worse
        // than useless.
        if ($type === ReportColumn::MONEY) {
            return '<c r="'.$reference.'"'.$style.'><v>'
                .Money::toDecimalString((int) $value).'</v></c>';
        }

        if ($type === ReportColumn::NUMBER && is_numeric($value)) {
            return '<c r="'.$reference.'"'.$style.'><v>'.$value.'</v></c>';
        }

        return '<c r="'.$reference.'"'.$style.' t="inlineStr"><is><t xml:space="preserve">'
            .$this->escape((string) $value)
            .'</t></is></c>';
    }

    /** 0 → A1, 26 → AA1, and so on. */
    private function reference(int $column, int $row): string
    {
        $name = '';
        $index = $column + 1;

        while ($index > 0) {
            $remainder = ($index - 1) % 26;
            $name = chr(65 + $remainder).$name;
            $index = intdiv($index - 1 - $remainder, 26);
        }

        return $name.$row;
    }

    /**
     * XML escaping, plus the control characters the format forbids.
     *
     * A stray 0x00–0x08 in a description — pasted from somewhere odd — makes an
     * otherwise valid workbook unopenable, and the reader would blame the
     * temple's software rather than the paste.
     */
    private function escape(string $value): string
    {
        $value = preg_replace('/[\x00-\x08\x0B\x0C\x0E-\x1F]/u', '', $value) ?? '';

        return htmlspecialchars($value, ENT_QUOTES | ENT_XML1, 'UTF-8');
    }

    private function contentTypes(): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            .'<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
            .'<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
            .'<Default Extension="xml" ContentType="application/xml"/>'
            .'<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
            .'<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'
            .'<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
            .'</Types>';
    }

    private function rootRelationships(): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            .'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            .'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
            .'</Relationships>';
    }

    private function workbook(ReportResult $result): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            .'<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
            .'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">'
            .'<sheets><sheet name="'.$this->sheetName($result).'" sheetId="1" r:id="rId1"/></sheets>'
            .'</workbook>';
    }

    /**
     * Excel refuses a sheet name over 31 characters or containing `: \ / ? * [ ]`,
     * and refuses to open the whole file rather than complaining about the name.
     * The report key is ASCII and short, which is why it is used here rather
     * than the translated title.
     */
    private function sheetName(ReportResult $result): string
    {
        $name = preg_replace('/[:\\\\\/?*\[\]]/', '-', $result->report->key()) ?? 'Report';

        return $this->escape(mb_substr($name, 0, 31));
    }

    private function workbookRelationships(): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            .'<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
            .'<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>'
            .'<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
            .'</Relationships>';
    }

    /** Two formats: plain, and bold. Style index 1 is the bold one. */
    private function styles(): string
    {
        return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            .'<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
            .'<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
            .'<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
            .'<fills count="1"><fill><patternFill patternType="none"/></fill></fills>'
            .'<borders count="1"><border/></borders>'
            .'<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>'
            .'<cellXfs count="2">'
            .'<xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>'
            .'<xf numFmtId="0" fontId="1" fillId="0" borderId="0" xfId="0" applyFont="1"/>'
            .'</cellXfs>'
            // A named default style. Excel tolerates its absence, but a reader
            // that warns about it is a reader that might one day refuse, and
            // this is four hundred bytes.
            .'<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles>'
            .'</styleSheet>';
    }
}
