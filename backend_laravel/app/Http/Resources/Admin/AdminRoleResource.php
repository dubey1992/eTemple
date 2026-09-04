<?php

declare(strict_types=1);

namespace App\Http\Resources\Admin;

use App\Models\Role;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A role with the permissions it actually grants.
 *
 * `is_editable` is false for Super Admin, whose set is computed and fixed, so
 * the matrix UI can render it read-only instead of offering a save that the
 * server would refuse.
 *
 * @mixin Role
 */
class AdminRoleResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'name' => $this->name,
            'description' => $this->description,
            'status' => $this->status,
            'permissions' => $this->effectivePermissions(),
            'is_editable' => ! $this->isSuperAdmin(),
            'user_count' => $this->whenCounted('users'),
        ];
    }
}
