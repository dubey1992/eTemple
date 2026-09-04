<?php

declare(strict_types=1);

namespace App\Exceptions;

use App\Support\ApiErrorCode;
use App\Support\ApiResponse;
use Illuminate\Http\JsonResponse;
use RuntimeException;

/**
 * Base class for expected, business-rule failures.
 *
 * Anything thrown from a service/action that the caller is allowed to see should
 * extend this, so the renderer can turn it into a stable envelope without leaking
 * framework internals.
 */
class DomainException extends RuntimeException
{
    /**
     * @param  array<string, mixed>|null  $details
     */
    public function __construct(
        public readonly string $errorCode = ApiErrorCode::SERVER_ERROR,
        string $message = 'Request could not be completed.',
        public readonly int $status = 400,
        public readonly ?array $details = null,
    ) {
        parent::__construct($message);
    }

    public function render(): JsonResponse
    {
        return ApiResponse::error($this->errorCode, $this->getMessage(), $this->status, $this->details);
    }
}
