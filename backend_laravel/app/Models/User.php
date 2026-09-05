<?php

declare(strict_types=1);

namespace App\Models;

use App\Mail\PasswordResetMail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Mail;

/**
 * Admin / committee user.
 *
 * Spec field `password_hash` is implemented as the framework-conventional
 * `password` column with a `hashed` cast, so a plain password can never be
 * persisted (see PHASE_0_PLAN assumption A1).
 *
 * @property int $id
 * @property string $first_name
 * @property string|null $last_name
 * @property string $email
 * @property string|null $mobile
 * @property string $password
 * @property int $role_id
 * @property string $status
 * @property Carbon|null $last_login_at
 * @property-read Role $role
 */
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasFactory;

    use Notifiable;

    public const STATUS_ACTIVE = 'active';

    public const STATUS_INACTIVE = 'inactive';

    public const STATUS_BLOCKED = 'blocked';

    /** @var list<string> */
    protected $fillable = [
        'first_name',
        'last_name',
        'email',
        'mobile',
        'password',
        'role_id',
        'status',
    ];

    /** @var list<string> */
    protected $hidden = [
        'password',
        'remember_token',
    ];

    /**
     * The reset link, in the temple's own words rather than the framework's.
     *
     * Laravel's default notification is in English and signs itself with
     * `APP_NAME`. This is the hook the password broker calls, so overriding it
     * here catches every path that asks for a reset — the forgot-password
     * endpoint and an administrator resending a link both come through.
     *
     * Sent rather than queued: see {@see PasswordResetMail}.
     */
    public function sendPasswordResetNotification(#[\SensitiveParameter] $token): void
    {
        Mail::to($this)->send(new PasswordResetMail($this, (string) $token));
    }

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'last_login_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /** @return BelongsTo<Role, $this> */
    public function role(): BelongsTo
    {
        return $this->belongsTo(Role::class);
    }

    public function fullName(): string
    {
        return trim($this->first_name.' '.($this->last_name ?? ''));
    }

    public function isActive(): bool
    {
        return $this->status === self::STATUS_ACTIVE;
    }

    public function isBlocked(): bool
    {
        return $this->status === self::STATUS_BLOCKED;
    }

    public function hasRole(string $slug): bool
    {
        return $this->role?->slug === $slug;
    }

    public function isSuperAdmin(): bool
    {
        return $this->hasRole(Role::SUPER_ADMIN);
    }

    /**
     * Whether this user's role grants a permission.
     *
     * An inactive or blocked account grants nothing regardless of its role —
     * the middleware already refuses such requests, and this keeps the answer
     * consistent anywhere else the check is made.
     */
    public function hasPermission(string $permission): bool
    {
        if (! $this->isActive()) {
            return false;
        }

        $this->loadMissing('role');

        return $this->role?->grants($permission) ?? false;
    }

    /** @return list<string> */
    public function effectivePermissions(): array
    {
        if (! $this->isActive()) {
            return [];
        }

        $this->loadMissing('role');

        return $this->role?->effectivePermissions() ?? [];
    }
}
