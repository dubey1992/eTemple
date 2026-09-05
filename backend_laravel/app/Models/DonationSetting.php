<?php

declare(strict_types=1);

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

/**
 * Singleton row of the public donation details: UPI, bank and the QR code.
 *
 * Always read through `DonationSettingService::current()` so exactly one row
 * exists, as with `site_settings` and `temple_profiles`.
 *
 * @property bool $is_published
 * @property string|null $upi_id
 * @property string|null $qr_url
 */
class DonationSetting extends Model
{
    /** @var list<string> */
    protected $fillable = [
        'upi_id', 'bank_name', 'account_name', 'account_number', 'ifsc',
        'qr_url',
        'intro_hi', 'intro_en', 'note_hi', 'note_en',
        'is_published',
    ];

    /** @return array<string, string> */
    protected function casts(): array
    {
        return ['is_published' => 'boolean'];
    }

    /** @return BelongsTo<User, $this> */
    public function updatedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    /**
     * True when there is actually somewhere to send money.
     *
     * `is_published` on its own is not enough: a row published with every field
     * still blank would render an empty box on the public page, which reads as
     * a broken site rather than an unconfigured one.
     */
    public function hasPayableDetails(): bool
    {
        foreach (['upi_id', 'bank_name', 'account_number', 'qr_url'] as $field) {
            if (trim((string) $this->{$field}) !== '') {
                return true;
            }
        }

        return false;
    }

    public function isPubliclyVisible(): bool
    {
        return $this->is_published && $this->hasPayableDetails();
    }
}
