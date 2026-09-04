<?php

declare(strict_types=1);

namespace App\Http\Resources;

use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

/**
 * The authenticated user as seen by the Flutter client.
 *
 * The password hash and remember token are never part of this shape.
 *
 * @mixin User
 */
class UserResource extends JsonResource
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
            'role' => $this->whenLoaded('role', fn () => new RoleResource($this->role)),
            // The client uses these to hide what the server would refuse. It is a
            // courtesy for the operator, never the access control - every
            // protected endpoint checks the same permissions independently.
            'permissions' => $this->effectivePermissions(),
        ];
    }
}
