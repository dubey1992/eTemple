<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Resources\Admin\AuditLogResource;
use App\Models\AuditLog;
use App\Support\ApiResponse;
use App\Support\AuditAction;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * The audit trail (spec Phase 11).
 *
 * **Read only, and that is the whole controller.** There is no POST, no PUT and
 * no DELETE at any permission: the trail is append-only, and an endpoint that
 * could edit it would make every row in it worthless.
 *
 * There is also **no export**. Phase 10 gave every report a CSV, an XLSX and a
 * printable document; this deliberately has none. An audit trail carries donor
 * names, enquirers' references and the amounts on edited entries — a trail that
 * can be downloaded as a spreadsheet is a personal-data leak with an
 * official-sounding name (PHASE_11_PLAN assumption S5).
 */
class AuditLogController extends Controller
{
    /**
     * GET /api/admin/audit-logs
     *
     * Newest first, because the question is nearly always "what just happened".
     */
    public function index(Request $request): JsonResponse
    {
        $query = AuditLog::query()->newestFirst();

        $action = (string) $request->query('action', '');
        if ($action !== '' && AuditAction::exists($action)) {
            $query->where('action', $action);
        }

        $entityType = (string) $request->query('entity_type', '');
        if ($entityType !== '') {
            $query->where('entity_type', $entityType);

            $entityId = $request->query('entity_id');
            if (is_numeric($entityId)) {
                $query->where('entity_id', (int) $entityId);
            }
        }

        $userId = $request->query('user_id');
        if (is_numeric($userId)) {
            $query->where('user_id', (int) $userId);
        }

        // A date window, read as plain dates: an audit trail is read by day,
        // and a timezone shifting the boundary is the defect Phase 4 spent a
        // red build finding.
        $from = (string) $request->query('from', '');
        if ($from !== '') {
            $query->whereDate('created_at', '>=', $from);
        }

        $to = (string) $request->query('to', '');
        if ($to !== '') {
            $query->whereDate('created_at', '<=', $to);
        }

        $perPage = min(max((int) $request->query('per_page', 50), 1), 200);

        $page = $query->paginate($perPage);

        return ApiResponse::paginated($page, AuditLogResource::collection($page->items()));
    }

    /**
     * GET /api/admin/audit-logs/actions
     *
     * The vocabulary, so a filter can offer the real list rather than a text
     * box that matches nothing.
     */
    public function actions(): JsonResponse
    {
        return ApiResponse::success([
            'actions' => array_map(
                static fn (string $action): array => [
                    'key' => $action,
                    'label' => AuditAction::label($action),
                ],
                AuditAction::all(),
            ),
        ]);
    }
}
