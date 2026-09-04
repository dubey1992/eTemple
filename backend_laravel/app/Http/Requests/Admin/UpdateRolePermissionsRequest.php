<?php

declare(strict_types=1);

namespace App\Http\Requests\Admin;

use App\Support\Permission;
use Illuminate\Foundation\Http\FormRequest;

/**
 * Replaces a role's permission set.
 *
 * Keys are validated against the catalogue here and again in RoleService, which
 * reports unknown keys by name rather than a generic "invalid" message.
 */
class UpdateRolePermissionsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->can(Permission::ROLES_MANAGE) ?? false;
    }

    /** @return array<string, array<int, mixed>> */
    public function rules(): array
    {
        return [
            'permissions' => ['present', 'array', 'max:100'],
            'permissions.*' => ['string', 'max:64'],
        ];
    }
}
