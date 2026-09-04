<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Temple\UpdateTempleProfileRequest;
use App\Http\Resources\Temple\AdminTempleProfileResource;
use App\Models\User;
use App\Services\Temple\TempleProfileService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;

class TempleProfileController extends Controller
{
    public function __construct(private readonly TempleProfileService $profile) {}

    /** GET /api/admin/temple-profile */
    public function show(): JsonResponse
    {
        return ApiResponse::success(new AdminTempleProfileResource($this->profile->current()));
    }

    /** PUT /api/admin/temple-profile */
    public function update(UpdateTempleProfileRequest $request): JsonResponse
    {
        /** @var User $editor */
        $editor = $request->user();

        $profile = $this->profile->update($request->validated(), $editor);

        return ApiResponse::success(new AdminTempleProfileResource($profile));
    }
}
