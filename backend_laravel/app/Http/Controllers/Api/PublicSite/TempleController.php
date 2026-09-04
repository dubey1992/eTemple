<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\PublicSite;

use App\Http\Controllers\Controller;
use App\Http\Resources\Temple\PublicCommitteeMemberResource;
use App\Http\Resources\Temple\PublicTempleProfileResource;
use App\Models\CommitteeMember;
use App\Services\Temple\CommitteeService;
use App\Services\Temple\TempleProfileService;
use App\Support\ApiResponse;
use App\Support\Language;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TempleController extends Controller
{
    public function __construct(
        private readonly TempleProfileService $profile,
        private readonly CommitteeService $committee,
    ) {}

    /**
     * GET /api/public/temple-profile?lang=hi|en
     *
     * Always answers, even before the committee has written anything: an
     * unconfigured temple returns empty values so the site renders its empty
     * states rather than an error.
     */
    public function profile(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));

        return ApiResponse::success(
            new PublicTempleProfileResource($this->profile->current(), $language)
        );
    }

    /**
     * GET /api/public/committee?lang=hi|en
     *
     * Published, currently-serving members only — filtered in the query, not the
     * serializer. Personal details appear only where consent is on record.
     */
    public function committee(Request $request): JsonResponse
    {
        $language = Language::fromRequest($request->query('lang'));

        $members = $this->committee->publicList()
            ->map(fn (CommitteeMember $member) => (new PublicCommitteeMemberResource($member, $language))
                ->resolve($request))
            ->all();

        return ApiResponse::success($members);
    }
}
