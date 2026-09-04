<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Temple\StoreCommitteeMemberRequest;
use App\Http\Resources\Temple\AdminCommitteeMemberResource;
use App\Models\CommitteeMember;
use App\Models\User;
use App\Services\Temple\CommitteeService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CommitteeMemberController extends Controller
{
    public function __construct(private readonly CommitteeService $committee) {}

    /**
     * GET /api/admin/committee-members
     *
     * Every member, including unpublished and past ones. The list is bounded by
     * the size of a village committee, so it is not paginated.
     */
    public function index(Request $request): JsonResponse
    {
        $members = $this->committee->adminList()
            ->map(fn (CommitteeMember $member) => (new AdminCommitteeMemberResource($member))->resolve($request))
            ->all();

        return ApiResponse::success($members);
    }

    /** GET /api/admin/committee-members/{member} */
    public function show(CommitteeMember $member): JsonResponse
    {
        $member->loadMissing('consentRecordedBy');

        return ApiResponse::success(new AdminCommitteeMemberResource($member));
    }

    /** POST /api/admin/committee-members */
    public function store(StoreCommitteeMemberRequest $request): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $member = $this->committee->create($request->validated(), $actor);

        return ApiResponse::success(new AdminCommitteeMemberResource($member), null, 201);
    }

    /** PUT /api/admin/committee-members/{member} */
    public function update(StoreCommitteeMemberRequest $request, CommitteeMember $member): JsonResponse
    {
        /** @var User $actor */
        $actor = $request->user();

        $updated = $this->committee->update($member, $request->validated(), $actor);

        return ApiResponse::success(new AdminCommitteeMemberResource($updated));
    }

    /**
     * DELETE /api/admin/committee-members/{member}
     *
     * Genuine erasure, distinct from ending a tenure — see CommitteeService.
     */
    public function destroy(CommitteeMember $member): JsonResponse
    {
        $this->committee->delete($member);

        return ApiResponse::noContent();
    }
}
