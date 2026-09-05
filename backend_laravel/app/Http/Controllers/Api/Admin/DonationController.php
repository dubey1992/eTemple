<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Donations\ReverseDonationRequest;
use App\Http\Requests\Donations\StoreDonationRequest;
use App\Http\Resources\Donations\AdminDonationResource;
use App\Models\Donation;
use App\Models\User;
use App\Services\Donations\DonationService;
use App\Services\Donations\ReceiptRenderer;
use App\Support\ApiResponse;
use App\Support\Money;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;

/**
 * The donation register.
 *
 * There is deliberately **no `destroy`**. Its absence is the rule: nothing is
 * ever deleted, and reversal — which keeps the row, its receipt number and a
 * stated reason — is the only undo (PHASE_6_PLAN assumption N4).
 */
class DonationController extends Controller
{
    public function __construct(
        private readonly DonationService $donations,
        private readonly ReceiptRenderer $receipts,
    ) {}

    /**
     * GET /api/admin/donations?status=&mode=&purpose=&from=&to=&q=&page=&per_page=
     *
     * Requires `donations.view`, so a Viewer or a Treasurer can read the
     * register without necessarily being able to change it.
     */
    public function index(Request $request): JsonResponse
    {
        $filters = $this->filters($request);
        $page = $this->donations->list($filters);

        return ApiResponse::success(
            array_map(
                fn (Donation $donation) => (new AdminDonationResource($donation))->resolve($request),
                $page->items(),
            ),
            [
                ...ApiResponse::paginationMeta($page),
                // The summary rides with the list so the screen never has to
                // add up a page and call it a total.
                'summary' => $this->summaryPayload($filters),
            ],
        );
    }

    /** GET /api/admin/donations/summary?from=&to=&mode=&purpose=&q= */
    public function summary(Request $request): JsonResponse
    {
        return ApiResponse::success($this->summaryPayload($this->filters($request)));
    }

    /** GET /api/admin/donations/{donation} */
    public function show(Request $request, Donation $donation): JsonResponse
    {
        $donation->load(['recordedBy', 'confirmedBy', 'reversedBy']);

        return ApiResponse::success(new AdminDonationResource($donation));
    }

    /** POST /api/admin/donations */
    public function store(StoreDonationRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $donation = $this->donations->record($request->validated(), $actor);

        return ApiResponse::success(new AdminDonationResource($donation), null, 201);
    }

    /**
     * PUT /api/admin/donations/{donation}
     *
     * Once a receipt has been issued only the notes may change; anything else
     * is refused with 409 and a message saying to reverse and record again.
     */
    public function update(StoreDonationRequest $request, Donation $donation): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $updated = $this->donations->update($donation, $request->validated(), $actor);

        return ApiResponse::success(new AdminDonationResource($updated));
    }

    /**
     * POST /api/admin/donations/{donation}/confirm
     *
     * Verification, and the moment a receipt number comes into existence.
     */
    public function confirm(Request $request, Donation $donation): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $confirmed = $this->donations->confirm($donation, $actor);

        return ApiResponse::success(new AdminDonationResource($confirmed));
    }

    /** POST /api/admin/donations/{donation}/reverse */
    public function reverse(ReverseDonationRequest $request, Donation $donation): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $reversed = $this->donations->reverse(
            $donation,
            (string) $request->validated()['reversal_reason'],
            $actor,
        );

        return ApiResponse::success(new AdminDonationResource($reversed));
    }

    /**
     * GET /api/admin/donations/{donation}/receipt
     *
     * A print-ready HTML document, not JSON and not a PDF.
     *
     * The browser is the renderer because a donor's name is Devanagari, and the
     * PHP PDF libraries do not shape complex scripts — they would print
     * `श्री रामप्रसाद` with its matras in the wrong places, on a receipt for
     * money. Every browser already ships a shaping engine and a PDF writer
     * (PHASE_6_PLAN assumption N10).
     */
    public function receipt(Donation $donation): Response
    {
        $donation->load(['confirmedBy', 'recordedBy']);

        return response($this->receipts->render($donation), 200, [
            'Content-Type' => 'text/html; charset=UTF-8',
            // A receipt names a donor. It must never be cached by a proxy, and
            // must not sit in the browser's cache after a shared computer is
            // handed back.
            'Cache-Control' => 'no-store, private',
            'X-Content-Type-Options' => 'nosniff',
        ]);
    }

    /**
     * @param  array<string, mixed>  $filters
     * @return array<string, mixed>
     */
    private function summaryPayload(array $filters): array
    {
        $summary = $this->donations->summary($filters);

        return [
            ...$summary,
            'total_formatted' => Money::format($summary['total_paise']),
            'pending_formatted' => Money::format($summary['pending_paise']),
        ];
    }

    /** @return array<string, mixed> */
    private function filters(Request $request): array
    {
        $filters = [];

        foreach (['status', 'mode', 'purpose', 'from', 'to', 'q'] as $key) {
            $value = $request->query($key);
            if (is_string($value) && trim($value) !== '') {
                $filters[$key] = trim($value);
            }
        }

        $perPage = $request->integer('per_page');
        if ($perPage > 0) {
            $filters['per_page'] = $perPage;
        }

        return $filters;
    }
}
