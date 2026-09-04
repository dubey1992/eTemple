<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;
use App\Support\ApiResponse;
use Illuminate\Auth\Access\AuthorizationException;
use Illuminate\Auth\AuthenticationException;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Http\Exceptions\HttpResponseException;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Session\TokenMismatchException;
use Illuminate\Validation\ValidationException;
use Symfony\Component\HttpKernel\Exception\HttpExceptionInterface;
use Symfony\Component\HttpKernel\Exception\MethodNotAllowedHttpException;
use Symfony\Component\HttpKernel\Exception\NotFoundHttpException;
use Symfony\Component\HttpKernel\Exception\TooManyRequestsHttpException;
use Throwable;

/**
 * Centralized exception handling.
 *
 * Every failure that reaches the API surface is turned into the standard error
 * envelope with a stable code. Internal details (messages of unexpected
 * exceptions, stack traces, SQL) are logged server-side and never returned
 * unless the application is explicitly in debug mode.
 */
final class ApiExceptionRenderer
{
    public static function register(Exceptions $exceptions): void
    {
        // Expected business-rule failures are answered, not alarming: they are
        // already recorded where it matters (AuthService logs login attempts).
        $exceptions->dontReport([
            DomainException::class,
        ]);

        $exceptions->render(function (Throwable $e, Request $request) {
            // HttpResponseException carries a response the framework built on
            // purpose - a rate limiter callback, or abort() with a response.
            // Render callbacks run before the framework unwraps it, so this must
            // fall through or every throttled request becomes a 500.
            if ($e instanceof HttpResponseException) {
                return null;
            }

            if (! self::expectsJson($request)) {
                return null;
            }

            return self::toResponse($e, $request);
        });

        $exceptions->context(fn () => [
            'request_id' => request()?->headers->get('X-Request-Id'),
        ]);
    }

    private static function expectsJson(Request $request): bool
    {
        return $request->is('api/*') || $request->expectsJson();
    }

    private static function toResponse(Throwable $e, Request $request): JsonResponse
    {
        return match (true) {
            $e instanceof DomainException => $e->render(),

            $e instanceof ValidationException => ApiResponse::error(
                ApiErrorCode::VALIDATION_FAILED,
                'The submitted data is invalid.',
                422,
                $e->errors(),
            ),

            $e instanceof AuthenticationException => ApiResponse::error(
                ApiErrorCode::UNAUTHENTICATED,
                'Authentication is required to access this resource.',
                401,
            ),

            $e instanceof TokenMismatchException => ApiResponse::error(
                ApiErrorCode::CSRF_TOKEN_MISMATCH,
                'The session token has expired. Please reload and try again.',
                419,
            ),

            $e instanceof AuthorizationException => ApiResponse::error(
                ApiErrorCode::FORBIDDEN,
                'You are not allowed to perform this action.',
                403,
            ),

            $e instanceof ModelNotFoundException, $e instanceof NotFoundHttpException => ApiResponse::error(
                ApiErrorCode::NOT_FOUND,
                'The requested resource was not found.',
                404,
            ),

            $e instanceof MethodNotAllowedHttpException => ApiResponse::error(
                ApiErrorCode::METHOD_NOT_ALLOWED,
                'This method is not supported for the requested route.',
                405,
            ),

            $e instanceof TooManyRequestsHttpException => ApiResponse::error(
                ApiErrorCode::TOO_MANY_REQUESTS,
                'Too many attempts. Please wait a moment and try again.',
                429,
            ),

            $e instanceof HttpExceptionInterface => ApiResponse::error(
                self::codeForStatus($e->getStatusCode()),
                $e->getMessage() !== '' ? $e->getMessage() : 'Request failed.',
                $e->getStatusCode(),
            ),

            default => self::serverError($e, $request),
        };
    }

    private static function serverError(Throwable $e, Request $request): JsonResponse
    {
        // Not reported here: the framework already reports the exception before
        // handing it to the renderer.
        return ApiResponse::error(
            ApiErrorCode::SERVER_ERROR,
            'An unexpected error occurred. The temple committee has been notified.',
            500,
            config('app.debug') === true
                ? [
                    'exception' => $e::class,
                    'message' => $e->getMessage(),
                    'path' => $request->path(),
                ]
                : null,
        );
    }

    private static function codeForStatus(int $status): string
    {
        return match ($status) {
            401 => ApiErrorCode::UNAUTHENTICATED,
            403 => ApiErrorCode::FORBIDDEN,
            404 => ApiErrorCode::NOT_FOUND,
            405 => ApiErrorCode::METHOD_NOT_ALLOWED,
            419 => ApiErrorCode::CSRF_TOKEN_MISMATCH,
            429 => ApiErrorCode::TOO_MANY_REQUESTS,
            default => ApiErrorCode::SERVER_ERROR,
        };
    }
}
