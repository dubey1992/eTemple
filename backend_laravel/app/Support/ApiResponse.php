<?php

declare(strict_types=1);

namespace App\Support;

use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Resources\Json\JsonResource;
use Illuminate\Http\Resources\Json\ResourceCollection;

/**
 * The single JSON envelope used by every endpoint in this API.
 *
 * Success: {"success": true,  "data": <mixed>, "meta": <object|null>}
 * Error:   {"success": false, "error": {"code": "...", "message": "...", "details": <object|null>}}
 *
 * Defined once here (spec: "Use a consistent JSON envelope/error structure across
 * endpoints" and "Define pagination/filter conventions once and reuse them") and
 * reused by all later phases.
 */
final class ApiResponse
{
    /**
     * @param  array<string, mixed>|null  $meta
     */
    public static function success(mixed $data = null, ?array $meta = null, int $status = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'data' => self::normalize($data),
            'meta' => $meta,
        ], $status);
    }

    public static function message(string $message, int $status = 200): JsonResponse
    {
        return self::success(['message' => $message], null, $status);
    }

    public static function noContent(): JsonResponse
    {
        return response()->json(null, 204);
    }

    /**
     * @param  array<string, mixed>|null  $details
     */
    public static function error(
        string $code,
        string $message,
        int $status,
        ?array $details = null,
    ): JsonResponse {
        return response()->json([
            'success' => false,
            'error' => array_filter([
                'code' => $code,
                'message' => $message,
                'details' => $details,
            ], static fn ($value) => $value !== null),
        ], $status);
    }

    /**
     * Paginated collection using the project-wide `meta` convention.
     *
     * @param  LengthAwarePaginator<int, mixed>  $paginator
     */
    public static function paginated(LengthAwarePaginator $paginator, mixed $data = null): JsonResponse
    {
        return self::success(
            $data ?? $paginator->items(),
            self::paginationMeta($paginator),
        );
    }

    /**
     * @param  LengthAwarePaginator<int, mixed>  $paginator
     * @return array<string, mixed>
     */
    public static function paginationMeta(LengthAwarePaginator $paginator): array
    {
        return [
            'current_page' => $paginator->currentPage(),
            'per_page' => $paginator->perPage(),
            'total' => $paginator->total(),
            'last_page' => $paginator->lastPage(),
            'has_more' => $paginator->hasMorePages(),
        ];
    }

    /**
     * API Resources wrap themselves in their own "data" key; resolve them here so
     * the envelope never nests data inside data.
     */
    private static function normalize(mixed $data): mixed
    {
        if ($data instanceof JsonResource || $data instanceof ResourceCollection) {
            return $data->resolve();
        }

        return $data;
    }
}
