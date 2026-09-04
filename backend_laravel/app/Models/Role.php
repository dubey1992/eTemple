<?php

declare(strict_types=1);

namespace App\Models;

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
}
