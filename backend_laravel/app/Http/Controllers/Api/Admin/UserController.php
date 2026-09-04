<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\StoreUserRequest;
use App\Http\Requests\Admin\UpdateUserRequest;
use App\Http\Resources\Admin\AdminUserResource;
use App\Http\Resources\Admin\LoginAttemptResource;
use App\Models\User;
use App\Services\Admin\LoginHistoryService;
use App\Services\Admin\UserService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class UserController extends Controller
{
    public function __construct(
        private readonly UserService $users,
        private readonly LoginHistoryService $history,
    ) {}

    /** GET /api/admin/users */
    public function index(Request $request): JsonResponse
    {
        $paginator = $this->users->paginate(
            [
                'search' => $request->string('search')->trim()->value() ?: null,
                'role' => $request->string('role')->trim()->value() ?: null,
                'status' => $request->string('status')->trim()->value() ?: null,
            ],
            (int) $request->integer('per_page', 25),
        );

        return ApiResponse::paginated(
            $paginator,
            AdminUserResource::collection($paginator->getCollection())->resolve($request),
        );
    }

    /** POST /api/admin/users */
    public function store(StoreUserRequest $request): JsonResponse
    {
        $user = $this->users->create($request->validated());

        return ApiResponse::success(new AdminUserResource($user), status: 201);
    }

    /** GET /api/admin/users/{user} */
    public function show(User $user): JsonResponse
    {
        return ApiResponse::success(new AdminUserResource($user->load('role')));
    }

    /** PUT /api/admin/users/{user} */
    public function update(UpdateUserRequest $request, User $user): JsonResponse
    {
        /** @var User $editor */
        $editor = $request->user();

        $updated = $this->users->update($user, $request->validated(), $editor);

        return ApiResponse::success(new AdminUserResource($updated));
    }

    /** GET /api/admin/users/{user}/login-history */
    public function loginHistory(Request $request, User $user): JsonResponse
    {
        $paginator = $this->history->forUser($user, (int) $request->integer('per_page', 25));

        return ApiResponse::paginated(
            $paginator,
            LoginAttemptResource::collection($paginator->getCollection())->resolve($request),
        );
    }

    /** POST /api/admin/users/{user}/send-password-reset */
    public function sendPasswordReset(User $user): JsonResponse
    {
        $this->users->sendPasswordResetLink($user);

        return ApiResponse::message('A password reset link has been sent.');
    }
}
