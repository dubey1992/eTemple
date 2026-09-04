<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Auth;

use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\Auth\AuthService;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Phase 0 authentication foundation.
 *
 * Thin controller: validation lives in Form Requests, business rules in
 * AuthService, and the response shape in ApiResponse.
 */
class AuthController extends Controller
{
    public function __construct(private readonly AuthService $auth) {}

    /** POST /api/auth/login */
    public function login(LoginRequest $request): JsonResponse
    {
        $user = $this->auth->login(
            $request,
            (string) $request->validated('email'),
            (string) $request->validated('password'),
            $request->remember(),
        );

        return ApiResponse::success(new UserResource($user));
    }

    /** POST /api/auth/logout */
    public function logout(Request $request): JsonResponse
    {
        $this->auth->logout($request);

        return ApiResponse::message('Signed out successfully.');
    }

    /** GET /api/auth/me */
    public function me(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        return ApiResponse::success(new UserResource($user->load('role')));
    }

    /**
     * POST /api/auth/forgot-password
     *
     * Always answers 200 with the same message, whether or not the address is
     * registered, so the endpoint cannot be used to enumerate accounts.
     */
    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        $this->auth->sendPasswordResetLink((string) $request->validated('email'));

        return ApiResponse::message(
            'If that e-mail address belongs to an active account, a password reset link has been sent.'
        );
    }
}
