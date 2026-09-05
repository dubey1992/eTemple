<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Accounting\ReverseTransactionRequest;
use App\Http\Requests\Accounting\StoreTransactionRequest;
use App\Http\Resources\Accounting\AdminTransactionResource;
use App\Models\Transaction;
use App\Services\Accounting\AttachmentStore;
use App\Services\Accounting\TransactionService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * The temple's ledger.
 *
 * Approve and reverse are separate endpoints rather than a `status` a `PUT`
 * can set, for the reason Phase 8 gives about sending: an operation with its
 * own consequences gets its own URL. Approving puts a figure into a total the
 * village reads; reversing takes it out and must say why.
 *
 * **There is no destroy method.** Reversal keeps the row, its bill and its
 * stated reason, which is the whole point of a ledger.
 */
class TransactionController extends Controller
{
    public function __construct(
        private readonly TransactionService $transactions,
        private readonly AttachmentStore $attachments,
    ) {}

    /** GET /api/admin/transactions */
    public function index(Request $request): JsonResponse
    {
        $transactions = $this->transactions->list($this->filters($request));

        return ApiResponse::paginated(
            $transactions,
            AdminTransactionResource::collection($transactions->getCollection()),
        );
    }

    /**
     * GET /api/admin/transactions/summary
     *
     * The same filters as the list, minus the status: a summary that honoured
     * it would report "spent: 0" whenever the reader happened to be looking at
     * the pending tab.
     */
    public function summary(Request $request): JsonResponse
    {
        return ApiResponse::success($this->transactions->summary($this->filters($request)));
    }

    /** GET /api/admin/transactions/{transaction} */
    public function show(Transaction $transaction): JsonResponse
    {
        $transaction->load([
            'category',
            'createdBy:id,first_name,last_name',
            'approvedBy:id,first_name,last_name',
            'reversedBy:id,first_name,last_name',
        ]);

        return ApiResponse::success(new AdminTransactionResource($transaction));
    }

    /**
     * GET /api/admin/transactions/{transaction}/attachment
     *
     * Streams the bill from the private disk behind `accounts.view`. It is
     * `accounts.view` rather than `accounts.manage` deliberately: a Viewer
     * auditing the books needs to see the evidence, which is the entire reason
     * for attaching it.
     *
     * `Content-Disposition: attachment` and `X-Content-Type-Options: nosniff`
     * together mean the file is saved rather than rendered, so nothing that got
     * past the byte check can execute in the admin session's origin.
     */
    public function attachment(Transaction $transaction): Response
    {
        $bytes = $this->attachments->read($transaction);

        return response($bytes, 200, [
            'Content-Type' => $transaction->attachment_mime ?? 'application/octet-stream',
            'Content-Disposition' => 'attachment; filename="'.($transaction->attachment_name ?? 'bill').'"',
            'Content-Length' => (string) strlen($bytes),
            'X-Content-Type-Options' => 'nosniff',
            'Cache-Control' => 'private, no-store',
        ]);
    }

    /** POST /api/admin/transactions */
    public function store(StoreTransactionRequest $request): JsonResponse
    {
        $transaction = $this->transactions->record(
            $request->validated(),
            $request->user(),
            $request->file('attachment'),
        );

        return ApiResponse::success(
            new AdminTransactionResource($transaction->load('category')),
            status: 201,
        );
    }

    /** PUT /api/admin/transactions/{transaction} */
    public function update(StoreTransactionRequest $request, Transaction $transaction): JsonResponse
    {
        $updated = $this->transactions->update(
            $transaction,
            $request->validated(),
            $request->user(),
            $request->file('attachment'),
        );

        return ApiResponse::success(new AdminTransactionResource($updated->load('category')));
    }

    /** POST /api/admin/transactions/{transaction}/approve */
    public function approve(Request $request, Transaction $transaction): JsonResponse
    {
        $approved = $this->transactions->approve($transaction, $request->user());

        return ApiResponse::success(new AdminTransactionResource($approved->load('category')));
    }

    /** POST /api/admin/transactions/{transaction}/reverse */
    public function reverse(ReverseTransactionRequest $request, Transaction $transaction): JsonResponse
    {
        $reversed = $this->transactions->reverse(
            $transaction,
            (string) $request->validated('reversal_reason'),
            $request->user(),
        );

        return ApiResponse::success(new AdminTransactionResource($reversed->load('category')));
    }

    /** @return array<string, mixed> */
    private function filters(Request $request): array
    {
        return array_filter([
            'status' => $request->query('status'),
            'type' => $request->query('type'),
            'category_id' => $request->query('category_id'),
            'mode' => $request->query('mode'),
            'from' => $request->query('from'),
            'to' => $request->query('to'),
            'q' => $request->query('q'),
            'per_page' => $request->query('per_page'),
        ], static fn ($value) => $value !== null && $value !== '');
    }
}
