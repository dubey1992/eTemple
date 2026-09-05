<?php

declare(strict_types=1);

namespace App\Reports\Reports;

use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRequest;
use App\Services\Accounting\TransparencyService;
use App\Support\FinancialYear;
use App\Support\Language;
use App\Support\Permission;

/**
 * The temple's account of itself.
 *
 * Opening balance, receipts by head, payments by head, closing balance — the
 * sheet a committee reads out at the annual meeting and hands to whoever audits
 * it. Every other report in this phase is a working list; this one is the
 * statement.
 *
 * **It is computed by {@see TransparencyService}**, the same code behind the
 * public page, and that is the point rather than a convenience: the statement
 * the committee prints and the figures the village reads come from one place, so
 * they cannot disagree (PHASE_10_PLAN assumption N9, extending Phase 9's N1).
 *
 * Consequently it is a **financial-year report**, not a free date range: the
 * service reports on years because carrying an opening balance forward only
 * means something between year boundaries.
 */
class IncomeExpenditureReport implements Report
{
    public function __construct(private readonly TransparencyService $transparency) {}

    public function key(): string
    {
        return 'income-expenditure';
    }

    public function title(Language $language): string
    {
        return $language === Language::English
            ? 'Income and expenditure statement'
            : 'आय-व्यय विवरण';
    }

    public function description(Language $language): string
    {
        return $language === Language::English
            ? 'The annual statement: opening balance, receipts and payments by head, closing balance.'
            : 'वार्षिक विवरण: आरंभिक शेष, मदवार आय एवं व्यय, और अंतिम शेष।';
    }

    public function permission(): string
    {
        return Permission::ACCOUNTS_VIEW;
    }

    public function personalPermission(): ?string
    {
        // A statement of heads names nobody, at any permission.
        return null;
    }

    public function columns(): array
    {
        return [
            ReportColumn::make('section', 'खंड', 'Section'),
            ReportColumn::make('head', 'मद', 'Head'),
            ReportColumn::make('amount', 'राशि', 'Amount', ReportColumn::MONEY),
        ];
    }

    public function rows(ReportRequest $request): array
    {
        $year = $this->year($request);
        $figures = $this->transparency->forYear($year, $request->language);
        $english = $request->language === Language::English;

        $receipts = $english ? 'Receipts' : 'आय';
        $payments = $english ? 'Payments' : 'व्यय';
        $balances = $english ? 'Balance' : 'शेष';

        $rows = [[
            'section' => $balances,
            'head' => $english ? 'Balance at the start of the year' : 'वर्ष के आरंभ में शेष',
            'amount' => $figures['opening_balance_paise'],
        ]];

        // Donations first, and on their own line: they are read from the
        // donation register, not the ledger, and a reader should be able to
        // check each source separately (Phase 9 N1).
        $rows[] = [
            'section' => $receipts,
            'head' => $english ? 'Donations received' : 'दान से प्राप्त',
            'amount' => $figures['donations_paise'],
        ];

        foreach ($figures['income_by_category'] as $line) {
            $rows[] = [
                'section' => $receipts,
                'head' => $line['name']['value'] ?? $line['code'],
                'amount' => $line['total_paise'],
            ];
        }

        $rows[] = [
            'section' => $receipts,
            'head' => $english ? 'Total received' : 'कुल आय',
            'amount' => $figures['total_income_paise'],
        ];

        foreach ($figures['expense_by_category'] as $line) {
            $rows[] = [
                'section' => $payments,
                'head' => $line['name']['value'] ?? $line['code'],
                'amount' => $line['total_paise'],
            ];
        }

        $rows[] = [
            'section' => $payments,
            'head' => $english ? 'Total spent' : 'कुल व्यय',
            'amount' => $figures['total_expense_paise'],
        ];

        $rows[] = [
            'section' => $balances,
            'head' => $english ? 'Balance at the end of the year' : 'वर्ष के अंत में शेष',
            'amount' => $figures['closing_balance_paise'],
        ];

        return $rows;
    }

    public function summary(ReportRequest $request): array
    {
        $year = $this->year($request);
        $figures = $this->transparency->forYear($year, $request->language);

        return [
            ['key' => 'year', 'label' => 'वित्तीय वर्ष · Financial year', 'value' => $year->label(), 'type' => ReportColumn::TEXT],
            ['key' => 'opening', 'label' => 'आरंभिक शेष · Opening balance', 'value' => $figures['opening_balance_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'income', 'label' => 'कुल आय · Total received', 'value' => $figures['total_income_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'expense', 'label' => 'कुल व्यय · Total spent', 'value' => $figures['total_expense_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'closing', 'label' => 'अंतिम शेष · Closing balance', 'value' => $figures['closing_balance_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'row_count', 'label' => 'पंक्तियाँ · Lines', 'value' => count($this->rows($request)), 'type' => ReportColumn::NUMBER],
        ];
    }

    /**
     * The financial year the statement covers.
     *
     * A `from`/`to` window is honoured only as far as which year it falls in:
     * the statement's opening balance is the year's, and half a year with a
     * whole year's opening balance would be a wrong number, not a partial one.
     */
    private function year(ReportRequest $request): FinancialYear
    {
        return $request->from !== null
            ? FinancialYear::containing($request->from)
            : FinancialYear::current();
    }
}
