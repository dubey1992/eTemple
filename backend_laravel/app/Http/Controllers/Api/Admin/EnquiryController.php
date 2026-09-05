<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Enquiries\UpdateEnquiryStatusRequest;
use App\Http\Resources\Enquiries\AdminEnquiryResource;
use App\Models\Enquiry;
use App\Services\Enquiries\EnquiryService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The committee's enquiry inbox.
 *
 * Every route here needs `enquiries.manage` — including the reads. There is no
 * `enquiries.view` tier: a Viewer may see the calendar and the donation totals,
 * but a villager's telephone number and their complaint are not general
 * committee reading (PHASE_7_PLAN assumption N9).
 *
 * There is no destroy method. `spam` takes a row out of the inbox and keeps it,
 * because a complaint its subject can delete is not a complaint (N8).
 */
class EnquiryController extends Controller
{
    public function __construct(private readonly EnquiryService $enquiries) {}

    /** GET /api/admin/enquiries */
    public function index(Request $request): JsonResponse
    {
        $enquiries = $this->enquiries->list([
            'status' => $request->query('status'),
            'category' => $request->query('category'),
            'assigned_to' => $request->query('assigned_to'),
            'search' => $request->query('search'),
            'per_page' => $request->query('per_page'),
        ]);

        return ApiResponse::paginated(
            $enquiries,
            AdminEnquiryResource::collection($enquiries->getCollection()),
        );
    }

    /** GET /api/admin/enquiries/summary */
    public function summary(Request $request): JsonResponse
    {
        return ApiResponse::success($this->enquiries->summary([
            'category' => $request->query('category'),
            'assigned_to' => $request->query('assigned_to'),
            'search' => $request->query('search'),
        ]));
    }

    /** GET /api/admin/enquiries/{enquiry} */
    public function show(Enquiry $enquiry): JsonResponse
    {
        $enquiry->load(['assignee:id,first_name,last_name', 'resolver:id,first_name,last_name']);

        // Opening one message is the single read this system audits: what is
        // being read is somebody's telephone number and their complaint.
        $this->enquiries->recordView($enquiry);

        return ApiResponse::success(new AdminEnquiryResource($enquiry));
    }

    /** PUT /api/admin/enquiries/{enquiry}/status */
    public function updateStatus(UpdateEnquiryStatusRequest $request, Enquiry $enquiry): JsonResponse
    {
        $updated = $this->enquiries->updateStatus(
            $enquiry,
            $request->validated(),
            $request->user(),
        );

        return ApiResponse::success(new AdminEnquiryResource($updated));
    }
}
