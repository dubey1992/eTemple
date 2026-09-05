<?php

declare(strict_types=1);

namespace App\Reports\Reports;

use App\Models\Donation;
use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRequest;
use App\Services\Donations\DonationService;
use App\Support\DonationPurpose;
use App\Support\Language;
use App\Support\PaymentMode;
use App\Support\Permission;

/**
 * The donation register, row by row.
 *
 * The report a treasurer hands somebody when a summary will not do — and the
 * one this phase's disclosure control exists for: three of its columns are a
 * donor's name, telephone number and address, and they are absent unless the
 * caller both holds `donations.view` and asked for them.
 */
class DonationRegisterReport implements Report
{
    public function __construct(private readonly DonationService $donations) {}

    public function key(): string
    {
        return 'donations';
    }

    public function title(Language $language): string
    {
        return $language === Language::English ? 'Donation register' : 'दान रजिस्टर';
    }

    public function description(Language $language): string
    {
        return $language === Language::English
            ? 'Every donation recorded in the period, with its receipt number and status.'
            : 'अवधि में दर्ज प्रत्येक दान, रसीद संख्या और स्थिति सहित।';
    }

    public function permission(): string
    {
        return Permission::DONATIONS_VIEW;
    }

    public function personalPermission(): string
    {
        return Permission::DONATIONS_VIEW;
    }

    public function columns(): array
    {
        return [
            ReportColumn::make('donation_date', 'तिथि', 'Date', ReportColumn::DATE),
            ReportColumn::make('receipt_number', 'रसीद संख्या', 'Receipt no.'),
            ReportColumn::personal('donor_name', 'दानदाता', 'Donor'),
            ReportColumn::personal('donor_phone', 'दूरभाष', 'Telephone'),
            ReportColumn::personal('donor_address', 'पता', 'Address'),
            ReportColumn::make('amount', 'राशि', 'Amount', ReportColumn::MONEY),
            ReportColumn::make('payment_mode', 'माध्यम', 'Mode'),
            ReportColumn::make('reference_number', 'संदर्भ', 'Reference'),
            ReportColumn::make('purpose', 'उद्देश्य', 'Purpose'),
            ReportColumn::make('status', 'स्थिति', 'Status'),
        ];
    }

    public function rows(ReportRequest $request): array
    {
        $page = $this->donations->list($this->filters($request) + [
            'per_page' => $request->perPage,
            'page' => $request->page,
        ]);

        return array_map(
            fn (Donation $donation) => [
                'donation_date' => $donation->donation_date->toDateString(),
                'receipt_number' => $donation->receipt_number,
                // An anonymous donor's own receipt names them — it is their
                // receipt — but the register's export says so instead, because
                // a file is read by people the donor never met.
                'donor_name' => $donation->is_anonymous
                    ? ($request->language === Language::English ? '(anonymous)' : '(गुप्त)')
                    : $donation->donor_name,
                'donor_phone' => $donation->is_anonymous ? null : $donation->donor_phone,
                'donor_address' => $donation->is_anonymous ? null : $donation->donor_address,
                'amount' => $donation->amount_paise,
                'payment_mode' => PaymentMode::label($donation->payment_mode),
                'reference_number' => $donation->reference_number,
                'purpose' => DonationPurpose::label($donation->purpose),
                'status' => $donation->status,
            ],
            $page->items(),
        );
    }

    public function summary(ReportRequest $request): array
    {
        $totals = $this->donations->summary($this->filters($request));

        return [
            ['key' => 'total', 'label' => 'कुल प्राप्त · Total received', 'value' => $totals['total_paise'], 'type' => ReportColumn::MONEY],
            ['key' => 'row_count', 'label' => 'प्रविष्टियाँ · Entries', 'value' => $totals['confirmed_count'] + $totals['pending_count'] + $totals['reversed_count'], 'type' => ReportColumn::NUMBER],
            ['key' => 'confirmed', 'label' => 'सत्यापित · Confirmed', 'value' => $totals['confirmed_count'], 'type' => ReportColumn::NUMBER],
            ['key' => 'pending', 'label' => 'जाँच शेष · Pending', 'value' => $totals['pending_count'], 'type' => ReportColumn::NUMBER],
            ['key' => 'reversed', 'label' => 'निरस्त · Reversed', 'value' => $totals['reversed_count'], 'type' => ReportColumn::NUMBER],
            ['key' => 'donors', 'label' => 'दानदाता · Donors', 'value' => $totals['donor_count'], 'type' => ReportColumn::NUMBER],
        ];
    }

    /** @return array<string, mixed> */
    private function filters(ReportRequest $request): array
    {
        return array_filter([
            'from' => $request->fromDate(),
            'to' => $request->toDate(),
            'status' => $request->filter('status'),
            'mode' => $request->filter('mode'),
            'purpose' => $request->filter('purpose'),
            'q' => $request->filter('q'),
        ], static fn ($value) => $value !== null);
    }
}
