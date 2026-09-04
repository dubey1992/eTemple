<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Role;
use App\Support\Permission;
use Illuminate\Database\Seeder;

/**
 * Production-safe, idempotent seed of the five roles named by the specification,
 * with the Phase 2 default permission matrix.
 *
 * Re-running this **does not** overwrite permissions that the committee has
 * since customised through the admin UI — defaults are applied only when a role
 * has never been configured. Otherwise a routine deploy would silently undo
 * their access decisions.
 */
class RoleSeeder extends Seeder
{
    /** @var list<array{slug: string, name: string, description: string}> */
    private const ROLES = [
        [
            'slug' => Role::SUPER_ADMIN,
            'name' => 'Super Admin',
            'description' => 'Full access including user, role and security management.',
        ],
        [
            'slug' => Role::ADMIN,
            'name' => 'Admin',
            'description' => 'Day-to-day administration of temple content and operations.',
        ],
        [
            'slug' => Role::TREASURER,
            'name' => 'Treasurer',
            'description' => 'Manages donations and accounting; cannot change security settings.',
        ],
        [
            'slug' => Role::CONTENT_MANAGER,
            'name' => 'Content Manager',
            'description' => 'Manages pages, events and media; no access to financial details.',
        ],
        [
            'slug' => Role::VIEWER,
            'name' => 'Viewer',
            'description' => 'Read-only access to permitted modules.',
        ],
    ];

    public function run(): void
    {
        $defaults = Permission::defaultsByRole();

        foreach (self::ROLES as $definition) {
            /** @var Role $role */
            $role = Role::query()->firstOrNew(['slug' => $definition['slug']]);

            $isNew = ! $role->exists;

            $role->name = $definition['name'];
            $role->description = $definition['description'];
            $role->status = Role::STATUS_ACTIVE;

            // Super Admin's set is computed, never stored (see Role::effectivePermissions).
            if ($definition['slug'] === Role::SUPER_ADMIN) {
                $role->permissions = null;
            } elseif ($isNew || $role->permissions === null) {
                $role->permissions = $defaults[$definition['slug']] ?? [];
            }

            $role->save();
        }
    }
}
