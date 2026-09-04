<?php

declare(strict_types=1);

namespace App\Http\Resources\Admin;

use App\Http\Resources\RoleResource;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * A committee account as the user-management screens see it.
 * The password hash is never part of this shape.
 *
 * @mixin User
 */
class AdminUserResource extends JsonResource
{
    /** @return array<string, mixed> */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'first_name' => $this->first_name,
            'last_name' => $this->last_name,
            'full_name' => $this->fullName(),
            'email' => $this->email,
            'mobile' => $this->mobile,
            'status' => $this->status,
            'last_login_at' => $this->last_login_at?->toIso8601String(),
            'created_at' => $this->created_at?->toIso8601String(),
            'role' => $this->whenLoaded('role', fn () => new RoleResource($this->role)),
        ];
    }
}
