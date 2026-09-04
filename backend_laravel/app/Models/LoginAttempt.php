<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\LoginAttemptFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * One recorded sign-in attempt.
 *
 * @property int $id
 * @property int|null $user_id
 * @property string $email
 * @property string $outcome
 * @property string|null $ip_address
 * @property string|null $user_agent
 * @property Carbon|null $created_at
 */
class LoginAttempt extends Model
{
    /** @use HasFactory<LoginAttemptFactory> */
    use HasFactory;

    public const OUTCOME_SUCCESS = 'success';

    public const OUTCOME_INVALID_CREDENTIALS = 'invalid_credentials';

    public const OUTCOME_INACTIVE = 'inactive';

    public const OUTCOME_BLOCKED = 'blocked';

    /** Written once and never updated, so only created_at is meaningful. */
    public const UPDATED_AT = null;

    /** @var list<string> */
    protected $fillable = ['user_id', 'email', 'outcome', 'ip_address', 'user_agent'];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['created_at' => 'datetime'];
    }

    /** @return BelongsTo<User, $this> */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function wasSuccessful(): bool
    {
        return $this->outcome === self::OUTCOME_SUCCESS;
    }
}
