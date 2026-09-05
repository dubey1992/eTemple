<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Carbon;

/**
 * Singleton row deciding whether the temple's books are public, and where they
 * start (spec Phase 9).
 *
 * Always read through `AccountingSettingService::current()` so exactly one row
 * exists, as with `site_settings`, `temple_profiles` and `donation_settings`.
 *
 * @property bool $is_published
 * @property int $opening_balance_paise
 * @property Carbon|null $opening_balance_date
 */
class AccountingSetting extends Model
{
    /** @var list<string> */
    protected $fillable = [
        'is_published',
        'opening_balance_paise', 'opening_balance_date',
        'intro_hi', 'intro_en', 'note_hi', 'note_en',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return [
            'is_published' => 'boolean',
            'opening_balance_paise' => 'integer',
            'opening_balance_date' => 'date',
        ];
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
