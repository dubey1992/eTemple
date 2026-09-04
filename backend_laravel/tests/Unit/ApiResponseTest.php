<?php

declare(strict_types=1);

namespace Tests\Unit;

use App\Support\ApiErrorCode;
use App\Support\ApiResponse;
use Illuminate\Pagination\LengthAwarePaginator;
use Tests\TestCase;

/**
 * The envelope is a contract shared with the Flutter client. If this test needs
 * changing, the Dart side changes in the same release.
 */
class ApiResponseTest extends TestCase
{
    public function test_success_envelope_shape(): void
    {
        $payload = ApiResponse::success(['id' => 1])->getData(true);

        $this->assertSame(
            ['success' => true, 'data' => ['id' => 1], 'meta' => null],
            $payload,
        );
    }

    public function test_error_envelope_shape(): void
    {
        $response = ApiResponse::error(
            ApiErrorCode::VALIDATION_FAILED,
            'The submitted data is invalid.',
            422,
            ['email' => ['The email field is required.']],
        );

        $this->assertSame(422, $response->getStatusCode());
        $this->assertSame([
            'success' => false,
            'error' => [
                'code' => 'VALIDATION_FAILED',
                'message' => 'The submitted data is invalid.',
                'details' => ['email' => ['The email field is required.']],
            ],
        ], $response->getData(true));
    }

    public function test_error_envelope_omits_null_details(): void
    {
        $payload = ApiResponse::error(ApiErrorCode::NOT_FOUND, 'Missing.', 404)->getData(true);

        $this->assertArrayNotHasKey('details', $payload['error']);
    }

    public function test_pagination_meta_convention(): void
    {
        $paginator = new LengthAwarePaginator(['a', 'b'], total: 7, perPage: 2, currentPage: 2);

        $this->assertSame([
            'current_page' => 2,
            'per_page' => 2,
            'total' => 7,
            'last_page' => 4,
            'has_more' => true,
        ], ApiResponse::paginationMeta($paginator));
    }
}
