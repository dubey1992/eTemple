<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\TempleProfileFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Singleton row holding the temple's own identity (spec Phase 3 entity).
 *
 * Authoritative for the name, the address, the history and the mission. Always
 * read through TempleProfileService::current() so exactly one row exists.
 *
 * @property int $id
 * @property string|null $name_hi
 * @property string|null $name_en
 * @property string|null $village_hi
 * @property string|null $village_en
 */
class TempleProfile extends Model
{
    /** @use HasFactory<TempleProfileFactory> */
    use HasFactory;

    /**
     * The address parts that exist in two scripts, in the order they render.
     *
     * Named once here because the migration, the form request and both
     * resources all need the same list. `postal_code` is not in it: `813204` is
     * `813204` in either language.
     *
     * @var list<string>
     */
    public const BILINGUAL_ADDRESS_PARTS = [
        'address_line1', 'address_line2', 'village', 'panchayat',
        'police_station', 'district', 'state', 'country',
    ];

    /**
     * The postal address columns, in the order they are rendered.
     *
     * @var list<string>
     */
    public const ADDRESS_COLUMNS = [
        'address_line1_hi', 'address_line1_en',
        'address_line2_hi', 'address_line2_en',
        'village_hi', 'village_en',
        'panchayat_hi', 'panchayat_en',
        'police_station_hi', 'police_station_en',
        'district_hi', 'district_en',
        'state_hi', 'state_en',
        'postal_code',
        'country_hi', 'country_en',
    ];

    /** @var list<string> */
    protected $fillable = [
        'name_hi', 'name_en',
        'history_hi', 'history_en',
        'mission_hi', 'mission_en',
        ...self::ADDRESS_COLUMNS,
        'logo_url', 'map_url', 'established_year',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['established_year' => 'integer'];
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /** True when the committee has not written the temple's name yet. */
    public function hasName(): bool
    {
        return trim((string) $this->name_hi) !== '' || trim((string) $this->name_en) !== '';
    }
}
