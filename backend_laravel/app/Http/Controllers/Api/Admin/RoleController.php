<?php

declare(strict_types=1);

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Http\Requests\Admin\UpdateRolePermissionsRequest;
use App\Http\Resources\Admin\AdminRoleResource;
use App\Models\Role;
use App\Services\Admin\RoleService;
use App\Support\ApiResponse;
use App\Support\Permission;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RoleController extends Controller
{
    public function __construct(private readonly RoleService $roles) {}

    /** GET /api/admin/roles */
    public function index(Request $request): JsonResponse
    {
        $roles = Role::query()->withCount('users')->orderBy('id')->get();

        return ApiResponse::success(
            AdminRoleResource::collection($roles)->resolve($request),
        );
    }

    /** GET /api/admin/permissions — the catalogue the matrix UI renders. */
    public function permissions(): JsonResponse
    {
        $modules = [];
        foreach (Permission::catalogue() as $key => $module) {
            $modules[] = [
                'module' => $key,
                'label' => $module['label'],
                // Tells the UI which toggles are reserved for a later phase, so
                // the committee is not misled into thinking one already applies.
                'phase' => $module['phase'],
                'permissions' => array_map(
                    static fn (string $k, string $label) => ['key' => $k, 'label' => $label],
                    array_keys($module['permissions']),
                    array_values($module['permissions']),
                ),
            ];
        }

        return ApiResponse::success(['modules' => $modules]);
    }

    /** PUT /api/admin/roles/{role}/permissions */
    public function updatePermissions(UpdateRolePermissionsRequest $request, Role $role): JsonResponse
    {
        /** @var list<string> $permissions */
        $permissions = $request->validated('permissions');

        $updated = $this->roles->replacePermissions($role, $permissions);

        return ApiResponse::success(new AdminRoleResource($updated));
    }
}
