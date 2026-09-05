<?php

declare(strict_types=1);

namespace App\Reports\Reports;

use App\Models\Enquiry;
use App\Reports\Report;
use App\Reports\ReportColumn;
use App\Reports\ReportRequest;
use App\Services\Enquiries\EnquiryService;
use App\Support\EnquiryCategory;
use App\Support\Language;
use App\Support\Permission;

/**
 * How many people wrote, about what, and how long the temple took.
 *
 * The last part is the only performance figure in this phase, and it is
 * computed from timestamps that already exist rather than from a field somebody
 * would have to remember to fill in.
 *
 * Every row is a villager's message. `enquiries.manage` is required to run this
 * at all — Phase 7 established that there is no view-only tier for a villager's
 * telephone number — and the name, mobile and e-mail are *additionally* behind
 * the disclosure switch, because a screen somebody is reading and a file that
 * leaves the building are different acts.
 *
 * **`submitted_ip_hash` is not a column here and never will be.** It is not
 * serialized even to the committee (Phase 7), and a report is not a way round
 * that.
 */
class EnquiriesReport implements Report
{
    public function __construct(private readonly EnquiryService $enquiries) {}

    public function key(): string
    {
        return 'enquiries';
    }

    public function title(Language $language): string
    {
        return $language === Language::English ? 'Enquiries' : 'पूछताछ';
    }

    public function description(Language $language): string
    {
        return $language === Language::English
            ? 'Messages received in the period, by category and status, with how long each took.'
            : 'अवधि में प्राप्त संदेश — श्रेणी एवं स्थिति सहित, और उत्तर में लगा समय।';
    }

    public function permission(): string
    {
        return Permission::ENQUIRIES_MANAGE;
    }

    public function personalPermission(): string
    {
        return Permission::ENQUIRIES_MANAGE;
    }

    public function columns(): array
    {
        return [
            ReportColumn::make('received_at', 'प्राप्ति', 'Received', ReportColumn::DATE),
            ReportColumn::make('reference', 'संदर्भ संख्या', 'Reference'),
            ReportColumn::personal('name', 'नाम', 'Name'),
            ReportColumn::personal('mobile', 'मोबाइल', 'Mobile'),
            ReportColumn::personal('email', 'ईमेल', 'E-mail'),
            ReportColumn::make('category', 'श्रेणी', 'Category'),
            ReportColumn::make('status', 'स्थिति', 'Status'),
            ReportColumn::make('assigned_to', 'सौंपा गया', 'Assigned to'),
            ReportColumn::make('resolved_in_days', 'दिनों में हल', 'Days to resolve', ReportColumn::NUMBER),
        ];
    }

    public function rows(ReportRequest $request): array
    {
        $page = $this->enquiries->list($this->filters($request) + [
            'per_page' => $request->perPage,
            'page' => $request->page,
        ]);

        return array_map(
            fn (Enquiry $enquiry) => [
                'received_at' => $enquiry->created_at?->toDateString(),
                'reference' => $enquiry->reference,
                'name' => $enquiry->name,
                'mobile' => $enquiry->mobile,
                'email' => $enquiry->email,
                'category' => EnquiryCategory::label($enquiry->category),
                'status' => $enquiry->status,
                // The member's name, not the villager's — this column is about
                // who in the committee took it on.
                'assigned_to' => $enquiry->assignee?->fullName(),
                'resolved_in_days' => $this->daysToResolve($enquiry),
            ],
            $page->items(),
        );
    }

    public function summary(ReportRequest $request): array
    {
        $totals = $this->enquiries->summary($this->filters($request));

        // The service counts by status and carries no total, because its own
        // screen shows four tabs rather than a sum. Adding them here is
        // arithmetic on figures the database produced, not a second query.
        $counted = 0;
        foreach (Enquiry::statuses() as $status) {
            $counted += (int) ($totals[$status] ?? 0);
        }

        $figures = [
            ['key' => 'row_count', 'label' => 'कुल संदेश · Messages', 'value' => $counted, 'type' => ReportColumn::NUMBER],
            ['key' => 'open', 'label' => 'लंबित · Open', 'value' => (int) ($totals['open'] ?? 0), 'type' => ReportColumn::NUMBER],
        ];

        foreach (Enquiry::statuses() as $status) {
            $figures[] = [
                'key' => $status,
                'label' => $status,
                'value' => (int) ($totals[$status] ?? 0),
                'type' => ReportColumn::NUMBER,
            ];
        }

        $figures[] = [
            'key' => 'average_days',
            'label' => 'औसत उत्तर समय (दिन) · Average days to resolve',
            'value' => $this->averageDaysToResolve($request),
            'type' => ReportColumn::NUMBER,
        ];

        return $figures;
    }

    /**
     * How long an answered message took, in whole days.
     *
     * Null while it is still open — reporting an unanswered message as "0 days"
     * would flatter the figure above it into meaninglessness.
     */
    private function daysToResolve(Enquiry $enquiry): ?int
    {
        if ($enquiry->resolved_at === null || $enquiry->created_at === null) {
            return null;
        }

        return (int) $enquiry->created_at->diffInDays($enquiry->resolved_at);
    }

    /** Averaged over resolved messages only, for the same reason. */
    private function averageDaysToResolve(ReportRequest $request): ?float
    {
        $query = Enquiry::query()
            ->whereNotNull('resolved_at')
            ->where('status', Enquiry::STATUS_RESOLVED);

        if ($request->fromDate() !== null) {
            $query->whereDate('created_at', '>=', $request->fromDate());
        }

        if ($request->toDate() !== null) {
            $query->whereDate('created_at', '<=', $request->toDate());
        }

        $resolved = $query->get(['created_at', 'resolved_at']);

        if ($resolved->isEmpty()) {
            return null;
        }

        $days = $resolved->map(
            static fn (Enquiry $enquiry) => $enquiry->created_at->diffInDays($enquiry->resolved_at),
        );

        return round((float) $days->avg(), 1);
    }

    /** @return array<string, mixed> */
    private function filters(ReportRequest $request): array
    {
        return array_filter([
            'from' => $request->fromDate(),
            'to' => $request->toDate(),
            'status' => $request->filter('status'),
            'category' => $request->filter('category'),
            'search' => $request->filter('q'),
        ], static fn ($value) => $value !== null);
    }
}
