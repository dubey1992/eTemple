<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Minimal protected endpoint proving the admin route group is enforced on the
 * server. Phase 2 replaces this with the real admin dashboard endpoints.
 */
class AdminPingController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return ApiResponse::success([
            'status' => 'ok',
            'user' => (new UserResource($user->load('role')))->resolve($request),
        ]);
    }
}
