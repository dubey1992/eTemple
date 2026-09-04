<?php

declare(strict_types=1);

namespace App\Models;

use Database\Factories\SiteSettingFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Singleton row of site-wide configurable content: tagline, footer, contact
 * details, social links and default SEO metadata.
 *
 * The postal address is **not** here. Phase 1 kept it in this table as a
 * stopgap; Phase 3 moved it to the authoritative `temple_profiles` row, so
 * there is exactly one source of truth for where the temple is.
 *
 * Always read through SiteSettingService::current() so exactly one row exists.
 */
class SiteSetting extends Model
{
    /** @use HasFactory<SiteSettingFactory> */
    use HasFactory;

    /** @var list<string> */
    protected $fillable = [
        'tagline_hi', 'tagline_en',
        'footer_text_hi', 'footer_text_en',
        'contact_phone', 'contact_email', 'social_links',
        'default_meta_title_hi', 'default_meta_title_en',
        'default_meta_description_hi', 'default_meta_description_en',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['social_links' => 'array'];
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }
}
