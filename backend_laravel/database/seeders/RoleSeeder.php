<?php

declare(strict_types=1);

namespace Database\Seeders;

use App\Models\Role;
use Illuminate\Database\Seeder;

/**
 * Production-safe, idempotent seed of the five roles named by the specification.
 *
 * Permission keys are deliberately left null — the permission matrix is Phase 2.
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
        foreach (self::ROLES as $role) {
            Role::query()->updateOrCreate(
                ['slug' => $role['slug']],
                [
                    'name' => $role['name'],
                    'description' => $role['description'],
                    'status' => Role::STATUS_ACTIVE,
                ],
            );
        }
    }
}
