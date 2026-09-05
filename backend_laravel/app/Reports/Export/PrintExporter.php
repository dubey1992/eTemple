<?php

declare(strict_types=1);

namespace App\Reports\Export;

use App\Models\User;
use App\Reports\ReportColumn;
use App\Reports\ReportResult;
use App\Services\Donations\ReceiptRenderer;
use App\Support\Money;

/**
 * A report as a print-ready HTML document — the "PDF" format.
 *
 * ## Why not a PDF library
 *
 * The same reason {@see ReceiptRenderer} gives, and it
 * has not changed: **no PHP PDF library shapes Devanagari.** `dompdf` and the
 * FPDF family would set `रामप्रसाद` with its matras in the wrong order, on a
 * financial document a committee hands to an auditor. Every browser ships a
 * shaping engine and a PDF writer, and the person exporting already has one
 * open (PHASE_10_PLAN assumption N3).
 *
 * So this returns a document with print styles and a print button, opened in a
 * new tab. Ctrl-P, "Save as PDF".
 *
 * ## Why not Blade
 *
 * There is exactly **one** place where a value reaches this document —
 * {@see self::escape()} — and every field goes through it. That is a smaller
 * and more checkable surface than a template where `{!! !!}` is one keystroke
 * away.
 */
class PrintExporter implements Exporter
{
    public function __construct(private readonly ExportHeader $header) {}

    public function format(): string
    {
        return 'pdf';
    }

    public function contentType(): string
    {
        return 'text/html; charset=UTF-8';
    }

    public function extension(): string
    {
        return 'html';
    }

    public function render(ReportResult $result, User $actor): string
    {
        $language = $result->language->value;

        return <<<HTML
            <!doctype html>
            <html lang="{$language}">
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>{$this->escape($result->title())}</title>
            <style>
              :root { --ink: #2b1b12; --muted: #6b5647; --rule: #d9cbbc; }
              * { box-sizing: border-box; }
              body {
                margin: 0; padding: 24px;
                font-family: "Noto Sans Devanagari","Segoe UI",Arial,sans-serif;
                color: var(--ink); background: #f4efe7; line-height: 1.5;
                font-size: 13px;
              }
              .sheet {
                max-width: 1000px; margin: 0 auto; background: #fff;
                border: 1px solid var(--rule); border-radius: 8px; padding: 28px;
              }
              h1 { font-size: 20px; margin: 0 0 4px; }
              .meta { border-collapse: collapse; margin: 0 0 18px; }
              .meta th, .meta td {
                text-align: left; vertical-align: top; padding: 2px 12px 2px 0;
                font-weight: normal;
              }
              .meta th { color: var(--muted); white-space: nowrap; }
              .figures {
                display: flex; flex-wrap: wrap; gap: 18px;
                border-top: 1px solid var(--rule); border-bottom: 1px solid var(--rule);
                padding: 12px 0; margin: 0 0 18px;
              }
              .figure { min-width: 130px; }
              .figure .label { color: var(--muted); font-size: 11px; display: block; }
              .figure .value { font-size: 15px; font-weight: 600; }
              table.rows { width: 100%; border-collapse: collapse; }
              table.rows th, table.rows td {
                border-bottom: 1px solid var(--rule); padding: 6px 8px;
                text-align: left; vertical-align: top;
              }
              table.rows th { color: var(--muted); font-size: 11px; text-transform: uppercase; }
              table.rows td.money, table.rows th.money { text-align: right; white-space: nowrap; }
              .notice {
                border: 1px solid #b3453b; color: #b3453b; border-radius: 6px;
                padding: 8px 12px; margin: 0 0 16px; font-size: 12px;
              }
              .print { margin: 0 0 18px; }
              .print button {
                font: inherit; padding: 8px 18px; border-radius: 6px;
                border: 1px solid var(--ink); background: var(--ink); color: #fff;
                cursor: pointer;
              }
              @media print {
                body { background: #fff; padding: 0; font-size: 11px; }
                .sheet { border: 0; border-radius: 0; padding: 0; max-width: none; }
                .print { display: none; }
                /* A long report runs to several sheets of paper, and a heading
                   row that appears only on the first one makes every page after
                   it unreadable. */
                table.rows thead { display: table-header-group; }
                table.rows tr { break-inside: avoid; }
              }
            </style>
            </head>
            <body>
            <div class="sheet">
              <div class="print"><button onclick="window.print()">{$this->printLabel($result)}</button></div>
              <h1>{$this->escape($result->title())}</h1>
              {$this->metaTable($result, $actor)}
              {$this->notices($result)}
              {$this->figures($result)}
              {$this->table($result)}
            </div>
            </body>
            </html>
            HTML;
    }

    private function printLabel(ReportResult $result): string
    {
        return $result->language->value === 'en' ? 'Print / Save as PDF' : 'प्रिंट करें / PDF सहेजें';
    }

    private function metaTable(ReportResult $result, User $actor): string
    {
        $rows = '';

        foreach ($this->header->lines($result, $actor) as [$label, $value]) {
            $rows .= '<tr><th>'.$this->escape($label).'</th><td>'
                .$this->escape($value).'</td></tr>';
        }

        return '<table class="meta">'.$rows.'</table>';
    }

    /**
     * The two things a reader must not miss, in a box rather than a row of the
     * meta table: that the sheet holds personal data, and that it is incomplete.
     */
    private function notices(ReportResult $result): string
    {
        $english = $result->language->value === 'en';
        $out = '';

        if ($result->truncated) {
            $out .= '<div class="notice">'.$this->escape(
                $english
                    ? 'This report reached the row limit and is incomplete. Choose a shorter period.'
                    : 'यह रिपोर्ट पंक्ति सीमा तक पहुँच गई और अपूर्ण है। छोटी अवधि चुनें।',
            ).'</div>';
        }

        if ($result->includesPersonal) {
            $out .= '<div class="notice">'.$this->escape(
                $english
                    ? 'Contains names and contact details.'
                    : 'इसमें नाम एवं संपर्क विवरण सम्मिलित हैं।',
            ).'</div>';
        }

        return $out;
    }

    private function figures(ReportResult $result): string
    {
        if ($result->summary === []) {
            return '';
        }

        $out = '<div class="figures">';

        foreach ($result->summary as $figure) {
            $out .= '<div class="figure"><span class="label">'
                .$this->escape($figure['label']).'</span><span class="value">'
                .$this->escape($this->display($figure['value'], $figure['type']))
                .'</span></div>';
        }

        return $out.'</div>';
    }

    private function table(ReportResult $result): string
    {
        $head = '';
        foreach ($result->columns as $column) {
            $class = $this->isNumeric($column->type) ? ' class="money"' : '';
            $head .= '<th'.$class.'>'.$this->escape($column->label($result->language)).'</th>';
        }

        $body = '';
        foreach ($result->rows as $row) {
            $body .= '<tr>';
            foreach ($result->columns as $column) {
                $class = $this->isNumeric($column->type) ? ' class="money"' : '';
                $body .= '<td'.$class.'>'
                    .$this->escape($this->display($row[$column->key] ?? null, $column->type))
                    .'</td>';
            }
            $body .= '</tr>';
        }

        return '<table class="rows"><thead><tr>'.$head.'</tr></thead><tbody>'.$body.'</tbody></table>';
    }

    private function isNumeric(string $type): bool
    {
        return $type === ReportColumn::MONEY || $type === ReportColumn::NUMBER;
    }

    /**
     * A value as a person reads it.
     *
     * Unlike the spreadsheet formats, this one **is** for reading, so money is
     * grouped the Indian way with its symbol — ₹1,25,500.00, not 125500.00
     * (assumption N6: the screen and the printed page format; the files do not).
     */
    private function display(mixed $value, string $type): string
    {
        if ($value === null || $value === '') {
            return '—';
        }

        return match ($type) {
            ReportColumn::MONEY => Money::format((int) $value),
            default => (string) $value,
        };
    }

    private function escape(string $value): string
    {
        return htmlspecialchars($value, ENT_QUOTES | ENT_SUBSTITUTE, 'UTF-8');
    }
}
