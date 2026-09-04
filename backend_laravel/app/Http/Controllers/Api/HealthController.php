<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;
use Throwable;

/**
 * Deployment/liveness probe. Reports only non-sensitive facts.
 */
class HealthController extends Controller
{
    public function __invoke(): JsonResponse
    {
        return ApiResponse::success([
            'status' => 'ok',
            'application' => config('app.name'),
            'environment' => config('app.env'),
            'timezone' => config('app.timezone'),
            'locale' => config('app.locale'),
            'database' => $this->databaseStatus(),
            'time' => now()->toIso8601String(),
        ]);
    }

    private function databaseStatus(): string
    {
        try {
            DB::connection()->getPdo();

            return 'connected';
        } catch (Throwable) {
            return 'unavailable';
        }
    }
}
