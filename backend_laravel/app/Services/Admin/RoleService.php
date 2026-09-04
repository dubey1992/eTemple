<?php

declare(strict_types=1);

namespace App\Services\Admin;

use App\Exceptions\AdminGuardException;
use App\Models\Role;
use App\Support\Permission;
use Illuminate\Database\Eloquent\Collection;

/**
 * Role and permission-matrix management.
 */
class RoleService
{
    /** @return Collection<int, Role> */
    public function all(): Collection
    {
        return Role::query()->orderBy('id')->get();
    }

    /**
     * Replace a role's permission set.
     *
     * Two refusals matter here. Unknown keys are rejected rather than stored, so
     * a typo cannot silently grant nothing forever. And Super Admin cannot be
     * restricted at all — its set is computed, and allowing it to be trimmed is
     * how a temple ends up with nobody who can administer the site.
     *
     * @param  list<string>  $permissions
     *
     * @throws AdminGuardException
     */
    public function replacePermissions(Role $role, array $permissions): Role
    {
        if ($role->isSuperAdmin()) {
            throw AdminGuardException::superAdminPermissionsAreFixed();
        }

        $unknown = array_values(array_diff($permissions, Permission::all()));
        if ($unknown !== []) {
            throw AdminGuardException::unknownPermissions($unknown);
        }

        // Normalised: de-duplicated and in catalogue order, so stored data does
        // not vary with the order the UI happened to send.
        $role->permissions = array_values(array_intersect(
            Permission::all(),
            array_unique($permissions),
        ));
        $role->save();

        return $role->refresh();
    }
}
