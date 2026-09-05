<?php

declare(strict_types=1);

namespace App\Reports\Reports;

use App\Models\Transaction;
use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRequest;
use App\Services\Accounting\TransactionService;
use App\Support\Language;
use App\Support\LocalizedText;
use App\Support\PaymentMode;
use App\Support\Permission;
use App\Support\TransactionType;

/**
 * The ledger, row by row.
 *
 * The list a treasurer hands to whoever is checking the bills. `payee_name` is a
 * personal column — it names a shopkeeper, a mistri, a priest — so it is absent
 * unless the caller holds `accounts.view` and asked for it.
 *
 * There is no bill in an export and there never will be: the files live on a
 * private disk and are addressed by transaction id, so there is no URL for a
 * spreadsheet to carry (Phase 9 N5).
 */
class LedgerReport implements Report
{
    public function __construct(private readonly TransactionService $transactions) {}

    public function key(): string
    {
        return 'ledger';
    }

    public function title(Language $language): string
    {
        return $language === Language::English ? 'Ledger' : 'बही';
    }

    public function description(Language $language): string
    {
        return $language === Language::English
            ? 'Every income and expenditure entry in the period, with its heading and status.'
            : 'अवधि की प्रत्येक आय एवं व्यय प्रविष्टि, मद और स्थिति सहित।';
    }

    public function permission(): string
    {
        return Permission::ACCOUNTS_VIEW;
    }

    public function personalPermission(): string
    {
        return Permission::ACCOUNTS_VIEW;
    }

    public function columns(): array
    {
        return [
            ReportColumn::make('transaction_date', 'तिथि', 'Date', ReportColumn::DATE),
            ReportColumn::make('type', 'प्रकार', 'Type'),
            ReportColumn::make('category', 'मद', 'Heading'),
            ReportColumn::make('amount', 'राशि', 'Amount', ReportColumn::MONEY),
            ReportColumn::make('payment_mode', 'माध्यम', 'Mode'),
            ReportColumn::make('reference_number', 'संदर्भ', 'Reference'),
            ReportColumn::personal('payee_name', 'किसे / किससे', 'Paid to / from'),
            ReportColumn::make('description', 'विवरण', 'Description'),
            ReportColumn::make('status', 'स्थिति', 'Status'),
            ReportColumn::make('has_attachment', 'बिल', 'Bill'),
        ];
    }

    public function rows(ReportRequest $request): array
    {
        $page = $this->transactions->list($this->filters($request) + [
            'per_page' => $request->perPage,
            'page' => $request->page,
        ]);

        $english = $request->language === Language::English;

        return array_map(
            fn (Transaction $transaction) => [
                'transaction_date' => $transaction->transaction_date->toDateString(),
                'type' => TransactionType::label($transaction->type),
                'category' => LocalizedText::resolve(
                    $transaction->category?->name_hi,
                    $transaction->category?->name_en,
                    $request->language,
                )->value ?? '',
                'amount' => $transaction->amount_paise,
                'payment_mode' => PaymentMode::label($transaction->payment_mode),
                'reference_number' => $transaction->reference_number,
                'payee_name' => $transaction->payee_name,
                'description' => $transaction->description,
                'status' => $transaction->status,
                // Whether one exists, never where it is.
                'has_attachment' => $transaction->hasAttachment()
                    ? ($english ? 'yes' : 'हाँ')
                    : '',
            ],
            $page->items(),
        );
    }

    public function summary(ReportRequest $request): array
    {
        $totals = $this->transactions->summary($this->filters($request));

        return [
            ['key' => 'income', 'label' => 'स्वीकृत आय · Approved income', 'value' => $totals['income_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'expense', 'label' => 'स्वीकृत व्यय · Approved expenditure', 'value' => $totals['expense_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'net', 'label' => 'बही का शुद्ध · Ledger net', 'value' => $totals['net_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'row_count', 'label' => 'प्रविष्टियाँ · Entries', 'value' => $totals['approved_count'] + $totals['pending_count'] + $totals['reversed_count'], 'type' => ReportColumn::NUMBER],
            ['key' => 'pending', 'label' => 'जाँच शेष · To check', 'value' => $totals['pending_count'], 'type' => ReportColumn::NUMBER],
        ];
    }

    /** @return array<string, mixed> */
    private function filters(ReportRequest $request): array
    {
        return array_filter([
            'from' => $request->fromDate(),
            'to' => $request->toDate(),
            'status' => $request->filter('status'),
            'type' => $request->filter('type'),
            'category_id' => $request->filter('category_id'),
            'mode' => $request->filter('mode'),
            'q' => $request->filter('q'),
        ], static fn ($value) => $value !== null);
    }
}
