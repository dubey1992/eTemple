<?php

declare(strict_types=1);

namespace App\Models;

use App\Support\Permission;
use Database\Factories\RoleFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\HasMany;

/**
 * Baseline role model required by the Phase 0 authentication foundation.
 *
 * The `permissions` column is reserved for Phase 2 (permission matrix by module)
 * and is intentionally left null by the Phase 0 seeder.
 *
 * @property int $id
 * @property string $slug
 * @property string $name
 * @property string|null $description
 * @property array<int, string>|null $permissions
 * @property string $status
 */
class Role extends Model
{
    /** @use HasFactory<RoleFactory> */
    use HasFactory;

    public const SUPER_ADMIN = 'super-admin';

    public const ADMIN = 'admin';

    public const TREASURER = 'treasurer';

    public const CONTENT_MANAGER = 'content-manager';

    public const VIEWER = 'viewer';

    public const STATUS_ACTIVE = 'active';

    public const STATUS_INACTIVE = 'inactive';

    /** All roles defined by the specification, in descending order of privilege. */
    public const ALL = [
        self::SUPER_ADMIN,
        self::ADMIN,
        self::TREASURER,
        self::CONTENT_MANAGER,
        self::VIEWER,
    ];

    protected $fillable = [
        'slug',
        'name',
        'description',
        'permissions',
        'status',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'permissions' => 'array',
        ];
    }

    /** @return HasMany<User, $this> */
    public function users(): HasMany
    {
        return $this->hasMany(User::class);
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    public function isSuperAdmin(): bool
    {
        return $this->slug === self::SUPER_ADMIN;
    }

    /**
     * The permission keys this role actually grants.
     *
     * Super Admin is computed, never stored: its set is the whole catalogue and
     * cannot be edited, so the temple can never be locked out of its own
     * administration (PHASE_2_PLAN assumption C3).
     *
     * Unknown keys left over from an older catalogue are filtered out rather
     * than trusted.
     *
     * @return list<string>
     */
    public function effectivePermissions(): array
    {
        if ($this->isSuperAdmin()) {
            return Permission::all();
        }

        return array_values(array_filter(
            $this->permissions ?? [],
            static fn (mixed $key) => is_string($key) && Permission::exists($key),
        ));
    }

    public function grants(string $permission): bool
    {
        return in_array($permission, $this->effectivePermissions(), true);
    }
}
